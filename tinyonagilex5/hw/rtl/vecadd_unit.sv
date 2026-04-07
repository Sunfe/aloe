// vecadd_unit.sv
// 向量加法: out = a + b
// 逐元素乘法: out = a * b (复用同一模块)

module vecadd_unit #(
    parameter MAX_DIM = 172,
    parameter DATA_W  = 16
)(
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       start,
    input  logic                       is_mul,   // 0=加法, 1=乘法
    input  logic [9:0]                 len,
    input  logic signed [DATA_W-1:0]   vec_a   [0:MAX_DIM-1],
    input  logic signed [DATA_W-1:0]   vec_b   [0:MAX_DIM-1],
    output logic signed [31:0]         vec_out [0:MAX_DIM-1],
    output logic                       done
);

    logic [9:0] idx;

    typedef enum logic [1:0] {
        VA_IDLE,
        VA_COMPUTE,
        VA_DONE
    } va_state_t;

    va_state_t va_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            va_state <= VA_IDLE;
            done     <= 0;
        end else begin
            case (va_state)
                VA_IDLE: begin
                    done <= 0;
                    if (start) begin
                        idx      <= 0;
                        va_state <= VA_COMPUTE;
                    end
                end

                VA_COMPUTE: begin
                    if (is_mul)
                        vec_out[idx] <= ($signed(vec_a[idx]) *
                                         $signed(vec_b[idx]));
                    else
                        vec_out[idx] <= {{(32-DATA_W){vec_a[idx][DATA_W-1]}}, vec_a[idx]} +
                                        {{(32-DATA_W){vec_b[idx][DATA_W-1]}}, vec_b[idx]};

                    idx <= idx + 1;
                    if (idx + 1 >= len) begin
                        va_state <= VA_DONE;
                    end
                end

                VA_DONE: begin
                    done     <= 1;
                    va_state <= VA_IDLE;
                end

                default: va_state <= VA_IDLE;
            endcase
        end
    end

endmodule
