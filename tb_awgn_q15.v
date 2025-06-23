module tb_awgn_q15;
    reg clk = 0, rst = 1;
    wire signed [15:0] noise_q15;
    reg signed [15:0] sigma;

    awgn_q15_pipelined uut (
        .clk(clk),
        .rst(rst),
        .sigma_q15(sigma),
        .noise_q15(noise_q15)
    );

    always #5 clk = ~clk;

    initial begin
        sigma = 16'h199A;  // 0.2 in Q1.15
        #20 rst = 0;
        #2000 $finish;
    end
endmodule
