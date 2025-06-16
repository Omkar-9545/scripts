//Add 2^14 (i.e. half of the shift base) before shifting, to round to nearest

module resampler_q15 #(
    parameter TAP_COUNT = 9,
    parameter DATA_WIDTH = 16
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // Control signals
    input  logic signed [31:0]    ppm_in,       // signed PPM input
    input  logic [DATA_WIDTH-1:0] coeffs [TAP_COUNT], // Q1.15 filter coefficients

    // FIFO interface
    input  logic [DATA_WIDTH-1:0] data_in,
    input  logic                  data_in_valid,
    output logic                  data_in_ready,

    output logic [DATA_WIDTH-1:0] data_out,
    output logic                  data_out_valid
);

    // Internal signals
    logic signed [31:0] ppm_accum;
    logic overflow;

    logic signed [DATA_WIDTH-1:0] shift_reg [TAP_COUNT];

    logic signed [2*DATA_WIDTH-1:0] products [TAP_COUNT];
    logic signed [31:0] acc_sum;

    // FIFO interface
    assign data_in_ready = 1'b1; // Always accept (backpressure to be added outside)

    // Shift register update gated by overflow
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ppm_accum <= 32'sd0;
        end else begin
            ppm_accum <= ppm_accum + ppm_in;
        end
    end

    // Detect signed overflow based on MSB
    assign overflow = (ppm_accum[31] == 1'b0 && ppm_accum[30] == 1'b1) ||
                      (ppm_accum[31] == 1'b1 && ppm_accum[30] == 1'b0);

    // Gated shift register update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < TAP_COUNT; i++) begin
                shift_reg[i] <= '0;
            end
        end else if (overflow && data_in_valid) begin
            shift_reg[0] <= data_in;
            for (int i = 1; i < TAP_COUNT; i++) begin
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end

    // Multiply coefficients with shift register
    always_comb begin
        for (int i = 0; i < TAP_COUNT; i++) begin
            products[i] = $signed(shift_reg[i]) * $signed(coeffs[i]);
        end
    end

    // Accumulate and saturate
    always_comb begin
        acc_sum = 0;
        for (int i = 0; i < TAP_COUNT; i++) begin
            acc_sum += $signed(products[i]) >>> 15; // shift back to Q1.15
        end
    end

    // Output valid only on overflow
    assign data_out       = $signed(acc_sum[DATA_WIDTH-1:0]);
    assign data_out_valid = overflow;

endmodule
