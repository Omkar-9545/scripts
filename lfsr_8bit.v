module lfsr_8bit_pipelined (
    input clk,
    input rst,
    output reg [7:0] out
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            out <= 8'hA5;
        else
            out <= {out[6:0], out[7] ^ out[5] ^ out[4] ^ out[3]};
    end
endmodule
