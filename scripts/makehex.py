import sys


with open(sys.argv[1], "rb") as f:
    bindata = f.read()

mem_size_words = int(sys.argv[2])
mem_size_bytes = mem_size_words * 4

# Garante que o binário não é maior que a memória
if len(bindata) > mem_size_bytes:
    print(f"Erro: Binário ({len(bindata)} bytes) maior que a memória ({mem_size_bytes} bytes)")
    sys.exit(1)

# Preenche o restante da memória com zeros
bindata = bindata.ljust(mem_size_bytes, b'\x00')

# Converte bytes para palavras de 32 bits (Little Endian) e imprime em HEX
for i in range(0, len(bindata), 4):
    w = bindata[i:i+4]
    # Empacota os 4 bytes em uma palavra de 32 bits
    word = (w[3] << 24) | (w[2] << 16) | (w[1] << 8) | w[0]
    print(f"{word:08x}")
