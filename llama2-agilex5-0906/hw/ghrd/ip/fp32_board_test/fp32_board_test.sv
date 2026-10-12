module fp32_board_test #(
    parameter int unsigned FP32_SETTLE_CYCLES = 16
) (
    input  logic        clk,
    input  logic        reset,

    // Avalon-MM CSR.
    // WORD address: 0,1,2,... correspond to byte offsets 0,4,8,...
    input  logic [3:0]  avs_address,
    input  logic        avs_read,
    input  logic        avs_write,
    input  logic [31:0] avs_writedata,
    input  logic [3:0]  avs_byteenable,
    output logic [31:0] avs_readdata,
    output logic        avs_waitrequest
);

    localparam logic [31:0] VERSION = 32'h4650_0001;

    typedef enum logic [1:0] {
        ST_IDLE = 2'd0,
        ST_SEND = 2'd1,
        ST_WAIT = 2'd2
    } state_t;

    state_t state;

    logic [31:0] a_reg;
    logic [31:0] b_reg;

    // Operands latched at START.
    logic [31:0] a_run;
    logic [31:0] b_run;
    logic        op_add;

    logic        done;
    logic [31:0] result_reg;
    logic [31:0] cycle_count;
    logic [31:0] completed_count;

    logic        busy;

    logic        mul_in_ready;
    logic        mul_out_valid;
    logic [31:0] mul_result;

    logic        add_in_ready;
    logic        add_out_valid;
    logic [31:0] add_result;

    assign busy = (state != ST_IDLE);

    // CSR accesses never wait for the arithmetic operation.
    assign avs_waitrequest = 1'b0;

    fp32_mul #(
        .SETTLE_CYCLES(FP32_SETTLE_CYCLES)
    ) u_mul (
        .clk       (clk),
        .reset     (reset),

        .in_valid  ((state == ST_SEND) && !op_add),
        .in_ready  (mul_in_ready),
        .a         (a_run),
        .b         (b_run),

        .out_valid (mul_out_valid),
        .out_ready ((state == ST_WAIT) && !op_add),
        .result    (mul_result)
    );

    fp32_add #(
        .SETTLE_CYCLES(FP32_SETTLE_CYCLES)
    ) u_add (
        .clk       (clk),
        .reset     (reset),

        .in_valid  ((state == ST_SEND) && op_add),
        .in_ready  (add_in_ready),
        .a         (a_run),
        .b         (b_run),

        .out_valid (add_out_valid),
        .out_ready ((state == ST_WAIT) && op_add),
        .result    (add_result)
    );

    // Combinational CSR read, readLatency = 0.
    always_comb begin
        avs_readdata = 32'b0;

        if (avs_read) begin
            case (avs_address)
                4'h0: avs_readdata = {30'b0, op_add, 1'b0};
                4'h1: avs_readdata = {30'b0, done, busy};
                4'h2: avs_readdata = a_reg;
                4'h3: avs_readdata = b_reg;
                4'h4: avs_readdata = result_reg;
                4'h5: avs_readdata = cycle_count;
                4'h6: avs_readdata = VERSION;
                4'h7: avs_readdata = completed_count;
                4'h8: avs_readdata = {29'b0, op_add, state};
                default: avs_readdata = 32'b0;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            state           <= ST_IDLE;
            a_reg           <= 32'b0;
            b_reg           <= 32'b0;
            a_run           <= 32'b0;
            b_run           <= 32'b0;
            op_add          <= 1'b0;
            done            <= 1'b0;
            result_reg      <= 32'b0;
            cycle_count     <= 32'b0;
            completed_count <= 32'b0;
        end else begin

            if (busy && cycle_count != 32'hFFFF_FFFF)
                cycle_count <= cycle_count + 32'd1;

            case (state)

                ST_IDLE: begin
                    if (avs_write) begin
                        case (avs_address)

                            4'h0: begin
                                if (avs_byteenable[0]) begin
                                    // START takes priority over CLEAR.
                                    if (avs_writedata[0]) begin
                                        a_run       <= a_reg;
                                        b_run       <= b_reg;
                                        op_add      <= avs_writedata[1];
                                        done        <= 1'b0;
                                        result_reg  <= 32'b0;
                                        cycle_count <= 32'b0;
                                        state       <= ST_SEND;
                                    end else if (avs_writedata[2]) begin
                                        done        <= 1'b0;
                                        result_reg  <= 32'b0;
                                        cycle_count <= 32'b0;
                                    end
                                end
                            end

                            4'h2: begin
                                a_reg <= merge32(
                                    a_reg,
                                    avs_writedata,
                                    avs_byteenable
                                );
                            end

                            4'h3: begin
                                b_reg <= merge32(
                                    b_reg,
                                    avs_writedata,
                                    avs_byteenable
                                );
                            end

                            default: ;
                        endcase
                    end
                end

                ST_SEND: begin
                    if ((!op_add && mul_in_ready) ||
                        ( op_add && add_in_ready))
                        state <= ST_WAIT;
                end

                ST_WAIT: begin
                    if ((!op_add && mul_out_valid) ||
                        ( op_add && add_out_valid)) begin

                        result_reg <= op_add ? add_result : mul_result;
                        done <= 1'b1;
                        completed_count <= completed_count + 32'd1;
                        state <= ST_IDLE;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                    done  <= 1'b0;
                end

            endcase
        end
    end

    function automatic logic [31:0] merge32 (
        input logic [31:0] old_value,
        input logic [31:0] new_value,
        input logic [3:0]  byte_enable
    );
        merge32 = old_value;

        for (int i = 0; i < 4; i++) begin
            if (byte_enable[i])
                merge32[i*8 +: 8] = new_value[i*8 +: 8];
        end
    endfunction

endmodule