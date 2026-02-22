#ifndef SOC_MAP_H
#define SOC_MAP_H

#include <stdint.h>

// --- Endereços Base (Memory Mapped I/O) ---
#define RAM_BASE_ADDR   0x00000000
#define UART_BASE_ADDR  0x02000000
#define AES_BASE_ADDR   0x04000000

// --- Registradores da UART ---
#define UART_DATA_REG   (*(volatile uint32_t*)(UART_BASE_ADDR + 0x00))
#define UART_STATUS_REG (*(volatile uint32_t*)(UART_BASE_ADDR + 0x04))

// Máscaras de Bits da UART
#define UART_RX_EMPTY   0x01  // Bit 0: FIFO Vazia
#define UART_TX_BUSY    0x02  // Bit 1: Transmissor Ocupado

// --- Registradores do Acelerador AES ---
// Entrada de Dados (128-bit divididos em 4 palavras de 32-bit)
#define AES_DIN_0       (*(volatile uint32_t*)(AES_BASE_ADDR + 0x00)) // LSB
#define AES_DIN_1       (*(volatile uint32_t*)(AES_BASE_ADDR + 0x04))
#define AES_DIN_2       (*(volatile uint32_t*)(AES_BASE_ADDR + 0x08))
#define AES_DIN_3       (*(volatile uint32_t*)(AES_BASE_ADDR + 0x0C)) // MSB

// Entrada da Chave (128-bit)
#define AES_KEY_0       (*(volatile uint32_t*)(AES_BASE_ADDR + 0x10)) // LSB
#define AES_KEY_1       (*(volatile uint32_t*)(AES_BASE_ADDR + 0x14))
#define AES_KEY_2       (*(volatile uint32_t*)(AES_BASE_ADDR + 0x18))
#define AES_KEY_3       (*(volatile uint32_t*)(AES_BASE_ADDR + 0x1C)) // MSB

// Controle e Status
#define AES_CTRL_REG    (*(volatile uint32_t*)(AES_BASE_ADDR + 0x20))
#define AES_STATUS_REG  (*(volatile uint32_t*)(AES_BASE_ADDR + 0x40))

// Máscaras do AES
#define AES_START_BIT   0x01
#define AES_DONE_BIT    0x01

// Saída de Dados (Ciphertext)
#define AES_DOUT_0      (*(volatile uint32_t*)(AES_BASE_ADDR + 0x30)) // LSB
#define AES_DOUT_1      (*(volatile uint32_t*)(AES_BASE_ADDR + 0x34))
#define AES_DOUT_2      (*(volatile uint32_t*)(AES_BASE_ADDR + 0x38))
#define AES_DOUT_3      (*(volatile uint32_t*)(AES_BASE_ADDR + 0x3C)) // MSB

#endif // SOC_MAP_H
