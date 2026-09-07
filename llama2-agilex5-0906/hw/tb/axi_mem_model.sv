`timescale 1ns/1ps
module axi_mem_model #(
  parameter longint BASE  = 64'h0000_0000_A000_0000,
  parameter int     WORDS = 1 << 18,       // 256-bit 字数 (8MB)
  parameter int     ID_W  = 4
)(
  input  logic             clk,
  input  logic             rst_n,
  input  logic [ID_W-1:0]  arid,
  input  logic [63:0]      araddr,
  input  logic [7:0]       arlen,
  input  logic             arvalid,
  output logic             arready,
  output logic [ID_W-1:0]  rid,
  output logic [255:0]     rdata,
  output logic [1:0]       rresp,
  output logic             rlast,
  output logic             rvalid,
  input  logic             rready
);
  logic [255:0] mem [WORDS];      // tb 里用 $readmemh(..., u_mem.mem) 装载

  typedef struct { logic [63:0] addr; logic [7:0] len; logic [ID_W-1:0] id; } req_t;
  req_t q[$];

  assign arready = rst_n && (q.size() < 8);
  always @(posedge clk) if (arvalid && arready) q.push_back('{araddr, arlen, arid});

  initial begin
    rvalid = 0; rlast = 0; rdata = '0; rresp = 0; rid = 0;
    wait (rst_n);
    forever begin
      req_t r; longint idx;
      @(posedge clk);
      if (q.size() == 0) continue;
      r = q.pop_front();
      repeat ($urandom_range(0, 20)) @(posedge clk);          // 内存延迟
      for (int b = 0; b <= r.len; b++) begin
        while ($urandom_range(0, 3) == 0) @(posedge clk);     // 拍间气泡
        idx = (longint'(r.addr) - BASE) / 32 + b;
        if (idx < 0 || idx >= WORDS) begin rdata <= 'x; rresp <= 2'b10; end
        else begin rdata <= mem[idx]; rresp <= 2'b00; end
        rid <= r.id; rlast <= (b == r.len); rvalid <= 1;
        @(posedge clk); while (!rready) @(posedge clk);
        rvalid <= 0;
      end
    end
  end
endmodule