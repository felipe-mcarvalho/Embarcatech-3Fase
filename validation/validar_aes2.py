import serial
import time
import sys
import struct

PORT = 'COM6' # Verifique a porta no gerenciador de dispositivos
BAUD = 115200
TIMEOUT_SEC = 2.0
CLOCK_FREQ_HZ = 25000000 # 25 MHz

PLAINTEXT = b"projeto_riscv_26"
EXPECTED_CIPHERTEXT_HEX = "66a9df27b2cfbd97e0a5ad31770b01fd"

def print_header():
    print("=" * 70)
    print("   Validacao e Análise de tempo: SoC RISC-V + AES-128")
    print("=" * 70)

def main():
    print_header()
    try:
        ser = serial.Serial(PORT, baudrate=BAUD, timeout=TIMEOUT_SEC)
    except Exception as e:
        print(f"[ERRO] {e}")
        sys.exit(1)

    ser.reset_input_buffer()
    ser.reset_output_buffer()

    print(" Iniciando Transacao...")
    t_start_pc = time.perf_counter()

    ser.write(PLAINTEXT)
    
    # Leitura de 20 bytes (16 Ciphertext + 4 informacoes de tempo geradas pelo Hardware)
    resposta = ser.read(20)

    t_end_pc = time.perf_counter()
    ser.close()

    if len(resposta) != 20:
        print(f"[FAIL] Timeout! Esperados 20 bytes, recebidos {len(resposta)}.")
        sys.exit(1)

    # Extraindo dados
    ciphertext_bytes = resposta[:16]
    ciclos_bytes = resposta[16:20]
    
    # Converte os 4 bytes do timestamp para um inteiro (Big Endian)
    ciclos_hw = struct.unpack('>I', ciclos_bytes)[0]

    # Cálculos de Análise Temporal
    total_ms = (t_end_pc - t_start_pc) * 1000
    tempo_interno_aes_ms = (ciclos_hw / CLOCK_FREQ_HZ) * 1000
    tempo_interno_aes_us = tempo_interno_aes_ms * 1000
    tempo_uart_ms = total_ms - tempo_interno_aes_ms

    received_hex = ciphertext_bytes.hex()

    print(f"[VERIFICATION] Resultado Obtido : {received_hex}")
    if received_hex == EXPECTED_CIPHERTEXT_HEX:
        print("[VERIFICATION] STATUS           : [PASS] - Exato!")
    else:
        print("[VERIFICATION] STATUS           : [FAIL] - Incompatibilidade!")

    print("-" * 70)
    print("   ANÁLISE DE DESEMPENHO")
    print("-" * 70)
    print(f" Ciclos de Clock no SoC      : {ciclos_hw} ciclos")
    print(f" Tempo Interno (SoC + AES)   : {tempo_interno_aes_us:.2f} us ({tempo_interno_aes_ms:.6f} ms)")
    print(f" Tempo de Transmissao (UART) : {tempo_uart_ms:.2f} ms")
    print(f" Tempo Total : {total_ms:.2f} ms")
    print("=" * 70)

if __name__ == '__main__':
    main()