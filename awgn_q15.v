module awgn_q15_pipelined (
    input clk,
    input rst,
    input signed [15:0] sigma_q15,         // Scaling factor (standard deviation)
    output reg signed [15:0] noise_q15     // Q1.15 output noise
);
    wire signed [15:0] gaussian_q15;
    reg signed [31:0] product_q30;

    // Pipeline registers
    reg signed [15:0] gaussian_stage;
    reg signed [15:0] sigma_stage;

    // Gaussian CLT approx stage
    gaussian_clt_pipelined gen (
        .clk(clk),
        .rst(rst),
        .centered_q15(gaussian_q15)
    );

    // Stage 1: Register Gaussian + Sigma
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gaussian_stage <= 0;
            sigma_stage <= 0;
        end else begin
            gaussian_stage <= gaussian_q15;
            sigma_stage <= sigma_q15;
        end
    end

    // Stage 2: Multiply (Q1.15 * Q1.15 = Q2.30)
    always @(posedge clk or posedge rst) begin
        if (rst)
            product_q30 <= 0;
        else
            product_q30 <= gaussian_stage * sigma_stage;
    end

    // Stage 3: Normalize to Q1.15
    always @(posedge clk or posedge rst) begin
        if (rst)
            noise_q15 <= 0;
        else
            noise_q15 <= product_q30[30:15]; // Truncate middle bits
    end
endmodule
