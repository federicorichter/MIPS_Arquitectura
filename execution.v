module execution#(
    parameter SIZE = 32,
    parameter OP_SIZE = 6
)(

);

    alu alu_inst #(
        .DATA_WIDTH(SIZE),
        .MODE_WIDTH(OP_SIZE)
    )(  
        .i_A(),
        .i_B(),
        .i_mode(),
        .o_result()
    );

endmodule