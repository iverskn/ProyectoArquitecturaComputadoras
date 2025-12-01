module MemoriaDeInstrucciones (
    input [31:0] address,      // El PC nos da la dirección
    output [31:0] instruction  // Salida de 32 bits
);

    reg [7:0] memory [0:1023];

    // Inicialización: Cargar el archivo generado por Python
    initial begin
        $readmemb("C:\instrucciones.txt", memory);
    end

    // Lectura (Big Endian):	
    assign instruction = { 
        memory[address], 
        memory[address+1], 
        memory[address+2], 
        memory[address+3] 
    };

endmodule
