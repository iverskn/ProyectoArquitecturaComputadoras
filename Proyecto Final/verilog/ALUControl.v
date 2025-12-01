module ALUControl (
    input [1:0] alu_op,       // Viene de la Unidad de Control principal
    input [5:0] funct,        // Viene de la instrucción (bits [5:0])
    output reg [3:0] alu_ctl  // Señal específica para la ALU
);

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctl = 4'b0010; // LW/SW -> Suma (para calcular dirección)
            2'b01: alu_ctl = 4'b0110; // BEQ   -> Resta (para comparar)
            2'b10: begin              // R-Type -> Mirar el campo 'funct'
                case (funct)
                    6'b100000: alu_ctl = 4'b0010; // ADD
                    6'b100010: alu_ctl = 4'b0110; // SUB
                    6'b100100: alu_ctl = 4'b0000; // AND
                    6'b100101: alu_ctl = 4'b0001; // OR
                    6'b101010: alu_ctl = 4'b0111; // SLT 
                    default:   alu_ctl = 4'b0000; // Default 
                endcase
            end
            default: alu_ctl = 4'b0000;
        endcase
    end
endmodule
