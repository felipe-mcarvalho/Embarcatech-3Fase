# Embarcatech 3Fase

## Documentação
A referência utilizada para o desenvolvimento e validação dos vetores de teste encontra-se em:
- `docs/NIST.FIPS.197.pdf`


## Imagens e Resultados

### Visão Física (Layout)
![Physical View do SoC com o PicoRV32](docs/img/soc_top_physical_view.png)

### Simulação: Bloco AES
Validação dos vetores de teste.
![Testbench AES 1](docs/img/tb_aes1.png)
![Testbench AES 2](docs/img/tb_aes2.png)
![Testbench AES 3](docs/img/tb_aes3.png)

### Simulação: SoC PicoRV32
Execução de código e validação do processador RISC-V.
![Testbench PicoRV32 1](docs/img/tb_pico1.png)
![Testbench PicoRV32 2](docs/img/tb_pico2.png)
![Testbench PicoRV32 3](docs/img/tb_pico3.png)

### Simulação: Comunicação UART
Teste de transmissão e recepção serial.
![Testbench UART](docs/img/tb_uart1.png)
![Pinagem UART](docs/img/pinagem_uart.png)

### Erros da placa
![erro1](docs/img/erro1.png)
![erro2](docs/img/erro2.png)