module w_reader
  import matvec_pkg::*;
#(
  parameter int MAX_OUT = 8,     // 最多在飞 burst 数
  parameter int BURST   = 16,    // 每 burst 拍数 (16 x 32B = 512B)
  parameter int ID_W    = 4
)(
  input  logic              clk,
  input  logic              rst_n,

  input  logic              start,        // 脉冲, 同时锁存 base_addr / total_beats
  input  logic [63:0]       base_addr,    // 必须 32B 对齐
  input  logic [31:0]       total_beats,  // = n_rows * d_cols / LANES
  output logic              busy,
  output logic              err_set,      // 脉冲: 收到 SLVERR/DECERR

  // ---- AXI4 read address ----
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
  // ---- AXI4 read data ----
  input  logic [ID_W-1:0]   m_rid,
  input  logic [AXI_DW-1:0] m_rdata,
  input  logic [1:0]        m_rresp,
  input  logic              m_rlast,
  input  logic              m_rvalid,
  output logic              m_rready,

  // ---- AXI-Stream 输出 → pe_array ----
  output logic [AXI_DW-1:0] tdata,
  output logic              tvalid,
  input  logic              tready
);
  localparam int BEAT_SHIFT = $clog2(AXI_DW/8);   // 32B -> 5

  // 常量侧带信号
  assign m_arid    = '0;
  assign m_arsize  = 3'($clog2(AXI_DW/8));        // 3'b101 = 32 bytes/beat
  assign m_arburst = 2'b01;                       // INCR
  assign m_arlock  = 1'b0;
  assign m_arcache = 4'b0011;                     // normal non-cacheable, bufferable
  assign m_arprot  = 3'b010;                      // 非安全访问 (HPS DDR 默认要求)

  // 数据直通
  assign tdata    = m_rdata;
  assign tvalid   = m_rvalid;
  assign m_rready = tready;

  logic ar_fire, r_fire, r_last_fire;
  assign ar_fire     = m_arvalid & m_arready;
  assign r_fire      = m_rvalid & m_rready;
  assign r_last_fire = r_fire & m_rlast;
  assign err_set     = r_fire & m_rresp[1];

  // ---------------- 发射 FSM ----------------
  logic                        running;
  logic [63:0]                 cur_addr;
  logic [31:0]                 beats_left;      // 尚未发出 AR 的拍数
  logic [$clog2(MAX_OUT+1)-1:0] outstanding;

  // 到 4KB 边界的拍数: 地址 32B 对齐时 = 128 - addr[11:5]
  logic [7:0] to_4k, len_beats;
  assign to_4k = 8'd128 - {1'b0, cur_addr[11:BEAT_SHIFT]};
  always_comb begin
    len_beats = BURST[7:0];
    if (beats_left < 32'(len_beats)) len_beats = beats_left[7:0];
    if (to_4k      < len_beats)      len_beats = to_4k;
  end

  logic can_issue;
  assign can_issue = running & (beats_left != 0) & (outstanding < MAX_OUT);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      running <= 1'b0; m_arvalid <= 1'b0; m_araddr <= '0; m_arlen <= '0;
      cur_addr <= '0; beats_left <= '0; outstanding <= '0;
    end else begin
      // outstanding 计数 (同拍加减抵消)
      case ({ar_fire, r_last_fire})
        2'b10: outstanding <= outstanding + 1'b1;
        2'b01: outstanding <= outstanding - 1'b1;
        default: ;
      endcase

      if (start) begin
        running    <= 1'b1;
        cur_addr   <= base_addr;
        beats_left <= total_beats;
        m_arvalid  <= 1'b0;
      end else if (running) begin
        if (!m_arvalid) begin
          if (can_issue) begin
            m_arvalid  <= 1'b1;
            m_araddr   <= cur_addr;
            m_arlen    <= len_beats - 8'd1;
            cur_addr   <= cur_addr + ({56'd0, len_beats} << BEAT_SHIFT);
            beats_left <= beats_left - 32'(len_beats);
          end
        end else if (m_arready) begin
          m_arvalid <= 1'b0;             // 每两个 AR 之间空一拍, 对 16 拍 burst 无影响
        end
        // 全部发完且全部收回 → 空闲
        if (beats_left == 0 && outstanding == 0 && !m_arvalid && !r_last_fire)
          running <= 1'b0;
      end
    end
  end

  assign busy = running;

endmodule