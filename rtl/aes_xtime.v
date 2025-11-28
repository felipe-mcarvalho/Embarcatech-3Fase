module aes_xtime (
    input  wire [7:0] in_byte,
    output wire [7:0] out_byte
);

    // ETAPA 1: Verificar se o MSB é 1.
    wire msb_is_set;
    assign msb_is_set = in_byte[7];

    // ETAPA 2: Fazer o Shift para a esquerda.
    wire [7:0] shifted;
    assign shifted = {in_byte[6:0], 1'b0}; // Descarta o bit 7  e concatena com 0.

    // ETAPA 3: Correção específica Campo de Galois (Polinômio 0x1B) se necessário.
    // Se msb_is_set for 1, fazemos XOR com 0x1B (00011011).
    assign out_byte = (msb_is_set) ? (shifted ^ 8'h1b) : shifted;

endmodule