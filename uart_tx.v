//Listing 8.3
module uart_tx
   #(
     parameter N = 8,     
    parameter COUNT_TICKS = 16 
   )
   (
    input wire clk,
    input wire reset,
    input wire tx_start, 
    input wire tick,
    input wire [N-1:0] data_in,
    output reg tx_done,
    output wire tx
   );

   // symbolic state declaration
   localparam [1:0]
      IDLE  = 2'b00,
      START = 2'b01,
      DATA  = 2'b10,
      STOP  = 2'b11;

   // signal declaration
   reg [1:0] state, next_state;
   reg [3:0] baud_counter, baud_counter_reg;
   reg [2:0] bit_counter, bit_counter_reg;
   reg [7:0] shift_reg, shift_reg_next;
   reg tx_reg, tx_next;

   // body
   // FSMD state & data registers
   always @(posedge clk)
      if (reset)
         begin
            state <= IDLE;
            baud_counter <= 0;
            bit_counter <= 0;
            shift_reg <= 0;
            tx_reg <= 1'b1;
         end
      else
         begin
            state <= next_state;
            baud_counter <= baud_counter_reg;
            bit_counter <= bit_counter_reg;
            shift_reg <= shift_reg_next;
            tx_reg <= tx_next;
         end

   // FSMD next-state logic & functional units
   always @*
   begin
      next_state = state;
      tx_done = 1'b0;
      baud_counter_reg = baud_counter;
      bit_counter_reg = bit_counter;
      shift_reg_next = shift_reg;
      tx_next = tx_reg ;
      case (state)
         IDLE:
            begin
               tx_next = 1'b1;
               if (tx_start)
                  begin
                     next_state = START;
                     baud_counter_reg = 0;
                     shift_reg_next = data_in;
                  end
            end
         START:
            begin
               tx_next = 1'b0;
               if (tick)
                  if (baud_counter==(COUNT_TICKS-1))
                     begin
                        next_state = DATA;
                        baud_counter_reg = 0;
                        bit_counter_reg = 0;
                     end
                  else
                     baud_counter_reg = baud_counter + 1;
            end
         DATA:
            begin
               tx_next = shift_reg[0];
               if (tick)
                  if (baud_counter==(COUNT_TICKS-1))
                     begin
                        baud_counter_reg = 0;
                        shift_reg_next = shift_reg >> 1;
                        if (bit_counter==(N-1))
                           next_state = STOP ;
                        else
                           bit_counter_reg = bit_counter + 1;
                     end
                  else
                     baud_counter_reg = baud_counter + 1;
            end
         STOP:
            begin
               tx_next = 1'b1;
               if (tick)
                  if (baud_counter==(COUNT_TICKS-1))
                     begin
                        next_state = IDLE;
                        tx_done = 1'b1;
                     end
                  else
                     baud_counter_reg = baud_counter + 1;
            end
      endcase
   end
   // output
   assign tx = tx_reg;

endmodule