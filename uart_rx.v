module uart_rx #(
    parameter N = 8,  // Number of data bits
    parameter M = 1,  // Number of stop bits
    parameter PARITY_EN = 0,  // Enable parity bit (0: disable, 1: enable)
    parameter BAUD_RATE = 9600,  // Baud rate
    parameter CLK_FREQ = 30000000,  // Clock frequency
    parameter COUNT_TICKS = 16
)(
    input wire tick,
    input wire reset,
    input wire clk,
    input wire rx,
    output wire [N-1:0] data_out,
    output wire valid,
    output wire [2:0]state_leds,
    output wire started
);

    reg valid_reg;
    reg [N-1:0] received_byte, received_byte_next;
    reg started_reg = 0;

    localparam integer CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam integer baud_counter_WIDTH = $clog2(CYCLES_PER_BIT);

    localparam [2:0] IDLE = 000,
                    START = 001,
                    DATA = 010,
                    PARITY = 011,
                    STOP = 100;
    


    reg[2:0] state = IDLE;
    reg[2:0] next_state;

    // Shift register
    //reg [N-1:0] shift_reg;
    reg [baud_counter_WIDTH-1:0] baud_counter, baud_counter_reg;

    integer bit_counter, bit_counter_reg;

    // State machine
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            baud_counter <= 0;
            bit_counter <= 0;
            received_byte <= {N,0};
        end else if(clk) begin
            state <= next_state;
            baud_counter <= baud_counter_reg;
            bit_counter <= bit_counter_reg;
            received_byte <= received_byte_next;
        end
    end

    always @(*) begin
    // Default assignments
    next_state          = state;
    valid_reg           = 1'b0; // Default to not done
    baud_counter_reg = baud_counter;
    bit_counter_reg = bit_counter;
    received_byte_next  = received_byte;

    // State machine for UART reception
    case (state)
        IDLE: begin
            if (~rx) begin
                // Transition to START state when the start bit (low) is detected
                next_state  = START;
                baud_counter_reg      = 0; // Reset bit timing counter
            end
        end
        
        START: begin
            if (tick) begin
                if (baud_counter == 7) begin
                    // Transition to DATA state after detecting start bit duration
                    next_state  = DATA;
                    baud_counter_reg      = 0; // Reset bit timing counter
                    bit_counter_reg      = 0; // Reset data bit index
                end
                else begin
                    baud_counter_reg      = baud_counter + 1; // Increment bit timing counter
                end
            end
        end

        DATA: begin
            if (tick) begin
                if (baud_counter == 15) begin
                    // Read current data bit into received_byte
                    baud_counter_reg = 0; // Reset bit timing counter
                    received_byte_next = {rx, received_byte[N-1:1]}; // Shift in new bit
                    if (bit_counter == (N - 1)) begin
                        // If all data bits have been received, transition to STOP state
                        next_state = STOP;
                    end
                    else begin
                        bit_counter_reg = bit_counter + 1; // Increment data bit index
                    end
                end
                else begin
                    baud_counter_reg = baud_counter + 1; // Increment bit timing counter
                end
            end
        end

        STOP: begin
            if (tick) begin
                if (baud_counter == (15)) begin
                    started_reg = 1;
                    // Transition back to IDLE state after receiving the stop bit
                    next_state = IDLE;
                    if (rx) begin
                        valid_reg = 1'b1; // Indicate that reception is complete if stop bit is valid
                    end
                end
                else begin
                    baud_counter_reg = baud_counter + 1; // Increment bit timing counter
                end
            end
        end

        default: begin
            next_state = IDLE; // Default state is IDLE
        end
    endcase
end

assign state_leds = state;
assign data_out = received_byte;
assign valid = valid_reg;
assign started = started_reg;

endmodule