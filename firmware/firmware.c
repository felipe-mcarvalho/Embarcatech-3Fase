#include "soc_map.h" 

// Função para ler o contador de ciclos de hardware do RISC-V
static inline uint32_t read_cycle() {
    uint32_t cycles;
    __asm__ volatile ("rdcycle %0" : "=r" (cycles));
    return cycles;
}

void uart_putc(char c) {
    // Aguarda enquanto o transmissor estiver ocupado
    while (UART_STATUS_REG & UART_TX_BUSY);
    UART_DATA_REG = c;
}

char uart_getc() {
    // Aguarda até que chegue um dado (FIFO não vazia)
    while (UART_STATUS_REG & UART_RX_EMPTY);
    return (char)UART_DATA_REG;
}

int main() {
    // 1. Configurar a Chave (definidade estaticamente para teste)
    // Chave: "minha_chave_1234"
    AES_KEY_3 = 0x6d696e68; // "minh" (MSB)
    AES_KEY_2 = 0x615f6368; // "a_ch"
    AES_KEY_1 = 0x6176655f; // "ave_"
    AES_KEY_0 = 0x31323334; // "1234" (LSB)

    while(1) {
        // 2. Receber 16 bytes da UART e montar as palavras
        // O Python envia MSB primeiro, então a ordem deve ser do Word 3 para o 0
        for (int i = 3; i >= 0; i--) {
            uint32_t word = 0;
            word |= (uint32_t)uart_getc() << 24;
            word |= (uint32_t)uart_getc() << 16;
            word |= (uint32_t)uart_getc() << 8;
            word |= (uint32_t)uart_getc();

            // Seleciona o registrador correto
            (*(volatile uint32_t*)(AES_BASE_ADDR + (i * 4))) = word;
        }
        
        // --- INÍCIO DA ANÁLISE DE TEMPO ---
        // Capturar os ciclos ANTES de iniciar o AES
        uint32_t t_start = read_cycle();

        // 3. Disparar o AES (Pulso)
        AES_CTRL_REG = AES_START_BIT; // Start = 1
        AES_CTRL_REG = 0;             // Start = 0 
        
        // 4. Aguardar Conclusão 
        while (!(AES_STATUS_REG & AES_DONE_BIT));

        // --- FIM DA ANÁLISE DE TEMPO ---
        // Capturar os ciclos assim que o sinal DONE é detectado
        uint32_t t_end = read_cycle();
        uint32_t cycles_taken = t_end - t_start;

        // 5. Ler Resultado e Enviar via UART
        // Lendo do Word 3 (MSB) para o Word 0 (LSB)
        for (int i = 3; i >= 0; i--) {
            // Offset 0x30 é a base da saída
            uint32_t res = (*(volatile uint32_t*)(AES_BASE_ADDR + 0x30 + (i * 4)));
            
            uart_putc((char)(res >> 24));
            uart_putc((char)(res >> 16));
            uart_putc((char)(res >> 8));
            uart_putc((char)(res));
        }

        // 6. Transmitir a análise de Hardware para o PC (4 bytes)(Big Endian)
        uart_putc((char)(cycles_taken >> 24));
        uart_putc((char)(cycles_taken >> 16));
        uart_putc((char)(cycles_taken >> 8));
        uart_putc((char)(cycles_taken));
    }
    return 0;
}