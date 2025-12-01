module ID_EX_Reg (
    input clk, reset, stall,
    
    // Señales de Control que deben viajar
    // WB (Para la etapa 5)
    input reg_write_in, mem_to_reg_in,
    // MEM (Para la etapa 4)
    input mem_read_in, mem_write_in, branch_in,
    // EX (Para la etapa 3 - Inmediata)
    input reg_dst_in, alu_src_in,
    input [1:0] alu_op_in,
    
    // Datos
    input [31:0] pc_plus4_in,
    input [31:0] read_data1_in,
    input [31:0] read_data2_in,
    input [31:0] sign_ext_imm_in,
    input [4:0] rs_in, 
    input [4:0] rt_in,
    input [4:0] rd_in,

    // SALIDAS (Todo lo mismo pero _out)
    output reg reg_write_out, mem_to_reg_out,
    output reg mem_read_out, mem_write_out, branch_out,
    output reg reg_dst_out, alu_src_out,
    output reg [1:0] alu_op_out,
    
    output reg [31:0] pc_plus4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] sign_ext_imm_out,
    output reg [4:0] rs_out,
    output reg [4:0] rt_out,
    output reg [4:0] rd_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Resetear todo a 0
            reg_write_out <= 0; mem_to_reg_out <= 0;
            mem_read_out <= 0; mem_write_out <= 0; branch_out <= 0;
            reg_dst_out <= 0; alu_src_out <= 0; alu_op_out <= 0;
            pc_plus4_out <= 0; read_data1_out <= 0; read_data2_out <= 0;
            sign_ext_imm_out <= 0; rs_out <= 0; rt_out <= 0; rd_out <= 0;
        end
        else if (stall == 0) begin // Si no hay stall, pasamos datos
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            branch_out <= branch_in;
            reg_dst_out <= reg_dst_in;
            alu_src_out <= alu_src_in;
            alu_op_out <= alu_op_in;
            
            pc_plus4_out <= pc_plus4_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            sign_ext_imm_out <= sign_ext_imm_in;
            rs_out <= rs_in;
            rt_out <= rt_in;
            rd_out <= rd_in;
        end
    end
endmodule
