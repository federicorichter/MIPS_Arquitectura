module adder#(
    parameter SIZE = 32
)(
    input [SIZE-1:0] i_a, i_b,
    output [SIZE-1:0] o_result,
    input i_stall
);
    assign o_result = i_stall ? 32'b0 : (i_a + $signed(i_b));
    
endmodule