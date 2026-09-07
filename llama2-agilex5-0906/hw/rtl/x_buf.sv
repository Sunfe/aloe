// x_buf: CPU 写 (32bit), PE 读 (256bit). 8 个独立 bank 按 word_addr[2:0] 交织,
// 这样 Quartus 能稳定推断出简单双口 RAM.
module x_buf
  import matvec_pkg::*;
(
  input  logic                        clk,
  // Avalon-MM slave, 字地址, 只写
  input  logic [$clog2(XBUF_DEP)-1:0] av_address,
  input  logic                        av_write,
  input  logic [31:0]                 av_writedata,
  // PE 读口
  input  logic                        rd_en,
  input  logic [XROW_AW-1:0]          rd_addr,
  output logic [AXI_DW-1:0]           rd_data
);
  localparam int BANK_DEP = XBUF_DEP / LANES;

  for (genvar b = 0; b < LANES; b++) begin : g_bank
    logic [31:0] mem [BANK_DEP];
    always_ff @(posedge clk) begin
      if (av_write && av_address[LANE_L-1:0] == b)
        mem[av_address[LANE_L +: XROW_AW]] <= av_writedata;
      if (rd_en)
        rd_data[32*b +: 32] <= mem[rd_addr];
    end
  end
endmodule
