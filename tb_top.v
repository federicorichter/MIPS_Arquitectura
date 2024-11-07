module tb_top;

    reg clk, rst, i_stall;

    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // Periodo de 20 ns, frecuencia de 50 MHz
    end

    initial begin
        rst = 1;
        i_stall = 0;
        #100;
        rst = 0;
        #500;
        $finish;
    end

    mips #(
        .SIZE(32)
    ) 
    uut(
        .clk(clk),
        .rst(rst),
        .i_stall(i_stall)
    );
    

endmodule