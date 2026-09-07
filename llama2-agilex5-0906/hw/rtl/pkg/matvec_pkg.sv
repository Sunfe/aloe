package matvec_pkg;
  // ---------------- 数据通路 ----------------
  localparam int AXI_DW   = 256;                    // F2H 读数据位宽
  localparam int LANES    = AXI_DW/32;              // 8 个 fp32 / 拍
  localparam int LANE_L   = $clog2(LANES);          // 3
  localparam int XBUF_DEP = 8192;                   // x 最大长度 (words)
  localparam int XROW_AW  = $clog2(XBUF_DEP/LANES); // x_buf 行地址宽 = 10
  localparam int YBUF_DEP = 32768;                  // y 最大长度 (vocab_size)
  localparam int ROW_W    = 16;                     // 行号位宽 (n_rows <= 65535)

  // ---------------- fp32 IP 延迟 (必须与 IP Catalog 生成的一致!) ----------------
  localparam int ML = 3;                            // fp32 乘法延迟
  localparam int AL = 4;                            // fp32 加法延迟 (要求 2 的幂)

  // ---------------- CSR 字节偏移 ----------------
  localparam logic [7:0] R_CTRL    = 8'h00;
  localparam logic [7:0] R_STATUS  = 8'h04;
  localparam logic [7:0] R_WLO     = 8'h08;
  localparam logic [7:0] R_WHI     = 8'h0C;
  localparam logic [7:0] R_NROWS   = 8'h10;
  localparam logic [7:0] R_DCOLS   = 8'h14;
  localparam logic [7:0] R_SCALE   = 8'h18;
  localparam logic [7:0] R_GROUP   = 8'h1C;
  localparam logic [7:0] R_CYCLES  = 8'h20;
  localparam logic [7:0] R_VERSION = 8'h24;
  localparam logic [31:0] VERSION  = 32'h2025_0001;
endpackage
