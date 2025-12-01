module ALU (
    input [31:0] a,       // Operando 1 (RS)
    input [31:0] b,       // Operando 2 (RT o Inmediato)
    input [3:0] alu_ctl,  // Operación a realizar
    output reg [31:0] result,
    output zero           // 1 si el resultado es 0 (para BEQ)
);

    assign zero = (result == 0); // Si la resta da 0, son iguales

    always @(*) begin
        case (alu_ctl)
            4'b0000: result = a & b;       // AND
            4'b0001: result = a | b;       // OR
            4'b0010: result = a + b;       // ADD (Suma)
            4'b0110: result = a - b;       // SUB (Resta)
            4'b0111: result = (a < b) ? 32'b1 : 32'b0; // SLT
            4'b1100: result = ~(a | b);    // NOR 
            default: result = 32'b0;
        endcase
    end
endmodule
