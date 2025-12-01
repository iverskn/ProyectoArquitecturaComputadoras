#!/usr/bin/env python3
"""
Decodificador MIPS32 (R/I/J) con GUI Tkinter.
Soporta:
  R: ADD, SUB, AND, OR, SLT
  I: ADDI, ANDI, ORI, XORI, SLTI, BEQ, LW, SW
  J: J

Características:
- Dos pasadas: primera para labels, segunda para ensamblar.
- Salida .txt formateada en 4 bloques de 8 bits (Big Endian) para memoria Verilog.
- GUI con vista previa idéntica al archivo de salida.
"""

import tkinter as tk
from tkinter import filedialog, messagebox
import struct
import sys
import re
from typing import List, Tuple, Dict, Optional

# ---------------------------
# Configuración básica
# ---------------------------

START_ADDRESS = 0x00000000  # Dirección inicial del PC.

# Registros por nombre y por número
REGISTERS = {f'${i}': i for i in range(32)}
REGISTERS.update({
    '$zero': 0, '$at': 1, '$v0': 2, '$v1': 3,
    '$a0': 4, '$a1': 5, '$a2': 6, '$a3': 7,
    '$t0': 8, '$t1': 9, '$t2': 10, '$t3': 11,
    '$t4': 12, '$t5': 13, '$t6': 14, '$t7': 15,
    '$s0': 16, '$s1': 17, '$s2': 18, '$s3': 19,
    '$s4': 20, '$s5': 21, '$s6': 22, '$s7': 23,
    '$t8': 24, '$t9': 25, '$k0': 26, '$k1': 27,
    '$gp': 28, '$sp': 29, '$fp': 30, '$ra': 31
})

# Tabla de instrucciones
INSTRUCTION_SET = {
    # R-type: opcode=0, funct
    'ADD':  {'type': 'R', 'opcode': 0, 'funct': 0x20},
    'SUB':  {'type': 'R', 'opcode': 0, 'funct': 0x22},
    'AND':  {'type': 'R', 'opcode': 0, 'funct': 0x24},
    'OR':   {'type': 'R', 'opcode': 0, 'funct': 0x25},
    'SLT':  {'type': 'R', 'opcode': 0, 'funct': 0x2A},
    # I-type
    'ADDI': {'type': 'I', 'opcode': 0x08},
    'ANDI': {'type': 'I', 'opcode': 0x0C},
    'ORI':  {'type': 'I', 'opcode': 0x0D},
    'XORI': {'type': 'I', 'opcode': 0x0E},
    'SLTI': {'type': 'I', 'opcode': 0x0A},
    'BEQ':  {'type': 'I', 'opcode': 0x04},
    'LW':   {'type': 'I', 'opcode': 0x23},
    'SW':   {'type': 'I', 'opcode': 0x2B},
    # J-type
    'J':    {'type': 'J', 'opcode': 0x02}
}

# ---------------------------
# Utilidades de parsing
# ---------------------------

def int_to_bin_str(val: int, bits: int) -> str:
    """Devuelve representación binaria de val en 'bits' bits (dos complementos si es negativo)."""
    if val < 0:
        val = (1 << bits) + val
    return format(val & ((1 << bits) - 1), f'0{bits}b')

def parse_register(tok: str, line_no: int) -> int:
    tok = tok.strip()
    if tok.endswith(','):
        tok = tok[:-1]
    if tok in REGISTERS:
        return REGISTERS[tok]
    m = re.match(r'^\$?(\d+)$', tok)
    if m:
        num = int(m.group(1))
        if 0 <= num < 32:
            return num
    raise ValueError(f"Línea {line_no}: Registro inválido '{tok}'")

def parse_immediate(tok: str, line_no: int) -> int:
    tok = tok.strip()
    if tok.endswith(','):
        tok = tok[:-1]
    try:
        return int(tok, 0)
    except:
        raise ValueError(f"Línea {line_no}: Inmediato inválido '{tok}'")

