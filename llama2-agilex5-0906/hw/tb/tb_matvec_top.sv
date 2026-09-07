`timescale 1ns/1ps
module tb_matvec_top;
  import matvec_pkg::*;
  localparam int     N = 768, D = 768;          // 改成 32000/768、768/2048 再各跑一次
  localparam longint WBASE = 64'hA000_0000;

  logic clk = 0, rst_n = 0; always #5 clk = ~clk;

  // AXI-Lite
  logic [7:0] s_awaddr, s_araddr; logic [31:0] s_wdata, s_rdata; logic [3:0] s_wstrb; logic [1:0] s_bresp, s_rresp;
  logic s_awvalid, s_awready, s_wvalid, s_wready, s_bvalid, s_bready, s_arvalid, s_arready, s_rvalid, s_rready;
  // Avalon
  logic [18:0] av_address; logic av_write, av_read; logic [31:0] av_writedata, av_readdata;
  // AXI4 master
  wire [3:0] m_awid, m_bid, m_arid, m_rid; wire [63:0] m_awaddr, m_araddr; wire [7:0] m_awlen, m_arlen;
  wire [2:0] m_awsize, m_arsize, m_awprot, m_arprot; wire [1:0] m_awburst, m_arburst, m_bresp, m_rresp;
  wire [3:0] m_awcache, m_arcache; wire [255:0] m_wdata, m_rdata; wire [31:0] m_wstrb;
  wire m_awlock, m_arlock, m_awvalid, m_awready, m_wlast, m_wvalid, m_wready, m_bvalid, m_bready;
  wire m_arvalid, m_arready, m_rlast, m_rvalid, m_rready;
  logic irq;

  matvec_top dut (.*, .s_awprot(3'b000), .s_arprot(3'b000));
  assign m_awready = 1'b1; assign m_wready = 1'b1; assign m_bvalid = 1'b0; assign m_bid = '0; assign m_bresp = '0;

  axi_mem_model #(.BASE(WBASE)) u_mem (
    .clk(clk), .rst_n(rst_n), .arid(m_arid), .araddr(m_araddr), .arlen(m_arlen), .arvalid(m_arvalid), .arready(m_arready),
    .rid(m_rid), .rdata(m_rdata), .rresp(m_rresp), .rlast(m_rlast), .rvalid(m_rvalid), .rready(m_rready));

  // ---------- AXI-Lite 主机任务 ----------
  task axil_wr(input [7:0] a, input [31:0] d);
    @(negedge clk); s_awaddr = a; s_awvalid = 1; s_wdata = d; s_wstrb = 4'hF; s_wvalid = 1; s_bready = 1;
    @(posedge clk); while (!(s_awready && s_wready)) @(posedge clk);
    @(negedge clk); s_awvalid = 0; s_wvalid = 0;
    @(posedge clk); while (!s_bvalid) @(posedge clk);
    @(negedge clk); s_bready = 0;
  endtask
  task axil_rd(input [7:0] a, output [31:0] d);
    @(negedge clk); s_araddr = a; s_arvalid = 1; s_rready = 1;
    @(posedge clk); while (!s_arready) @(posedge clk);
    @(negedge clk); s_arvalid = 0;
    @(posedge clk); while (!s_rvalid) @(posedge clk);
    d = s_rdata;
    @(negedge clk); s_rready = 0;
  endtask
  // ---------- Avalon 主机任务 ----------
  task av_wr(input [18:0] a, input [31:0] d);
    @(negedge clk); av_address = a; av_writedata = d; av_write = 1; @(posedge clk); @(negedge clk); av_write = 0;
  endtask
  task av_rd(input [18:0] a, output [31:0] d);
    @(negedge clk); av_address = a; av_read = 1; @(posedge clk); @(negedge clk); av_read = 0; d = av_readdata;
  endtask

  logic [31:0] xmem [D], yref [N];
  logic [31:0] v, st; int errs = 0, timeout;

  initial begin
    $readmemh("golden/w.hex", u_mem.mem);          // W 放在模型内存起始 = WBASE
    $readmemh("golden/x.hex", xmem);
    $readmemh("golden/y_ref.hex", yref);
    s_awvalid = 0; s_wvalid = 0; s_bready = 0; s_arvalid = 0; s_rready = 0; av_write = 0; av_read = 0;
    repeat (5) @(posedge clk); rst_n = 1; repeat (2) @(posedge clk);

    axil_rd(R_VERSION, v);
    if (v != VERSION) begin $display("VERSION mismatch %h", v); $finish; end

    for (int i = 0; i < D; i++) av_wr(i, xmem[i]);               // x -> x_buf
    axil_wr(R_WLO, WBASE[31:0]); axil_wr(R_WHI, WBASE[63:32]);
    axil_wr(R_NROWS, N); axil_wr(R_DCOLS, D);
    axil_wr(R_CTRL, 32'h1);                                        // START

    timeout = 0;
    do begin axil_rd(R_STATUS, st); timeout++; end
    while (!(st & 32'h6) && timeout < 200000);
    if (st & 32'h4) begin $display("AXI ERROR"); $finish; end
    if (!(st & 32'h2)) begin $display("TIMEOUT"); $finish; end
    axil_wr(R_STATUS, 32'h2);
    axil_rd(R_CYCLES, v);
    $display("cycles=%0d  ideal=%0d  (差值 = 模型延迟/气泡 + flush)", v, N*D/LANES);

    for (int r = 0; r < N; r++) begin
      shortreal a, b;
      av_rd(19'h40000 + r, v);                                     // y_buf
      a = $bitstoshortreal(v); b = $bitstoshortreal(yref[r]);
      if ($abs(a-b) > 1e-4 * ($abs(b) + 1e-3)) begin errs++; if (errs < 10) $display("row %0d: got %f ref %f", r, a, b); end
    end
    $display(errs == 0 ? "PASS" : "FAIL (%0d errors)", errs);
    $finish;
  end
endmodule