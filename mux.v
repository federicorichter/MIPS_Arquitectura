module mux#(
        parameter BITS_ENABLES = 2,
        parameter BUS_SIZE = 8
    )(
        input   [BITS_ENABLES - 1 : 0] i_en,
        input   [2**BITS_ENABLES*BUS_SIZE - 1 : 0] i_data,
        output  [BUS_SIZE - 1 : 0] o_data 
    );
         
    assign o_data = i_data>>BUS_SIZE*i_en;      


endmodule