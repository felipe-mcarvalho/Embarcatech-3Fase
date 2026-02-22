# --- Estrutura de Diretórios ---
FW_DIR      = firmware
SCRIPT_DIR  = scripts

# --- Configurações da Toolchain ---
TOOLCHAIN_PREFIX = riscv32-unknown-elf-
GCC      = $(TOOLCHAIN_PREFIX)gcc
OBJDUMP  = $(TOOLCHAIN_PREFIX)objdump
OBJCOPY  = $(TOOLCHAIN_PREFIX)objcopy
PYTHON   = python3

# --- Flags ---
# -Os: Otimiza para tamanho
# -Wall: Mostra avisos
CFLAGS  = -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib -Os -Wall
LDFLAGS = -T $(FW_DIR)/sections.lds

# --- Alvos Principais ---
all: firmware.hex firmware.lst

# Gera listagem para debug
firmware.lst: firmware.elf
	$(OBJDUMP) -D firmware.elf > firmware.lst

# Linkagem final
firmware.elf: start.o firmware.o
	$(GCC) $(CFLAGS) $(LDFLAGS) start.o firmware.o -o firmware.elf

# Compilação do Assembly 
start.o: $(FW_DIR)/start.S
	$(GCC) $(CFLAGS) -c $(FW_DIR)/start.S -o start.o

# Compilação do C 
firmware.o: $(FW_DIR)/firmware.c
	$(GCC) $(CFLAGS) -c $(FW_DIR)/firmware.c -o firmware.o

# Conversão ELF -> Binário
firmware.bin: firmware.elf
	$(OBJCOPY) -O binary firmware.elf firmware.bin

# Geração do HEX 
firmware.hex: firmware.bin
	$(PYTHON) $(SCRIPT_DIR)/makehex.py firmware.bin 1024 > firmware.hex

# Limpeza
clean:
	rm -f *.o *.elf *.bin *.hex *.lst

.PHONY: all clean