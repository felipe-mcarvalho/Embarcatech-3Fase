module aes_key_expand_128 (
    input  wire [127:0] current_key, // Chave da rodada atual (Round K)
    input  wire [7:0]   rcon,        // Constante da rodada atual (Rcon[i])
    output wire [127:0] next_key     // Chave da próxima rodada (Round K+1)
);

    // ETAPA 1: Dividir a chave atual em 4 palavras de 32 bits (w0..w3)
    wire [31:0] w0, w1, w2, w3;
    
    assign w0 = current_key[127:96];
    assign w1 = current_key[95: 64];
    assign w2 = current_key[63: 32];
    assign w3 = current_key[31:  0];

    // ETAPA 2: Implementação da Função "g()" aplicada sobre w3
    // g(w3) = SubWord(RotWord(w3)) XOR Rcon
    
    // 2.1 RotWord: Rotaciona 8 bits à esquerda
    // Entrada: [b0, b1, b2, b3] -> Saída: [b1, b2, b3, b0]
    wire [31:0] rot_w3;
    assign rot_w3 = {w3[23:0], w3[31:24]};

    // 2.2 SubWord: Aplica a S-Box em cada um dos 4 bytes rotacionados
    wire [31:0] sub_w3;
    
    // Instancia 4 S-Boxes 
    aes_sbox sbox_0 (.in_byte(rot_w3[31:24]), .out_byte(sub_w3[31:24]));
    aes_sbox sbox_1 (.in_byte(rot_w3[23:16]), .out_byte(sub_w3[23:16]));
    aes_sbox sbox_2 (.in_byte(rot_w3[15: 8]), .out_byte(sub_w3[15: 8]));
    aes_sbox sbox_3 (.in_byte(rot_w3[ 7: 0]), .out_byte(sub_w3[ 7: 0]));

    // 2.3 Rcon XOR: Soma a constante apenas no byte mais significativo
    // Rcon é aplicado em [31:24], os outros bits são XOR com 0.
    wire [31:0] g_w3;
    assign g_w3 = sub_w3 ^ {rcon, 24'h000000};


    // ETAPA 3: Geração das novas palavras (XOR em Cadeia)
    wire [31:0] w4, w5, w6, w7;

    assign w4 = w0 ^ g_w3;  // A primeira palavra nova depende da função g()
    assign w5 = w1 ^ w4;    // As seguintes dependem da anterior
    assign w6 = w2 ^ w5;
    assign w7 = w3 ^ w6;

    // ETAPA 4: Concatenação final
    assign next_key = {w4, w5, w6, w7};

endmodule