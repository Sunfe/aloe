module fp32_binary_serial #(
    parameter bit MULTIPLY = 1'b1,

    // Conservative settling budget for the initial serial design.
    // This is NOT a declaration of the DSP core's exact latency.
    parameter int unsigned SETTLE_CYCLES = 16
) (
    input  logic        clk,
    input  logic        reset,

    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,

    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result
);

    localparam int unsigned COUNT_W =
        (SETTLE_CYCLES < 2) ? 1 : $clog2(SETTLE_CYCLES);

    localparam logic [COUNT_W-1:0] COUNT_INIT =
        SETTLE_CYCLES - 1;

    logic [31:0] a_q;
    logic [31:0] b_q;
    logic [31:0] core_result;

    logic busy_q;
    logic [COUNT_W-1:0] count_q;

    // No new request while calculating or holding an unread result.
    assign in_ready = !reset && !busy_q && !out_valid;

    generate
        if (MULTIPLY) begin : g_mul
            gemv_fp32_mul_ip u_core (
                .clk          (clk),
                .ena          (3'b111),
                .clr          ({2{reset}}),

                .fp32_mult_a  (a_q),
                .fp32_mult_b  (b_q),
                .fp32_result  (core_result)
            );
        end else begin : g_add
            gemv_fp32_add_ip u_core (
                .clk          (clk),
                .ena          (3'b111),
                .clr          ({2{reset}}),

                .fp32_adder_a  (a_q),
                .fp32_adder_b  (b_q),
                .fp32_result  (core_result)
            );
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (reset) begin
            a_q       <= 32'b0;
            b_q       <= 32'b0;
            busy_q    <= 1'b0;
            count_q   <= '0;
            out_valid <= 1'b0;
            result    <= 32'b0;
        end else begin
            // Retire a result only when the consumer accepts it.
            if (out_valid && out_ready)
                out_valid <= 1'b0;

            // Capture exactly one pair of operands.
            if (in_valid && in_ready) begin
                a_q     <= a;
                b_q     <= b;
                busy_q  <= 1'b1;
                count_q <= COUNT_INIT;
            end else if (busy_q) begin
                if (count_q == '0) begin
                    result    <= core_result;
                    out_valid <= 1'b1;
                    busy_q    <= 1'b0;
                end else begin
                    count_q <= count_q - 1'b1;
                end
            end
        end
    end

    // synthesis translate_off
    initial begin
        if (SETTLE_CYCLES < 16)
            $fatal(1,
                "Initial serial wrapper requires SETTLE_CYCLES >= 16");
    end
    // synthesis translate_on

endmodule


module fp32_mul #(
    parameter int unsigned SETTLE_CYCLES = 16
) (
    input  logic        clk,
    input  logic        reset,

    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,

    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result
);

    fp32_binary_serial #(
        .MULTIPLY      (1'b1),
        .SETTLE_CYCLES (SETTLE_CYCLES)
    ) u_serial (
        .clk       (clk),
        .reset     (reset),
        .in_valid  (in_valid),
        .in_ready  (in_ready),
        .a         (a),
        .b         (b),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .result    (result)
    );

endmodule


module fp32_add #(
    parameter int unsigned SETTLE_CYCLES = 16
) (
    input  logic        clk,
    input  logic        reset,

    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,

    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result
);

    fp32_binary_serial #(
        .MULTIPLY      (1'b0),
        .SETTLE_CYCLES (SETTLE_CYCLES)
    ) u_serial (
        .clk       (clk),
        .reset     (reset),
        .in_valid  (in_valid),
        .in_ready  (in_ready),
        .a         (a),
        .b         (b),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .result    (result)
    );

endmodule