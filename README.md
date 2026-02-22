# SoC RISC-V com Acelerador AES-128 - Embarcatech 3ª Fase

Este repositório contém o projeto final da 3ª Fase do programa Embarcatech. O sistema consiste em um System-on-Chip (SoC) baseado no processador RISC-V (PicoRV32), integrado a um acelerador criptográfico de hardware para o algoritmo AES-128 e controlado externamente via interface serial (UART). O projeto foi sintetizado e validado fisicamente em uma FPGA Lattice ECP5 (Colorlight i9).

## Visão Geral do Projeto
Abaixo estão representados o diagrama da arquitetura lógica instanciada no SoC e a montagem física do sistema na placa FPGA.

![Diagrama RTL](docs/img/diagrama_rtl.svg)
![Foto do Projeto](docs/img/placa1.jpg)

---

## Estrutura do Repositório

- `rtl/`: Códigos-fonte em Verilog descrevendo o hardware (CPU, AES, UART, Interconexões).
- `firmware/`: Códigos em linguagem C e Linker Scripts executados pelo PicoRV32.
- `sim/`: Arquivos de testbench e simulação.
- `scripts/`: Scripts auxiliares de automação.
- `validation/`: Scripts em Python.
- `Makefile`: Automação da compilação do firmware.
- `docs/`: Documentação de referência, imagens e diagramas.

---

## Demonstrações em Vídeo
Clique nas thumbnails abaixo para visualizar os testes na placa:

[![Validação módulo AES](https://img.youtube.com/vi/sAaSfQWxbzg/0.jpg)](https://www.youtube.com/watch?v=sAaSfQWxbzg)
[![Validação RISC-V](https://img.youtube.com/vi/2NX07yqfi-U/0.jpg)](https://www.youtube.com/watch?v=2NX07yqfi-U)

## Visão Física e Layout
![Physical View do SoC com o PicoRV32](docs/img/soc_top_physical_view.png)

## Simulação: Bloco AES
Validação dos vetores de teste matemáticos da criptografia.
![Testbench AES 1](docs/img/tb_aes1.png)
![Testbench AES 2](docs/img/tb_aes2.png)
![Testbench AES 3](docs/img/tb_aes3.png)

## Simulação: SoC PicoRV32
Execução de código e validação das instruções do processador RISC-V.
![Testbench PicoRV32 1](docs/img/tb_pico1.png)
![Testbench PicoRV32 2](docs/img/tb_pico2.png)
![Testbench PicoRV32 3](docs/img/tb_pico3.png)

## Comunicação UART
Teste de transmissão e recepção serial.
![Testbench UART](docs/img/tb_uart1.png)
![Teste UART sintetizada na colorlight-i9](docs/img/teste_uart_sintetizada.png)
![Pinagem UART](docs/img/pinagem_uart.png)

## Erros da Placa (Debug)
![erro1](docs/img/erro1.png)
![erro2](docs/img/erro2.png)