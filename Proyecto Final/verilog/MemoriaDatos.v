module MemoriaDatos (
    input clk,
    input [31:0] address,      // Dirección calculada por la ALU 
    input [31:0] write_data,   // Dato a escribir 
    input mem_write,           // Señal de control
    input mem_read,            // Señal de control
    output [31:0] read_data    // Dato leodo
);

    // Definirt memoria 
    reg [7:0] memory [0:1023];
    integer i;

    // Inicialización 
    initial begin
        for (i=0; i<1024; i=i+1) memory[i] = 8'b0;

 end

    // Escritura Síncrona (
    always @(posedge clk) begin
        if (mem_write) begin
            // Big Endian
            memory[address]   <= write_data[31:24];
            memory[address+1] <= write_data[23:16];
            memory[address+2] <= write_data[15:8];
            memory[address+3] <= write_data[7:0];
            
            // mostrar en consola cuando se escribe algo
            $display("MEM WRITE: Dir[%d] = %d (Hex: %h)", address, write_data, write_data);
        end
    end

    // Lectura Asíncrona 
    // leee 4 bytes 
    assign read_data = (mem_read) ? 
                       {memory[address], memory[address+1], memory[address+2], memory[address+3]} : 
                       32'b0;

endmodule
