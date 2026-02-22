	//    Referência: FIPS 197, Página 17, Tabela 5. "Round constantes".
	module aes_rcon (
    input  wire [3:0] round,    // Número da rodada atual (1 a 10)
    output reg  [7:0] rcon_val  // Valor da constante Rcon
);

    always @(*) begin
        case (round)
            4'd1:  rcon_val = 8'h01; // Rodada 1
            4'd2:  rcon_val = 8'h02; // Rodada 2
            4'd3:  rcon_val = 8'h04; // Rodada 3
            4'd4:  rcon_val = 8'h08; // Rodada 4
            4'd5:  rcon_val = 8'h10; // Rodada 5
            4'd6:  rcon_val = 8'h20; // Rodada 6
            4'd7:  rcon_val = 8'h40; // Rodada 7
            4'd8:  rcon_val = 8'h80; // Rodada 8
            4'd9:  rcon_val = 8'h1b; // Rodada 9
            4'd10: rcon_val = 8'h36; // Rodada 10
            default: rcon_val = 8'h00;
        endcase
    end

endmodule