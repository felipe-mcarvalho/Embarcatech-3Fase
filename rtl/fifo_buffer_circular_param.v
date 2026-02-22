module fifo_buffer_circular_param #(
    parameter DATA_WIDTH = 8, // Largura da palavra (ex: 8 bits, 16 bits...)
    parameter FIFO_DEPTH = 8  // Profundidade da FIFO (Quantidade de palavras: 8, 16, 32...)
)(
    input clk,
    input reset,
    input rd,
    input wr,
    input [DATA_WIDTH-1:0] w_data,
    output full,
    output empty,
    output [DATA_WIDTH-1:0] r_data
);

    // CALCULO AUTOMATICO DOS BITS DE ENDEREÇO
    // A função $clog2 calcula o logaritmo na base 2 arredondado para cima.
    // Ex: Se FIFO_DEPTH = 8, $clog2(8) = 3 bits.
    // Ex: Se FIFO_DEPTH = 16, $clog2(16) = 4 bits.
    localparam PTR_WIDTH = $clog2(FIFO_DEPTH);
    
    integer i;
    
    // Array de memória: Profundidade x Largura
    reg [DATA_WIDTH-1:0] array_reg [0:FIFO_DEPTH-1];
    
    // Ponteiros
    reg [PTR_WIDTH-1:0] w_ptr_reg, w_ptr_next, r_ptr_reg, r_ptr_next;
    wire [PTR_WIDTH-1:0] w_ptr_succ, r_ptr_succ;
    
    reg full_reg, empty_reg, full_next, empty_next;
    
    wire [1:0] wr_op; 
    wire wr_en; 

    assign wr_en = wr & ~full_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            for (i = 0; i < FIFO_DEPTH; i = i + 1)
                array_reg[i] <= {DATA_WIDTH{1'b0}};
        else if (wr_en)
            array_reg[w_ptr_reg] <= w_data;
    end

    assign r_data = array_reg[r_ptr_reg];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            w_ptr_reg <= {PTR_WIDTH{1'b0}};
            r_ptr_reg <= {PTR_WIDTH{1'b0}};
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    // Lógica de incremento
    // Nota: Isso funciona perfeitamente quando FIFO_DEPTH é potência de 2 (8, 16, 32...)
    // pois o overflow binário natural faz a volta para 0.
    assign w_ptr_succ = w_ptr_reg + 1'b1;
    assign r_ptr_succ = r_ptr_reg + 1'b1;

    assign wr_op = {wr, rd};

    assign full  = full_reg;
    assign empty = empty_reg;

    always @(*) begin
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;

        case (wr_op)
            2'b00: ; // NOP
            
            2'b01: begin // Read
                if (!empty_reg) begin
                    r_ptr_next = r_ptr_succ;
                    full_next  = 1'b0;
                    if (r_ptr_succ == w_ptr_reg)
                        empty_next = 1'b1;
                end
            end
            
            2'b10: begin // Write
                if (!full_reg) begin
                    w_ptr_next = w_ptr_succ;
                    empty_next = 1'b0;
                    if (w_ptr_succ == r_ptr_reg)
                        full_next = 1'b1;
                end
            end
            
            default: begin // Read + Write
                w_ptr_next = w_ptr_succ;
                r_ptr_next = r_ptr_succ;
            end
        endcase
    end

endmodule
