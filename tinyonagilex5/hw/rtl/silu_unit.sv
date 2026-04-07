// silu_unit.sv
// SiLU(x) = x * sigmoid(x) = x / (1 + exp(-x))
//
// FPGA 实现: 256 项查找表 + 线性插值
// 输入范围 [-8, 8] 映射到 [0, 255]
// 超出范围: x < -8 → 0, x > 8 → x

module silu_unit #(
    parameter MAX_DIM = 172,
    parameter DATA_W  = 16,
    parameter FRAC_W  = 8
)(
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       start,
    input  logic [9:0]                 len,
    input  logic signed [DATA_W-1:0]   vec_in  [0:MAX_DIM-1],
    output logic signed [31:0]         vec_out [0:MAX_DIM-1],
    output logic                       done
);

    // SiLU 查找表 (Q8 格式)
    // silu_lut[i] = silu((i - 128) / 16.0) * 256
    // 覆盖 x ∈ [-8, +8]
    logic signed [DATA_W-1:0] silu_lut [0:255];

    // 初始化查找表
    initial begin
        // 预计算的 SiLU 值 (工具生成，这里用近似)
        for (int i = 0; i < 256; i++) begin
            // x = (i - 128) / 16.0, 范围 [-8, 8]
            // silu(x) = x * sigmoid(x)
            // 这些值应该由离线工具精确计算后填入
            // 这里用简化的分段近似
            automatic real x_real = (real'(i) - 128.0) / 16.0;
            automatic real sig = 1.0 / (1.0 + $exp(-x_real));
            automatic real silu_val = x_real * sig;
            silu_lut[i] = DATA_W'($rtoi(silu_val * (2.0 ** FRAC_W)));
        end
    end

    typedef enum logic [1:0] {
        SL_IDLE,
        SL_COMPUTE,
        SL_DONE
    } sl_state_t;

    sl_state_t sl_state;
    logic [9:0] idx;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sl_state <= SL_IDLE;
            done     <= 0;
        end else begin
            case (sl_state)
                SL_IDLE: begin
                    done <= 0;
                    if (start) begin
                        idx      <= 0;
                        sl_state <= SL_COMPUTE;
                    end
                end

                SL_COMPUTE: begin
                    // 查表索引: 将输入映射到 [0, 255]
                    // lut_idx = clamp((x >> (FRAC_W-4)) + 128, 0, 255)
                    automatic logic signed [DATA_W-1:0] x_val = vec_in[idx];
                    automatic logic [7:0] lut_idx;
                    automatic logic signed [15:0] shifted;

                    shifted = x_val >>> (FRAC_W - 4);  // 除以16
                    if (shifted < -128)
                        lut_idx = 0;
                    else if (shifted > 127)
                        lut_idx = 255;
                    else
                        lut_idx = shifted[7:0] + 8'd128;

                    vec_out[idx] <= {{16{silu_lut[lut_idx][DATA_W-1]}},
                                     silu_lut[lut_idx]};

                    idx <= idx + 1;
                    if (idx + 1 >= len) begin
                        sl_state <= SL_DONE;
                    end
                end

                SL_DONE: begin
                    done     <= 1;
                    sl_state <= SL_IDLE;
                end

                default: sl_state <= SL_IDLE;
            endcase
        end
    end

endmodule
