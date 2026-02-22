#!/bin/bash
set -e

echo "--- 1. Compilando Firmware ---"
make all

echo "--- 2. Iniciando Simulação (Icarus Verilog) ---"
iverilog -o sim_soc \
    sim/soc_tb.v \
    rtl/soc_top.v \
    rtl/picorv32.v \
    rtl/uart_tx.v \
    rtl/uart_rx.v \
    rtl/fifo_buffer_circular_param.v \
    rtl/aes_core.v \
    rtl/aes_add_round_key.v \
    rtl/aes_key_expand_128.v \
    rtl/aes_mix_columns.v \
    rtl/aes_rcon.v \
    rtl/aes_round.v \
    rtl/aes_sbox.v \
    rtl/aes_shiftrows.v \
    rtl/aes_sub_bytes.v \
    rtl/aes_xtime.v

echo "--- 3. Rodando Simulação ---"
vvp sim_soc > resultado_sim.txt

echo "--- Simulação Concluída. Verifique resultado_sim.txt ---"
head -n 30 resultado_sim.txt