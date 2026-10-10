// top_accel.sv
// Tiny LLM FPGA 加速器顶层
// 接口: AXI4-Lite (控制) + AXI4 Master (DMA 读写 DDR)

module top_accel #(
    parameter DIM       = 64,
    parameter FFN_DIM   = 172,
    parameter VOCAB_SIZE= 64,
    parameter CTX_LEN   = 128,
    parameter DATA_W    = 16,    // Q16 定点数宽度
    parameter FRAC_W    = 8      // 小数位宽
)(
    input  logic        clk,
    input  logic        rst_n,

    // ======== AXI4-Lite Slave (控制接口) ========
    // HPS 通过这个接口写寄存器来控制加速器
    input  logic [11:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    input  logic [31:0] s_axi_wdata,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,
    input  logic [11:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // ======== AXI4 Master (DMA 接口) ========
    // 加速器通过这个接口读写 HPS DDR 内存
    output logic [31:0] m_axi_awaddr,
    output logic [7:0]  m_axi_awlen,
    output logic        m_axi_awvalid,
    input  logic        m_axi_awready,
    output logic [63:0] m_axi_wdata,
    output logic        m_axi_wlast,
    output logic        m_axi_wvalid,
    input  logic        m_axi_wready,
    input  logic        m_axi_bvalid,
    output logic        m_axi_bready,
    output logic [31:0] m_axi_araddr,
    output logic [7:0]  m_axi_arlen,
    output logic        m_axi_arvalid,
    input  logic        m_axi_arready,
    input  logic [63:0] m_axi_rdata,
    input  logic        m_axi_rlast,
    input  logic        m_axi_rvalid,
    output logic        m_axi_rready,

    // ======== 中断 ========
    output logic        irq    // 完成中断 -> HPS GIC
);

    // ============================================
    // 控制寄存器
    // ============================================
    // 地址映射:
    //   0x000: CTRL      [0]=start, [1]=irq_en
    //   0x004: STATUS    [0]=busy, [1]=done
    //   0x008: OP_TYPE   操作类型
    //   0x00C: PARAM0    参数0 (如 in_dim)
    //   0x010: PARAM1    参数1 (如 out_dim)
    //   0x014: PARAM2    参数2 (如 seq_len)
    //   0x020: SRC_ADDR  输入数据 DDR 地址
    //   0x024: WGT_ADDR  权重数据 DDR 地址
    //   0x028: DST_ADDR  输出数据 DDR 地址
    //   0x02C: CYCLES    计算耗时 (性能计数)

    logic [31:0] reg_ctrl;
    logic [31:0] reg_status;
    logic [31:0] reg_op_type;
    logic [31:0] reg_param0;
    logic [31:0] reg_param1;
    logic [31:0] reg_param2;
    logic [31:0] reg_src_addr;
    logic [31:0] reg_wgt_addr;
    logic [31:0] reg_dst_addr;
    logic [31:0] reg_cycles;

    // 操作类型编码
    localparam OP_MATMUL    = 32'd0;
    localparam OP_RMSNORM   = 32'd1;
    localparam OP_SOFTMAX   = 32'd2;
    localparam OP_SILU      = 32'd3;
    localparam OP_ROPE      = 32'd4;
    localparam OP_VECADD    = 32'd5;
    localparam OP_ELEMMUL   = 32'd6;
    localparam OP_ATTN_SCORE= 32'd7;
    localparam OP_ATTN_MIX  = 32'd8;

    // 状态机
    typedef enum logic [3:0] {
        S_IDLE,
        S_LOAD_INPUT,
        S_LOAD_WEIGHT,
        S_COMPUTE,
        S_STORE_OUTPUT,
        S_DONE
    } state_t;

    state_t state, next_state;

    // 内部 BRAM 缓冲
    // 输入向量缓冲 (最大 FFN_DIM)
    logic signed [DATA_W-1:0] buf_in [0:FFN_DIM-1];
    // 权重缓冲 (一行，用于流式计算)
    logic signed [DATA_W-1:0] buf_weight [0:FFN_DIM-1];
    // 输出缓冲
    logic signed [31:0]       buf_out [0:FFN_DIM-1];

    // 周期计数器
    logic [31:0] cycle_count;

    // ============================================
    // AXI4-Lite Slave: 寄存器读写
    // ============================================
    axi_lite_slave u_axi_slave (
        .clk          (clk),
        .rst_n        (rst_n),
        // AXI ports ...
        .s_axi_awaddr (s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata  (s_axi_wdata),
        .s_axi_wvalid (s_axi_wvalid),
        .s_axi_wready (s_axi_wready),
        .s_axi_bresp  (s_axi_bresp),
        .s_axi_bvalid (s_axi_bvalid),
        .s_axi_bready (s_axi_bready),
        .s_axi_araddr (s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata  (s_axi_rdata),
        .s_axi_rresp  (s_axi_rresp),
        .s_axi_rvalid (s_axi_rvalid),
        .s_axi_rready (s_axi_rready),
        // 寄存器接口
        .reg_ctrl     (reg_ctrl),
        .reg_status   (reg_status),
        .reg_op_type  (reg_op_type),
        .reg_param0   (reg_param0),
        .reg_param1   (reg_param1),
        .reg_param2   (reg_param2),
        .reg_src_addr (reg_src_addr),
        .reg_wgt_addr (reg_wgt_addr),
        .reg_dst_addr (reg_dst_addr),
        .reg_cycles   (reg_cycles)
    );

    // ============================================
    // 主状态机
    // ============================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            cycle_count <= 0;
            irq         <= 0;
        end else begin
            state <= next_state;

            case (state)
                S_IDLE: begin
                    irq         <= 0;
                    cycle_count <= 0;
                end
                S_COMPUTE, S_LOAD_INPUT, S_LOAD_WEIGHT, S_STORE_OUTPUT: begin
                    cycle_count <= cycle_count + 1;
                end
                S_DONE: begin
                    irq <= reg_ctrl[1]; // 如果 irq_en=1 则触发中断
                end
                default: ;
            endcase
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            S_IDLE:         if (reg_ctrl[0]) next_state = S_LOAD_INPUT;
            S_LOAD_INPUT:   if (load_in_done) next_state = S_LOAD_WEIGHT;
            S_LOAD_WEIGHT:  if (load_wgt_done) next_state = S_COMPUTE;
            S_COMPUTE:      if (compute_done) next_state = S_STORE_OUTPUT;
            S_STORE_OUTPUT: if (store_done) next_state = S_DONE;
            S_DONE:         next_state = S_IDLE;
            default:        next_state = S_IDLE;
        endcase
    end

    // 状态信号
    assign reg_status = {30'b0, (state == S_DONE), (state != S_IDLE)};
    assign reg_cycles = cycle_count;

    // ============================================
    // DMA 引擎实例
    // ============================================
    logic load_in_done, load_wgt_done, store_done;

    dma_engine u_dma (
        .clk            (clk),
        .rst_n          (rst_n),
        // AXI Master
        .m_axi_araddr   (m_axi_araddr),
        .m_axi_arlen    (m_axi_arlen),
        .m_axi_arvalid  (m_axi_arvalid),
        .m_axi_arready  (m_axi_arready),
        .m_axi_rdata    (m_axi_rdata),
        .m_axi_rlast    (m_axi_rlast),
        .m_axi_rvalid   (m_axi_rvalid),
        .m_axi_rready   (m_axi_rready),
        .m_axi_awaddr   (m_axi_awaddr),
        .m_axi_awlen    (m_axi_awlen),
        .m_axi_awvalid  (m_axi_awvalid),
        .m_axi_awready  (m_axi_awready),
        .m_axi_wdata    (m_axi_wdata),
        .m_axi_wlast    (m_axi_wlast),
        .m_axi_wvalid   (m_axi_wvalid),
        .m_axi_wready   (m_axi_wready),
        .m_axi_bvalid   (m_axi_bvalid),
        .m_axi_bready   (m_axi_bready),
        // 控制
        .src_addr       (reg_src_addr),
        .wgt_addr       (reg_wgt_addr),
        .dst_addr       (reg_dst_addr),
        .param0         (reg_param0),
        .param1         (reg_param1),
        .state          (state),
        .load_in_done   (load_in_done),
        .load_wgt_done  (load_wgt_done),
        .store_done     (store_done),
        // 数据缓冲接口
        .buf_in         (buf_in),
        .buf_weight     (buf_weight),
        .buf_out        (buf_out)
    );

    // ============================================
    // 计算单元实例化
    // ============================================
    logic compute_done;
    logic matmul_done, rmsnorm_done, softmax_done;
    logic silu_done, rope_done, vecadd_done;

    // ---- MatMul 单元 ----
    logic matmul_start;
    assign matmul_start = (state == S_COMPUTE) && (reg_op_type == OP_MATMUL);

    matmul_unit #(
        .MAX_DIM  (FFN_DIM),
        .DATA_W   (DATA_W),
        .FRAC_W   (FRAC_W)
    ) u_matmul (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (matmul_start),
        .in_dim   (reg_param0[9:0]),
        .out_dim  (reg_param1[9:0]),
        .vec_in   (buf_in),
        .weight   (buf_weight),
        .vec_out  (buf_out),
        .done     (matmul_done)
    );

    // ---- RMSNorm 单元 ----
    logic rmsnorm_start;
    assign rmsnorm_start = (state == S_COMPUTE) && (reg_op_type == OP_RMSNORM);

    rmsnorm_unit #(
        .DIM    (DIM),
        .DATA_W (DATA_W),
        .FRAC_W (FRAC_W)
    ) u_rmsnorm (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (rmsnorm_start),
        .dim    (reg_param0[9:0]),
        .vec_in (buf_in),
        .weight (buf_weight),
        .vec_out(buf_out),
        .done   (rmsnorm_done)
    );

    // ---- Softmax 单元 ----
    logic softmax_start;
    assign softmax_start = (state == S_COMPUTE) && (reg_op_type == OP_SOFTMAX);

    softmax_unit #(
        .MAX_LEN (CTX_LEN),
        .DATA_W  (DATA_W),
        .FRAC_W  (FRAC_W)
    ) u_softmax (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (softmax_start),
        .len     (reg_param0[9:0]),
        .vec_in  (buf_in),
        .vec_out (buf_out),
        .done    (softmax_done)
    );

    // ---- SiLU 单元 ----
    logic silu_start;
    assign silu_start = (state == S_COMPUTE) && (reg_op_type == OP_SILU);

    silu_unit #(
        .MAX_DIM (FFN_DIM),
        .DATA_W  (DATA_W),
        .FRAC_W  (FRAC_W)
    ) u_silu (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (silu_start),
        .len     (reg_param0[9:0]),
        .vec_in  (buf_in),
        .vec_out (buf_out),
        .done    (silu_done)
    );

    // ---- RoPE 单元 ----
    logic rope_start;
    assign rope_start = (state == S_COMPUTE) && (reg_op_type == OP_ROPE);

    rope_unit #(
        .DIM    (DIM),
        .DATA_W (DATA_W),
        .FRAC_W (FRAC_W)
    ) u_rope (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (rope_start),
        .dim    (reg_param0[9:0]),
        .pos    (reg_param1[9:0]),
        .vec_in (buf_in),
        .vec_out(buf_out),
        .done   (rope_done)
    );

    // ---- VecAdd 单元 ----
    logic vecadd_start;
    assign vecadd_start = (state == S_COMPUTE) &&
                          (reg_op_type == OP_VECADD || reg_op_type == OP_ELEMMUL);

    vecadd_unit #(
        .MAX_DIM (FFN_DIM),
        .DATA_W  (DATA_W)
    ) u_vecadd (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (vecadd_start),
        .is_mul  (reg_op_type == OP_ELEMMUL),
        .len     (reg_param0[9:0]),
        .vec_a   (buf_in),
        .vec_b   (buf_weight),
        .vec_out (buf_out),
        .done    (vecadd_done)
    );

    // 计算完成信号汇总
    assign compute_done = matmul_done | rmsnorm_done | softmax_done |
                          silu_done   | rope_done    | vecadd_done;

endmodule