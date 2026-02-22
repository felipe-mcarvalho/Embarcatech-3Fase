`timescale 1ns / 1ps

module aes_core (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,      
    input  wire [127:0] plaintext,  
    input  wire [127:0] key,        
    
    output wire [127:0] ciphertext, 
    output wire         done        
);

    // 1. Registradores Internos 
    reg [127:0] state_reg;  
    reg [127:0] key_reg;    
    reg [3:0]   round_cnt;  
    reg         busy;       

    // 2. Fios de Conexão
    wire [7:0]   rcon_wire;
    wire [127:0] next_key_wire;
    wire [127:0] next_state_wire;
    wire         is_last_round;

    assign is_last_round = (round_cnt == 4'd10);
    assign ciphertext = state_reg;
    assign done = (round_cnt == 4'd11); 

    // 3. Instanciação dos Módulos Auxiliares

    aes_rcon u_rcon (
        .round    (round_cnt),
        .rcon_val (rcon_wire)
    );

    aes_key_expand_128 u_key_expand (
        .current_key (key_reg),
        .rcon         (rcon_wire),
        .next_key    (next_key_wire)
    );

    aes_round u_round (
        .state_in      (state_reg),
        .round_key     (next_key_wire),
        .is_last_round (is_last_round),
        .state_out     (next_state_wire)
    );

    // 4. Lógica Sequencial
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= 128'd0;
            key_reg   <= 128'd0;
            round_cnt <= 4'd0;
            busy      <= 1'b0;
        end else begin
            if (start) begin
                state_reg <= plaintext ^ key;
                key_reg   <= key;
                round_cnt <= 4'd1; 
                busy      <= 1'b1;
            end 
            else if (busy) begin
                if (round_cnt <= 4'd10) begin
                    state_reg <= next_state_wire;
                    key_reg   <= next_key_wire;
                    round_cnt <= round_cnt + 1'b1;
                end else begin
                    busy <= 1'b0;
                end
            end
        end
    end

endmodule