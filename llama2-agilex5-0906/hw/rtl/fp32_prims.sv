// ---------------------------------------------------------------
// 带使能的通用延迟线: 只有 en=1 时移位。整个 PE 流水线都用它对齐 tag。
// ---------------------------------------------------------------
module pipe_delay #(
  parameter int W = 1,
  parameter int D = 1
)(
  input  logic         clk,
  input  logic         rst_n,
  input  logic         en,
  input  logic [W-1:0] din,
  output logic [W-1:0] dout
);
  logic [W-1:0] sr [D];
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < D; i++) sr[i] <= '0;
    end else if (en) begin
      sr[0] <= din;
      for (int i = 1; i < D; i++) sr[i] <= sr[i-1];
    end
  end
  assign dout = sr[D-1];
endmodule

// ---------------------------------------------------------------
// fp32 乘法, 延迟 ML, 带 en
// 综合: 在 IP Catalog 生成 "Floating Point Functions Intel FPGA IP"
//       功能 MULT, 单精度, 固定延迟 = ML, 勾选 enable 端口, 命名 fp32_mul_ip
// ---------------------------------------------------------------
module fp32_mul
  import matvec_pkg::*;
(
  input  logic        clk,
  input  logic        en,
  input  logic [31:0] a,
  input  logic [31:0] b,
  output logic [31:0] q
);
`ifdef SYNTHESIS
  fp32_mul_ip u_ip (.clk(clk), .areset(1'b0), .en(en), .a(a), .b(b), .q(q));
`else
  logic [31:0] p;
  assign p = $shortrealtobits($bitstoshortreal(a) * $bitstoshortreal(b));
  pipe_delay #(.W(32), .D(ML)) u_d (.clk(clk), .rst_n(1'b1), .en(en), .din(p), .dout(q));
`endif
endmodule

// ---------------------------------------------------------------
// fp32 加法, 延迟 AL, 带 en  (IP: 功能 ADD, 命名 fp32_add_ip)
// ---------------------------------------------------------------
module fp32_add
  import matvec_pkg::*;
(
  input  logic        clk,
  input  logic        en,
  input  logic [31:0] a,
  input  logic [31:0] b,
  output logic [31:0] q
);
`ifdef SYNTHESIS
  fp32_add_ip u_ip (.clk(clk), .areset(1'b0), .en(en), .a(a), .b(b), .q(q));
`else
  logic [31:0] s;
  assign s = $shortrealtobits($bitstoshortreal(a) + $bitstoshortreal(b));
  pipe_delay #(.W(32), .D(AL)) u_d (.clk(clk), .rst_n(1'b1), .en(en), .din(s), .dout(q));
`endif
endmodule

// ---------------------------------------------------------------
// N 输入 fp32 加法树 (N 为 2 的幂), 延迟 = log2(N) * AL
// ---------------------------------------------------------------
module fp32_add_tree #(
  parameter int N = 8
)(
  input  logic        clk,
  input  logic        en,
  input  logic [31:0] din [N],
  output logic [31:0] dout
);
  localparam int L = $clog2(N);
  initial if ((1 << L) != N) $fatal(1, "fp32_add_tree: N must be power of 2");

  wire [31:0] node [0:L][0:N-1];

  for (genvar i = 0; i < N; i++) begin : g_in
    assign node[0][i] = din[i];
  end
  for (genvar l = 0; l < L; l++) begin : g_lvl
    for (genvar i = 0; i < (N >> (l+1)); i++) begin : g_add
      fp32_add u_add (.clk(clk), .en(en),
                      .a(node[l][2*i]), .b(node[l][2*i+1]), .q(node[l+1][i]));
    end
  end
  assign dout = node[L][0];
endmodule
