`timescale 1ns / 1ps

module tb_soc_top;

    // 1. Sinais de Teste
    reg clk;
    reg resetn;     // Reset ativo BAIXO (0 = Reset, 1 = Funciona)
    wire [7:0] leds;
    wire trap;

    // 2. Instância do SoC 
    soc_top dut (
        .clk    (clk),
        .resetn (resetn),
        .leds   (leds),
        .trap   (trap)
    );

    // 3. Geração de Clock (10ns = 100MHz)
    always #5 clk = ~clk;

    // 4. Sequência de Teste
    initial begin
        $display("--------------------------------------------------");
        $display("   TESTE DO PICO-RV32 (Buscando Instrucoes)       ");
        $display("--------------------------------------------------");

        // Inicialização
        clk = 0;
        resetn = 0; // Mantém o processador em Reset
        
        // Espera 5 ciclos de clock
        repeat (5) @(posedge clk);
        
        $display("[t=%0t] Liberando Reset...", $time);
        resetn = 1; // Solta o Reset (CPU deve começar a rodar)

        // Deixa rodar por tempo suficiente para ver o loop

        #2000; 

        $display("--------------------------------------------------");
        $display("Simulacao Finalizada.");
        $finish;
    end

    // 5. Monitoramento (Spy)
    // Este bloco observa o barramento sempre que a CPU faz uma requisição válida
    // O 'dut.mem_valid' acessa o sinal dentro do módulo instanciado.
    
    always @(posedge clk) begin
        if (resetn && dut.mem_valid && dut.mem_ready) begin
            // Se for leitura de instrução (Instruction Fetch)
            if (dut.mem_instr) begin
                $display("[t=%0t] CPU Buscando Instrucao no Endereco: %h | LEDs: %b", 
                         $time, dut.mem_addr, leds);
            end
            
            // Se houver Trap (Erro Fatal)
            if (trap) begin
                $display("[t=%0t] ERRO FATAL: CPU entrou em estado TRAP!", $time);
                $stop;
            end
        end
    end

endmodule