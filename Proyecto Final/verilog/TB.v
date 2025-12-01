`timescale 1ns / 1ps

module Testbench;

    // Entradas para el procesador (Registros)
    reg clk;
    reg reset;

    // Salidas del procesador (Cables para observar)
    wire [31:0] alu_result_out;

    // Instanciar el Procesador (Unit Under Test - UUT)
    TortaAhogada UUT (
        .clk(clk), 
        .reset(reset), 
        .alu_result_out(alu_result_out)
    );

    // Generador de Reloj
    // El reloj cambia de estado cada 5 nanosegundos (Periodo = 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Bloque de pruebas
    initial begin
        // 1. Inicializar y Resetear
        $display("Iniciando Simulación MIPS Pipeline...");
        reset = 1;
        #10;       // Esperar 10ns con el reset activado
        reset = 0; // Soltar el reset (Arranca el procesador)
        
        // 2. Dejar correr el procesador
        // El programa tiene un bucle, así que necesitamos tiempo suficiente.
        // 5 vueltas x aprox 10 instrucciones x 10ns = 500ns aprox.
        // Le damos 1000ns para estar seguros.
        #1000;

        // 3. Terminar simulación
        $display("Simulación terminada.");
        $stop;
    end
    
    // Opcional: Monitor para ver qué pasa en consola cada ciclo
    // Muestra el resultado de la ALU cada vez que cambia
    initial begin
        $monitor("Tiempo: %d | Reset: %b | Resultado ALU (WB): %d", 
                 $time, reset, alu_result_out);
    end

endmodule
