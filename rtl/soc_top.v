`timescale 1ns / 1ps

module soc_top (
    input wire clk,             // Clock principal do sistema (25MHz)
    input wire resetn,          // Reset Ativo em Nível Baixo (Active Low)
    input wire uart_rx,         // Entrada Serial (Recebe do PC)
    output wire uart_tx,        // Saída Serial (Envia para o PC)
    output wire [7:0] leds,     // LEDs de Debug (conectados ao endereço)
    output wire trap            // Sinal de erro/exceção do processador
);

    // =========================================================================
    // 1. DEFINIÇÃO DO BARRAMENTO DO SISTEMA 
    // =========================================================================
    wire        mem_valid;      // Mestre indica transação válida
    wire        mem_ready;      // Escravo indica que transação foi aceita
    wire [31:0] mem_addr;       // Endereço de acesso 
    wire [31:0] mem_wdata;      // Dados de escrita 
    wire [ 3:0] mem_wstrb;      // Máscara de escrita 
    wire [31:0] mem_rdata;      // Dados de leitura 

    // =========================================================================
    // 2. DECODIFICAÇÃO DE ENDEREÇOS 
    // =========================================================================
    // Decodifica usando os 8 bits mais significativos (MSB)
    wire sel_ram  = (mem_addr[31:24] == 8'h00);
    wire sel_uart = (mem_addr[31:24] == 8'h02);
    wire sel_aes  = (mem_addr[31:24] == 8'h04);

    // =========================================================================
    // 3. INTERFACE COM O ACELERADOR AES (Registradores Internos)
    // =========================================================================
    reg [127:0] aes_data_in;    // Buffer para o Bloco de Texto (Plaintext)
    reg [127:0] aes_key_in;     // Buffer para a Chave (Key)
    reg         aes_start;      // Sinal de disparo que inicia o processo
    wire [127:0] aes_data_out;  // Resultado do AES (Ciphertext)
    wire         aes_done;      // Sinal de conclusão

    // =========================================================================
    // 4. CONTROLE DE FLUXO 
    // =========================================================================
    // Gera um ciclo de espera (Wait State) para sincronizar leitura/escrita
    reg mem_ready_q;
    always @(posedge clk) begin
        if (!resetn) 
            mem_ready_q <= 1'b0;
        else 
            mem_ready_q <= mem_valid && !mem_ready_q;
    end
    assign mem_ready = mem_ready_q;
    
    // =========================================================================
    // 5. LÓGICA DE ESCRITA NOS PERIFÉRICOS (MMIO Write)
    // =========================================================================
    always @(posedge clk) begin
        if (!resetn) begin
            aes_data_in <= 128'b0; 
            aes_key_in  <= 128'b0; 
            aes_start   <= 1'b0;
        end else begin
            // Pulso único de start (volta a zero automaticamente)
            aes_start <= 1'b0;

            // Escrita ocorre apenas se: (Valid=1) E (Ready=0) E (AES Selecionado)
            if (mem_valid && !mem_ready && sel_aes && |mem_wstrb) begin
                // Multiplexa a escrita baseado no Offset (mem_addr[7:0])
                case (mem_addr[7:0])
                    // Configuração dos Dados (Plaintext) - 4 palavras de 32 bits
                    8'h00: aes_data_in[31:0]   <= mem_wdata;
                    8'h04: aes_data_in[63:32]  <= mem_wdata;
                    8'h08: aes_data_in[95:64]  <= mem_wdata;
                    8'h0C: aes_data_in[127:96] <= mem_wdata; // MSB
                    
                    // Configuração da Chave (Key) - 4 palavras de 32 bits
                    8'h10: aes_key_in[31:0]    <= mem_wdata;
                    8'h14: aes_key_in[63:32]   <= mem_wdata;
                    8'h18: aes_key_in[95:64]   <= mem_wdata;
                    8'h1C: aes_key_in[127:96]  <= mem_wdata; // MSB
                    
                    // Registro de Controle (Start)
                    8'h20: aes_start           <= mem_wdata[0];
                endcase
            end
        end
    end

    // =========================================================================
    // 6. LÓGICA DE LEITURA (MMIO Read Multiplexer)
    // =========================================================================
    
    // Of: Seleciona qual parte do AES ler (Resultado ou Status)
    wire [31:0] aes_rdata_val = 
        (mem_addr[7:0] == 8'h30) ? aes_data_out[31:0]   : // Resultado [31:0]
        (mem_addr[7:0] == 8'h34) ? aes_data_out[63:32]  : // Resultado [63:32]
        (mem_addr[7:0] == 8'h38) ? aes_data_out[95:64]  : // Resultado [95:64]
        (mem_addr[7:0] == 8'h3C) ? aes_data_out[127:96] : // Resultado MSB
        (mem_addr[7:0] == 8'h40) ? {31'b0, aes_done}    : // Status Register
        32'b0;

    // Mux Principal: Arbitra quem entrega dados para a CPU
    reg [31:0] rdata_ram;
    assign mem_rdata = 
        sel_ram  ? rdata_ram : // Prioridade 1: RAM
        sel_uart ? (mem_addr[2] ? {30'b0, w_tx_active, w_fifo_empty} : {24'b0, w_fifo_data_out}) : // UART
        sel_aes  ? aes_rdata_val : // AES
        32'b0; // Default

    // =========================================================================
    // 7. INSTANCIAÇÃO DOS MÓDULOS 
    // =========================================================================

    // --- Processador RISC-V (PicoRV32) ---
    picorv32 #(.ENABLE_REGS_16_31(1)) cpu (
        .clk(clk), 
        .resetn(resetn), 
        .trap(trap), 
        .mem_valid(mem_valid), 
        .mem_ready(mem_ready), 
        .mem_addr(mem_addr), 
        .mem_wdata(mem_wdata), 
        .mem_wstrb(mem_wstrb), 
        .mem_rdata(mem_rdata)
    );
    
    // --- Memória RAM ---
    reg [31:0] memory [0:1023]; // 4KB de Memória (1024 palavras de 32 bits)
    initial $readmemh("firmware.hex", memory);
    
    always @(posedge clk) if (mem_valid && sel_ram) begin
        // Leitura Síncrona
        if (!mem_wstrb) rdata_ram <= memory[mem_addr[11:2]];
        // Escrita Byte-Addressable
        else begin
            if (mem_wstrb[0]) memory[mem_addr[11:2]][ 7: 0] <= mem_wdata[ 7: 0];
            if (mem_wstrb[1]) memory[mem_addr[11:2]][15: 8] <= mem_wdata[15: 8];
            if (mem_wstrb[2]) memory[mem_addr[11:2]][23:16] <= mem_wdata[23:16];
            if (mem_wstrb[3]) memory[mem_addr[11:2]][31:24] <= mem_wdata[31:24];
        end
    end

    // --- UART (RX + FIFO + TX) ---
    wire [7:0] w_rx_byte, w_fifo_data_out;
    wire w_rx_dv, w_fifo_empty, w_fifo_full, w_tx_active;
    
    // Sinais de controle barramento
    wire uart_rd_en = (mem_valid && mem_ready && sel_uart && !mem_wstrb && (mem_addr[7:0] == 8'h00));
    wire uart_wr_en = (mem_valid && sel_uart && |mem_wstrb && (mem_addr[7:0] == 8'h00));
    
    // Sincronizador de entrada para evitar metaestabilidade
    reg [1:0] rx_sync;
    always @(posedge clk) rx_sync <= {rx_sync[0], uart_rx};

    uart_rx #(.CLK_FREQ(25000000)) rx (
        .i_Clk(clk), .i_Rst_L(resetn), .i_Rx_Serial(rx_sync[1]), 
        .o_Rx_DV(w_rx_dv), .o_Rx_Byte(w_rx_byte)
    );
    
    fifo_buffer_circular_param #(.FIFO_DEPTH(16)) fifo (
        .clk(clk), .reset(~resetn), 
        .wr(w_rx_dv), .w_data(w_rx_byte), 
        .rd(uart_rd_en), .r_data(w_fifo_data_out), 
        .empty(w_fifo_empty), .full(w_fifo_full)
    );
    
    uart_tx #(.CLK_FREQ(25000000)) tx (
        .i_Clk(clk), .i_Rst_L(resetn), 
        .i_Tx_DV(uart_wr_en), .i_Tx_Byte(mem_wdata[7:0]), 
        .o_Tx_Active(w_tx_active), .o_Tx_Serial(uart_tx)
    );

    // --- Nucleo aes ---
    aes_core u_aes_real (
        .clk(clk), 
        .rst(~resetn), 
        .start(aes_start), 
        .plaintext(aes_data_in), 
        .key(aes_key_in), 
        .ciphertext(aes_data_out), 
        .done(aes_done)
    );
    
    // Debug: LEDs mostram o byte menos significativo do endereço acessado
    //  assign leds = mem_addr[7:0];

endmodule