# ---------------------------
# Primera pasada: recolectar labels
# ---------------------------

def first_pass(lines: List[str]) -> Dict[str, int]:
    labels = {}
    pc = START_ADDRESS
    for idx, raw in enumerate(lines):
        line = raw.split('#')[0].strip()
        if not line:
            continue
        while True:
            m = re.match(r'^([A-Za-z_]\w*):\s*(.*)$', line)
            if m:
                label = m.group(1)
                rest = m.group(2)
                if label in labels:
                    raise ValueError(f"Línea {idx+1}: Label '{label}' redeclarado")
                labels[label] = pc
                line = rest.strip()
                if not line:
                    break
            else:
                break
        if line:
            pc += 4
    return labels

# ---------------------------
# Ensamblador (segunda pasada)
# ---------------------------

def assemble_lines(lines: List[str]) -> Tuple[List[str], List[str]]:
    """
    Ensambla y devuelve (bin_lines_32bit_text, errors).
    bin_lines_32bit_text: lista de strings "0101..." de 32 bits.
    """
    errors = []
    try:
        labels = first_pass(lines)
    except Exception as e:
        return [], [str(e)]

    pc = START_ADDRESS
    output_bin_lines = []

    for idx, raw in enumerate(lines):
        line_no = idx + 1
        line = raw.split('#')[0].strip()
        if not line:
            continue

        # Sacar labels
        while True:
            m = re.match(r'^([A-Za-z_]\w*):\s*(.*)$', line)
            if m:
                line = m.group(2).strip()
                if not line: break
            else:
                break
        if not line: continue

        toks = line.replace(',', ' , ').replace('(', ' ( ').replace(')', ' ) ').split()
        if not toks: continue
        
        mnemonic = toks[0].upper()
        if mnemonic not in INSTRUCTION_SET:
            errors.append(f"Línea {line_no}: Instrucción desconocida '{mnemonic}'")
            pc += 4
            continue

        info = INSTRUCTION_SET[mnemonic]
        try:
            if info['type'] == 'R':
                regs = [t for t in toks[1:] if t != ',']
                if len(regs) != 3:
                    raise ValueError(f"Línea {line_no}: R-type espera 3 operandos")
                rd = parse_register(regs[0], line_no)
                rs = parse_register(regs[1], line_no)
                rt = parse_register(regs[2], line_no)
                shamt = 0
                binstr = (int_to_bin_str(info['opcode'],6) +
                          int_to_bin_str(rs,5) +
                          int_to_bin_str(rt,5) +
                          int_to_bin_str(rd,5) +
                          int_to_bin_str(shamt,5) +
                          int_to_bin_str(info['funct'],6))
                output_bin_lines.append(binstr)

            elif info['type'] == 'I':
                opcode = info['opcode']
                if mnemonic in ('LW', 'SW'):
                    # Parse LW/SW format: offset(base)
                    tail = line[len(mnemonic):].strip()
                    m = re.match(r'^\s*(\$[\w\d]+)\s*,\s*([\-]?\w+)\s*\(\s*(\$[\w\d]+)\s*\)\s*$', tail)
                    if not m:
                         raise ValueError(f"Línea {line_no}: Formato LW/SW inválido.")
                    rt = parse_register(m.group(1), line_no)
                    imm = parse_immediate(m.group(2), line_no)
                    rs = parse_register(m.group(3), line_no)
                    if not -32768 <= imm <= 0xFFFF:
                        raise ValueError(f"Línea {line_no}: Offset fuera de rango.")
                    binstr = (int_to_bin_str(opcode,6) +
                              int_to_bin_str(rs,5) +
                              int_to_bin_str(rt,5) +
                              int_to_bin_str(imm & 0xFFFF, 16))
                    output_bin_lines.append(binstr)

                elif mnemonic == 'BEQ':
                    regs = [t for t in toks[1:] if t != ',']
                    rs = parse_register(regs[0], line_no)
                    rt = parse_register(regs[1], line_no)
                    target = regs[2]
                    if re.match(r'^[A-Za-z_]\w*$', target):
                        if target not in labels:
                             raise ValueError(f"Línea {line_no}: Label '{target}' no existe.")
                        target_addr = labels[target]
                    else:
                        target_addr = parse_immediate(target, line_no)
                    
                    offset_words = (target_addr - (pc + 4)) // 4
                    if not -32768 <= offset_words <= 32767:
                         raise ValueError(f"Línea {line_no}: Salto BEQ muy lejano.")
                    binstr = (int_to_bin_str(opcode,6) +
                              int_to_bin_str(rs,5) +
                              int_to_bin_str(rt,5) +
                              int_to_bin_str(offset_words & 0xFFFF, 16))
                    output_bin_lines.append(binstr)

                else: # ADDI, etc.
                    regs = [t for t in toks[1:] if t != ',']
                    rt = parse_register(regs[0], line_no)
                    rs = parse_register(regs[1], line_no)
                    imm = parse_immediate(regs[2], line_no)
                    if mnemonic in ('ANDI', 'ORI', 'XORI'):
                         if not 0 <= imm <= 0xFFFF: raise ValueError("Inmediato fuera de rango.")
                    else:
                         if not -32768 <= imm <= 32767: raise ValueError("Inmediato fuera de rango.")
                    binstr = (int_to_bin_str(opcode,6) +
                              int_to_bin_str(rs,5) +
                              int_to_bin_str(rt,5) +
                              int_to_bin_str(imm & 0xFFFF, 16))
                    output_bin_lines.append(binstr)

            elif info['type'] == 'J':
                target = toks[1]
                if re.match(r'^[A-Za-z_]\w*$', target):
                    if target not in labels: raise ValueError(f"Label '{target}' no existe.")
                    target_addr = labels[target]
                else:
                    target_addr = parse_immediate(target, line_no)
                addr_word = (target_addr >> 2) & ((1 << 26) - 1)
                binstr = int_to_bin_str(info['opcode'],6) + int_to_bin_str(addr_word,26)
                output_bin_lines.append(binstr)

        except Exception as e:
            errors.append(str(e))
        
        pc += 4

    return output_bin_lines, errors

