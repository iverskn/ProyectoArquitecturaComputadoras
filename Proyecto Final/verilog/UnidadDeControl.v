module UnidadControl (
    input [5:0] opcode,
    output reg reg_dst,
    output reg branch,
    output reg mem_read,
    output reg mem_to_reg,
    output reg [1:0] alu_op,
    output reg mem_write,
    output reg alu_src,
    output reg reg_write,
    output reg jump 
);

    always @(*) begin
        // Valores por defecto 
        reg_dst = 0; branch = 0; mem_read = 0; mem_to_reg = 0;
        alu_op = 2'b00; mem_write = 0; alu_src = 0; reg_write = 0; jump = 0;

        case (opcode)
            6'b000000: begin // tipo R
                reg_dst = 1;
                reg_write = 1;
                alu_op = 2'b10; // mitar el funct
            end
            6'b100011: begin // LW 
                alu_src = 1;
                mem_to_reg = 1;
                reg_write = 1;
                mem_read = 1;
                alu_op = 2'b00; // 00 es suma (para calcular dirección)
            end
            6'b101011: begin // SW 
                alu_src = 1;
                mem_write = 1;
                alu_op = 2'b00; // 00 es suma
            end
            6'b000100: begin // BEQ 
                branch = 1;
                alu_op = 2'b01; // 01 es resta (para comparar)
            end
            6'b001000: begin // ADDI 
                alu_src = 1;
                reg_write = 1;
                alu_op = 2'b00; // Suma inmediata
            end
            6'b000010: begin // J (Jump)
                jump = 1;
            end
			
        endcase
    end
endmodule
