.section .text
.global _start

_start:
    # Usa o símbolo _stack_top definido no Linker Script
    la sp, _stack_top

    # Limpar a seção BSS (Zerar variáveis globais não inicializadas)
    # Isso garante que variáveis globais comecem em 0 na FPGA
    la t0, _bss_start
    la t1, _bss_end

bss_clear_loop:
    bge t0, t1, bss_clear_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j bss_clear_loop

bss_clear_done:

    # Chamar a função main do C
    jal ra, main

    # Caso o main retorne, entra em loop infinito (Trap)
trap_loop:
    j trap_loop