module int8_mac_lane (
  input  logic               clk,
  input  logic               en,
  input  logic [255:0]       w,      // 32 x int8
  input  logic [255:0]       x,      // 32 x int8
  output logic signed [31:0] dot     // 延迟 3 拍
);
  logic signed [15:0] prod [32];
  logic signed [31:0] p4   [4];

  always_ff @(posedge clk) if (en)
    for (int i = 0; i < 32; i++)
      prod[i] <= $signed(w[8*i +: 8]) * $signed(x[8*i +: 8]);

  always_ff @(posedge clk) if (en)
    for (int g = 0; g < 4; g++) begin
      logic signed [31:0] s;
      s = '0;
      for (int i = 0; i < 8; i++) s += 32'(prod[g*8 + i]);
      p4[g] <= s;
    end

  always_ff @(posedge clk) if (en)
    dot <= p4[0] + p4[1] + p4[2] + p4[3];
endmodule