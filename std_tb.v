`timescale 1ns/1ps

module tb_convolution;

  parameter DATA_WIDTH = 16;
  parameter N_INPUTS = 64;   // number of input samples
  parameter N_TAPS   = 16;   // number of filter coefficients

  reg clk = 0;
  reg rst = 1;
  reg start = 0;
  reg signed [DATA_WIDTH-1:0] input_data [0:N_INPUTS-1];
  reg signed [DATA_WIDTH-1:0] coeffs     [0:N_TAPS-1];
  wire signed [DATA_WIDTH-1:0] y;
  integer i, j;

  // File handles
  integer input_file, coeff_file, output_file;
  integer status;

  // For feeding input and collecting output
  reg signed [DATA_WIDTH-1:0] x_reg;
  reg signed [DATA_WIDTH-1:0] h_reg [0:N_TAPS-1];

  // DUT interface
  reg valid_in = 0;
  wire valid_out;

  // Output from DUT
  wire signed [DATA_WIDTH-1:0] y_out;

  // Clock generation
  always #5 clk = ~clk;

  // DUT instance (you must implement this module)
  convolution #(
    .DATA_WIDTH(DATA_WIDTH),
    .N_TAPS(N_TAPS)
  ) dut (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .x_in(x_reg),
    .h_in(h_reg),
    .valid_out(valid_out),
    .y_out(y_out)
  );

  initial begin
    // Read input and coefficients
    $readmemh("input.txt", input_data);
    $readmemh("coeff.txt", coeffs);

    // Open output file
    output_file = $fopen("output.txt", "w");
    if (!output_file) begin
      $display("ERROR: Could not open output file.");
      $finish;
    end

    // Reset
    #10 rst = 0;

    // Copy coefficients to h_reg
    for (j = 0; j < N_TAPS; j = j + 1)
      h_reg[j] = coeffs[j];

    // Feed input samples
    for (i = 0; i < N_INPUTS; i = i + 1) begin
      @(posedge clk);
      x_reg = input_data[i];
      valid_in = 1;
    end

    // Stop feeding
    @(posedge clk);
    valid_in = 0;

    // Capture output
    forever begin
      @(posedge clk);
      if (valid_out) begin
        $fdisplay(output_file, "%h", y_out);
      end
    end
  end

endmodule
