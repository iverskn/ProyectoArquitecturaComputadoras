module Multiplexor (
    input [31:0] a,    // Entrada 0
    input [31:0] b,    // Entrada 1
    input sel,         // Selector
    output [31:0] out  // Salida seleccionada
);
    assign out = (sel == 1'b1) ? b : a;
endmodule
