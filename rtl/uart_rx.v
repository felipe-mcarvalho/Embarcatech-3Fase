module uart_rx
  #(parameter CLK_FREQ = 25000000,
    parameter BAUD_RATE = 115200)
  (
    input  wire       i_Clk,
    input  wire       i_Rst_L,
    input  wire       i_Rx_Serial,
    output reg        o_Rx_DV,
    output reg [7:0]  o_Rx_Byte
  );

  localparam IDLE         = 3'b000;
  localparam RX_START_BIT = 3'b001;
  localparam RX_DATA_BITS = 3'b010;
  localparam RX_STOP_BIT  = 3'b011;
  localparam CLEANUP      = 3'b100;

  localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
   
  reg r_Rx_Data_R = 1'b1;
  reg r_Rx_Data   = 1'b1;

  reg [2:0]  r_SM_Main   = 0;
  reg [15:0] r_Clk_Count = 0;
  reg [2:0]  r_Bit_Index = 0;
  reg [7:0]  r_Rx_Byte   = 0;

  always @(posedge i_Clk) begin
    if (i_Rst_L == 1'b0) begin
        r_SM_Main   <= 3'b000;
        o_Rx_DV     <= 1'b0;
        r_Clk_Count <= 0;
        r_Bit_Index <= 0;
        r_Rx_Data_R <= 1'b1; // Resetar para 1 
        r_Rx_Data   <= 1'b1;
    end else begin
        // Sincronizadores
        r_Rx_Data_R <= i_Rx_Serial;
        r_Rx_Data   <= r_Rx_Data_R;
        
        case (r_SM_Main)
          IDLE : begin
            o_Rx_DV       <= 1'b0;
            r_Clk_Count   <= 0;
            r_Bit_Index   <= 0;
            if (r_Rx_Data == 1'b0) begin
              r_SM_Main <= RX_START_BIT;
            end
          end

          RX_START_BIT : begin
            if (r_Clk_Count == (CLKS_PER_BIT-1)/2) begin
              if (r_Rx_Data == 1'b0) begin
                r_Clk_Count <= 0;
                r_SM_Main   <= RX_DATA_BITS;
              end else begin
                r_SM_Main   <= IDLE;
              end
            end else begin
              r_Clk_Count <= r_Clk_Count + 1;
            end
          end

          RX_DATA_BITS : begin
            if (r_Clk_Count < CLKS_PER_BIT-1) begin
              r_Clk_Count <= r_Clk_Count + 1;
            end else begin
              r_Clk_Count            <= 0;
              r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
              if (r_Bit_Index < 7) begin
                r_Bit_Index <= r_Bit_Index + 1;
              end else begin
                r_Bit_Index <= 0;
                r_SM_Main   <= RX_STOP_BIT;
              end
            end
          end

          RX_STOP_BIT : begin
            if (r_Clk_Count < CLKS_PER_BIT-1) begin
              r_Clk_Count <= r_Clk_Count + 1;
            end else begin
              o_Rx_DV     <= 1'b1;
              o_Rx_Byte   <= r_Rx_Byte;
              r_Clk_Count <= 0;
              r_SM_Main   <= CLEANUP;
            end
          end

          CLEANUP : begin
            r_SM_Main <= IDLE;
            o_Rx_DV   <= 1'b0;
          end

          default : r_SM_Main <= IDLE;
        endcase
    end 
  end   
endmodule