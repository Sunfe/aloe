`timescale 1ns/1ps
module tb_pe_array;
  import matvec_pkg::*;
  localparam int N = 768, D = 768;

  logic clk = 0, rst_n = 0;  always #5 clk = ~clk;

  logic start; logic [31:0] n_rows = N, d_cols = D;
  logic [AXI_DW-1:0] w_tdata; logic w_tvalid, w_tready;
  logic x_rd_en; logic [XROW_AW-1:0] x_rd_addr; logic [AXI_DW-1:0] x_rd_data;
  logic y_we; logic [ROW_W-1:0] y_addr; logic [31:0] y_data; logic busy, done;

  // x_buf 行为模型 (同步读, en 门控)
  logic [31:0] xmem [XBUF_DEP];
  always_ff @(posedge clk) if (x_rd_en)
    for (int i = 0; i < LANES; i++) x_rd_data[32*i +: 32] <= xmem[x_rd_addr*LANES + i];

  pe_array dut (.*);

  logic [AXI_DW-1:0] wmem [N*D/LANES];
  logic [31:0] yref [N], yout [N];
  int beat, errs = 0;

  initial begin
    $readmemh("golden/w.hex", wmem);
    $readmemh("golden/x.hex", xmem);
    $readmemh("golden/y_ref.hex", yref);
    start = 0; w_tvalid = 0; beat = 0;
    repeat (3) @(posedge clk); rst_n = 1;
    @(posedge clk); start = 1; @(posedge clk); start = 0;

    // 驱动权重流, 随机插入气泡, 检验 en 门控对齐是否正确
    while (beat < N*D/LANES) begin
      @(negedge clk);
      w_tvalid = ($urandom_range(0, 3) != 0);
      w_tdata  = wmem[beat];
      @(posedge clk);
      if (w_tvalid && w_tready) beat++;
    end
    @(negedge clk); w_tvalid = 0;
    wait (done); repeat (5) @(posedge clk);

    for (int r = 0; r < N; r++) begin
      shortreal a = $bitstoshortreal(yout[r]), b = $bitstoshortreal(yref[r]);
      if (($abs(a-b) > 1e-4 * ($abs(b) + 1e-3))) begin
        errs++; if (errs < 10) $display("row %0d: got %f ref %f", r, a, b);
      end
    end
    $display(errs == 0 ? "PASS" : "FAIL (%0d errors)", errs);
    $finish;
  end

  always_ff @(posedge clk) if (y_we) yout[y_addr] <= y_data;
endmodule
