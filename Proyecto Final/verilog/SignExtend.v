module SignExtend (
    input [15:0] in_imm,
    output [31:0] out_imm
);
    // Repite el bit 15 (signo) 16 veces y concatena el original
    assign out_imm = {{16{in_imm[15]}}, in_imm};
endmodule
