module gaussian_clt_pipelined (
    input clk,
    input rst,
    output reg signed [15:0] centered_q15  // Output centered and scaled for Q1.15
);
    reg [7:0] buffer[0:11];
    wire [7:0] rand_out;
    reg [15:0] sum;
    integer i;

    lfsr_8bit_pipelined lfsr(.clk(clk), .rst(rst), .out(rand_out));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 12; i = i + 1) buffer[i] <= 0;
            sum <= 0;
            centered_q15 <= 0;
        end else begin
            for (i = 11; i > 0; i = i - 1)
                buffer[i] <= buffer[i - 1];
            buffer[0] <= rand_out;

            sum = 0;
            for (i = 0; i < 12; i = i + 1)
                sum = sum + buffer[i];

            // Center and shift for Q1.15
            centered_q15 <= ($signed({1'b0, sum}) - 16'sd1536) <<< 4;
        end
    end
endmodule
