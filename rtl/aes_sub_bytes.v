module aes_sub_bytes (
    input  wire [127:0] state_in,  // Estado atual
    output wire [127:0] state_out  // Estado depois da substituição
);

    genvar i;
    generate
        // Instanciação de 16 SBOX
        for (i = 0; i < 16; i = i + 1) begin : gen_sbox
            aes_sbox sbox_inst (       
                .in_byte  (state_in[(8*i) + 7 : (8*i)]), // Pega 8 bits da entrada (ex: 7:0, 15:8, 23:16...)
                .out_byte (state_out[(8*i) + 7 : (8*i)]) // Joga o resultado nos 8 bits da saída
            );
            
        end
    endgenerate

endmodule