// softmax_unit.sv
// Softmax: out[i] = exp(x[i] - max) / Σ exp(x[j] - max)
//
// 三遍扫描:
//   Pass 1: 找 max
//   Pass 2: 计算 exp 并累加
//   Pass 3: 归一化 (乘以 1/sum)
//
// exp 近似: 分段线性 + 查表

module softmax_unit #(
    parameter MAX_LEN = 128,
    parameter DATA_W  = 16,
    parameter FRAC_W  = 8
)(
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       start,
    input  logic [9:0]                 len,
    input  logic signed [DATA_W-1:0]   vec_in  [0:MAX_LEN-1],
    output logic signed [31:0]         vec_out [0:MAX_LEN-1],
    output logic                       done
);

    // exp 查找表: 256 项, 覆盖 x ∈ [-8, 0]
    

## You
请继续

## Claude Opus 4.6
接着 `softmax_unit.sv` 继续：

```systemverilog
    // exp 查找表: 256 项, 覆盖 x ∈ [-8, 0]
    // 因为 softmax 减去了 max，所以输入总是 <= 0
    logic [DATA_W-1:0] exp_lut [0:255];

    initial begin
        for (int i = 0; i < 256; i++) begin
            // x = -8.0 * (255 - i) / 255.0, 范围 [-8, 0]
            automatic real x_val = -8.0 * real'(255 - i) / 255.0;
            automatic real exp_val = $exp(x_val);
            exp_lut[i] = DATA_W'($rtoi(exp_val * (2.0 ** FRAC_W)));
        end
    end

    typedef enum logic [2:0] {
        SM_IDLE,
        SM_FIND_MAX,
        SM_EXP_SUM,
        SM_INV_SUM,
        SM_NORMALIZE,
        SM_DONE
    } sm_state_t;

    sm_state_t sm_state;
    logic [9:0] idx;
    logic signed [DATA_W-1:0] max_val;
    logic [31:0] exp_sum;
    logic [31:0] inv_sum;     // 1/sum in Q format
    logic signed [31:0] exp_buf [0:MAX_LEN-1];  // 暂存 exp 结果

    // exp 查表函数
    function automatic logic [DATA_W-1:0] lookup_exp(
        input logic signed [DATA_W-1:0] x
    );
        // 映射 x ∈ [-8,0] → index ∈ [0,255]
        automatic logic signed [15:0] shifted;
        automatic logic [7:0] lut_idx;

        shifted = (x * 16'sd32) >>> FRAC_W;  // x * (255/8)
        if (shifted < -255)
            return 0;
        else if (shifted >= 0)
            return (1 << FRAC_W);  // exp(0) = 1.0
        else
            lut_idx = 8'(shifted + 256);
            return exp_lut[lut_idx];
    endfunction

    // 简易牛顿迭代求 1/x
    // 用于避免硬除法
    logic [1:0] newton_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sm_state <= SM_IDLE;
            done     <= 0;
        end else begin
            case (sm_state)
                // ---- 空闲 ----
                SM_IDLE: begin
                    done <= 0;
                    if (start) begin
                        idx      <= 0;
                        max_val  <= vec_in[0];
                        sm_state <= SM_FIND_MAX;
                    end
                end

                // ---- Pass 1: 找最大值 ----
                SM_FIND_MAX: begin
                    if ($signed(vec_in[idx]) > $signed(max_val))
                        max_val <= vec_in[idx];

                    idx <= idx + 1;
                    if (idx + 1 >= len) begin
                        idx      <= 0;
                        exp_sum  <= 0;
                        sm_state <= SM_EXP_SUM;
                    end
                end

                // ---- Pass 2: 计算 exp(x-max) 并累加 ----
                SM_EXP_SUM: begin
                    automatic logic signed [DATA_W-1:0] diff;
                    automatic logic [DATA_W-1:0] e;

                    diff = vec_in[idx] - max_val;
                    e    = lookup_exp(diff);

                    exp_buf[idx] <= {16'b0, e};
                    exp_sum      <= exp_sum + {16'b0, e};

                    idx <= idx + 1;
                    if (idx + 1 >= len) begin
                        newton_cnt <= 0;
                        // 初始估计 1/sum
                        inv_sum    <= (32'h1 << (2 * FRAC_W)) / (exp_sum + 1);
                        sm_state   <= SM_INV_SUM;
                    end
                end

                // ---- 牛顿迭代求 1/sum ----
                // y_{n+1} = y_n * (2 - sum * y_n)
                SM_INV_SUM: begin
                    automatic logic [31:0] prod;
                    automatic logic [31:0] correction;

                    prod       = (exp_sum * inv_sum) >> FRAC_W;
                    correction = (32'h2 << FRAC_W) - prod;
                    inv_sum    <= (inv_sum * correction) >> FRAC_W;

                    newton_cnt <= newton_cnt + 1;
                    if (newton_cnt == 2) begin
                        idx      <= 0;
                        sm_state <= SM_NORMALIZE;
                    end
                end

                // ---- Pass 3: 归一化 ----
                SM_NORMALIZE: begin
                    vec_out[idx] <= (exp_buf[idx] * inv_sum) >>> FRAC_W;

                    idx <= idx + 1;
                    if (idx + 1 >= len) begin
                        sm_state <= SM_DONE;
                    end
                end

                SM_DONE: begin
                    done     <= 1;
                    sm_state <= SM_IDLE;
                end

                default: sm_state <= SM_IDLE;
            endcase
        end
    end

endmodule
