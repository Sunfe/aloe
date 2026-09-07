// y_buf: PE 写, CPU 读 (Avalon 固定读延迟 1)
module y_buf
  import matvec_pkg::*;
(
  input  logic                        clk,
  input  logic [$clog2(YBUF_DEP)-1:0] av_address,
  input  logic                        av_read,
  output logic [31:0]                 av_readdata,
  input  logic                        we,
  input  logic [ROW_W-1:0]            waddr,
  input  logic [31:0]                 wdata
);
  logic [31:0] mem [YBUF_DEP];
  always_ff @(posedge clk) begin
    if (we) mem[waddr[$clog2(YBUF_DEP)-1:0]] <= wdata;
    av_readdata <= mem[av_address];
  end
endmodule
