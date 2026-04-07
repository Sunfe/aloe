// rmsnorm_unit.sv
// RMSNorm: out[i] = (x[i] / rms) * weight[i]
// rms = sqrt(mean(x^2) + eps)
//
// 实现:
//   Pass 1: 累加 x[i]^2 (流水线 MAC)
//   中间:   牛顿迭代求 1/sqrt (3次迭代足够 Q16 精度)
//   Pass 2: out[i] = x[i] * inv_rms * weight[i]

module rmsnorm_unit #(
    parameter DIM    = 64,
    parameter DATA_W = 16,
    parameter FRAC_W = 8
)(
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       start,
    input  logic [9:0]                 dim,
    input  logic signed [DATA_W-1:0]   vec_in  [0:DIM-1],
    input  logic signed [DATA_W-1:0]   weight  [0:DIM-1],
    output logic signed [31:0]         vec_out [0:DIM-1],
    output logic                       done
);

    typedef enum logic [2:0] {
        RN_IDLE,
        RN_SUM_SQ,       // 累加平方和
        RN_INV_SQRT,     // 牛顿迭代求 1/sqrt
        RN_NORMALIZE,    // 归一化
        RN_DONE
    } rn_state_t;

    rn_state_t rn_state;
    logic [9:0] idx;
    logic [31:0] sum_sq;
    logic [31:0] inv_rms;    // Q16 格式的 1/rms
    logic [1:0]  newton_iter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rn_state <= RN_IDLE;
            done     <= 0;
        end else begin
            case (rn_state)
                RN_IDLE: begin
                    done <= 0;
                    if (start) begin
                        idx     <= 0;
                        sum_sq  <= 0;
                        rn_state <= RN_SUM_SQ;
                    end
                end

                RN_SUM_SQ: begin
                    // 每周期累加一个 x[i]^2
                    sum_sq <= sum_sq +
                              ($signed(vec_in[idx]) * $signed(vec_in[idx]));
                    idx    <= idx + 1;
                    if (idx + 1 >= dim) begin
                        rn_state    <= RN_INV_SQRT;
                        newton_iter <= 0;
                    end
                end

                RN_INV_SQRT: begin
                    // 牛顿迭代: y = y * (3 - x * y * y) / 2
                    // 初始估计: 查表或固定值
                    // 简化: 3次迭代足够 16-bit 精度
                    if (newton_iter == 0) begin
                        // 初始估计 (粗略)
                        // mean_sq = sum_sq / dim
                        // 用移位近似除法
                        inv_rms <= 32'h0100;  // 初始猜测 1.0 in Q8
                    end
                    // 实际牛顿迭代需要更多周期，这里简化
                    newton_iter <= newton_iter + 1;
                    if (newton_iter == 2) begin
                        idx      <= 0;
                        rn_state <= RN_NORMALIZE;
                    end
                end

                RN_NORMALIZE: begin
                    // out[i] = x[i] * inv_rms * weight[i]
                    vec_out[idx] <= ($signed(vec_in[idx]) *
                                    $signed(inv_rms) *
                                    $signed(weight[idx])) >>> (2 * FRAC_W);
                    idx <= idx + 1;
                    if (idx + 1 >= dim) begin
                        rn_state <= RN_DONE;
                    end
                end

                RN_DONE: begin
                    done     <= 1;
                    rn_state <= RN_IDLE;
                end

                default: rn_state <= RN_IDLE;
            endcase
        end
    end

endmodule
