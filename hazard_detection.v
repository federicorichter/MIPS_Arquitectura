module hazard_detection #(
    parameter SIZE_REG_DIR = 5,
    parameter SIZE = 32
)
(
    input [SIZE_REG_DIR-1:0] i_rs_if_id,
    input [SIZE_REG_DIR-1:0] i_rt_if_id,
    input [SIZE_REG_DIR-1:0] i_rt_id_ex,
    input i_mem_read_id_ex,
    input i_branch,
    input i_jump_brch,
    output  o_hazard,
    output  o_flush
);

    assign o_hazard = (i_mem_read_id_ex && ((i_rs_if_id == i_rt_id_ex) || (i_rt_if_id == i_rt_id_ex))) ? 1 : 0;  
    assign o_flush = (i_jump_brch || i_branch) ? 1 : 0;

    //assign o_flush = 

endmodule