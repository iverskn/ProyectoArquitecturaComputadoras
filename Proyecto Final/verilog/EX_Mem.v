module EX_MEM_Reg (
    input clk, reset, stall,

    // Señales de Control (Viajeras)
    // WB (Para etapa 5)
    input reg_write_in, mem_to_reg_in,
    // MEM (Para etapa 4 - Próxima parada)
    input mem_read_in, mem_write_in, branch_in,

    // Datos calculados
    input [31:0] alu_result_in,   // Resultado de la suma/resta/dirección
    input [31:0] write_data_in,   // El valor de $rt (solo útil para SW)
    input [4:0] rd_in,            // Registro destino (para escribir al final)
    input zero_in,                // Bandera Zero
    input [31:0] pc_branch_in,    // Dirección calculada del salto (si hay branch)

    // SALIDAS
    output reg reg_write_out, mem_to_reg_out,
    output reg mem_read_out, mem_write_out, branch_out,
    
    output reg [31:0] alu_result_out,
    output reg [31:0] write_data_out,
    output reg [4:0] rd_out,
    output reg zero_out,
    output reg [31:0] pc_branch_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_write_out <= 0; mem_to_reg_out <= 0;
            mem_read_out <= 0; mem_write_out <= 0; branch_out <= 0;
            alu_result_out <= 0; write_data_out <= 0;
            rd_out <= 0; zero_out <= 0; pc_branch_out <= 0;
        end
        else if (stall == 0) begin
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            branch_out <= branch_in;
            
            alu_result_out <= alu_result_in;
            write_data_out <= write_data_in; // OJO: Esto es read_data2 original
            rd_out <= rd_in;
            zero_out <= zero_in;
            pc_branch_out <= pc_branch_in;
        end
    end
endmodule
