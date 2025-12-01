module PC(
    input clk,
    input reset,
    input stall,             
    input [31:0] next_pc,    // La siguiente dirección
    output reg [31:0] pc_out // La dirección actual
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_out <= 32'b0; //dirección 0
        end
        else if (stall == 0) begin
            pc_out <= next_pc;
        end
    end

endmodule
