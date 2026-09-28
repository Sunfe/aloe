module gemv_4x4_test #(
    parameter int unsigned AXI_ADDR_WIDTH      = 64,
    parameter int unsigned AXI_DATA_WIDTH      = 128,
    parameter int unsigned AXI_ID_WIDTH        = 4,
    parameter int unsigned AXI_PROT_VALUE      = 2,
    parameter int unsigned FP32_SETTLE_CYCLES  = 16
) (
    input  logic clk,
    input  logic reset,

    // ------------------------------------------------------------
    // AXI4-Lite CSR subordinate
    // 12-bit byte address, 32-bit data
    // ------------------------------------------------------------

    input  logic [11:0] csr_awaddr,
    input logic [2:0]  csr_awprot,
    input logic        csr_awvalid,
    output logic        csr_awready,

    input logic [31:0] csr_wdata,
    input logic [3:0]  csr_wstrb,
    input logic        csr_wvalid,
    output logic        csr_wready,

    output logic [1:0] csr_bresp,
    output logic        csr_bvalid,
    input logic         csr_bready,

    input logic [11:0] csr_araddr,
    input logic [2:0]  csr_arprot,
    input logic        csr_arvalid,
    output logic        csr_arready,

    output logic [31:0] csr_rdata,
    output logic [1:0]  csr_rresp,
    output logic        csr_rvalid,
    input logic         csr_rready,

    // ------------------------------------------------------------
    // AXI4 memory manager
    // 128-bit data, single-beat, one outstanding transaction
    // ------------------------------------------------------------

    output logic [AXI_ID_WIDTH-1:0]     axi_awid,
    output logic [AXI_ADDR_WIDTH-1:0]   axi_awaddr,
    output logic [7:0]                  axi_awlen,
    output logic [2:0]                  axi_awsize,
    output logic [1:0]                  axi_awburst,
    output logic                        axi_awlock,
    output logic [3:0]                  axi_awcache,
    output logic [2:0]                  axi_awprot,
    output logic [3:0]                  axi_awqos,
    output logic                        axi_awvalid,
    input  logic                        axi_awready,

    output logic [AXI_DATA_WIDTH-1:0]   axi_wdata,
    output logic [AXI_DATA_WIDTH/8-1:0] axi_wstrb,
    output logic                        axi_wlast,
    output logic                        axi_wvalid,
    input logic                         axi_wready,

    input logic [AXI_ID_WIDTH-1:0]      axi_bid,
    input logic [1:0]                   axi_bresp,
    input logic                         axi_bvalid,
    output logic                        axi_bready,

    output logic [AXI_ID_WIDTH-1:0]     axi_arid,
    output logic [AXI_ADDR_WIDTH-1:0]   axi_araddr,
    output logic [7:0]                  axi_arlen,
    output logic [2:0]                  axi_arsize,
    output logic [1:0]                  axi_arburst,
    output logic                        axi_arlock,
    output logic [3:0]                  axi_arcache,
    output logic [2:0]                  axi_arprot,
    output logic [3:0]                  axi_arqos,
    output logic                        axi_arvalid,
    input logic                         axi_arready,

    input logic [AXI_ID_WIDTH-1:0]      axi_rid,
    input logic [AXI_DATA_WIDTH-1:0]    axi_rdata,
    input logic [1:0]                   axi_rresp,
    input logic                         axi_rlast,
    input logic                         axi_rvalid,
    output logic                        axi_rready
);

    localparam logic [1:0] RESP_OKAY   = 2'b00;
    localparam logic [1:0] RESP_SLVERR = 2'b10;

    localparam int unsigned BYTES_PER_BEAT =
        AXI_DATA_WIDTH / 8;

    localparam int unsigned BYTE_SHIFT =
        $clog2(BYTES_PER_BEAT);

    localparam logic [2:0] AXI_SIZE =
        BYTE_SHIFT;

    localparam logic [31:0] VERSION =
        32'h474D_5631;  // "GMV1"

    typedef enum logic [3:0] {
        ST_IDLE        = 4'd0,

        ST_READ_X_AR   = 4'd1,
        ST_READ_X_DATA = 4'd2,

        ST_READ_W_AR   = 4'd3,
        ST_READ_W_DATA = 4'd4,

        ST_MUL_SEND    = 4'd5,
        ST_MUL_WAIT    = 4'd6,

        ST_ADD_SEND    = 4'd7,
        ST_ADD_WAIT    = 4'd8,

        ST_WRITE_SEND  = 4'd9,
        ST_WRITE_RESP  = 4'd10
    } state_t;

    state_t state;

    // ============================================================
    // CSR registers
    // ============================================================

    logic [63:0] w_addr_reg;
    logic [63:0] x_addr_reg;
    logic [63:0] y_addr_reg;

    logic [31:0] cycle_count;

    logic        done;
    logic        err_param;
    logic        err_resp;
    logic        err_protocol;

    logic        busy;
    logic        error_flag;
    logic [31:0] status_word;
    logic [31:0] debug_word;

    // ============================================================
    // AXI4-Lite CSR write channel
    // ============================================================

    logic        csr_aw_have;
    logic        csr_w_have;
    logic [11:0] csr_aw_hold;
    logic [31:0] csr_wdata_hold;
    logic [3:0]  csr_wstrb_hold;

    logic        csr_wr_commit;
    logic        csr_wr_allowed;
    logic        csr_wr_ok;

    logic        csr_cmd_start;
    logic        csr_cmd_clear;

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

    assign busy = (state != ST_IDLE);

    assign error_flag =
        err_param || err_resp || err_protocol;

    /*
     * STATUS:
     *
     * bit 0 = BUSY
     * bit 1 = DONE
     * bit 2 = ERROR
     * bit 3 = PARAM_ERROR
     * bit 4 = RESP_ERROR
     * bit 5 = PROTOCOL_ERROR
     */
    assign status_word = {
        26'b0,
        err_protocol,
        err_resp,
        err_param,
        error_flag,
        done,
        busy
    };

    /*
     * DEBUG:
     *
     * bits [3:0]   = state
     * bits [5:4]   = row_index
     * bits [7:6]   = col_index
     * bit  [8]     = read_bad_seen
     * bit  [9]     = mul_out_valid
     * bit  [10]    = add_out_valid
     */
    always_comb begin
        debug_word = 32'b0;
        debug_word[3:0]  = state;
        debug_word[5:4]  = row_index;
        debug_word[7:6]  = col_index;
        debug_word[8]    = read_bad_seen;
        debug_word[9]    = mul_out_valid;
        debug_word[10]   = add_out_valid;
    end

    assign csr_awready =
        !reset &&
        !csr_aw_have &&
        !csr_bvalid;

    assign csr_wready =
        !reset &&
        !csr_w_have &&
        !csr_bvalid;

    assign csr_wr_commit =
        csr_aw_have &&
        csr_w_have &&
        !csr_bvalid;

    /*
     * Configuration and commands are accepted only while idle.
     */
    always_comb begin
        csr_wr_allowed = 1'b0;

        if (!busy) begin
            case (csr_aw_hold)
                12'h000, // CTRL
                12'h008, // W_ADDR_LOW
                12'h00C, // W_ADDR_HIGH
                12'h010, // X_ADDR_LOW
                12'h014, // X_ADDR_HIGH
                12'h018, // Y_ADDR_LOW
                12'h01C: // Y_ADDR_HIGH
                    csr_wr_allowed = 1'b1;

                default:
                    csr_wr_allowed = 1'b0;
            endcase
        end
    end

    assign csr_wr_ok =
        csr_wr_commit &&
        csr_wr_allowed;

    assign csr_cmd_start =
        csr_wr_ok &&
        (csr_aw_hold == 12'h000) &&
        csr_wstrb_hold[0] &&
        csr_wdata_hold[0];

    /*
     * START has priority over CLEAR.
     */
    assign csr_cmd_clear =
        csr_wr_ok &&
        (csr_aw_hold == 12'h000) &&
        csr_wstrb_hold[0] &&
        csr_wdata_hold[2] &&
        !csr_wdata_hold[0];

    /*
     * AXI4-Lite write channel.
     *
     * AW and W may arrive in either order.
     */
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            csr_aw_have    <= 1'b0;
            csr_w_have     <= 1'b0;
            csr_aw_hold    <= 12'b0;
            csr_wdata_hold <= 32'b0;
            csr_wstrb_hold <= 4'b0;

            csr_bvalid     <= 1'b0;
            csr_bresp      <= RESP_OKAY;

            w_addr_reg     <= 64'b0;
            x_addr_reg     <= 64'b0;
            y_addr_reg     <= 64'b0;
        end else begin
            if (csr_bvalid && csr_bready)
                csr_bvalid <= 1'b0;

            if (csr_awvalid && csr_awready) begin
                csr_aw_hold <= csr_awaddr;
                csr_aw_have <= 1'b1;
            end

            if (csr_wvalid && csr_wready) begin
                csr_wdata_hold <= csr_wdata;
                csr_wstrb_hold <= csr_wstrb;
                csr_w_have     <= 1'b1;
            end

            if (csr_wr_commit) begin
                csr_aw_have <= 1'b0;
                csr_w_have  <= 1'b0;

                csr_bvalid <= 1'b1;
                csr_bresp  <= csr_wr_allowed ?
                              RESP_OKAY :
                              RESP_SLVERR;

                if (csr_wr_allowed) begin
                    case (csr_aw_hold)
                        12'h008: begin
                            w_addr_reg[31:0] <= merge32(
                                w_addr_reg[31:0],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );
                        end

                        12'h00C: begin
                            w_addr_reg[63:32] <= merge32(
                                w_addr_reg[63:32],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );
                        end

                        12'h010: begin
                            x_addr_reg[31:0] <= merge32(
                                x_addr_reg[31:0],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );
                        end

                        12'h014: begin
                            x_addr_reg[63:32] <= merge32(
                                x_addr_reg[63:32],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );
                        end

                        12'h018: begin
                            y_addr_reg[31:0] <= merge32(
                                y_addr_reg[31:0],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );
                        end

                        12'h01C: begin
                            y_addr_reg[63:32] <= merge32(
                                y_addr_reg[63:32],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );
                        end

                        12'h000: begin
                            /*
                             * CTRL is a command register.
                             * START and CLEAR are consumed by the
                             * GEMV state machine.
                             */
                        end

                        default: begin
                        end
                    endcase
                end
            end
        end
    end

    // ============================================================
    // AXI4-Lite CSR read channel
    // ============================================================

    logic [31:0] csr_read_data;
    logic [1:0]  csr_read_resp;

    assign csr_arready =
        !reset &&
        !csr_rvalid;

    always_comb begin
        csr_read_data = 32'b0;
        csr_read_resp = RESP_OKAY;

        case (csr_araddr)
            12'h000: csr_read_data = 32'b0;
            12'h004: csr_read_data = status_word;

            12'h008: csr_read_data = w_addr_reg[31:0];
            12'h00C: csr_read_data = w_addr_reg[63:32];

            12'h010: csr_read_data = x_addr_reg[31:0];
            12'h014: csr_read_data = x_addr_reg[63:32];

            12'h018: csr_read_data = y_addr_reg[31:0];
            12'h01C: csr_read_data = y_addr_reg[63:32];

            12'h020: csr_read_data = cycle_count;
            12'h024: csr_read_data = VERSION;
            12'h028: csr_read_data = debug_word;

            default: begin
                csr_read_data = 32'b0;
                csr_read_resp = RESP_SLVERR;
            end
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            csr_rvalid <= 1'b0;
            csr_rdata  <= 32'b0;
            csr_rresp  <= RESP_OKAY;
        end else begin
            if (csr_rvalid && csr_rready)
                csr_rvalid <= 1'b0;

            if (csr_arvalid && csr_arready) begin
                csr_rvalid <= 1'b1;
                csr_rdata  <= csr_read_data;
                csr_rresp  <= csr_read_resp;
            end
        end
    end

    // ============================================================
    // Configuration validation
    // ============================================================

    logic [64:0] w_last_addr;
    logic [64:0] x_last_addr;
    logic [64:0] y_last_addr;

    logic cfg_invalid;

    /*
     * W occupies 64 bytes:
     *
     * W[0][0..3] -> W_ADDR + 0x00
     * W[1][0..3] -> W_ADDR + 0x10
     * W[2][0..3] -> W_ADDR + 0x20
     * W[3][0..3] -> W_ADDR + 0x30
     */
    assign w_last_addr =
        {1'b0, w_addr_reg} + 65'd63;

    /*
     * X occupies one 16-byte beat.
     */
    assign x_last_addr =
        {1'b0, x_addr_reg} + 65'd15;

    /*
     * Y occupies one 16-byte beat.
     */
    assign y_last_addr =
        {1'b0, y_addr_reg} + 65'd15;

    always_comb begin
        cfg_invalid = 1'b0;

        if (w_addr_reg[3:0] != 4'b0)
            cfg_invalid = 1'b1;

        if (x_addr_reg[3:0] != 4'b0)
            cfg_invalid = 1'b1;

        if (y_addr_reg[3:0] != 4'b0)
            cfg_invalid = 1'b1;

        if (w_last_addr[64])
            cfg_invalid = 1'b1;

        if (x_last_addr[64])
            cfg_invalid = 1'b1;

        if (y_last_addr[64])
            cfg_invalid = 1'b1;

        if (AXI_ADDR_WIDTH == 32) begin
            if (w_addr_reg[63:32] != 32'b0)
                cfg_invalid = 1'b1;

            if (x_addr_reg[63:32] != 32'b0)
                cfg_invalid = 1'b1;

            if (y_addr_reg[63:32] != 32'b0)
                cfg_invalid = 1'b1;
        end
    end

    // ============================================================
    // Active GEMV registers
    // ============================================================

    logic [AXI_ADDR_WIDTH-1:0] w_addr_q;
    logic [AXI_ADDR_WIDTH-1:0] x_addr_q;
    logic [AXI_ADDR_WIDTH-1:0] y_addr_q;

    logic [1:0] row_index;
    logic [1:0] col_index;

    logic [AXI_ADDR_WIDTH-1:0] row_offset;
    logic [AXI_ADDR_WIDTH-1:0] current_w_addr;

    always_comb begin
        row_offset = '0;
        row_offset = row_index;
        row_offset = row_offset << 4;
    end

    assign current_w_addr =
        w_addr_q + row_offset;

    // ============================================================
    // Local FP32 data
    // ============================================================

    logic [31:0] x_value [0:3];
    logic [31:0] w_row   [0:3];
    logic [31:0] y_value [0:3];

    logic [31:0] accumulator;
    logic [31:0] product;

    // ============================================================
    // FP32 multiplier
    // ============================================================

    logic        mul_in_valid;
    logic        mul_in_ready;
    logic        mul_out_valid;
    logic        mul_out_ready;
    logic [31:0] mul_result;

    assign mul_in_valid =
        (state == ST_MUL_SEND);

    assign mul_out_ready =
        (state == ST_MUL_WAIT);

    fp32_mul #(
        .SETTLE_CYCLES(FP32_SETTLE_CYCLES)
    ) u_mul (
        .clk       (clk),
        .reset     (reset),

        .in_valid  (mul_in_valid),
        .in_ready  (mul_in_ready),
        .a         (w_row[col_index]),
        .b         (x_value[col_index]),

        .out_valid (mul_out_valid),
        .out_ready (mul_out_ready),
        .result    (mul_result)
    );

    // ============================================================
    // FP32 adder
    // ============================================================

    logic        add_in_valid;
    logic        add_in_ready;
    logic        add_out_valid;
    logic        add_out_ready;
    logic [31:0] add_result;

    assign add_in_valid =
        (state == ST_ADD_SEND);

    assign add_out_ready =
        (state == ST_ADD_WAIT);

    fp32_add #(
        .SETTLE_CYCLES(FP32_SETTLE_CYCLES)
    ) u_add (
        .clk       (clk),
        .reset     (reset),

        .in_valid  (add_in_valid),
        .in_ready  (add_in_ready),
        .a         (accumulator),
        .b         (product),

        .out_valid (add_out_valid),
        .out_ready (add_out_ready),
        .result    (add_result)
    );

    // ============================================================
    // AXI transaction status
    // ============================================================

    logic aw_pending;
    logic w_pending;

    logic aw_fire;
    logic w_fire;
    logic b_fire;
    logic ar_fire;
    logic r_fire;

    logic b_bad_now;
    logic r_bad_now;
    logic read_bad_seen;

    assign aw_fire =
        axi_awvalid && axi_awready;

    assign w_fire =
        axi_wvalid && axi_wready;

    assign b_fire =
        axi_bvalid && axi_bready;

    assign ar_fire =
        axi_arvalid && axi_arready;

    assign r_fire =
        axi_rvalid && axi_rready;

    assign b_bad_now =
        (axi_bresp != RESP_OKAY) ||
        (axi_bid != '0);

    assign r_bad_now =
        (axi_rresp != RESP_OKAY) ||
        (axi_rid != '0) ||
        !axi_rlast;

    // ============================================================
    // AXI4 manager outputs
    // ============================================================

    // ---------- Write address channel ----------

    assign axi_awid    = '0;
    assign axi_awaddr  = y_addr_q;
    assign axi_awlen   = 8'd0;
    assign axi_awsize  = AXI_SIZE;
    assign axi_awburst = 2'b01;
    assign axi_awlock  = 1'b0;
    assign axi_awcache = 4'b0010;
    assign axi_awprot  = AXI_PROT_VALUE[2:0];
    assign axi_awqos   = 4'b0000;

    assign axi_awvalid =
        (state == ST_WRITE_SEND) &&
        aw_pending;

    // ---------- Write data channel ----------

    /*
     * The four output values are written as one 128-bit beat:
     *
     * axi_wdata[31:0]    = y[0]
     * axi_wdata[63:32]   = y[1]
     * axi_wdata[95:64]   = y[2]
     * axi_wdata[127:96]  = y[3]
     */
    always_comb begin
        axi_wdata = '0;

        for (int k = 0; k < 4; k++) begin
            axi_wdata[k*32 +: 32] = y_value[k];
        end
    end

    assign axi_wstrb  = '1;
    assign axi_wlast  = 1'b1;

    assign axi_wvalid =
        (state == ST_WRITE_SEND) &&
        w_pending;

    // ---------- Write response channel ----------

    assign axi_bready =
        (state == ST_WRITE_RESP);

    // ---------- Read address channel ----------

    assign axi_arid    = '0;
    assign axi_araddr  =
        (state == ST_READ_X_AR) ?
        x_addr_q :
        current_w_addr;

    assign axi_arlen   = 8'd0;
    assign axi_arsize  = AXI_SIZE;
    assign axi_arburst = 2'b01;
    assign axi_arlock  = 1'b0;
    assign axi_arcache = 4'b0010;
    assign axi_arprot  = AXI_PROT_VALUE[2:0];
    assign axi_arqos   = 4'b0000;

    assign axi_arvalid =
        (state == ST_READ_X_AR) ||
        (state == ST_READ_W_AR);

    // ---------- Read data channel ----------

    assign axi_rready =
        (state == ST_READ_X_DATA) ||
        (state == ST_READ_W_DATA);

    // ============================================================
    // GEMV state machine
    // ============================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= ST_IDLE;

            w_addr_q <= '0;
            x_addr_q <= '0;
            y_addr_q <= '0;

            row_index <= 2'b0;
            col_index <= 2'b0;

            accumulator <= 32'b0;
            product     <= 32'b0;

            for (int k = 0; k < 4; k++) begin
                x_value[k] <= 32'b0;
                w_row[k]   <= 32'b0;
                y_value[k] <= 32'b0;
            end

            aw_pending   <= 1'b0;
            w_pending    <= 1'b0;
            read_bad_seen <= 1'b0;

            done         <= 1'b0;
            err_param    <= 1'b0;
            err_resp     <= 1'b0;
            err_protocol <= 1'b0;
            cycle_count  <= 32'b0;
        end else begin
            if (busy && cycle_count != 32'hFFFF_FFFF)
                cycle_count <= cycle_count + 32'd1;

            // ----------------------------------------------------
            // Idle: accept START, CLEAR or configuration commands
            // ----------------------------------------------------

            if (state == ST_IDLE) begin
                if (csr_cmd_start) begin
                    done         <= 1'b0;
                    err_param    <= 1'b0;
                    err_resp     <= 1'b0;
                    err_protocol <= 1'b0;
                    cycle_count  <= 32'b0;

                    w_addr_q <= w_addr_reg[AXI_ADDR_WIDTH-1:0];
                    x_addr_q <= x_addr_reg[AXI_ADDR_WIDTH-1:0];
                    y_addr_q <= y_addr_reg[AXI_ADDR_WIDTH-1:0];

                    row_index <= 2'b0;
                    col_index <= 2'b0;

                    accumulator <= 32'b0;
                    product     <= 32'b0;

                    aw_pending    <= 1'b0;
                    w_pending     <= 1'b0;
                    read_bad_seen <= 1'b0;

                    for (int k = 0; k < 4; k++) begin
                        y_value[k] <= 32'b0;
                    end

                    if (cfg_invalid) begin
                        done      <= 1'b1;
                        err_param <= 1'b1;
                        state     <= ST_IDLE;
                    end else begin
                        state <= ST_READ_X_AR;
                    end
                end else if (csr_cmd_clear) begin
                    done         <= 1'b0;
                    err_param    <= 1'b0;
                    err_resp     <= 1'b0;
                    err_protocol <= 1'b0;
                    cycle_count  <= 32'b0;
                    read_bad_seen <= 1'b0;
                end
            end else begin
                case (state)

                    // ------------------------------------------------
                    // Read x address
                    // ------------------------------------------------

                    ST_READ_X_AR: begin
                        if (ar_fire) begin
                            read_bad_seen <= 1'b0;
                            state <= ST_READ_X_DATA;
                        end
                    end

                    // ------------------------------------------------
                    // Read x data
                    // ------------------------------------------------

                    ST_READ_X_DATA: begin
                        if (r_fire) begin
                            if (axi_rresp != RESP_OKAY)
                                err_resp <= 1'b1;

                            if ((axi_rid != '0) || !axi_rlast)
                                err_protocol <= 1'b1;

                            if (!axi_rlast) begin
                                /*
                                 * Drain malformed multi-beat response
                                 * until RLAST arrives.
                                 */
                                read_bad_seen <= 1'b1;
                            end else begin
                                if (read_bad_seen || r_bad_now) begin
                                    done  <= 1'b1;
                                    state <= ST_IDLE;
                                end else begin
                                    for (int k = 0; k < 4; k++) begin
                                        x_value[k] <=
                                            axi_rdata[k*32 +: 32];
                                    end

                                    row_index <= 2'b0;
                                    state <= ST_READ_W_AR;
                                end

                                read_bad_seen <= 1'b0;
                            end
                        end
                    end

                    // ------------------------------------------------
                    // Read current W row address
                    // ------------------------------------------------

                    ST_READ_W_AR: begin
                        if (ar_fire) begin
                            read_bad_seen <= 1'b0;
                            state <= ST_READ_W_DATA;
                        end
                    end

                    // ------------------------------------------------
                    // Read current W row data
                    // ------------------------------------------------

                    ST_READ_W_DATA: begin
                        if (r_fire) begin
                            if (axi_rresp != RESP_OKAY)
                                err_resp <= 1'b1;

                            if ((axi_rid != '0) || !axi_rlast)
                                err_protocol <= 1'b1;

                            if (!axi_rlast) begin
                                read_bad_seen <= 1'b1;
                            end else begin
                                if (read_bad_seen || r_bad_now) begin
                                    done  <= 1'b1;
                                    state <= ST_IDLE;
                                end else begin
                                    for (int k = 0; k < 4; k++) begin
                                        w_row[k] <=
                                            axi_rdata[k*32 +: 32];
                                    end

                                    accumulator <= 32'b0;
                                    col_index   <= 2'b0;
                                    state       <= ST_MUL_SEND;
                                end

                                read_bad_seen <= 1'b0;
                            end
                        end
                    end

                    // ------------------------------------------------
                    // Send multiplication request
                    // ------------------------------------------------

                    ST_MUL_SEND: begin
                        if (mul_in_ready)
                            state <= ST_MUL_WAIT;
                    end

                    // ------------------------------------------------
                    // Wait for multiplication result
                    // ------------------------------------------------

                    ST_MUL_WAIT: begin
                        if (mul_out_valid) begin
                            product <= mul_result;
                            state   <= ST_ADD_SEND;
                        end
                    end

                    // ------------------------------------------------
                    // Send addition request
                    // ------------------------------------------------

                    ST_ADD_SEND: begin
                        if (add_in_ready)
                            state <= ST_ADD_WAIT;
                    end

                    // ------------------------------------------------
                    // Wait for addition result
                    // ------------------------------------------------

                    ST_ADD_WAIT: begin
                        if (add_out_valid) begin
                            if (col_index == 2'd3) begin
                                /*
                                 * Last product of this row.
                                 *
                                 * The first three rows continue directly
                                 * to the next W read. After row 3, the
                                 * complete y vector is written in one
                                 * 128-bit AXI beat.
                                 */
                                y_value[row_index] <= add_result;

                                if (row_index == 2'd3) begin
                                    aw_pending <= 1'b1;
                                    w_pending  <= 1'b1;
                                    state      <= ST_WRITE_SEND;
                                end else begin
                                    row_index <= row_index + 2'd1;
                                    state     <= ST_READ_W_AR;
                                end
                            end else begin
                                accumulator <= add_result;
                                col_index   <= col_index + 2'd1;
                                state       <= ST_MUL_SEND;
                            end
                        end
                    end

                    // ------------------------------------------------
                    // Send output write address and data
                    // ------------------------------------------------

                    ST_WRITE_SEND: begin
                        if (aw_fire)
                            aw_pending <= 1'b0;

                        if (w_fire)
                            w_pending <= 1'b0;

                        if ((!aw_pending || aw_fire) &&
                            (!w_pending  || w_fire)) begin
                            state <= ST_WRITE_RESP;
                        end
                    end

                    // ------------------------------------------------
                    // Wait for output write response
                    // ------------------------------------------------

                    ST_WRITE_RESP: begin
                        if (b_fire) begin
                            if (axi_bresp != RESP_OKAY)
                                err_resp <= 1'b1;

                            if (axi_bid != '0)
                                err_protocol <= 1'b1;

                            done  <= 1'b1;
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
    end

    // ============================================================
    // Simulation-time parameter checks
    // ============================================================

    // synthesis translate_off
    initial begin
        if (AXI_ADDR_WIDTH != 32 &&
            AXI_ADDR_WIDTH != 64) begin
            $fatal(1, "AXI_ADDR_WIDTH must be 32 or 64");
        end

        if (AXI_DATA_WIDTH != 128) begin
            $fatal(1, "This GEMV version requires AXI_DATA_WIDTH=128");
        end

        if (AXI_ID_WIDTH < 1 ||
            AXI_ID_WIDTH > 16) begin
            $fatal(1, "AXI_ID_WIDTH must be between 1 and 16");
        end

        if (AXI_PROT_VALUE > 7) begin
            $fatal(1, "AXI_PROT_VALUE must be between 0 and 7");
        end
    end
    // synthesis translate_on

endmodule