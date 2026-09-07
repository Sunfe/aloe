module csr
  import matvec_pkg::*;
(
  input  logic        clk,
  input  logic        rst_n,

  // ---- AXI4-Lite slave (LWH2F) ----
  input  logic [7:0]  s_awaddr,
  input  logic        s_awvalid,
  output logic        s_awready,
  input  logic [31:0] s_wdata,
  input  logic [3:0]  s_wstrb,
  input  logic        s_wvalid,
  output logic        s_wready,
  output logic [1:0]  s_bresp,
  output logic        s_bvalid,
  input  logic        s_bready,
  input  logic [7:0]  s_araddr,
  input  logic        s_arvalid,
  output logic        s_arready,
  output logic [31:0] s_rdata,
  output logic [1:0]  s_rresp,
  output logic        s_rvalid,
  input  logic        s_rready,

  // ---- 给数据通路 ----
  output logic        start,          // 单周期脉冲
  output logic        irq_en,
  output logic        mode_int8,
  output logic [63:0] w_addr,
  output logic [63:0] scale_addr,
  output logic [31:0] n_rows,
  output logic [31:0] d_cols,
  output logic [31:0] group_size,

  // ---- 来自数据通路 ----
  input  logic        busy,
  input  logic        done_set,       // 单周期脉冲: 本次 matvec 完成
  input  logic        axi_err_set,    // 单周期脉冲: w_reader 收到 SLVERR/DECERR
  input  logic [31:0] cycles,

  output logic        irq
);

  // ---------------- 写通道 ----------------
  // AW 与 W 同时到齐才接收 (AXI 允许 ready 依赖 valid)
  logic wr_fire;
  assign wr_fire  = s_awvalid & s_wvalid & ~s_bvalid;
  assign s_awready = wr_fire;
  assign s_wready  = wr_fire;
  assign s_bresp   = 2'b00;

  logic done_sticky, err_sticky;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_bvalid    <= 1'b0;
      start       <= 1'b0;
      irq_en      <= 1'b0;
      mode_int8   <= 1'b0;
      w_addr      <= '0;
      scale_addr  <= '0;
      n_rows      <= '0;
      d_cols      <= '0;
      group_size  <= 32'd64;
      done_sticky <= 1'b0;
      err_sticky  <= 1'b0;
    end else begin
      start <= 1'b0;                         // 默认脉冲拉低

      // 粘滞位置位 (优先级低于软件 W1C 清除, 见下)
      if (done_set)    done_sticky <= 1'b1;
      if (axi_err_set) err_sticky  <= 1'b1;

      if (s_bvalid & s_bready) s_bvalid <= 1'b0;

      if (wr_fire) begin
        s_bvalid <= 1'b1;
        case (s_awaddr)
          R_CTRL: begin
            if (s_wdata[0] & ~busy) start <= 1'b1;   // 忙时忽略 START
            irq_en    <= s_wdata[1];
            mode_int8 <= s_wdata[2];
          end
          R_STATUS: begin
            if (s_wdata[1]) done_sticky <= 1'b0;    // W1C
            if (s_wdata[2]) err_sticky  <= 1'b0;    // W1C
          end
          R_WLO:   w_addr[31:0]      <= s_wdata;
          R_WHI:   w_addr[63:32]     <= s_wdata;
          R_NROWS: n_rows            <= s_wdata;
          R_DCOLS: d_cols            <= s_wdata;
          R_SCALE: scale_addr[31:0]  <= s_wdata;   // 阶段 2: 高 32 位复用 W_HI 同一段
          R_GROUP: group_size        <= s_wdata;
          default: ;
        endcase
      end
    end
  end

  // ---------------- 读通道 ----------------
  assign s_arready = ~s_rvalid;
  assign s_rresp   = 2'b00;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_rvalid <= 1'b0;
      s_rdata  <= '0;
    end else begin
      if (s_rvalid & s_rready) s_rvalid <= 1'b0;
      if (s_arvalid & s_arready) begin
        s_rvalid <= 1'b1;
        case (s_araddr)
          R_CTRL:    s_rdata <= {29'd0, mode_int8, irq_en, 1'b0};
          R_STATUS:  s_rdata <= {29'd0, err_sticky, done_sticky, busy};
          R_WLO:     s_rdata <= w_addr[31:0];
          R_WHI:     s_rdata <= w_addr[63:32];
          R_NROWS:   s_rdata <= n_rows;
          R_DCOLS:   s_rdata <= d_cols;
          R_SCALE:   s_rdata <= scale_addr[31:0];
          R_GROUP:   s_rdata <= group_size;
          R_CYCLES:  s_rdata <= cycles;
          R_VERSION: s_rdata <= VERSION;
          default:   s_rdata <= 32'hDEAD_BEEF;   // 读错地址一眼看出
        endcase
      end
    end
  end

  assign irq = irq_en & done_sticky;

endmodule
