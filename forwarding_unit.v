module forwarding_unit#(
        parameter   TAM_BITS_FORWARD  =   2,
        parameter   TAM_DIREC_REG     =   5  
)(
    input   [TAM_DIREC_REG-1 : 0]       i_rs_id_ex, //if_id
    input   [TAM_DIREC_REG-1 : 0]       i_rt_id_ex, //if_id
    input   [TAM_DIREC_REG-1 : 0]       i_rd_id_ex,
    input   [TAM_DIREC_REG-1 : 0]       i_rd_ex_mem,
    input   [TAM_DIREC_REG-1 : 0]       i_rd_mem_wb,
    input                               i_reg_wr_id_ex,
    input                               i_reg_wr_ex_mem,
    input                               i_reg_wr_mem_wb,
    output  reg [TAM_BITS_FORWARD-1 : 0]    o_forward_a,
    output  reg [TAM_BITS_FORWARD-1 : 0]    o_forward_b
);

    always @(*) begin
        // Inicializar las señales de reenvío a 00 (sin reenvío)
        o_forward_a = 2'b00;
        o_forward_b = 2'b00;

        // MEM hazard
        if (i_reg_wr_ex_mem && (i_rd_ex_mem != 0) && (i_rd_ex_mem == i_rs_id_ex)) begin
            o_forward_a = 2'b10; // Reenvío desde la etapa EX/MEM
        end
        if (i_reg_wr_ex_mem && (i_rd_ex_mem != 0) && (i_rd_ex_mem == i_rt_id_ex)) begin
            o_forward_b = 2'b10; // Reenvío desde la etapa EX/MEM
        end

        // WB hazard
        if (i_reg_wr_mem_wb && (i_rd_mem_wb != 0) && (i_rd_mem_wb == i_rs_id_ex) && (i_rd_ex_mem != i_rs_id_ex)) begin
            o_forward_a = 2'b01; // Reenvío desde la etapa MEM/WB
        end
        if (i_reg_wr_mem_wb && (i_rd_mem_wb != 0) && (i_rd_mem_wb == i_rt_id_ex) && (i_rd_ex_mem != i_rt_id_ex)) begin
            o_forward_b = 2'b01; // Reenvío desde la etapa MEM/WB
        end
        
        // EX hazard
        if(i_reg_wr_id_ex && (i_rd_id_ex != 0) && (i_rd_id_ex == i_rs_id_ex)  && (i_rd_ex_mem != i_rs_id_ex) && (i_rd_mem_wb != i_rs_id_ex))begin
            o_forward_a = 2'b11;
        end
        if(i_reg_wr_id_ex && (i_rd_id_ex != 0) && (i_rd_id_ex == i_rt_id_ex)  && (i_rd_ex_mem != i_rt_id_ex) && (i_rd_mem_wb != i_rt_id_ex))begin
            o_forward_b = 2'b11;
        end
    end
endmodule