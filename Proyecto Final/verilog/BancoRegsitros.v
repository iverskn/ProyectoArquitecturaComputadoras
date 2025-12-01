module BR (
    input clk,
    input reset,
    input reg_write_en,
    input [4:0] read_reg1,  // Dirección registro fuente 1 (rs)
    input [4:0] read_reg2,  // Dirección registro fuente 2 (rt)
    input [4:0] write_reg,  // Dirección registro destino (rd o rt)
    input [31:0] write_data,// Dato a escribir
    output [31:0] read_data1,
    output [31:0] read_data2
);

    reg [31:0] registers [0:31]; // 32 registros de 32 bits
    integer i;

    // Lectura asíncrona
    // Si intenta leer el registro 0 devulve 0 
    assign read_data1 = (read_reg1 == 0) ? 32'b0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 0) ? 32'b0 : registers[read_reg2];

    // Escritura síncrona
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (reg_write_en && write_reg != 0) begin
            // Solo escribe si enable es 1 y NO es el registro 0
            registers[write_reg] <= write_data;
        end
    end
endmodule
