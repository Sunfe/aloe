module matvec_top
  import matvec_pkg::*;
#(
  parameter int MAX_OUT = 8,
  parameter int ID_W    = 4
)(
  input  logic              clk,
  input  logic              rst_n,

  // ---- AXI4-Lite slave  s_csr (LWH2F) ----
  input  logic [7:0]        s_awaddr,
  input  logic [2:0]        s_awprot,      // 未用
  input  logic              s_awvalid,
  output logic              s_awready,
  input  logic [31:0]       s_wdata,
  input  logic [3:0]        s_wstrb,
  input  logic              s_wvalid,
  output logic              s_wready,
  output logic [1:0]        s_bresp,
  output logic              s_bvalid,
  input  logic              s_bready,
  input  logic [7:0]        s_araddr,
  input  logic [2:0]        s_arprot,      // 未用
  input  logic              s_arvalid,
  output logic              s_arready,
  output logic [31:0]       s_rdata,
  output logic [1:0]        s_rresp,
  output logic              s_rvalid,
  input  logic              s_rready,

  // ---- Avalon-MM slave  s_mem (H2F), 字地址, 读延迟 1 ----
  input  logic [18:0]       av_address,    // [18]=0: x_buf, [18]=1: y_buf
  input  logic              av_write,
  input  logic              av_read,
  input  logic [31:0]       av_writedata,
  output logic [31:0]       av_readdata,

  // ---- AXI4 master  m_wr (F2H) ----
  output logic [ID_W-1:0]   m_awid,
  output logic [63:0]       m_awaddr,
  output logic [7:0]        m_awlen,
  output logic [2:0]        m_awsize,
  output logic [1:0]        m_awburst,
  output logic              m_awlock,
  output logic [3:0]        m_awcache,
  output logic [2:0]        m_awprot,
  output logic              m_awvalid,
  input  logic              m_awready,
  output logic [AXI_DW-1:0] m_wdata,
  output logic [AXI_DW/8-1:0] m_wstrb,
  output logic              m_wlast,
  output logic              m_wvalid,
  input  logic              m_wready,
  input  logic [ID_W-1:0]   m_bid,
  input  logic [1:0]        m_bresp,
  input  logic              m_bvalid,
  output logic              m_bready,
  output logic [ID_W-1:0]   m_arid,
  output logic [63:0]       m_araddr,
  output logic [7:0]        m_arlen,
  output logic [2:0]        m_arsize,
  output logic [1:0]        m_arburst,
  output logic              m_arlock,
  output logic [3:0]        m_arcache,
  output logic [2:0]        m_arprot,
  output logic              m_arvalid,
  input  logic              m_arready,
  input  logic [ID_W-1:0]   m_rid,
  input  logic [AXI_DW-1:0] m_rdata,
  input  logic [1:0]        m_rresp,
  input  logic              m_rlast,
  input  logic              m_rvalid,
  output logic              m_rready,

  output logic              irq
);

  // ---------------- 写通道 tie-off (只读主机) ----------------
  assign m_awid = '0;  assign m_awaddr = '0;  assign m_awlen = '0;  assign m_awsize = '0;
  assign m_awburst = 2'b01; assign m_awlock = 1'b0; assign m_awcache = '0; assign m_awprot = '0;
  assign m_awvalid = 1'b0; assign m_wdata = '0; assign m_wstrb = '0; assign m_wlast = 1'b0;
  assign m_wvalid = 1'b0;  assign m_bready = 1'b1;

  // ---------------- CSR ----------------
  logic        start, irq_en, mode_int8, busy, done_set, err_set;
  logic [63:0] w_addr, scale_addr;
  logic [31:0] n_rows, d_cols, group_size, cycles;

  csr u_csr (
    .clk(clk), .rst_n(rst_n),
    .s_awaddr(s_awaddr), .s_awvalid(s_awvalid), .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_araddr(s_araddr), .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rvalid(s_rvalid), .s_rready(s_rready),
    .start(start), .irq_en(irq_en), .mode_int8(mode_int8),
    .w_addr(w_addr), .scale_addr(scale_addr),
    .n_rows(n_rows), .d_cols(d_cols), .group_size(group_size),
    .busy(busy), .done_set(done_set), .axi_err_set(err_set), .cycles(cycles),
    .irq(irq)
  );
  // mode_int8 / scale_addr / group_size: 阶段 2 接 int8 通路, 阶段 1 悬空

  // ---------------- 权重读取 ----------------
  logic              rd_busy, pe_busy, pe_done;
  logic [AXI_DW-1:0] w_tdata;
  logic              w_tvalid, w_tready;
  logic [31:0]       total_beats;
  assign total_beats = n_rows * (d_cols >> LANE_L);

  w_reader #(.MAX_OUT(MAX_OUT), .ID_W(ID_W)) u_rd (
    .clk(clk), .rst_n(rst_n),
    .start(start), .base_addr(w_addr), .total_beats(total_beats),
    .busy(rd_busy), .err_set(err_set),
    .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen), .m_arsize(m_arsize),
    .m_arburst(m_arburst), .m_arlock(m_arlock), .m_arcache(m_arcache), .m_arprot(m_arprot),
    .m_arvalid(m_arvalid), .m_arready(m_arready),
    .m_rid(m_rid), .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rlast(m_rlast),
    .m_rvalid(m_rvalid), .m_rready(m_rready),
    .tdata(w_tdata), .tvalid(w_tvalid), .tready(w_tready)
  );

  // ---------------- 片上缓冲 ----------------
  logic               x_rd_en;
  logic [XROW_AW-1:0] x_rd_addr;
  logic [AXI_DW-1:0]  x_rd_data;
  logic               y_we;
  logic [ROW_W-1:0]   y_addr;
  logic [31:0]        y_data;

  x_buf u_x (
    .clk(clk),
    .av_address(av_address[$clog2(XBUF_DEP)-1:0]),
    .av_write(av_write & ~av_address[18]),
    .av_writedata(av_writedata),
    .rd_en(x_rd_en), .rd_addr(x_rd_addr), .rd_data(x_rd_data)
  );

  y_buf u_y (
    .clk(clk),
    .av_address(av_address[$clog2(YBUF_DEP)-1:0]),
    .av_read(av_read),
    .av_readdata(av_readdata),
    .we(y_we), .waddr(y_addr), .wdata(y_data)
  );

  // ---------------- 数据通路 ----------------
  pe_array u_pe (
    .clk(clk), .rst_n(rst_n),
    .start(start), .n_rows(n_rows), .d_cols(d_cols),
    .w_tdata(w_tdata), .w_tvalid(w_tvalid), .w_tready(w_tready),
    .x_rd_en(x_rd_en), .x_rd_addr(x_rd_addr), .x_rd_data(x_rd_data),
    .y_we(y_we), .y_addr(y_addr), .y_data(y_data),
    .busy(pe_busy), .done(pe_done)
  );

  assign busy     = pe_busy | rd_busy;
  assign done_set = pe_done;

  // ---------------- 周期计数器 ----------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)      cycles <= '0;
    else if (start)  cycles <= '0;
    else if (busy)   cycles <= cycles + 32'd1;
  end

endmodule