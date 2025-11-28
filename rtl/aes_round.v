module aes_round (
    input  wire [127:0] state_in,      // Dados de entrada da rodada
    input  wire [127:0] round_key,     // A chave específica desta rodada
    input  wire         is_last_round, // 0 = Rodada Normal, 1 = última rodada 
    output wire [127:0] state_out      // Dados de saída
);

    // Fios internos para conectar os blocos
    wire [127:0] after_subbytes;
    wire [127:0] after_shiftrows;
    wire [127:0] after_mixcolumns;
    
    // Instância subBytes
    aes_sub_bytes u_subbytes (
        .state_in  (state_in),
        .state_out (after_subbytes)
    );

    // Instância shiftRows
    aes_shift_rows u_shiftrows (
        .state_in  (after_subbytes),
        .state_out (after_shiftrows)
    );

    // Instância mixColumns
    aes_mix_columns u_mixcolumns (
        .state_in  (after_shiftrows),
        .state_out (after_mixcolumns)
    );


    // Lógica do MUX para a última rodada
    // Se for a última rodada, pegar o dado  do ShiftRows.
    // Se for rodada normal,   pegar o dado do MixColumns.
	    
    wire [127:0] mix_mux_out; // Fio que decide quem entra no AddRoundKey
    assign mix_mux_out = (is_last_round) ? after_shiftrows : after_mixcolumns;


    // Instância addRoundKey
    aes_add_round_key u_addroundkey (
        .state_in  (mix_mux_out),
        .round_key (round_key),
        .state_out (state_out)
    );

endmodule