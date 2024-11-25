module baudrate_generator #(
    parameter BAUD_RATE = 9600,
    parameter CLK_FREQ = 50000000
)(
    input wire clk,
    input wire reset,
    output reg tick
);

    localparam integer CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer TICK_COUNTER_WIDTH = $clog2(CYCLES_PER_BIT);

    reg [TICK_COUNTER_WIDTH-1:0] tick_counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tick_counter <= 0;
            tick <= 0;
        end else begin
            if (tick_counter == CYCLES_PER_BIT - 1) begin
                tick_counter <= 0;
                tick <= 1;
            end else begin
                tick_counter <= tick_counter + 1;
                tick <= 0;
            end
        end
    end

endmodule