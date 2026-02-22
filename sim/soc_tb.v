`timescale 1ns / 1ps

module soc_tb;
    reg clk;
    reg resetn;
    reg uart_rx;
    wire uart_tx;
    wire [7:0] leds;
    wire trap;

    soc_top uut (
        .clk(clk),
        .resetn(resetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .leds(), // Nao utilizado
        .trap(trap)
    );

    // =========================================================================
    // 1. GERAÇÃO DE FORMAS DE OND
    // =========================================================================
    initial begin
        $dumpfile("sim_soc.vcd"); 
        $dumpvars(0, soc_tb);     
    end

    // --- Clock de 25MHz (Período de 40ns) ---
    always #20 clk = ~clk; 

    // Task para emular o protocolo serial UART (115200 bps @ 25MHz)
    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            uart_rx = 0; // Start bit
            #(8680);     
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                #(8680);
            end
            uart_rx = 1; // Stop bit
            #(8680);
        end
    endtask

    // =========================================================================
    // 2. PROCESSO PRINCIPAL DE ESTIMULO 
    // =========================================================================
    initial begin
        clk = 0;
        resetn = 0;
        uart_rx = 1;
        
        $display("\n------------------------------------------------------------");
        $display("[INFO] Iniciando Testbench: SoC RISC-V + AES-128");
        $display("------------------------------------------------------------");
        
        $display("[INFO] %t | Aplicando reset no sistema...", $time);
        #200;
        resetn = 1;
        #1000000; 

        $display("[INFO] %t | Transmitindo Plaintext...", $time);
        
        // Vetor de teste: "projeto_riscv_26"
        send_uart_byte(8'h70); send_uart_byte(8'h72); send_uart_byte(8'h6f); send_uart_byte(8'h6a);
        send_uart_byte(8'h65); send_uart_byte(8'h74); send_uart_byte(8'h6f); send_uart_byte(8'h5f);
        send_uart_byte(8'h72); send_uart_byte(8'h69); send_uart_byte(8'h73); send_uart_byte(8'h63);
        send_uart_byte(8'h76); send_uart_byte(8'h5f); send_uart_byte(8'h32); send_uart_byte(8'h36);

        $display("[INFO] %t | Bloco transmitido. Aguardando processamento do AES...", $time);

        // Tempo total de simulacao
        #50000000; 
        $display("\n[INFO] %t | Simulacao concluida por esgotamento do tempo total.", $time);
        $finish;
    end

    // =========================================================================
    // 3. LÓGICA DE VERIFICAÇÃO 
    // =========================================================================
    reg aes_done_q; 
    
    always @(posedge clk) begin
        aes_done_q <= uut.aes_done;
        
        // Dispara na borda de subida do sinal 'done' do acelerador
        if (uut.aes_done && !aes_done_q) begin
            $display("\n------------------------------------------------------------");
            $display("[VERIFICATION] Acelerador AES-128 terminou processamento.");
            $display("[VERIFICATION] Resultado Obtido   : 0x%h", uut.aes_data_out);
            $display("[VERIFICATION] Resultado Esperado : 0x66a9df27b2cfbd97e0a5ad31770b01fd");
            
            // Verificacao rigida de 128 bits do Ciphertext
            if (uut.aes_data_out == 128'h66a9df27b2cfbd97e0a5ad31770b01fd) begin
                $display("[VERIFICATION] STATUS: [PASS] - Correspondencia exata de 128 bits.");
            end else begin
                $display("[VERIFICATION] STATUS: [FAIL] - Resultado não bateu com a referência.");
            end
            $display("------------------------------------------------------------\n");
        end
    end

    // =========================================================================
    // 4. MONITORAMENTO DO BARRAMENTO
    // =========================================================================
    always @(posedge clk) begin
        // Monitor de acessos ao barramento 
        if (uut.mem_valid && uut.mem_ready && uut.sel_aes) begin
            if (|uut.mem_wstrb)
                $display("[BUS MONITOR]  %t | AES WRITE | Addr: 0x%h | Data: 0x%h", $time, uut.mem_addr, uut.mem_wdata);
            else
                $display("[BUS MONITOR]  %t | AES READ  | Addr: 0x%h | Data: 0x%h", $time, uut.mem_addr, uut.mem_rdata);
        end
        
        // Monitoramento de excecoes da CPU
        if (trap) begin
            $display("\n[FATAL ERROR]  %t | Processador entrou em estado de TRAP.", $time);
            $finish;
        end
    end

endmodule