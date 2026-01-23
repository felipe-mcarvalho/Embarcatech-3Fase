module top (
    input  wire clk,      // Clock 25MHz
    input  wire rst_n,    // Reset (Ativo em Baixo)
    input  wire uart_rx,  // Entrada Serial
    output wire uart_tx   // Saída Serial
);

    // -------------------------------------------------------------------------
    // 1. Sinais Internos
    // -------------------------------------------------------------------------
    
    // O FIFO usa reset positivo, mas esse top usa negativo (rst_n)
    wire w_rst_pos = ~rst_n;

    // Conexões RX -> FIFO
    wire [7:0] w_rx_byte;
    wire       w_rx_dv;
    
    // Conexões FIFO -> Controle -> TX
    wire [7:0] w_fifo_data_out;
    wire       w_fifo_empty;
    wire       w_fifo_full;
    reg        r_fifo_rd;      // Sinal de leitura da FIFO
    
    // Sinais do TX
    reg        r_tx_start;     // Sinal para iniciar transmissão
    wire       w_tx_active;    // Feedback se o TX está ocupado

    // -------------------------------------------------------------------------
    // 2. Instância do RX (Recebe do PC)
    // -------------------------------------------------------------------------
    uart_rx #(
        .CLK_FREQ(25000000), 
        .BAUD_RATE(115200)
    ) Receiver (
        .i_Clk(clk),
        .i_Rst_L(rst_n),
        .i_Rx_Serial(uart_rx),
        .o_Rx_DV(w_rx_dv),      // Pulso de "Dado Pronto"
        .o_Rx_Byte(w_rx_byte)   // O Dado
    );

    // -------------------------------------------------------------------------
    // 3. Instância da FIFO 
    // O RX escreve aqui. A lógica de controle lê daqui.
    // -------------------------------------------------------------------------
    fifo_buffer_circular_param #(
        .DATA_WIDTH(8),
        .FIFO_DEPTH(16) // Potência de 2 obrigatória (16 bytes de buffer)
    ) MyUART_FIFO (
        .clk(clk),
        .reset(w_rst_pos), // Reset Positivo
        
        // --- Escrita (Vem do RX) ---
        // Só escreve se o RX mandou dado E a FIFO não está cheia
        .wr(w_rx_dv & ~w_fifo_full), 
        .w_data(w_rx_byte),
        
        // --- Leitura  ---
        .rd(r_fifo_rd),
        .r_data(w_fifo_data_out),
        
        // --- Status ---
        .full(w_fifo_full),
        .empty(w_fifo_empty)
    );

    // -------------------------------------------------------------------------
    // 4. Lógica de Controle 
    // Tira da FIFO e manda para o TX apenas quando o TX está livre.
    // -------------------------------------------------------------------------
    
    // Estados da FSM de controle
    localparam S_IDLE    = 2'b00;
    localparam S_TRIGGER = 2'b01;
    localparam S_WAIT    = 2'b10;
    
    reg [1:0] state = S_IDLE;

    always @(posedge clk) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            r_fifo_rd  <= 1'b0;
            r_tx_start <= 1'b0;
        end else begin
            case (state)
                // Estado 0: Espera ter dados na FIFO e TX estar livre
                S_IDLE: begin
                    r_fifo_rd  <= 1'b0;
                    r_tx_start <= 1'b0;

                    // Se FIFO tem algo (NÃO vazia) E o TX NÃO está ocupado
                    if (!w_fifo_empty && !w_tx_active) begin
                        // Inicia a transferência
                        r_fifo_rd  <= 1'b1; // Consome o dado da FIFO 
                        r_tx_start <= 1'b1; // Manda o TX enviar esse dado
                        state      <= S_TRIGGER;
                    end
                end

                // Estado 1: Garante que os pulsos durem apenas 1 ciclo
                S_TRIGGER: begin
                    r_fifo_rd  <= 1'b0; // Desliga o sinal de leitura
                    r_tx_start <= 1'b0; // Desliga o sinal de start
                    state      <= S_WAIT;
                end

                // Estado 2: Espera o TX terminar o serviço
                S_WAIT: begin
                    // Enquanto w_tx_active for 1, ficamos aqui.
                    // Quando for 0, voltamos para buscar o próximo na FIFO.
                    if (!w_tx_active) begin
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // 5. Instância do TX (Manda para o PC)
    // -------------------------------------------------------------------------
    uart_tx #(
        .CLK_FREQ(25000000), 
        .BAUD_RATE(115200)
    ) Transmitter (
        .i_Clk(clk),
        .i_Rst_L(rst_n),
        .i_Tx_DV(r_tx_start),        // Gatilho controlado pela FSM
        .i_Tx_Byte(w_fifo_data_out), // Dado vindo da FIFO
        .o_Tx_Active(w_tx_active),   // Avisa a FSM se está ocupado
        .o_Tx_Serial(uart_tx),
        .o_Tx_Done()                 // Não usado aqui
    );

endmodule