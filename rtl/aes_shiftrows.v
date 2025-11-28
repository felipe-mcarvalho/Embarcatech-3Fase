module aes_shift_rows (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);

    // ETAPA 1: Apelidos para os bytes de entrada
    // s0 é o primeiro byte, s15 é o último.
    wire [7:0] s0,  s1,  s2,  s3;
    wire [7:0] s4,  s5,  s6,  s7;
    wire [7:0] s8,  s9,  s10, s11;
    wire [7:0] s12, s13, s14, s15;

	// Notação BIG-ENDIAN
    // Mapeamento do vetor linear de entrada em uma matriz 4X4 preenchida coluna por coluna
    assign s0  = state_in[127:120]; 
	assign s1  = state_in[119:112]; 
	assign s2  = state_in[111:104]; 
	assign s3  = state_in[103: 96];
    assign s4  = state_in[ 95: 88]; 
	assign s5  = state_in[ 87: 80]; 
	assign s6  = state_in[ 79: 72]; 
	assign s7  = state_in[ 71: 64];
    assign s8  = state_in[ 63: 56]; 
	assign s9  = state_in[ 55: 48]; 
	assign s10 = state_in[ 47: 40]; 
	assign s11 = state_in[ 39: 32];
    assign s12 = state_in[ 31: 24]; 
	assign s13 = state_in[ 23: 16]; 
	assign s14 = state_in[ 15:  8]; 
	assign s15 = state_in[  7:  0];


    // ETAPA 2: ShiftRows
	// Operação de rotacionar é feita sobre as linhas
	
    // Linha 0:  s0,  s4,  s8, s12  (Não muda)
    // Linha 1:  s1,  s5,  s9, s13  (Rotaciona 1 p/ esquerda) -> s5,  s9, s13,  s1
    // Linha 2:  s2,  s6, s10, s14  (Rotaciona 2 p/ esquerda) -> s10, s14, s2,  s6
    // Linha 3:  s3,  s7, s11, s15  (Rotaciona 3 p/ esquerda) -> s15,  s3, s7, s11

    // Reconstrução da matriz da ETAPA 2 para vetor (coluna por coluna)
    // --- Coluna 0 da Saída ---
    assign state_out[127:120] = s0;   // Linha 0 original
    assign state_out[119:112] = s5;   // Linha 1 rotacionada: agora é s5
    assign state_out[111:104] = s10;  // Linha 2 rotacionada: agora é s10
    assign state_out[103: 96] = s15;  // Linha 3 rotacionada: agora é s15

    // --- Coluna 1 da Saída ---
    assign state_out[ 95: 88] = s4;   
    assign state_out[ 87: 80] = s9;   
    assign state_out[ 79: 72] = s14;  
    assign state_out[ 71: 64] = s3;   

    // --- Coluna 2 da Saída ---
    assign state_out[ 63: 56] = s8;   
    assign state_out[ 55: 48] = s13;  
    assign state_out[ 47: 40] = s2;   
    assign state_out[ 39: 32] = s7;   

    // --- Coluna 3 da Saída ---
    assign state_out[ 31: 24] = s12;  
    assign state_out[ 23: 16] = s1;   
    assign state_out[ 15:  8] = s6;   
    assign state_out[  7:  0] = s11;  

endmodule