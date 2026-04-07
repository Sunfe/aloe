// rope_unit.sv
// RoPE 旋转位置编码
// 对每对 (x[2i], x[2i+1]) 做 2D 旋转:
//   x'[2i]   = x[2i]*cos(θ) - x[2i+1]*sin(θ)
//   x'[2i+1] = x[2i]*sin(θ) + x[2i+1]*cos(θ)
// θ = pos * freq[i], freq[i] = 1/10000^(2i/dim)
//
// FPGA: 预计算 sin/cos 表存入 BRAM
//       表大小: CTX_LEN * (DIM/2) * 2 = 128 * 32 * 2 = 8192 项

module rope_unit #(
    parameter DIM    = 64,
    parameter DATA_W = 16,
    parameter FRAC_W = 8,
    parameter CTX_LEN = 128
)(
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       start,
    input  logic [9:0]                 dim,
    input  logic [9:0]                 pos,
    input  logic signed [DATA_W-1:0]   vec_in  [0:DIM-1],
    output logic signed [31:0]         vec_out [0:DIM-1],
    output logic                       done
);

    // 预计算的 sin/cos 表
    // cos_table[pos][pair_idx], sin_table[pos][pair_idx]
    logic signed [DATA_W-1:0] cos_table [0:CTX_LEN-1][0:DIM/2-1];
    logic signed [DATA_W-1:0] sin_table [0:CTX_LEN-1][0:DIM/2-1];

    // 初始化 (综合时预计算)
    initial begin
        for (int p = 0; p < CTX_LEN; p++) begin
            for (int i = 0; i < DIM/2; i++) begin
                automatic real freq = 1.0 / (10000.0 ** (real'(2*i) / real'(DIM)));
                automatic real theta = real'(p) * freq;
                cos_table[p][i] = DATA_W'($rtoi($cos(theta) * (2.0 ** FRAC_W)));
                sin_table[p][i] = DATA_W'($rtoi($sin(theta) * (2.0 ** FRAC_W)));
            end
        end
    end

    typedef enum logic [1:0] {
        RP_IDLE,
        RP_ROTATE,
        RP_DONE
    } rp_state_t;

    rp_state_t rp_state;
    logic [9:0] pair_idx;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rp_state <= RP_IDLE;
            done     <= 0;
        end else begin
            case (rp_state)
                RP_IDLE: begin
                    done <= 0;
                    if (start) begin
                        pair_idx <= 0;
                        rp_state <= RP_ROTATE;
                    end
                end

                RP_ROTATE: begin
                    // 读取 cos/sin
                    automatic logic signed [DATA_W-1:0] c = cos_table[pos][pair_idx];
                    automatic logic signed [DATA_W-1:0] s = sin_table[pos][pair_idx];
                    automatic logic signed [DATA_W-1:0] x0 = vec_in[2*pair_idx];
                    automatic logic signed [DATA_W-1:0] x1 = vec_in[2*pair_idx+1];

                    // 旋转
                    vec_out[2*pair_idx]   <= ($signed(x0)*$signed(c) -
                                              $signed(x1)*$signed(s)) >>> FRAC_W;
                    vec_out[2*pair_idx+1] <= ($signed(x0)*$signed(s) +
                                              $signed(x1)*$signed(c)) >>> FRAC_W;

                    pair_idx <= pair_idx + 1;
                    if (pair_idx + 1 >= dim/2) begin
                        rp_state <= RP_DONE;
                    end
                end

                RP_DONE: begin
                    done     <= 1;
                    rp_state <= RP_IDLE;
                end

                default: rp_state <= RP_IDLE;
            endcase
        end
    end

endmodule
