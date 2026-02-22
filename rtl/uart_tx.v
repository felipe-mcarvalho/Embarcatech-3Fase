module uart_tx 
  #(parameter CLK_FREQ = 25000000, // 25 MHz
    parameter BAUD_RATE = 115200)
  (
    input  wire       i_Clk,
    input  wire       i_Rst_L,     // Reset Ativo em Baixo
    input  wire       i_Tx_DV,
    input  wire [7:0] i_Tx_Byte,
    output reg        o_Tx_Active,
    output reg        o_Tx_Serial,
    output reg        o_Tx_Done
  );

  localparam IDLE         = 3'b000;
  localparam TX_START_BIT = 3'b001;
  localparam TX_DATA_BITS = 3'b010;
  localparam TX_STOP_BIT  = 3'b011;
  localparam CLEANUP      = 3'b100;

  localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

  reg [2:0]    r_SM_Main     = 0;
  reg [15:0]   r_Clk_Count   = 0;
  reg [2:0]    r_Bit_Index   = 0;
  reg [7:0]    r_Tx_Data     = 0;
   
  always @(posedge i_Clk) begin
    // Se o RESET for 0 (GND), reseta tudo
    if (i_Rst_L == 1'b0) begin
        r_SM_Main   <= 3'b000; // IDLE
        o_Tx_Active <= 1'b0;
        o_Tx_Done   <= 1'b0;
        o_Tx_Serial <= 1'b1;   // Linha TX deve resetar em ALTO (Idle)
        r_Clk_Count <= 0;
        r_Bit_Index <= 0;
    end else begin
        case (r_SM_Main)
          IDLE : begin
            o_Tx_Serial   <= 1'b1; 
            o_Tx_Done     <= 1'b0;
            o_Tx_Active   <= 1'b0;
            r_Clk_Count   <= 0;
            r_Bit_Index   <= 0;

            if (i_Tx_DV == 1'b1) begin
              r_Tx_Data   <= i_Tx_Byte;
              r_SM_Main   <= TX_START_BIT;
              o_Tx_Active <= 1'b1;
            end
          end

          TX_START_BIT : begin
            o_Tx_Serial <= 1'b0;
            if (r_Clk_Count < CLKS_PER_BIT-1) begin
              r_Clk_Count <= r_Clk_Count + 1;
            end else begin
              r_Clk_Count <= 0;
              r_SM_Main   <= TX_DATA_BITS;
            end
          end

          TX_DATA_BITS : begin
            o_Tx_Serial <= r_Tx_Data[r_Bit_Index];
            if (r_Clk_Count < CLKS_PER_BIT-1) begin
              r_Clk_Count <= r_Clk_Count + 1;
            end else begin
              r_Clk_Count <= 0;
              if (r_Bit_Index < 7) begin
                r_Bit_Index <= r_Bit_Index + 1;
              end else begin
                r_Bit_Index <= 0;
                r_SM_Main   <= TX_STOP_BIT;
              end
            end
          end

          TX_STOP_BIT : begin
            o_Tx_Serial <= 1'b1;
            if (r_Clk_Count < CLKS_PER_BIT-1) begin
              r_Clk_Count <= r_Clk_Count + 1;
            end else begin
              o_Tx_Done   <= 1'b1;
              r_Clk_Count <= 0;
              r_SM_Main   <= CLEANUP;
              o_Tx_Active <= 1'b0;
            end
          end

          CLEANUP : begin
            o_Tx_Done <= 1'b1;
            r_SM_Main <= IDLE;
          end

          default : r_SM_Main <= IDLE;
        endcase
    end 
  end   
endmodule