# ---------------------------
# Guardado en archivos (MODIFICADO)
# ---------------------------

def save_as_text(lines32: List[str], path: str):
    """
    MODIFICADO: Guarda dividiendo cada instrucción de 32 bits 
    en 4 líneas de 8 bits (Big Endian) para Verilog con memoria de 8 bits.
    """
    with open(path, 'w') as f:
        for b32 in lines32:
            # Se divide la cadena de 32 caracteres en 4 partes de 8
            f.write(b32[0:8] + '\n')   # Byte MSB (31-24)
            f.write(b32[8:16] + '\n')  # Byte (23-16)
            f.write(b32[16:24] + '\n') # Byte (15-8)
            f.write(b32[24:32] + '\n') # Byte LSB (7-0)

def save_as_bin(lines32: List[str], path: str):
    """Guarda como archivo binario (bytes puros)."""
    with open(path, 'wb') as f:
        for b32 in lines32:
            byte0 = int(b32[0:8], 2)
            byte1 = int(b32[8:16], 2)
            byte2 = int(b32[16:24], 2)
            byte3 = int(b32[24:32], 2)
            f.write(bytes([byte0, byte1, byte2, byte3]))

# ---------------------------
# GUI (Tkinter)
# ---------------------------

class MIPSDecoderApp:
    def __init__(self, master):
        self.master = master
        master.title("Decodificador MIPS32 - Formato Byte (8-bit)")
        master.geometry("1000x650")

        # Top buttons
        top = tk.Frame(master, pady=6)
        top.pack(side=tk.TOP, fill=tk.X)
        tk.Button(top, text="Cargar archivo (.asm)", command=self.load_file, bg="#1976D2", fg="white").pack(side=tk.LEFT, padx=6)
        tk.Button(top, text="Vista previa / Ensamblar", command=self.preview, bg="#388E3C", fg="white").pack(side=tk.LEFT, padx=6)
        tk.Button(top, text="Guardar (.txt/.bin)", command=self.save_output, bg="#6A1B9A", fg="white").pack(side=tk.LEFT, padx=6)
        tk.Button(top, text="Limpiar", command=self.clear_all).pack(side=tk.LEFT, padx=6)

        # Main frames
        main = tk.Frame(master)
        main.pack(fill=tk.BOTH, expand=True, padx=8, pady=6)

        left = tk.Frame(main)
        left.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        tk.Label(left, text="Entrada - Código ensamblador (.asm):", font=('Arial', 10, 'bold')).pack(anchor='w')
        self.text_in = tk.Text(left, font=('Consolas', 11), wrap='none')
        self.text_in.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

        right = tk.Frame(main)
        right.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)
        tk.Label(right, text="Salida - (4 líneas de 8 bits por instrucción):", font=('Arial', 10, 'bold')).pack(anchor='w')
        self.text_out = tk.Text(right, font=('Consolas', 11), bg="#f3f3f3", wrap='none')
        self.text_out.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

        # Status bar
        self.status = tk.Label(master, text="Listo.", bd=1, relief=tk.SUNKEN, anchor=tk.W)
        self.status.pack(side=tk.BOTTOM, fill=tk.X)

    def load_file(self):
        path = filedialog.askopenfilename(filetypes=[("ASM/TXT", "*.asm;*.txt"), ("All", "*.*")])
        if path:
            try:
                with open(path, 'r') as f:
                    self.text_in.delete('1.0', tk.END)
                    self.text_in.insert(tk.END, f.read())
                self.status.config(text=f"Cargado: {path}")
            except Exception as e:
                messagebox.showerror("Error", str(e))

    def preview(self):
        asm_text = self.text_in.get('1.0', tk.END).splitlines()
        if not any(line.strip() for line in asm_text):
            messagebox.showwarning("Aviso", "Entrada vacía.")
            return
        
        binlines, errors = assemble_lines(asm_text)
        
        self.text_out.delete('1.0', tk.END)
        if errors:
            self.text_out.insert(tk.END, '\n'.join(errors))
            self.status.config(text="Errores encontrados", fg='red')
        else:
            # MODIFICADO: Mostrar en GUI también dividido en 8 bits para que coincida con el archivo
            display_lines = []
            for b32 in binlines:
                display_lines.append(b32[0:8])
                display_lines.append(b32[8:16])
                display_lines.append(b32[16:24])
                display_lines.append(b32[24:32])
                display_lines.append("") # Línea vacía visual para separar instrucciones (opcional)
            
            self.text_out.insert(tk.END, '\n'.join(display_lines))
            self.status.config(text=f"Ensamblado OK. {len(binlines)} instrucciones.", fg='blue')

    def save_output(self):
        out_text = self.text_in.get('1.0', tk.END).splitlines()
        binlines, errors = assemble_lines(out_text)
        
        if errors:
            messagebox.showerror("Error", "Corrige los errores antes de guardar.")
            return

        filetypes = [("Texto (.txt)", "*.txt"), ("Binario (.bin)", "*.bin")]
        path = filedialog.asksaveasfilename(defaultextension=".txt", filetypes=filetypes)
        
        if path:
            try:
                if path.endswith('.bin'):
                    save_as_bin(binlines, path)
                else:
                    save_as_text(binlines, path) # Usa la función modificada
                messagebox.showinfo("Guardado", f"Archivo guardado en:\n{path}")
                self.status.config(text="Guardado exitoso.", fg='green')
            except Exception as e:
                messagebox.showerror("Error", str(e))

    def clear_all(self):
        self.text_in.delete('1.0', tk.END)
        self.text_out.delete('1.0', tk.END)
        self.status.config(text="Listo.")

if __name__ == '__main__':
    root = tk.Tk()
    app = MIPSDecoderApp(root)
    root.mainloop()