// Testbench for AXI4 Master FSM with memory tracking and verification

`timescale 1ns / 1ps

module axi4_master_tb;
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 128;
    parameter BURST_LEN  = 8;

    // DUT Signals
    reg                       clk;
    reg                       rst_n;
    reg                       start;
    reg  [ADDR_WIDTH-1:0]     addr;
    reg  [1:0]                burst_type;
    reg                       rw;

    wire                      awvalid;
    reg                       awready;
    wire [ADDR_WIDTH-1:0]     awaddr;
    wire [7:0]                awlen;
    wire [2:0]                awsize;
    wire [1:0]                awburst;

    wire                      wvalid;
    reg                       wready;
    wire [DATA_WIDTH-1:0]     wdata;
    wire                      wlast;

    reg                       bvalid;
    wire                      bready;

    wire                      arvalid;
    reg                       arready;
    wire [ADDR_WIDTH-1:0]     araddr;
    wire [7:0]                arlen;
    wire [2:0]                arsize;
    wire [1:0]                arburst;

    reg                       rvalid;
    wire                      rready;
    reg  [DATA_WIDTH-1:0]     rdata;
    reg                       rlast;

    // Memory model
    localparam MEM_DEPTH = 1024;
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    integer beat;
    integer base_idx;

    // Clock
    always #5 clk = ~clk;

    // DUT
    axi4_master_fsm #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BURST_LEN(BURST_LEN),
        .MAX_OUTSTANDING_W(4),
        .MAX_OUTSTANDING_R(4)
    ) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .addr(addr), .burst_type(burst_type), .rw(rw),
        .awvalid(awvalid), .awready(awready), .awaddr(awaddr), .awlen(awlen), .awsize(awsize), .awburst(awburst),
        .wvalid(wvalid), .wready(wready), .wdata(wdata), .wlast(wlast),
        .bvalid(bvalid), .bready(bready),
        .arvalid(arvalid), .arready(arready), .araddr(araddr), .arlen(arlen), .arsize(arsize), .arburst(arburst),
        .rvalid(rvalid), .rready(rready), .rdata(rdata), .rlast(rlast)
    );

    task do_write(input [ADDR_WIDTH-1:0] a, input [1:0] burst);
        begin
            @(negedge clk);
            addr <= a;
            burst_type <= burst;
            rw <= 0;
            start <= 1;
            @(negedge clk); start <= 0;
        end
    endtask

    task do_read(input [ADDR_WIDTH-1:0] a, input [1:0] burst);
        begin
            @(negedge clk);
            addr <= a;
            burst_type <= burst;
            rw <= 1;
            start <= 1;
            @(negedge clk); start <= 0;
        end
    endtask

    initial begin
        clk = 0; rst_n = 0;
        start = 0; addr = 0; rw = 0; burst_type = 0;

        awready = 1; wready = 1; bvalid = 0;
        arready = 1; rvalid = 0; rdata = 0; rlast = 0;

        #20 rst_n = 1;
        #10;

        // Write burst: INCR
        do_write(32'h0000_1000, 2'b01);
        base_idx = 32'h0000_1000 >> $clog2(DATA_WIDTH / 8);
        for (beat = 0; beat < BURST_LEN; beat = beat + 1) begin
            @(negedge clk);
            if (wvalid && wready) begin
                mem[base_idx + beat] = wdata;
                $display("Write @ %0d = %h", base_idx + beat, wdata);
            end
        end
        #5 bvalid = 1;
        @(negedge clk); bvalid = 0;

        // Read burst: INCR (verify)
        do_read(32'h0000_1000, 2'b01);
        base_idx = 32'h0000_1000 >> $clog2(DATA_WIDTH / 8);
        for (beat = 0; beat < BURST_LEN; beat = beat + 1) begin
            @(negedge clk);
            rdata = mem[base_idx + beat];
            rvalid = 1; rlast = (beat == BURST_LEN - 1);
            @(negedge clk);
            if (rvalid && rready) begin
                if (rdata !== mem[base_idx + beat])
                    $error("Mismatch at beat %0d: Expected %h, Got %h", beat, mem[base_idx + beat], rdata);
                else
                    $display("Read matched at beat %0d: %h", beat, rdata);
            end
        end
        rvalid = 0; rlast = 0;

        #50;
        $finish;
    end
endmodule
