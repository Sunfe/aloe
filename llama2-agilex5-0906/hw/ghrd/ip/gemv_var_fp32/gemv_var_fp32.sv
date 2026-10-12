module gemv_var_fp32 #(
    parameter int unsigned AXI_ADDR_WIDTH     = 64,
    parameter int unsigned AXI_DATA_WIDTH     = 128,

    // This manager uses only ID 0 and one outstanding transaction.
    parameter int unsigned AXI_ID_WIDTH       = 1,
    parameter int unsigned AXI_PROT_VALUE     = 2,

    parameter int unsigned FP32_SETTLE_CYCLES = 16,

    // Keep column accumulation order. Overlap only independent
    // operations within one four-element W/x beat.
    parameter bit OVERLAP_MUL_ADD = 1'b1,

    // Implementation limits, not runtime matrix dimensions.
    parameter int unsigned MAX_ROWS           = 32768,
    parameter int unsigned MAX_COLS           = 8192
) (
    input  logic clk,
    input  logic reset,

    // ============================================================
    // AXI4-Lite CSR subordinate
    // 12-bit BYTE address, 32-bit data, 4 KiB aperture
    // ============================================================

    input  logic [11:0] csr_awaddr,
    input  logic [2:0]  csr_awprot,
    input  logic        csr_awvalid,
    output logic        csr_awready,

    input  logic [31:0] csr_wdata,
    input  logic [3:0]  csr_wstrb,
    input  logic        csr_wvalid,
    output logic        csr_wready,

    output logic [1:0]  csr_bresp,
    output logic        csr_bvalid,
    input  logic        csr_bready,

    input  logic [11:0] csr_araddr,
    input  logic [2:0]  csr_arprot,
    input  logic        csr_arvalid,
    output logic        csr_arready,

    output logic [31:0] csr_rdata,
    output logic [1:0]  csr_rresp,
    output logic        csr_rvalid,
    input  logic        csr_rready,

    // ============================================================
    // AXI4 DDR manager
    // Fixed 128-bit, single-beat, one outstanding transaction
    // ============================================================

    output logic [AXI_ID_WIDTH-1:0]      axi_awid,
    output logic [AXI_ADDR_WIDTH-1:0]    axi_awaddr,
    output logic [7:0]                   axi_awlen,
    output logic [2:0]                   axi_awsize,
    output logic [1:0]                   axi_awburst,
    output logic                        axi_awlock,
    output logic [3:0]                   axi_awcache,
    output logic [2:0]                   axi_awprot,
    output logic [3:0]                   axi_awqos,
    output logic                        axi_awvalid,
    input  logic                        axi_awready,

    output logic [AXI_DATA_WIDTH-1:0]    axi_wdata,
    output logic [AXI_DATA_WIDTH/8-1:0]  axi_wstrb,
    output logic                        axi_wlast,
    output logic                        axi_wvalid,
    input  logic                        axi_wready,

    input  logic [AXI_ID_WIDTH-1:0]      axi_bid,
    input  logic [1:0]                   axi_bresp,
    input  logic                        axi_bvalid,
    output logic                        axi_bready,

    output logic [AXI_ID_WIDTH-1:0]      axi_arid,
    output logic [AXI_ADDR_WIDTH-1:0]    axi_araddr,
    output logic [7:0]                   axi_arlen,
    output logic [2:0]                   axi_arsize,
    output logic [1:0]                   axi_arburst,
    output logic                        axi_arlock,
    output logic [3:0]                   axi_arcache,
    output logic [2:0]                   axi_arprot,
    output logic [3:0]                   axi_arqos,
    output logic                        axi_arvalid,
    input  logic                        axi_arready,

    input  logic [AXI_ID_WIDTH-1:0]      axi_rid,
    input  logic [AXI_DATA_WIDTH-1:0]    axi_rdata,
    input  logic [1:0]                   axi_rresp,
    input  logic                        axi_rlast,
    input  logic                        axi_rvalid,
    output logic                        axi_rready
);

    // ============================================================
    // Constants
    // ============================================================

    localparam logic [31:0] VERSION = 32'h4756_4D32; // "GVM2": BUILD_ID registers present

    // BEGIN GENERATED BUILD_ID
    // Opaque build token; source hashes are in the manifest.
    localparam logic [127:0] BUILD_ID =
        128'h1a67165bfaa445ed98c33b673a9b04db;
    // END GENERATED BUILD_ID

    localparam logic [1:0] RESP_OKAY   = 2'b00;
    localparam logic [1:0] RESP_SLVERR = 2'b10;

    localparam logic [AXI_ADDR_WIDTH-1:0] ADDR_STEP = 16;

    // One RAM entry contains four FP32 values.
    localparam int unsigned XBUF_DEPTH =
        (MAX_COLS < 4) ? 1 : (MAX_COLS / 4);

    localparam int unsigned XBUF_AW =
        (XBUF_DEPTH < 2) ? 1 : $clog2(XBUF_DEPTH);

    // Include the maximum count itself:
    // MAX_ROWS=32768 needs 16 bits, MAX_COLS=8192 needs 14 bits.
    localparam int unsigned ROW_COUNT_W =
        (MAX_ROWS < 2) ? 1 : $clog2(MAX_ROWS + 1);

    localparam int unsigned COL_COUNT_W =
        (MAX_COLS < 2) ? 1 : $clog2(MAX_COLS + 1);

    localparam int unsigned ELEMENT_COUNT_W =
        ROW_COUNT_W + COL_COUNT_W;

    // ============================================================
    // State encoding
    // DEBUG[3:0] exposes these values.
    // ============================================================

    typedef enum logic [3:0] {
        ST_IDLE       = 4'd0,
        ST_VALIDATE   = 4'd1,

        ST_X_AR       = 4'd2,
        ST_X_R        = 4'd3,

        ST_W_AR       = 4'd4,
        ST_W_R        = 4'd5,

        ST_XBUF_REQ   = 4'd6,
        ST_XBUF_WAIT  = 4'd7,

        ST_MUL_SEND   = 4'd8,
        ST_MUL_WAIT   = 4'd9,

        ST_ADD_SEND   = 4'd10,
        ST_ADD_WAIT   = 4'd11,

        ST_Y_SEND     = 4'd12,
        ST_Y_RESP     = 4'd13,

        // Internal illegal-state trap.
        // No software CLEAR/START can cancel an active transaction.
        ST_FAULT      = 4'd15
    } state_t;

    state_t state;

    // ============================================================
    // Software configuration registers
    // Writable only while idle.
    // ============================================================

    logic [63:0] w_addr_reg;
    logic [63:0] x_addr_reg;
    logic [63:0] y_addr_reg;

    logic [31:0] rows_reg;
    logic [31:0] cols_reg;

    // ============================================================
    // Active command snapshot
    // Latched at START.
    // ============================================================

    logic [63:0] w_base_q;
    logic [63:0] x_base_q;
    logic [63:0] y_base_q;

    logic [31:0] rows_q;
    logic [31:0] cols_q;
    logic [31:0] beats_per_row_q;

    logic [63:0] w_bytes_q;
    logic [63:0] x_bytes_q;
    logic [63:0] y_bytes_q;

    logic [AXI_ADDR_WIDTH-1:0] x_read_addr_q;
    logic [AXI_ADDR_WIDTH-1:0] w_read_addr_q;
    logic [AXI_ADDR_WIDTH-1:0] y_write_addr_q;

    logic [31:0] x_load_index;
    logic [31:0] w_beat_index;
    logic [31:0] row_index;
    logic [1:0]  lane_index;

    // Bounded integer product for legal matrix dimensions.
    // The complete 32-bit ROWS/COLS are independently validated.
    logic [ELEMENT_COUNT_W-1:0] cfg_element_count;
    logic [63:0] cfg_w_bytes;

    // ============================================================
    // Result/status registers
    // ============================================================

    logic        busy;
    logic        done;
    logic        err_param;
    logic        err_resp;
    logic        err_protocol;

    logic [31:0] cycle_count;
    logic [31:0] status_word;
    logic [31:0] debug_word;
    logic [31:0] current_col;

    // ============================================================
    // AXI4-Lite write holding registers
    // ============================================================

    logic        csr_aw_have;
    logic        csr_w_have;
    logic [11:0] csr_aw_hold;
    logic [31:0] csr_wdata_hold;
    logic [3:0]  csr_wstrb_hold;

    logic        csr_wr_commit;
    logic        csr_wr_allowed;
    logic        csr_wr_ok;
    logic        cmd_start;
    logic        cmd_clear;

    logic [31:0] csr_read_data;
    logic [1:0]  csr_read_resp;

    // ============================================================
    // Configuration validation
    // ============================================================

    logic [64:0] w_last_addr;
    logic [64:0] x_last_addr;
    logic [64:0] y_last_addr;

    logic        y_overlaps_w;
    logic        y_overlaps_x;
    logic        cfg_invalid;

    // ============================================================
    // x RAM and local data
    // ============================================================

    (* ramstyle = "M20K" *)
    logic [127:0] x_mem [0:XBUF_DEPTH-1];

    logic [127:0] x_ram_rdata;
    logic         x_ram_we;
    logic         x_ram_re;

    logic [127:0] x_beat_q;
    logic [127:0] w_beat_q;
    logic [127:0] y_group_q;

    logic [31:0] accumulator;
    logic [31:0] product;

    // ============================================================
    // Floating-point handshakes
    // ============================================================

    logic        mul_in_ready;
    logic        mul_out_valid;
    logic [31:0] mul_result;

    logic        add_in_ready;
    logic        add_out_valid;
    logic [31:0] add_result;

    logic       overlap_next;
    logic       add_step_ready;
    logic       add_step_valid;
    logic [1:0] mul_lane_index;

    // ============================================================
    // AXI transaction bookkeeping
    // ============================================================

    logic aw_pending;
    logic w_pending;
    logic read_bad_seen;

    logic aw_fire;
    logic w_fire;
    logic b_fire;
    logic ar_fire;
    logic r_fire;

    logic r_bad_now;
    logic b_bad_now;

    // ============================================================
    // Helpers
    // ============================================================

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

    // ============================================================
    // Status and debug
    // ============================================================

    assign busy = (state != ST_IDLE);

    // STATUS:
    // [0] BUSY
    // [1] DONE
    // [2] ERROR
    // [3] PARAM_ERROR
    // [4] RESP_ERROR
    // [5] PROTOCOL_ERROR

    assign status_word = {
        26'b0,
        err_protocol,
        err_resp,
        err_param,
        (err_param | err_resp | err_protocol),
        done,
        busy
    };

    assign current_col =
        (w_beat_index << 2) | {30'b0, lane_index};

    // DEBUG is intentionally different from the fixed 4x4 component.
    // [3:0] state
    // [5:4] lane_index
    // [6]   read_bad_seen
    // [7]   mul_out_valid
    // [8]   add_out_valid
    // [9]   aw_pending
    // [10]  w_pending
    // [31:11] reserved

    always_comb begin
        debug_word = 32'b0;
        debug_word[3:0] = state;
        debug_word[5:4] = lane_index;
        debug_word[6]   = read_bad_seen;
        debug_word[7]   = mul_out_valid;
        debug_word[8]   = add_out_valid;
        debug_word[9]   = aw_pending;
        debug_word[10]  = w_pending;
    end

    // ============================================================
    // AXI4-Lite write channel
    // AW and W can arrive independently, in either order.
    // ============================================================

    assign csr_awready =
        !reset && !csr_aw_have && !csr_bvalid;

    assign csr_wready =
        !reset && !csr_w_have && !csr_bvalid;

    assign csr_wr_commit =
        csr_aw_have && csr_w_have && !csr_bvalid;

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
                12'h01C, // Y_ADDR_HIGH
                12'h02C, // ROWS
                12'h030: // COLS
                    csr_wr_allowed = 1'b1;

                default:
                    csr_wr_allowed = 1'b0;
            endcase
        end
    end

    assign csr_wr_ok =
        csr_wr_commit && csr_wr_allowed;

    assign cmd_start =
        csr_wr_ok &&
        (csr_aw_hold == 12'h000) &&
        csr_wstrb_hold[0] &&
        csr_wdata_hold[0];

    // START takes priority over CLEAR.
    assign cmd_clear =
        csr_wr_ok &&
        (csr_aw_hold == 12'h000) &&
        csr_wstrb_hold[0] &&
        csr_wdata_hold[2] &&
        !csr_wdata_hold[0];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            csr_aw_have    <= 1'b0;
            csr_w_have     <= 1'b0;
            csr_aw_hold    <= '0;
            csr_wdata_hold <= '0;
            csr_wstrb_hold <= '0;

            csr_bvalid <= 1'b0;
            csr_bresp  <= RESP_OKAY;

            w_addr_reg <= '0;
            x_addr_reg <= '0;
            y_addr_reg <= '0;
            rows_reg   <= '0;
            cols_reg   <= '0;
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
                              RESP_OKAY : RESP_SLVERR;

                if (csr_wr_allowed) begin
                    case (csr_aw_hold)
                        12'h008:
                            w_addr_reg[31:0] <= merge32(
                                w_addr_reg[31:0],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        12'h00C:
                            w_addr_reg[63:32] <= merge32(
                                w_addr_reg[63:32],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        12'h010:
                            x_addr_reg[31:0] <= merge32(
                                x_addr_reg[31:0],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        12'h014:
                            x_addr_reg[63:32] <= merge32(
                                x_addr_reg[63:32],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        12'h018:
                            y_addr_reg[31:0] <= merge32(
                                y_addr_reg[31:0],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        12'h01C:
                            y_addr_reg[63:32] <= merge32(
                                y_addr_reg[63:32],
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        12'h02C:
                            rows_reg <= merge32(
                                rows_reg,
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        12'h030:
                            cols_reg <= merge32(
                                cols_reg,
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        default: begin
                            // CTRL is consumed by the engine.
                        end
                    endcase
                end
            end
        end
    end

    // ============================================================
    // AXI4-Lite read channel
    // Capture at AR handshake; hold until R handshake.
    // ============================================================

    assign csr_arready = !reset && !csr_rvalid;

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

            12'h02C: csr_read_data = rows_reg;
            12'h030: csr_read_data = cols_reg;

            12'h034: csr_read_data = MAX_ROWS;
            12'h038: csr_read_data = MAX_COLS;

            12'h03C: csr_read_data = row_index;
            12'h040: csr_read_data = current_col;

            // Additive read-only identification registers.
            // SCHED_INFO[31:16] = scheduling revision, currently 1.
            // SCHED_INFO[0]     = OVERLAP_MUL_ADD.
            // SCHED_INFO[15:1]  = reserved, zero.
            12'h044: csr_read_data =
                {16'h0001, 15'b0, OVERLAP_MUL_ADD};
            12'h048: csr_read_data = FP32_SETTLE_CYCLES;

            // One immutable 128-bit build token, low word first.
            12'h04C: csr_read_data = BUILD_ID[31:0];
            12'h050: csr_read_data = BUILD_ID[63:32];
            12'h054: csr_read_data = BUILD_ID[95:64];
            12'h058: csr_read_data = BUILD_ID[127:96];

            default: begin
                csr_read_data = 32'b0;
                csr_read_resp = RESP_SLVERR;
            end
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            csr_rvalid <= 1'b0;
            csr_rdata  <= '0;
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
    // Matrix byte count
    //
    // Limit integer multiplier width to the supported dimensions.
    // Out-of-range 32-bit dimensions are rejected in ST_VALIDATE.
    // No DDR requests are issued before validation completes.
    // ============================================================

    assign cfg_element_count =
        {{COL_COUNT_W{1'b0}}, rows_reg[ROW_COUNT_W-1:0]} *
        {{ROW_COUNT_W{1'b0}}, cols_reg[COL_COUNT_W-1:0]};

    assign cfg_w_bytes =
        {{(64-ELEMENT_COUNT_W){1'b0}}, cfg_element_count} << 2;

    // ============================================================
    // Address and shape validation
    // ============================================================

    assign w_last_addr =
        {1'b0, w_base_q} + {1'b0, w_bytes_q} - 65'd1;

    assign x_last_addr =
        {1'b0, x_base_q} + {1'b0, x_bytes_q} - 65'd1;

    assign y_last_addr =
        {1'b0, y_base_q} + {1'b0, y_bytes_q} - 65'd1;

    // Output must not overwrite input data.
    // W and x may overlap because both are read-only.
    assign y_overlaps_w =
        ({1'b0, y_base_q} <= w_last_addr) &&
        ({1'b0, w_base_q} <= y_last_addr);

    assign y_overlaps_x =
        ({1'b0, y_base_q} <= x_last_addr) &&
        ({1'b0, x_base_q} <= y_last_addr);

    always_comb begin
        cfg_invalid =
            (rows_q == 32'b0) ||
            (cols_q == 32'b0) ||
            (rows_q > MAX_ROWS) ||
            (cols_q > MAX_COLS) ||
            (rows_q[1:0] != 2'b0) ||
            (cols_q[1:0] != 2'b0) ||

            (w_base_q[3:0] != 4'b0) ||
            (x_base_q[3:0] != 4'b0) ||
            (y_base_q[3:0] != 4'b0) ||

            w_last_addr[64] ||
            x_last_addr[64] ||
            y_last_addr[64] ||

            y_overlaps_w ||
            y_overlaps_x;

        if (AXI_ADDR_WIDTH == 32) begin
            cfg_invalid =
                cfg_invalid ||
                (w_base_q[63:32] != 32'b0) ||
                (x_base_q[63:32] != 32'b0) ||
                (y_base_q[63:32] != 32'b0) ||
                (w_last_addr[64:32] != 33'b0) ||
                (x_last_addr[64:32] != 33'b0) ||
                (y_last_addr[64:32] != 33'b0);
        end
    end

    // ============================================================
    // AXI manager outputs
    // ID=0, ARLEN/AWLEN=0, 16 bytes per transaction.
    // ============================================================

    assign axi_awid    = '0;
    assign axi_awaddr  = y_write_addr_q;
    assign axi_awlen   = 8'd0;
    assign axi_awsize  = 3'd4;
    assign axi_awburst = 2'b01;
    assign axi_awlock  = 1'b0;
    assign axi_awcache = 4'b0010;
    assign axi_awprot  = AXI_PROT_VALUE[2:0];
    assign axi_awqos   = 4'b0000;

    assign axi_awvalid =
        !reset && (state == ST_Y_SEND) && aw_pending;

    assign axi_wdata  = y_group_q;
    assign axi_wstrb  = '1;
    assign axi_wlast  = 1'b1;

    assign axi_wvalid =
        !reset && (state == ST_Y_SEND) && w_pending;

    assign axi_bready =
        !reset && (state == ST_Y_RESP);

    assign axi_arid = '0;

    assign axi_araddr =
        ((state == ST_X_AR) || (state == ST_X_R)) ?
        x_read_addr_q : w_read_addr_q;

    assign axi_arlen   = 8'd0;
    assign axi_arsize  = 3'd4;
    assign axi_arburst = 2'b01;
    assign axi_arlock  = 1'b0;
    assign axi_arcache = 4'b0010;
    assign axi_arprot  = AXI_PROT_VALUE[2:0];
    assign axi_arqos   = 4'b0000;

    assign axi_arvalid =
        !reset &&
        ((state == ST_X_AR) || (state == ST_W_AR));

    assign axi_rready =
        !reset &&
        ((state == ST_X_R) || (state == ST_W_R));

    assign aw_fire = axi_awvalid && axi_awready;
    assign w_fire  = axi_wvalid  && axi_wready;
    assign b_fire  = axi_bvalid  && axi_bready;
    assign ar_fire = axi_arvalid && axi_arready;
    assign r_fire  = axi_rvalid  && axi_rready;

    assign r_bad_now =
        (axi_rresp != RESP_OKAY) ||
        (axi_rid != '0) ||
        !axi_rlast;

    assign b_bad_now =
        (axi_bresp != RESP_OKAY) ||
        (axi_bid != '0);

    // ============================================================
    // x buffer
    //
    // 128-bit write and synchronous 128-bit read.
    // No reset on RAM contents or RAM output register.
    // Every used entry is loaded before computation starts.
    // ============================================================

    assign x_ram_we =
        !reset &&
        (state == ST_X_R) &&
        r_fire &&
        axi_rlast &&
        !read_bad_seen &&
        !r_bad_now;

    assign x_ram_re =
        !reset && (state == ST_XBUF_REQ);

    always_ff @(posedge clk) begin
        if (x_ram_we)
            x_mem[x_load_index[XBUF_AW-1:0]] <= axi_rdata;

        if (x_ram_re)
            x_ram_rdata <= x_mem[w_beat_index[XBUF_AW-1:0]];
    end

    // ============================================================
    // FP32 arithmetic
    //
    // Separate multiply and add, no fused multiply-add.
    // Column order is 0, 1, 2, ... COLS-1.
    // ============================================================

    // In overlapped mode, ADD_SEND issues add(current)
    // and mul(next) together for lanes 0, 1 and 2.
    //
    // fp32_serial.in_ready is independent of in_valid, and
    // fp32_serial holds out_valid/result until acceptance.
    // Cross-gating below therefore has no combinational loop
    // and prevents either member of a pair retiring alone.
    assign overlap_next =
        OVERLAP_MUL_ADD && (lane_index != 2'd3);

    assign add_step_ready =
        add_in_ready && (!overlap_next || mul_in_ready);

    assign add_step_valid =
        add_out_valid && (!overlap_next || mul_out_valid);

    assign mul_lane_index =
        ((state == ST_ADD_SEND) && overlap_next) ?
        (lane_index + 2'd1) : lane_index;

    fp32_mul #(
        .SETTLE_CYCLES(FP32_SETTLE_CYCLES)
    ) u_mul (
        .clk       (clk),
        .reset     (reset),

        .in_valid  (
            !reset &&
            ((state == ST_MUL_SEND) ||
             ((state == ST_ADD_SEND) &&
              overlap_next && add_in_ready))
        ),
        .in_ready  (mul_in_ready),

        .a         (w_beat_q[mul_lane_index*32 +: 32]),
        .b         (x_beat_q[mul_lane_index*32 +: 32]),

        .out_valid (mul_out_valid),
        .out_ready (
            !reset &&
            ((state == ST_MUL_WAIT) ||
             ((state == ST_ADD_WAIT) &&
              overlap_next && add_out_valid))
        ),
        .result    (mul_result)
    );

    fp32_add #(
        .SETTLE_CYCLES(FP32_SETTLE_CYCLES)
    ) u_add (
        .clk       (clk),
        .reset     (reset),

        .in_valid  (
            !reset && (state == ST_ADD_SEND) &&
            (!overlap_next || mul_in_ready)
        ),
        .in_ready  (add_in_ready),

        .a         (accumulator),
        .b         (product),

        .out_valid (add_out_valid),
        .out_ready (
            !reset && (state == ST_ADD_WAIT) &&
            (!overlap_next || mul_out_valid)
        ),
        .result    (add_result)
    );

    // ============================================================
    // GEMV engine
    // ============================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= ST_IDLE;

            w_base_q <= '0;
            x_base_q <= '0;
            y_base_q <= '0;

            rows_q          <= '0;
            cols_q          <= '0;
            beats_per_row_q <= '0;

            w_bytes_q <= '0;
            x_bytes_q <= '0;
            y_bytes_q <= '0;

            x_read_addr_q <= '0;
            w_read_addr_q <= '0;
            y_write_addr_q <= '0;

            x_load_index <= '0;
            w_beat_index <= '0;
            row_index    <= '0;
            lane_index   <= '0;

            x_beat_q  <= '0;
            w_beat_q  <= '0;
            y_group_q <= '0;

            accumulator <= '0;
            product     <= '0;

            aw_pending    <= 1'b0;
            w_pending     <= 1'b0;
            read_bad_seen <= 1'b0;

            done         <= 1'b0;
            err_param    <= 1'b0;
            err_resp     <= 1'b0;
            err_protocol <= 1'b0;
            cycle_count  <= '0;
        end else begin
            if (busy && cycle_count != 32'hFFFF_FFFF)
                cycle_count <= cycle_count + 32'd1;

            case (state)

                // ------------------------------------------------
                // Accept one command while idle.
                // ------------------------------------------------

                ST_IDLE: begin
                    if (cmd_start) begin
                        w_base_q <= w_addr_reg;
                        x_base_q <= x_addr_reg;
                        y_base_q <= y_addr_reg;

                        rows_q <= rows_reg;
                        cols_q <= cols_reg;

                        beats_per_row_q <= cols_reg >> 2;

                        w_bytes_q <= cfg_w_bytes;
                        x_bytes_q <= {32'b0, cols_reg} << 2;
                        y_bytes_q <= {32'b0, rows_reg} << 2;

                        x_read_addr_q <=
                            x_addr_reg[AXI_ADDR_WIDTH-1:0];

                        w_read_addr_q <=
                            w_addr_reg[AXI_ADDR_WIDTH-1:0];

                        y_write_addr_q <=
                            y_addr_reg[AXI_ADDR_WIDTH-1:0];

                        x_load_index <= '0;
                        w_beat_index <= '0;
                        row_index    <= '0;
                        lane_index   <= '0;

                        x_beat_q  <= '0;
                        w_beat_q  <= '0;
                        y_group_q <= '0;

                        accumulator <= 32'b0;
                        product     <= 32'b0;

                        aw_pending    <= 1'b0;
                        w_pending     <= 1'b0;
                        read_bad_seen <= 1'b0;

                        done         <= 1'b0;
                        err_param    <= 1'b0;
                        err_resp     <= 1'b0;
                        err_protocol <= 1'b0;
                        cycle_count  <= '0;

                        state <= ST_VALIDATE;
                    end else if (cmd_clear) begin
                        done         <= 1'b0;
                        err_param    <= 1'b0;
                        err_resp     <= 1'b0;
                        err_protocol <= 1'b0;
                        cycle_count  <= '0;

                        x_load_index <= '0;
                        w_beat_index <= '0;
                        row_index    <= '0;
                        lane_index   <= '0;

                        aw_pending    <= 1'b0;
                        w_pending     <= 1'b0;
                        read_bad_seen <= 1'b0;

                        // Configuration registers and RAM contents
                        // are deliberately not cleared.
                    end
                end

                // ------------------------------------------------
                // Validate the latched command before any AXI request.
                // ------------------------------------------------

                ST_VALIDATE: begin
                    if (cfg_invalid) begin
                        done      <= 1'b1;
                        err_param <= 1'b1;
                        state     <= ST_IDLE;
                    end else begin
                        state <= ST_X_AR;
                    end
                end

                // ------------------------------------------------
                // Issue one x read.
                // ------------------------------------------------

                ST_X_AR: begin
                    if (ar_fire) begin
                        read_bad_seen <= 1'b0;
                        state <= ST_X_R;
                    end
                end

                // ------------------------------------------------
                // Issue one W read.
                // ------------------------------------------------

                ST_W_AR: begin
                    if (ar_fire) begin
                        read_bad_seen <= 1'b0;
                        state <= ST_W_R;
                    end
                end

                // ------------------------------------------------
                // Handle x/W read response.
                //
                // Missing RLAST is a protocol error. Keep receiving
                // until RLAST; do not launch another transaction.
                // ------------------------------------------------

                ST_X_R, ST_W_R: begin
                    if (r_fire) begin
                        if (axi_rresp != RESP_OKAY)
                            err_resp <= 1'b1;

                        if ((axi_rid != '0) || !axi_rlast)
                            err_protocol <= 1'b1;

                        if (!axi_rlast) begin
                            read_bad_seen <= 1'b1;
                        end else begin
                            read_bad_seen <= 1'b0;

                            if (read_bad_seen || r_bad_now) begin
                                // This response is now closed.
                                // Earlier output groups, if any,
                                // must be treated as invalid.
                                done  <= 1'b1;
                                state <= ST_IDLE;
                            end else if (state == ST_X_R) begin
                                // x RAM write occurs on this edge.
                                if (x_load_index ==
                                    beats_per_row_q - 32'd1) begin
                                    state <= ST_W_AR;
                                end else begin
                                    x_load_index <=
                                        x_load_index + 32'd1;

                                    x_read_addr_q <=
                                        x_read_addr_q + ADDR_STEP;

                                    state <= ST_X_AR;
                                end
                            end else begin
                                w_beat_q  <= axi_rdata;
                                lane_index <= 2'd0;
                                state <= ST_XBUF_REQ;
                            end
                        end
                    end
                end

                // ------------------------------------------------
                // Synchronous x RAM read.
                // ------------------------------------------------

                ST_XBUF_REQ: begin
                    // RAM read is requested on this edge.
                    state <= ST_XBUF_WAIT;
                end

                ST_XBUF_WAIT: begin
                    // RAM output from the preceding edge is valid.
                    x_beat_q <= x_ram_rdata;
                    state <= ST_MUL_SEND;
                end

                // ------------------------------------------------
                // One serial FP32 multiply.
                // ------------------------------------------------

                ST_MUL_SEND: begin
                    if (mul_in_ready)
                        state <= ST_MUL_WAIT;
                end

                ST_MUL_WAIT: begin
                    if (mul_out_valid) begin
                        product <= mul_result;
                        state   <= ST_ADD_SEND;
                    end
                end

                // ------------------------------------------------
                // One serial FP32 add.
                // ------------------------------------------------

                ST_ADD_SEND: begin
                    if (add_step_ready)
                        state <= ST_ADD_WAIT;
                end

                ST_ADD_WAIT: begin
                    if (add_step_valid) begin

                        if (lane_index != 2'd3) begin
                            // Commit the current addition in order.
                            accumulator <= add_result;
                            lane_index  <= lane_index + 2'd1;

                            if (OVERLAP_MUL_ADD) begin
                                // mul(next) completed alongside
                                // add(current). Its rounded result
                                // becomes the next addend.
                                product <= mul_result;
                                state   <= ST_ADD_SEND;
                            end else begin
                                state <= ST_MUL_SEND;
                            end

                        end else if (w_beat_index !=
                                     beats_per_row_q - 32'd1) begin
                            // More beats remain in this row.
                            accumulator <= add_result;
                            lane_index  <= 2'd0;

                            w_beat_index <=
                                w_beat_index + 32'd1;

                            w_read_addr_q <=
                                w_read_addr_q + ADDR_STEP;

                            state <= ST_W_AR;

                        end else begin
                            // Complete one row.
                            y_group_q[row_index[1:0]*32 +: 32]
                                <= add_result;

                            // Next W row is physically contiguous.
                            // Do not advance beyond the final row.
                            if (row_index != rows_q - 32'd1)
                                w_read_addr_q <=
                                    w_read_addr_q + ADDR_STEP;

                            if (row_index[1:0] == 2'd3) begin
                                // Four results are ready.
                                // y_group_q is fully updated before
                                // ST_Y_SEND asserts WVALID.
                                aw_pending <= 1'b1;
                                w_pending  <= 1'b1;
                                state      <= ST_Y_SEND;
                            end else begin
                                // Continue within this output group.
                                row_index <= row_index + 32'd1;

                                w_beat_index <= 32'd0;
                                lane_index   <= 2'd0;
                                accumulator  <= 32'b0;

                                state <= ST_W_AR;
                            end
                        end
                    end
                end

                // ------------------------------------------------
                // Send one complete 128-bit output group.
                // AW and W may finish on different cycles.
                // ------------------------------------------------

                ST_Y_SEND: begin
                    if (aw_fire)
                        aw_pending <= 1'b0;

                    if (w_fire)
                        w_pending <= 1'b0;

                    if ((!aw_pending || aw_fire) &&
                        (!w_pending  || w_fire)) begin
                        state <= ST_Y_RESP;
                    end
                end

                // ------------------------------------------------
                // Wait for output write response.
                // Final DONE is set only after final B handshake.
                // ------------------------------------------------

                ST_Y_RESP: begin
                    if (b_fire) begin
                        if (axi_bresp != RESP_OKAY)
                            err_resp <= 1'b1;

                        if (axi_bid != '0)
                            err_protocol <= 1'b1;

                        if (b_bad_now) begin
                            done  <= 1'b1;
                            state <= ST_IDLE;
                        end else if (row_index ==
                                     rows_q - 32'd1) begin
                            done  <= 1'b1;
                            state <= ST_IDLE;
                        end else begin
                            // Continue with the next group of rows.
                            y_write_addr_q <=
                                y_write_addr_q + ADDR_STEP;

                            row_index <= row_index + 32'd1;

                            w_beat_index <= 32'd0;
                            lane_index   <= 2'd0;
                            accumulator  <= 32'b0;

                            state <= ST_W_AR;
                        end
                    end
                end

                // ------------------------------------------------
                // Internal illegal-state trap.
                //
                // This is not a recoverable software timeout.
                // Remain BUSY; do not pretend AXI was cancelled.
                // ------------------------------------------------

                ST_FAULT: begin
                    // Hold until a coordinated system reset.
                end

                default: begin
                    err_protocol <= 1'b1;
                    done         <= 1'b0;
                    state        <= ST_FAULT;
                end

            endcase
        end
    end

    // ============================================================
    // Simulation-time parameter checks
    // ============================================================

    // synthesis translate_off
    initial begin
        if (AXI_ADDR_WIDTH != 32 && AXI_ADDR_WIDTH != 64)
            $fatal(1, "AXI_ADDR_WIDTH must be 32 or 64");

        if (AXI_DATA_WIDTH != 128)
            $fatal(1, "gemv_var_fp32 requires AXI_DATA_WIDTH=128");

        if (AXI_ID_WIDTH < 1 || AXI_ID_WIDTH > 16)
            $fatal(1, "AXI_ID_WIDTH must be 1..16");

        if (AXI_PROT_VALUE > 7)
            $fatal(1, "AXI_PROT_VALUE must be 0..7");

       if (FP32_SETTLE_CYCLES < 1)
            $fatal(1, "FP32_SETTLE_CYCLES must be >=1");

        if (MAX_ROWS < 4 ||
            MAX_ROWS > 32768 ||
            (MAX_ROWS % 4) != 0)
            $fatal(1, "MAX_ROWS must be a multiple of 4 in 4..32768");

        if (MAX_COLS < 4 ||
            MAX_COLS > 8192 ||
            (MAX_COLS % 4) != 0)
            $fatal(1, "MAX_COLS must be a multiple of 4 in 4..8192");
    end
    // synthesis translate_on

endmodule