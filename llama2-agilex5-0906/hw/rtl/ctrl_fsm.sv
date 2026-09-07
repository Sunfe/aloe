// 顶层控制 FSM: start → 启动 w_reader 和 pe_array → done
module ctrl_fsm
  import matvec_pkg::*;
(
  input  logic        clk,
  input  logic        rst_n,

  // CSR 输入
  input  logic        start,
  input  logic [31:0] n_rows,
  input  logic [31:0] d_cols,

  // w_reader 控制
  output logic        wr_start,
  input  logic        wr_busy,
  input  logic        wr_err,

  // pe_array 控制
  output logic        pe_start,
  input  logic        pe_busy,
  input  logic        pe_done,

  // CSR 输出
  output logic        busy,
  output logic        done_pulse,
  output logic        err_pulse
);

  typedef enum logic [1:0] {IDLE, RUN, WAIT_DONE, ERROR} state_t;
  state_t state;

  assign busy = (state != IDLE);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      wr_start <= 1'b0;
      pe_start <= 1'b0;
      done_pulse <= 1'b0;
      err_pulse  <= 1'b0;
    end else begin
      done_pulse <= 1'b0;
      err_pulse  <= 1'b0;
      wr_start   <= 1'b0;
      pe_start   <= 1'b0;

      case (state)
        IDLE: begin
          if (start) begin
            wr_start <= 1'b1;
            pe_start <= 1'b1;
            state <= RUN;
          end
        end

        RUN: begin
          // 检查错误
          if (wr_err) begin
            err_pulse <= 1'b1;
            state <= ERROR;
          end
          // 等 pe_array 完成 (w_reader 通常会先结束)
          if (pe_done) begin
            done_pulse <= 1'b1;
            state <= IDLE;
          end
        end

        ERROR: begin
          // 停在错误状态，需要软件重置 (写 STATUS W1C)
          if (start) state <= IDLE;  // 或者复位才能清
        end
      endcase
    end
  end

endmodule