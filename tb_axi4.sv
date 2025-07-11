// Testbench for AXI4 Master FSM with memory tracking, verification, and response handling

`timescale 1ns / 1ps

module axi4_master_tb;
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 64;
    parameter BURST_LEN  = 8;

    // DUT Signals
    reg                       clk;
    reg                       rst_n;
    reg                       start;
    reg  [ADDR_WIDTH-1:0]     addr;
    reg  [1:0]                burst_type;
    reg  [7:0]                burst_len;
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
    reg  [1:0]                bresp;
    wire                      bready;

    wire                      arvalid;
    reg                       arready;
    wire [ADDR_WIDTH-1:0]     araddr;
    wire [7:0]                arlen;
    wire [2:0]                arsize;
    wire [1:0]                arburst;

    reg                       rvalid;
    reg  [1:0]                rresp;
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
        .clk(clk), .rst_n(rst_n), .start(start), .addr(addr), .burst_type(burst_type), .burst_len(burst_len), .rw(rw),
        .awvalid(awvalid), .awready(awready), .awaddr(awaddr), .awlen(awlen), .awsize(awsize), .awburst(awburst),
        .wvalid(wvalid), .wready(wready), .wdata(wdata), .wlast(wlast),
        .bvalid(bvalid), .bready(bready), .bresp(bresp),
        .arvalid(arvalid), .arready(arready), .araddr(araddr), .arlen(arlen), .arsize(arsize), .arburst(arburst),
        .rvalid(rvalid), .rready(rready), .rdata(rdata), .rlast(rlast), .rresp(rresp)
    );

    task do_write(input [ADDR_WIDTH-1:0] a, input [1:0] burst, input [7:0] len);
        begin
            @(negedge clk);
            addr <= a;
            burst_type <= burst;
            burst_len <= len;
            rw <= 0;
            start <= 1;
            @(negedge clk); start <= 0;
        end
    endtask

    task do_read(input [ADDR_WIDTH-1:0] a, input [1:0] burst, input [7:0] len);
        begin
            @(negedge clk);
            addr <= a;
            burst_type <= burst;
            burst_len <= len;
            rw <= 1;
            start <= 1;
            @(negedge clk); start <= 0;
        end
    endtask

    initial begin
        clk = 0; rst_n = 0;
        start = 0; addr = 0; rw = 0; burst_type = 0; burst_len = 8;

        awready = 1; wready = 1; bvalid = 0; bresp = 2'b00;
        arready = 1; rvalid = 0; rresp = 2'b00; rdata = 0; rlast = 0;

        #20 rst_n = 1;
        #10;

        // Write burst with SLVERR on first try to test retry
        do_write(32'h0000_1000, 2'b01, 8);
        base_idx = 32'h0000_1000 >> $clog2(DATA_WIDTH / 8);
        for (beat = 0; beat < 8; beat = beat + 1) begin
            @(negedge clk);
            if (wvalid && wready) begin
                mem[base_idx + beat] = wdata;
                $display("Write @ %0d = %h", base_idx + beat, wdata);
            end
        end
        #5 bvalid = 1; bresp = 2'b10; // SLVERR
        @(negedge clk);
        bvalid = 0;
        #20;
        // Simulate retry success
        #5 bvalid = 1; bresp = 2'b00;
        @(negedge clk);
        bvalid = 0;

        // Read burst with SLVERR first to trigger retry
        do_read(32'h0000_1000, 2'b01, 8);
        base_idx = 32'h0000_1000 >> $clog2(DATA_WIDTH / 8);
        for (beat = 0; beat < 8; beat = beat + 1) begin
            @(negedge clk);
            rdata = mem[base_idx + beat];
            rvalid = 1; rresp = (beat == 7) ? 2'b10 : 2'b00; // SLVERR on last beat
            rlast = (beat == 7);
            @(negedge clk);
            if (rvalid && rready) begin
                if (rresp != 2'b00)
                    $error("Read RRESP error at beat %0d: %b", beat, rresp);
                if (rdata !== mem[base_idx + beat])
                    $error("Mismatch at beat %0d: Expected %h, Got %h", beat, mem[base_idx + beat], rdata);
                else
                    $display("Read matched at beat %0d: %h", beat, rdata);
            end
        end
        rvalid = 0; rlast = 0; rresp = 2'b00;

        #50;
        $finish;
    end
endmodule
