# Procesador MIPS Pipeline de 5 Etapas

Este repositorio contiene la implementación de un procesador MIPS32 con arquitectura Pipeline de 5 etapas (Fetch, Decode, Execute, Memory, WriteBack), desarrollado en Verilog. Incluye además un decodificador de instrucciones (Ensamblador) escrito en Python con interfaz gráfica.

Características

- Arquitectura: MIPS Pipeline (5 Etapas) 
- Lenguajes: Verilog (Hardware description), Python (Software).
- Instrucciones Soportadas:
    - Tipo R: ADD, SUB, AND, OR, SLT.
    - Tipo I: ADDI, ANDI, ORI, LW, SW, BEQ.
    - Tipo J: J.


Componentes del Proyecto

1. Decodificador (Python)
Una herramienta con GUI (Tkinter) que traduce código ensamblador MIPS a lenguaje máquina binario (formato Big Endian de 8 bits para la memoria Verilog).
 - Entrada: Archivo .asm o .txt.
 - Salida: Archivo txt.

2. Procesador (Verilog)
Implementación completa del Datapath y Unidad de Control.
 - Módulos: PC, MemoriaDeInstrucciones, Sumador, BR, ALU, MemoriaDatos, UnidadControl, SignExtend, Multiplexor, TortaAhogada, TB.
 - Buffers: IF/ID, ID/EX, EX/MEM, MEM/WB.


Cómo ejecutar

1.  Abrir el archivo de Python, cargar el código ensamblador o escribir directamente y generar `instrucciones.txt`.
2.  Colocar `instrucciones.txt` en la ruta especificada en `MemoriaDeInstrucciones.v`.
3.  Importar los archivos de `/src_verilog` en ModelSim.
4.  Compilar y ejecutar el `TB.v`.

Autor
Márquez Prado Cristofer Iverson - 220758015
Arquitectura de Computadoras
INFO
