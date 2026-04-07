// matmul_unit.sv
// 矩阵-向量乘法: out[j] = Σ_i vec_in[i] * weight[i][j]
//
// 实现策略:
//   - 外层循环 (j=0..out_dim): 每周期算一个输出元素
//   - 内层循环 (i=0..in_dim): 用 PARALLEL_MACS 个并行 MAC 展开
//   - 总延迟: out_dim * ceil(in_dim / PARALLEL_MACS) 周期
//
// Agilex 5 资源:
//   - DSP: 每个 MAC 用 1 个 DSP block (支持 18x18 乘法)
//   - PARALLEL_MACS=16: 用 16 个 DSP，延迟 = 172 * 4 = 688 周期
//   - PARALLEL_MACS=32: 用 32 个 DSP，延迟 = 172 * 2 = 344 周期
//   - Agilex 5 有 ~1500+ DSP blocks，资源充裕

module matmul_unit #(
    parameter MAX_DIM       = 172,
    parameter DATA_W        = 16,
    parameter FRAC_W        = 8,
    parameter PARALLEL_MACS = 16    // 并行乘累加单元数
)(
    input  logic                          clk,
    input  logic                          rst_n,
    input  logic                          start,
    input  logic [9:0]                    in_dim,
    input  logic [9:0]                    out_dim,
    input  logic signed [DATA_W-1:0]      vec_in   [0:MAX_DIM-1],
    input  logic signed [DATA_W-1:0]      weight   [0:MAX_DIM-1],  // 一行，由 DMA 逐行送入
    output logic signed [31:0]            vec_out  [0:MAX_DIM-1],
    output logic                          done
);

    // 状态机
    typedef enum logic [2:0] {
        M_IDLE,
        M_COMPUTE,
        M_ACCUMULATE,
        M_NEXT_OUT,
        M_DONE
    } mstate_t;

    mstate_t mstate;

    logic [9:0] out_idx;    // 当前输出元素索引
    logic [9:0] in_idx;     // 当前输入元素索引
    logic signed [31:0] accumulator;

    // 并行 MAC 阵列
    logic signed [31:0] mac_results [0:PARALLEL_MACS-1];

    genvar g;
    generate
        for (g = 0; g < PARALLEL_MACS; g++) begin : MAC_ARRAY
            always_comb begin
                if ((in_idx + g) < in_dim) begin
                    // 16-bit × 16-bit = 32-bit
                    mac_results[g] = $signed(vec_in[in_idx + g]) *
                                     $signed(weight[in_idx + g]);
                end else begin
                    mac_results[g] = 0;
                end
            end
        end
    endgenerate

    // MAC 结果求和 (加法树)
    function automatic logic signed [31:0] sum_macs();
        logic signed [31:0] s;
        s = 0;
        for (int i = 0; i < PARALLEL_MACS; i++)
            s = s + mac_results[i];
        return s;
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mstate      <= M_IDLE;
            done        <= 0;
            out_idx     <= 0;
            in_idx      <= 0;
            accumulator <= 0;
        end else begin
            case (mstate)
                M_IDLE: begin
                    done <= 0;
                    if (start) begin
                        out_idx     <= 0;
                        in_idx      <= 0;
                        accumulator <= 0;
                        mstate      <= M_COMPUTE;
                    end
                end

                M_COMPUTE: begin
                    accumulator <= accumulator + sum_macs();
                    in_idx      <= in_idx + PARALLEL_MACS;

                    if (in_idx + PARALLEL_MACS >= in_dim) begin
                        mstate <= M_ACCUMULATE;
                    end
                end

                M_ACCUMULATE: begin
                    // 存储当前输出元素 (定点数右移恢复小数位)
                    vec_out[out_idx] <= (accumulator + sum_macs()) >>> FRAC_W;
                    mstate           <= M_NEXT_OUT;
                end

                M_NEXT_OUT: begin
                    accumulator <= 0;
                    in_idx      <= 0;
                    out_idx     <= out_idx + 1;
                    if (out_idx + 1 >= out_dim) begin
                        mstate <= M_DONE;
                    end else begin
                        mstate <= M_COMPUTE;
                    end
                end

                M_DONE: begin
                    done   <= 1;
                    mstate <= M_IDLE;
                end

                default: mstate <= M_IDLE;
            endcase
        end
    end

endmodule