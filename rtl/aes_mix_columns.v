module aes_mix_columns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);

	// Referência: FIPS 197, Página 17, Seção 5.1.3
	
    // ETAPA 1: Instanciação dos multiplicadores por 2 (xtime)
    // Calcular o xtime para cada byte da entrada.
    wire [127:0] state_x; // valores intermediários
    
    genvar i;
    generate
		// Instancia o módulo aes_xtime para cada byte 
        for (i = 0; i < 16; i = i + 1) begin : gen_xtime
            aes_xtime u_xtime (
                .in_byte  (state_in[8*i + 7 : 8*i]), 
                .out_byte (state_x [8*i + 7 : 8*i])
            );
        end
    endgenerate


    // ETAPA 2: Apelidos
    // s = byte original do state_in
    // x = byte multiplicado por 2 (state_x)
    wire [7:0] s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10,s11, s12, s13, s14,s15;
    wire [7:0] x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10,x11, x12, x13, x14,x15;

    // Mapeamento dos bytes BIG-ENDIAN
    assign s0 = state_in[127:120]; assign x0 = state_x[127:120];
    assign s1 = state_in[119:112]; assign x1 = state_x[119:112];
    assign s2 = state_in[111:104]; assign x2 = state_x[111:104];
    assign s3 = state_in[103: 96]; assign x3 = state_x[103: 96];

    assign s4 = state_in[ 95: 88]; assign x4 = state_x[ 95: 88];
    assign s5 = state_in[ 87: 80]; assign x5 = state_x[ 87: 80];
    assign s6 = state_in[ 79: 72]; assign x6 = state_x[ 79: 72];
    assign s7 = state_in[ 71: 64]; assign x7 = state_x[ 71: 64];

    assign s8 = state_in[ 63: 56]; assign x8 = state_x[ 63: 56];
    assign s9 = state_in[ 55: 48]; assign x9 = state_x[ 55: 48];
    assign s10= state_in[ 47: 40]; assign x10= state_x[ 47: 40];
    assign s11= state_in[ 39: 32]; assign x11= state_x[ 39: 32];

    assign s12= state_in[ 31: 24]; assign x12= state_x[ 31: 24];
    assign s13= state_in[ 23: 16]; assign x13= state_x[ 23: 16];
    assign s14= state_in[ 15:  8]; assign x14= state_x[ 15:  8];
    assign s15= state_in[  7:  0]; assign x15= state_x[  7:  0];


    // ETAPA: 3. Aplicando a Transformação
	// Multiplicar o byte atual pela matriz constante definida pela referência
	// ---
    // Multiplicação por 3 é (x ^ s) (3y = 2y XOR y)
    // 2*s = x - multiplicação do byte original (s) por 2 pré calculada pelo xtime
    // 3*s = x ^ s
    // 1*s = s
    
    // Coluna 0 
    assign state_out[127:120] = x0 ^ (x1 ^ s1) ^ s2 ^ s3;    // [02 03 01 01] -> x0 ^ (x1^s1) ^ s2 ^ s3
    assign state_out[119:112] = s0 ^ x1 ^ (x2 ^ s2) ^ s3;    // [01 02 03 01] -> s0 ^ x1 ^ (x2^s2) ^ s3
    assign state_out[111:104] = s0 ^ s1 ^ x2 ^ (x3 ^ s3);    // [01 01 02 03] -> s0 ^ s1 ^ x2 ^ (x3^s3)
    assign state_out[103: 96] = (x0 ^ s0) ^ s1 ^ s2 ^ x3;    // [03 01 01 02] -> (x0^s0) ^ s1 ^ s2 ^ x3

    // Coluna 1
    assign state_out[ 95: 88] = x4 ^ (x5 ^ s5) ^ s6 ^ s7;
    assign state_out[ 87: 80] = s4 ^ x5 ^ (x6 ^ s6) ^ s7;
    assign state_out[ 79: 72] = s4 ^ s5 ^ x6 ^ (x7 ^ s7);
    assign state_out[ 71: 64] = (x4 ^ s4) ^ s5 ^ s6 ^ x7;

    // Coluna 2
    assign state_out[ 63: 56] = x8 ^ (x9 ^ s9) ^ s10 ^ s11;
    assign state_out[ 55: 48] = s8 ^ x9 ^ (x10 ^ s10) ^ s11;
    assign state_out[ 47: 40] = s8 ^ s9 ^ x10 ^ (x11 ^ s11);
    assign state_out[ 39: 32] = (x8 ^ s8) ^ s9 ^ s10 ^ x11;

    // Coluna 3
    assign state_out[ 31: 24] = x12 ^ (x13 ^ s13) ^ s14 ^ s15;
    assign state_out[ 23: 16] = s12 ^ x13 ^ (x14 ^ s14) ^ s15;
    assign state_out[ 15:  8] = s12 ^ s13 ^ x14 ^ (x15 ^ s15);
    assign state_out[  7:  0] = (x12 ^ s12) ^ s13 ^ s14 ^ x15;

endmodule