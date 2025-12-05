`timescale 1ns / 1ps

module soc_top (
    input wire clk,
    input wire resetn,      // Reset ativo baixo
    output wire [7:0] leds, // LEDs da placa para debug
    output wire trap        // Indica se a CPU travou (erro fatal)
);

    // Sinais do Barramento Nativo do PicoRV32
    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [ 3:0] mem_wstrb;
    wire [31:0] mem_rdata;

    // 1. Instância do PicoRV32 (Configuração Minima)
    picorv32 #(
        .ENABLE_COUNTERS(0),       // Economiza LUTs
        .ENABLE_COUNTERS64(0),
        .ENABLE_REGS_16_31(0),     // Usa apenas 16 registradores (RV32E) - Menor área
        .ENABLE_REGS_DUALPORT(1),  // Melhor performance
        .LATCHED_MEM_RDATA(0),     // 0 = Memória responde no mesmo ciclo (BRAM simples)
        .CATCH_MISALIGN(1),
        .CATCH_ILLINSN(1),
        .PROGADDR_RESET(32'h0000_0000) // O código começa no endereço 0
    ) cpu (
        .clk       (clk),
        .resetn    (resetn),
        .trap      (trap),
        .mem_valid (mem_valid),
        .mem_instr (mem_instr),
        .mem_ready (mem_ready),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_rdata (mem_rdata)
        // Interrupções (irq) deixadas desconectadas (0)
    );

    // 2. Memória RAM Simples (BRAM)
    // O PicoRV32 precisa ler instruções daqui.
    reg [31:0] memory [0:255]; // 1KB de RAM (256 palavras de 32 bits)
    
    // Inicializa a memória com um arquivo HEX 
    initial begin
        $readmemh("C:/Users/fe/Documents/FPGA/AES/firmware.hex", memory);
    end

    // Lógica de Leitura/Escrita da Memória
    // O PicoRV32 espera handshake. Para BRAM interna -> dar ready imediato.
    
    assign mem_ready = mem_valid; // A memória é rápida, responde na hora
    
    // Leitura Síncrona
    reg [31:0] rdata_reg;
    always @(posedge clk) begin
        if (mem_valid && !mem_wstrb) begin
            rdata_reg <= memory[mem_addr[31:2]]; 
        end
        
        // Escrita (Byte Enable)
        if (mem_valid && |mem_wstrb) begin
            if (mem_wstrb[0]) memory[mem_addr[31:2]][ 7: 0] <= mem_wdata[ 7: 0];
            if (mem_wstrb[1]) memory[mem_addr[31:2]][15: 8] <= mem_wdata[15: 8];
            if (mem_wstrb[2]) memory[mem_addr[31:2]][23:16] <= mem_wdata[23:16];
            if (mem_wstrb[3]) memory[mem_addr[31:2]][31:24] <= mem_wdata[31:24];
        end
    end

    assign mem_rdata = rdata_reg;

    // 3. Debug Visual: Mapear LEDs para mostrar os bits baixos do endereço sendo acessado.
    // Se os LEDs piscarem rápido, a CPU está buscando instruções (buscando endereços).
    // Se ficarem estáticos, a CPU travou.
    assign leds = mem_addr[7:0];

endmodule