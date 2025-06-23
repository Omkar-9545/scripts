module notch_filter_q15 (
    input logic clk,
    input logic reset,
    input logic signed [15:0] x_in,     // Q1.15 input
    output logic signed [15:0] y_out,   // Q1.15 output
    input logic signed [15:0] b0,
    input logic signed [15:0] b1,
    input logic signed [15:0] b2,
    input logic signed [15:0] a1,
    input logic signed [15:0] a2
);

    // Internal delay registers
    logic signed [31:0] w1, w2;
    logic signed [31:0] w0;
    logic signed [31:0] fb, ff;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            w1 <= 0;
            w2 <= 0;
            y_out <= 0;
        end else begin
            // Feedback: w[n] = x[n] - a1*w1 - a2*w2
            fb = x_in <<< 15; // convert to Q2.30
            fb = fb - ((a1 * w1) >>> 15);
            fb = fb - ((a2 * w2) >>> 15);
            w0 = fb;

            // Feedforward: y[n] = b0*w0 + b1*w1 + b2*w2
            ff = (b0 * w0) >>> 15;
            ff = ff + ((b1 * w1) >>> 15);
            ff = ff + ((b2 * w2) >>> 15);

            // Update state
            w2 <= w1;
            w1 <= w0;

            // Output truncate to Q1.15
            y_out <= ff[30:15];  // take middle 16 bits
        end
    end

endmodule
