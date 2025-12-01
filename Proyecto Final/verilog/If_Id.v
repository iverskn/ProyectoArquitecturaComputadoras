module IF_ID_Reg (
    input clk,
    input reset,
    input flush,             // Para limpiar el tubo si hay un salto incorrecto
    input stall,             // Para congelar el tubo si hay dependencia de datos
    input [31:0] pc_plus4_in,
    input [31:0] instruction_in,
    
    output reg [31:0] pc_plus4_out,
    output reg [31:0] instruction_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_plus4_out <= 32'b0;
            instruction_out <= 32'b0;
        end
        else if (flush) begin
            // Si hacemos flush, insertamos una "burbuja" (NOP = todo ceros)
            pc_plus4_out <= 32'b0;
            instruction_out <= 32'b0; 
        end
        else if (stall == 0) begin
            // Operación normal: pasar datos de izquierda a derecha
            pc_plus4_out <= pc_plus4_in;
            instruction_out <= instruction_in;
        end
        // Si stall == 1, mantenemos los valores (congelamos)
    end

endmodule
