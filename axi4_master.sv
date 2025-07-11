// AXI4 Master FSM with INCR/WRAP support and outstanding write/read control and retry logic

module axi4_master_fsm #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64,
    parameter BURST_LEN  = 8,
    parameter MAX_OUTSTANDING_W = 4,
    parameter MAX_OUTSTANDING_R = 4,
    parameter RETRY_LIMIT = 3
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Control
    input  wire                     start,
    input  wire [ADDR_WIDTH-1:0]   addr,
    input  wire [1:0]              burst_type, // 2'b01: INCR, 2'b10: WRAP
    input  wire                    rw,         // 1: Read, 0: Write

    // AXI Write Address Channel
    output reg                     awvalid,
    input  wire                    awready,
    output reg [ADDR_WIDTH-1:0]    awaddr,
    output reg [7:0]               awlen,
    output reg [2:0]               awsize,
    output reg [1:0]               awburst,

    // AXI Write Data Channel
    output reg                     wvalid,
    input  wire                    wready,
    output reg [DATA_WIDTH-1:0]    wdata,
    output reg                     wlast,

    // AXI Write Response Channel
    input  wire                    bvalid,
    output reg                     bready,
    input  wire [1:0]              bresp,

    // AXI Read Address Channel
    output reg                     arvalid,
    input  wire                    arready,
    output reg [ADDR_WIDTH-1:0]    araddr,
    output reg [7:0]               arlen,
    output reg [2:0]               arsize,
    output reg [1:0]               arburst,

    // AXI Read Data Channel
    input  wire                    rvalid,
    output reg                     rready,
    input  wire [DATA_WIDTH-1:0]   rdata,
    input  wire                    rlast,
    input  wire [1:0]              rresp
);

    typedef enum logic [2:0] {
        IDLE,
        WRITE_ADDR,
        WRITE_DATA,
        WRITE_RESP,
        READ_ADDR,
        READ_DATA
    } state_t;

    state_t state, next_state;

    reg [$clog2(MAX_OUTSTANDING_W+1)-1:0] w_outstanding;
    reg [$clog2(MAX_OUTSTANDING_R+1)-1:0] r_outstanding;
    reg [7:0] burst_cnt;

    reg [1:0] write_retry_count;
    reg [1:0] read_retry_count;

    localparam integer BEAT_SIZE_BYTES = DATA_WIDTH / 8;
    localparam integer WRAP_BOUNDARY   = BURST_LEN * BEAT_SIZE_BYTES;
    localparam [ADDR_WIDTH-1:0] WRAP_ADDR_MASK = ~(WRAP_BOUNDARY - 1);

    wire [ADDR_WIDTH-1:0] aligned_wrap_addr = addr & WRAP_ADDR_MASK;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = rw ? READ_ADDR : WRITE_ADDR;
            end
            WRITE_ADDR: begin
                if (awready && w_outstanding < MAX_OUTSTANDING_W)
                    next_state = WRITE_DATA;
                else if (w_outstanding >= MAX_OUTSTANDING_W)
                    next_state = WRITE_RESP;
            end
            WRITE_DATA: begin
                if (wvalid && wready && wlast)
                    next_state = WRITE_RESP;
            end
            WRITE_RESP: begin
                if (bvalid) begin
                    if (bresp != 2'b00 && write_retry_count < RETRY_LIMIT)
                        next_state = WRITE_ADDR;
                    else
                        next_state = IDLE;
                end
            end
            READ_ADDR: begin
                if (arready && r_outstanding < MAX_OUTSTANDING_R)
                    next_state = READ_DATA;
            end
            READ_DATA: begin
                if (rvalid && rlast) begin
                    if (rresp != 2'b00 && read_retry_count < RETRY_LIMIT)
                        next_state = READ_ADDR;
                    else
                        next_state = IDLE;
                end
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            w_outstanding <= 0;
        else begin
            if (awvalid && awready)
                w_outstanding <= w_outstanding + 1;
            if (bvalid && bready)
                w_outstanding <= w_outstanding - 1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            r_outstanding <= 0;
        else begin
            if (arvalid && arready)
                r_outstanding <= r_outstanding + 1;
            if (rvalid && rready && rlast)
                r_outstanding <= r_outstanding - 1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            burst_cnt <= 0;
        else if ((state == WRITE_DATA) && (wvalid && wready))
            burst_cnt <= burst_cnt + 1;
        else if ((state == READ_DATA) && (rvalid && rready))
            burst_cnt <= burst_cnt + 1;
        else if (state == IDLE)
            burst_cnt <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            write_retry_count <= 0;
        else if (state == WRITE_RESP && bvalid) begin
            if (bresp != 2'b00 && write_retry_count < RETRY_LIMIT)
                write_retry_count <= write_retry_count + 1;
            else if (bresp == 2'b00)
                write_retry_count <= 0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            read_retry_count <= 0;
        else if (state == READ_DATA && rvalid && rlast) begin
            if (rresp != 2'b00 && read_retry_count < RETRY_LIMIT)
                read_retry_count <= read_retry_count + 1;
            else if (rresp == 2'b00)
                read_retry_count <= 0;
        end
    end

    always @(*) begin
        awvalid = 0;
        awaddr  = (burst_type == 2'b10) ? aligned_wrap_addr : addr;
        awlen   = BURST_LEN - 1;
        awsize  = $clog2(DATA_WIDTH / 8);
        awburst = burst_type;

        wvalid = 0;
        wdata  = {DATA_WIDTH{1'b1}};
        wlast  = (burst_cnt == BURST_LEN - 1);

        bready = 1;

        arvalid = 0;
        araddr  = (burst_type == 2'b10) ? aligned_wrap_addr : addr;
        arlen   = BURST_LEN - 1;
        arsize  = $clog2(DATA_WIDTH / 8);
        arburst = burst_type;

        rready  = 1;

        case (state)
            WRITE_ADDR: awvalid = (w_outstanding < MAX_OUTSTANDING_W);
            WRITE_DATA: wvalid  = 1;
            READ_ADDR:  arvalid = (r_outstanding < MAX_OUTSTANDING_R);
        endcase
    end

endmodule
