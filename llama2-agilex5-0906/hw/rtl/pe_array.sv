module pe_array
  import matvec_pkg::*;
(
  input  logic                 clk,
  input  logic                 rst_n,

  // ---- 控制 (来自 csr, 运行期间保持稳定) ----
  input  logic                 start,       // 脉冲
  input  logic [31:0]          n_rows,
  input  logic [31:0]          d_cols,      // 要求: LANES 的倍数, 且 >= LANES*AL

  // ---- 权重流 (来自 w_reader), 行主序, 每拍 LANES 个 fp32 ----
  input  logic [AXI_DW-1:0]    w_tdata,
  input  logic                 w_tvalid,
  output logic                 w_tready,

  // ---- x_buf 读口 (同步读, 1 拍延迟, 受 x_rd_en 门控) ----
  output logic                 x_rd_en,
  output logic [XROW_AW-1:0]   x_rd_addr,
  input  logic [AXI_DW-1:0]    x_rd_data,

  // ---- y 写口 ----
  output logic                 y_we,
  output logic [ROW_W-1:0]     y_addr,
  output logic [31:0]          y_data,

  output logic                 busy,
  output logic                 done         // 脉冲: 最后一行 y 已写
);

  // ---------------- 延迟预算 (以 S0 为 0) ----------------
  localparam int RED_L    = $clog2(AL);
  localparam int LAT_MUL  = 1 + ML;                 // S1 寄存 + 乘法
  localparam int LAT_TREE = LAT_MUL + LANE_L*AL;    // 加法树输出 = 累加器输入
  localparam int LAT_ACC  = LAT_TREE + AL;          // 累加器输出
  localparam int LAT_RED  = RED_L*AL;               // 行末归约树
  localparam int FLUSH    = LAT_ACC + 1 + LAT_RED + 2;

  // ---------------- 计数器 / FSM ----------------
  logic [31:0]      beats_per_row;
  logic [31:0]      col;
  logic [ROW_W-1:0] row;
  logic             running, flushing;
  logic [$clog2(FLUSH+1)-1:0] flush_cnt;

  assign beats_per_row = d_cols >> LANE_L;
  assign w_tready = running & ~flushing;
  assign busy     = running;

  logic fire, en, last_col, last_row;
  assign fire     = w_tvalid & w_tready;
  assign en       = fire | flushing;
  assign last_col = (col == beats_per_row - 32'd1);
  assign last_row = (row == n_rows[ROW_W-1:0] - 1'b1);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      running <= 1'b0; flushing <= 1'b0;
      col <= '0; row <= '0; flush_cnt <= '0;
    end else begin
      if (start) begin
        running <= 1'b1; flushing <= 1'b0;
        col <= '0; row <= '0; flush_cnt <= '0;
      end else if (fire) begin
        if (last_col) begin
          col <= '0;
          row <= row + 1'b1;
          if (last_row) begin flushing <= 1'b1; flush_cnt <= '0; end
        end else begin
          col <= col + 32'd1;
        end
      end else if (flushing) begin
        if (flush_cnt == FLUSH-1) begin flushing <= 1'b0; running <= 1'b0; end
        else flush_cnt <= flush_cnt + 1'b1;
      end
    end
  end

  // ---------------- S0: 发出 x 读, 生成 tag ----------------
  logic s0_first, s0_tail, s0_last;
  assign s0_first  = (col < AL);                    // 本行前 AL 拍: 累加器清零
  assign s0_tail   = (col + AL >= beats_per_row);   // 本行最后 AL 拍: 需要捕获
  assign s0_last   = last_col;
  assign x_rd_en   = en;
  assign x_rd_addr = col[XROW_AW-1:0];

  // ---------------- S1: 寄存 w, 与 x_buf 输出对齐 ----------------
  logic [AXI_DW-1:0] w_s1;
  always_ff @(posedge clk) if (en) w_s1 <= w_tdata;

  // ---------------- 乘法 + 加法树 ----------------
  logic [31:0] prod [LANES];
  for (genvar i = 0; i < LANES; i++) begin : g_mul
    fp32_mul u_mul (.clk(clk), .en(en),
                    .a(w_s1[32*i +: 32]), .b(x_rd_data[32*i +: 32]), .q(prod[i]));
  end

  logic [31:0] tree_out;
  fp32_add_tree #(.N(LANES)) u_tree (.clk(clk), .en(en), .din(prod), .dout(tree_out));

  // ---------------- 累加器: 一个加法器 = AL 个交错部分和 ----------------
  logic        t_first_tree;
  logic [31:0] acc_out, acc_b;
  pipe_delay #(.W(1), .D(LAT_TREE)) u_d_first
    (.clk(clk), .rst_n(rst_n), .en(en), .din(s0_first), .dout(t_first_tree));

  assign acc_b = t_first_tree ? 32'h0000_0000 : acc_out;
  fp32_add u_acc (.clk(clk), .en(en), .a(tree_out), .b(acc_b), .q(acc_out));

  // tag 对齐到累加器输出
  logic             t_v, t_tail, t_last;
  logic [ROW_W-1:0] t_row;
  pipe_delay #(.W(3+ROW_W), .D(LAT_ACC)) u_d_tag
    (.clk(clk), .rst_n(rst_n), .en(en),
     .din({fire, s0_tail, s0_last, row}), .dout({t_v, t_tail, t_last, t_row}));

  // ---------------- 行末捕获 AL 个部分和 ----------------
  logic [31:0] cap [AL];
  always_ff @(posedge clk) begin
    if (en && t_v && t_tail) begin
      cap[AL-1] <= acc_out;
      for (int i = 0; i < AL-1; i++) cap[i] <= cap[i+1];
    end
  end

  logic             r_v;
  logic [ROW_W-1:0] r_row;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin r_v <= 1'b0; r_row <= '0; end
    else if (en) begin r_v <= t_v & t_last; r_row <= t_row; end
  end

  // ---------------- 归约树 → y ----------------
  logic [31:0] red_out;
  fp32_add_tree #(.N(AL)) u_red (.clk(clk), .en(en), .din(cap), .dout(red_out));

  logic             o_v;
  logic [ROW_W-1:0] o_row;
  pipe_delay #(.W(1+ROW_W), .D(LAT_RED)) u_d_out
    (.clk(clk), .rst_n(rst_n), .en(en), .din({r_v, r_row}), .dout({o_v, o_row}));

  assign y_we   = o_v & en;              // 与 en 相与: 每个 tag 恰好写一次
  assign y_addr = o_row;
  assign y_data = red_out;
  assign done   = y_we & (o_row == n_rows[ROW_W-1:0] - 1'b1);

endmodule
