// Top-level wrapper that connects FIFO, resampler core, and output

module resampler_top #(
    parameter DATA_WIDTH = 16,
    parameter TAP_COUNT  = 9,
    parameter FIFO_DEPTH = 1024
)(
    input  logic clk,
    input  logic rst_n,

    // Control
    input  logic signed [31:0] ppm_value,
    input  logic [DATA_WIDTH-1:0] coeffs [TAP_COUNT],

    // External data interface
    input  logic                  stream_in_valid,
    input  logic [DATA_WIDTH-1:0] stream_in_data,
    output logic                  stream_in_ready,

    output logic                  stream_out_valid,
    output logic [DATA_WIDTH-1:0] stream_out_data
);

    // === FIFO Interfaces ===
    logic [DATA_WIDTH-1:0] fifo_in_data;
    logic fifo_in_wr_en, fifo_in_full;

    logic [DATA_WIDTH-1:0] fifo_out_data;
    logic fifo_out_rd_en, fifo_out_empty;

    // === Instantiate Input FIFO ===
    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) input_fifo (
        .clk(clk), .rst_n(rst_n),
        .wr_en(stream_in_valid),
        .din(stream_in_data),
        .full(fifo_in_full),
        .rd_en(fifo_out_rd_en),
        .dout(fifo_out_data),
        .empty(fifo_out_empty)
    );

    assign stream_in_ready = !fifo_in_full;

    // === Instantiate Output FIFO (optional) ===
    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) output_fifo (
        .clk(clk), .rst_n(rst_n),
        .wr_en(stream_out_valid_internal),
        .din(stream_out_data_internal),
        .full(),
        .rd_en(1'b1), // always ready
        .dout(stream_out_data),
        .empty()
    );

    assign stream_out_valid = 1'b1;

    // === Resampler Core ===
    logic [DATA_WIDTH-1:0] stream_out_data_internal;
    logic stream_out_valid_internal;

    resampler_q15 #(
        .TAP_COUNT(TAP_COUNT),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_resampler (
        .clk(clk),
        .rst_n(rst_n),
        .ppm_in(ppm_value),
        .coeffs(coeffs),
        .data_in(fifo_out_data),
        .data_in_valid(!fifo_out_empty),
        .data_in_ready(fifo_out_rd_en),
        .data_out(stream_out_data_internal),
        .data_out_valid(stream_out_valid_internal)
    );

endmodule
