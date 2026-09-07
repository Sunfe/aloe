`timescale 1ns/1ps
module tb_w_reader;
  import matvec_pkg::*;
  localparam longint BASE = 64'hA000_0000;
  localparam int TOTAL = 1000;

  logic clk = 0, rst_n = 0; always #5 clk = ~clk;
  logic start, busy, err_set, tvalid, tready;
  logic [255:0] tdata;
  wire [3:0] arid, rid; wire [63:0] araddr; wire [7:0] arlen; wire [2:0] arsize, arprot;
  wire [1:0] arburst, rresp; wire arlock, arvalid, arready, rlast, rvalid, rready; wire [3:0] arcache; wire [255:0] rdata;

  w_reader dut (
    .clk(clk), .rst_n(rst_n), .start(start),
    .base_addr(BASE + 64'hF00),          // 故意从 4KB 边界前 256B 开始
    .total_beats(TOTAL), .busy(busy), .err_set(err_set),
    .m_arid(arid), .m_araddr(araddr), .m_arlen(arlen), .m_arsize(arsize), .m_arburst(arburst),
    .m_arlock(arlock), .m_arcache(arcache), .m_arprot(arprot), .m_arvalid(arvalid), .m_arready(arready),
    .m_rid(rid), .m_rdata(rdata), .m_rresp(rresp), .m_rlast(rlast), .m_rvalid(rvalid), .m_rready(rready),
    .tdata(tdata), .tvalid(tvalid), .tready(tready));

  axi_mem_model #(.BASE(BASE)) u_mem (
    .clk(clk), .rst_n(rst_n), .arid(arid), .araddr(araddr), .arlen(arlen), .arvalid(arvalid), .arready(arready),
    .rid(rid), .rdata(rdata), .rresp(rresp), .rlast(rlast), .rvalid(rvalid), .rready(rready));

  int got = 0, errs = 0;
  always @(negedge clk) tready = ($urandom_range(0, 4) != 0);   // 随机反压
  always @(posedge clk) if (tvalid && tready) begin
    if (tdata[31:0] != 32'h78 + got) begin errs++; if (errs < 10) $display("beat %0d got %0h", got, tdata[31:0]); end
    got++;
  end
  // 4KB 边界检查: 一个 burst 不得跨越
  always @(posedge clk) if (arvalid && arready)
    if ((araddr[11:0] + 32*(arlen+1)) > 4096) begin errs++; $display("burst crosses 4KB @%h len %0d", araddr, arlen+1); end

  initial begin
    for (int i = 0; i < 4096; i++) u_mem.mem[i] = 256'(i);   // 字 i 的低 32 位 = i; 0xF00/32 = 0x78
    start = 0; repeat (3) @(posedge clk); rst_n = 1;
    @(posedge clk); start = 1; @(posedge clk); start = 0;
    wait (!busy); repeat (10) @(posedge clk);
    if (got != TOTAL) begin errs++; $display("got %0d beats, expected %0d", got, TOTAL); end
    $display(errs == 0 ? "PASS" : "FAIL (%0d errors)", errs); $finish;
  end
endmodule