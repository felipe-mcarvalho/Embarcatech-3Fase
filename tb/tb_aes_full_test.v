`timescale 1ns / 1ps

module tb_aes_full_test;

    // Sinais
    reg  [127:0] current_state; // Estado atual
    reg  [127:0] current_key;   // Chave da rodada
    reg          is_last_round; // Flag
    wire [127:0] next_state;    // Saída do hardware

    // Memória para as keys disponíveis no Apêndice C.1, FIPS 197, Página 35
    reg [127:0] keys [0:10]; 
    integer i;

    // Instancia do top module Round
    aes_round dut (
        .state_in      (current_state),
        .round_key     (current_key),
        .is_last_round (is_last_round),
        .state_out     (next_state)
    );

    initial begin
        $display("TESTE AES-128 (FIPS 197 - Apendice C.1, Página 35)");

        // 1. Carregar as chaves manuais (Extraídas das linhas "k_sch")
        keys[0]  = 128'h000102030405060708090a0b0c0d0e0f; // Chave Inicial
        keys[1]  = 128'hd6aa74fdd2af72fadaa678f1d6ab76fe; // Round 1
        keys[2]  = 128'hb692cf0b643dbdf1be9bc5006830b3fe; // Round 2
        keys[3]  = 128'hb6ff744ed2c2c9bf6c590cbf0469bf41; // Round 3
        keys[4]  = 128'h47f7f7bc95353e03f96c32bcfd058dfd; // Round 4
        keys[5]  = 128'h3caaa3e8a99f9deb50f3af57adf622aa; // Round 5
        keys[6]  = 128'h5e390f7df7a69296a7553dc10aa31f6b; // Round 6
        keys[7]  = 128'h14f9701ae35fe28c440adf4d4ea9c026; // Round 7
        keys[8]  = 128'h47438735a41c65b9e016baf4aebf7ad2; // Round 8
        keys[9]  = 128'h549932d1f08557681093ed9cbe2c974e; // Round 9
        keys[10] = 128'h13111d7fe3944a17f307a78b4d2b30c5; // Round 10 

        // 2. Initial Key Addition
        // Estado Inicial = Plaintext XOR Chave[0]
        // Plaintext: 00112233445566778899aabbccddeeff
        
        current_state = 128'h00112233445566778899aabbccddeeff ^ keys[0];
        
        $display("Plaintext utilizado: 00112233445566778899aabbccddeeff");
        $display("Estado apos XOR Inicial (Start Round 1): %h", current_state);

        // 3. Loop das 10 Rodadas
        for (i = 1; i <= 10; i = i + 1) begin
            current_key = keys[i]; // Utiliza a chave da rodada atual
            
            // Verifica se é a última rodada para desligar o MixColumns
            if (i == 10) is_last_round = 1; 
            else         is_last_round = 0;
            #10; 
            
            $display("Rodada %0d Completada. Saida: %h", i, next_state);
            
            // Atualiza o estado para a próxima rodada
            current_state = next_state; 
        end

        $display("------------------------------------------------");
        $display("CIPHERTEXT FINAL: %h", current_state);
        $display("ESPERADO:   69c4e0d86a7b0430d8cdb78070b4c55a");

        $finish;
    end

endmodule