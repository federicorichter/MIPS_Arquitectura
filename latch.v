
module latch#(
        parameter BUS_DATA = 8
    )(
        input                       clk,
        input                       rst,
        input                       i_enable,
      
        input   [BUS_DATA - 1 : 0]  i_data,
        output  [BUS_DATA - 1 : 0]  o_data     
    );
    
    reg [BUS_DATA - 1 : 0]  data_reg, data_next;     
    
    /*always @(posedge clk or posedge rst)
    begin
        if (rst) begin   
            data_reg <= 0;
        end
        else begin
            data_reg <= data_next;      
        end
    end
    
    always@(*)
    begin
        data_next   =  data_reg;
        if(i_enable)
            data_next   =   i_data;
    end
    */

    always @(posedge clk or posedge rst)
begin
    if (rst) begin
        data_reg <= 0;
    end
    else if (i_enable) begin
        data_reg <= i_data;
    end
end

    assign o_data = data_reg;

endmodule