module MEM_WB_Reg (
    input clk, reset, stall,

    // Señales de Control 
    input reg_write_in,
    input mem_to_reg_in,

    // Datos
    input [31:0] read_data_in,  // Dato leído de memoria (si fue LW)
    input [31:0] alu_result_in, // Resultado de ALU (si fue ADD, SUB)
    input [4:0] rd_in,          // registro destino 

    // SALIDAS
    output reg reg_write_out,
    output reg mem_to_reg_out,
    
    output reg [31:0] read_data_out,
    output reg [31:0] alu_result_out,
    output reg [4:0] rd_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_write_out <= 0;
            mem_to_reg_out <= 0;
            read_data_out <= 0;
            alu_result_out <= 0;
            rd_out <= 0;
        end
        else if (stall == 0) begin
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            
            read_data_out <= read_data_in;
            alu_result_out <= alu_result_in;
            rd_out <= rd_in;
        end
    end
endmodule
