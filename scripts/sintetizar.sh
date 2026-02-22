#!/bin/bash
set -e

echo "--- 1. Compilando Firmware ---"

make clean
make all

echo "--- 2. Sintetizando com Yosys ---"

yosys -p "synth_ecp5 -top soc_top -json soc.json" \
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

echo "--- 3. Place & Route com nextpnr ---"
nextpnr-ecp5 --45k --package CABGA381 --json soc.json --lpf rtl/soc.lpf --textcfg soc_out.config --lpf-allow-unconstrained

echo "--- 4. Gerando Bitstream ---"
ecppack soc_out.config firmware.bit

echo "--- SUCESSO: firmware.bit gerado ---"