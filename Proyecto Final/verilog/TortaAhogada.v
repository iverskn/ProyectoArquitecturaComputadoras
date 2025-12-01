`timescale 1ns / 1ps

module TortaAhogada(
    input clk,
    input reset,
    output [31:0] alu_result_out // Salida solo para ver qué pasa en la simulación
    );

    // -------------------------------------------------
    // CABLES 
    
    // --- Etapa 1: IF (Fetch) ---
    wire [31:0] pc_current, pc_next, pc_plus4_if, instruction_if;
    wire [31:0] branch_target_address; // Calculada en EX, usada aquí
    wire pc_src; // Decide si PC+4 o Salto (Branch)

    // --- Buffer IF/ID ---
    wire [31:0] pc_plus4_id, instruction_id;

    // --- Etapa 2: ID (Decode) ---
    wire [31:0] read_data1_id, read_data2_id, sign_ext_imm_id;
    wire [4:0] rs_id, rt_id, rd_id;
    // Señales de Control ID
    wire reg_dst_id, branch_id, mem_read_id, mem_to_reg_id;
    wire [1:0] alu_op_id;
    wire mem_write_id, alu_src_id, reg_write_id, jump_id;

    // --- Buffer ID/EX ---
    wire [31:0] pc_plus4_ex, read_data1_ex, read_data2_ex, sign_ext_imm_ex;
    wire [4:0] rs_ex, rt_ex, rd_ex;
    // Señales Control en EX
    wire reg_write_ex, mem_to_reg_ex, mem_read_ex, mem_write_ex, branch_ex;
    wire reg_dst_ex, alu_src_ex;
    wire [1:0] alu_op_ex;

    // --- Etapa 3: EX (Execute) ---
    wire [31:0] alu_input_b, alu_result_ex;
    wire [4:0] write_reg_ex; // Destino elegido (rd o rt)
    wire [3:0] alu_ctl;
    wire zero_ex;
    wire [31:0] branch_addr_ex; // Dirección calculada para salto

    // --- Buffer EX/MEM ---
    wire reg_write_mem, mem_to_reg_mem, mem_read_mem, mem_write_mem, branch_mem;
    wire [31:0] alu_result_mem, write_data_mem, branch_addr_mem;
    wire [4:0] write_reg_mem;
    wire zero_mem;

    // --- Etapa 4: MEM (Memory) ---
    wire [31:0] read_data_mem;
    
    // --- Buffer MEM/WB ---
    wire reg_write_wb, mem_to_reg_wb;
    wire [31:0] read_data_wb, alu_result_wb;
    wire [4:0] write_reg_wb;

    // --- Etapa 5: WB (Write Back) ---
    wire [31:0] result_to_write; // El dato final que regresa al inicio

    // ==========================================
    // INSTANCIACIÓN DE MÓDULOS
    // ==========================================

    // ----------------ETAPA 1: FETCH----------------
    
    // Mux para el PC (Salto condicional vs PC+4)
    // PCSrc se decide en la etapa MEM (Branch & Zero)
    assign pc_src = branch_mem & zero_mem; 
    
   // 1. Calculamos la dirección a la que iría el JUMP
    // (4 bits del PC actual + 26 bits de la instrucción + 00)
    wire [31:0] jump_addr;
    assign jump_addr = {pc_plus4_id[31:28], instruction_id[25:0], 2'b00};

    // 2. Lógica Maestra del PC (Branch vs Jump vs Normal)
    assign pc_src = branch_mem & zero_mem; // ¿Hay que saltar por un BEQ?

    assign pc_next = (pc_src)  ? branch_addr_mem : // Prioridad 1: BEQ (Corrección de error)
                     (jump_id) ? jump_addr :       // Prioridad 2: JUMP (Instrucción J)
                     pc_plus4_if;                  // Prioridad 3: Seguir derecho (PC+4)

    PC PCounter (
        .clk(clk), .reset(reset), .stall(1'b0), // Stall desactivado por ahora
        .next_pc(pc_next), 
        .pc_out(pc_current)
    );

    Sumador PC_sumador (
        .a(pc_current), .b(32'd4), 
        .out(pc_plus4_if)
    );

    MemoriaDeInstrucciones MI (
        .address(pc_current), 
        .instruction(instruction_if)
    );

    // ----------------BUFFER IF/ID----------------
    IF_ID_Reg IF_ID (
        .clk(clk), .reset(reset), .flush(pc_src), .stall(1'b0), // Flush si hay salto
        .pc_plus4_in(pc_plus4_if), .instruction_in(instruction_if),
        .pc_plus4_out(pc_plus4_id), .instruction_out(instruction_id)
    );

    // ----------------ETAPA 2: DECODE----------------
    
    // Desglose de instrucción
    assign rs_id = instruction_id[25:21];
    assign rt_id = instruction_id[20:16];
    assign rd_id = instruction_id[15:11];

    UnidadControl Control (
        .opcode(instruction_id[31:26]),
        .reg_dst(reg_dst_id), .branch(branch_id), .mem_read(mem_read_id),
        .mem_to_reg(mem_to_reg_id), .alu_op(alu_op_id), .mem_write(mem_write_id),
        .alu_src(alu_src_id), .reg_write(reg_write_id), .jump(jump_id)
    );

    BR BancoRegistros (
        .clk(clk), .reset(reset), 
        .reg_write_en(reg_write_wb), // Viene de la etapa 5 (Feedback)
        .read_reg1(rs_id), .read_reg2(rt_id), 
        .write_reg(write_reg_wb),    // Viene de la etapa 5
        .write_data(result_to_write),// Viene de la etapa 5
        .read_data1(read_data1_id), .read_data2(read_data2_id)
    );

    SignExtend SignExt (
        .in_imm(instruction_id[15:0]), 
        .out_imm(sign_ext_imm_id)
    );

    // ----------------BUFFER ID/EX----------------
    ID_EX_Reg ID_EX (
        .clk(clk), .reset(reset), .stall(1'b0),
        // Control
        .reg_write_in(reg_write_id), .mem_to_reg_in(mem_to_reg_id),
        .mem_read_in(mem_read_id), .mem_write_in(mem_write_id), .branch_in(branch_id),
        .reg_dst_in(reg_dst_id), .alu_src_in(alu_src_id), .alu_op_in(alu_op_id),
        // Datos
        .pc_plus4_in(pc_plus4_id),
        .read_data1_in(read_data1_id), .read_data2_in(read_data2_id),
        .sign_ext_imm_in(sign_ext_imm_id),
        .rs_in(rs_id), .rt_in(rt_id), .rd_in(rd_id),
        // Salidas
        .reg_write_out(reg_write_ex), .mem_to_reg_out(mem_to_reg_ex),
        .mem_read_out(mem_read_ex), .mem_write_out(mem_write_ex), .branch_out(branch_ex),
        .reg_dst_out(reg_dst_ex), .alu_src_out(alu_src_ex), .alu_op_out(alu_op_ex),
        .pc_plus4_out(pc_plus4_ex),
        .read_data1_out(read_data1_ex), .read_data2_out(read_data2_ex),
        .sign_ext_imm_out(sign_ext_imm_ex),
        .rs_out(rs_ex), .rt_out(rt_ex), .rd_out(rd_ex)
    );

    // ----------------ETAPA 3: EXECUTE----------------
    
    // Mux para ALUSrc (Registro vs Inmediato)
    Multiplexor ALU_Mux (
        .a(read_data2_ex), 
        .b(sign_ext_imm_ex), 
        .sel(alu_src_ex), 
        .out(alu_input_b)
    );

    // Mux para RegDst (Destino rt vs rd)
    // OJO: Este Mux es de 5 bits, necesitamos adaptar el Mux o usar assign directo
    assign write_reg_ex = (reg_dst_ex == 1'b1) ? rd_ex : rt_ex;

    // Cálculo de dirección de Branch (Shift Left 2 + Add)
    assign branch_addr_ex = pc_plus4_ex + (sign_ext_imm_ex << 2);

    ALUControl ALU_Ctl (
        .alu_op(alu_op_ex), 
        .funct(sign_ext_imm_ex[5:0]), // funct son los 6 bits bajos del inmediato extendido
        .alu_ctl(alu_ctl)
    );

    ALU Main_ALU (
        .a(read_data1_ex), 
        .b(alu_input_b), 
        .alu_ctl(alu_ctl), 
        .result(alu_result_ex), 
        .zero(zero_ex)
    );

    // ----------------BUFFER EX/MEM----------------
    EX_MEM_Reg EX_MEM (
        .clk(clk), .reset(reset), .stall(1'b0),
        // Control
        .reg_write_in(reg_write_ex), .mem_to_reg_in(mem_to_reg_ex),
        .mem_read_in(mem_read_ex), .mem_write_in(mem_write_ex), .branch_in(branch_ex),
        // Datos
        .alu_result_in(alu_result_ex), .write_data_in(read_data2_ex),
        .rd_in(write_reg_ex), .zero_in(zero_ex), .pc_branch_in(branch_addr_ex),
        // Salidas
        .reg_write_out(reg_write_mem), .mem_to_reg_out(mem_to_reg_mem),
        .mem_read_out(mem_read_mem), .mem_write_out(mem_write_mem), .branch_out(branch_mem),
        .alu_result_out(alu_result_mem), .write_data_out(write_data_mem),
        .rd_out(write_reg_mem), .zero_out(zero_mem), .pc_branch_out(branch_addr_mem)
    );

    // ----------------ETAPA 4: MEMORY----------------
    
    MemoriaDatos M (
        .clk(clk), 
        .address(alu_result_mem), 
        .write_data(write_data_mem), 
        .mem_write(mem_write_mem), 
        .mem_read(mem_read_mem), 
        .read_data(read_data_mem)
    );

    // ----------------BUFFER MEM/WB----------------
    MEM_WB_Reg MEM_WB (
        .clk(clk), .reset(reset), .stall(1'b0),
        .reg_write_in(reg_write_mem), .mem_to_reg_in(mem_to_reg_mem),
        .read_data_in(read_data_mem), .alu_result_in(alu_result_mem), .rd_in(write_reg_mem),
        // Salidas
        .reg_write_out(reg_write_wb), .mem_to_reg_out(mem_to_reg_wb),
        .read_data_out(read_data_wb), .alu_result_out(alu_result_wb), .rd_out(write_reg_wb)
    );

    // ----------------ETAPA 5: WRITE BACK----------------
    
    // Mux final: ¿Dato de Memoria o de ALU?
    Multiplexor WB_Mux (
        .a(alu_result_wb), 
        .b(read_data_wb), 
        .sel(mem_to_reg_wb), 
        .out(result_to_write)
    );

    // Salida de depuración
    assign alu_result_out = result_to_write;

endmodule
