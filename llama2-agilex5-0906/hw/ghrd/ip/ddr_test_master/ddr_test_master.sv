module ddr_test_master #(
    parameter int unsigned AXI_ADDR_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH = 128,
    parameter int unsigned AXI_ID_WIDTH   = 4,

    // AxPROT[2]: instruction/data, [1]: nonsecure/secure,
    //        [0]: privileged/unprivileged.
    // 2 = nonsecure, unprivileged, data access.
    parameter int unsigned AXI_PROT_VALUE = 2
) (
    input  logic                        clk,
    input  logic                        reset,

    // AXI4-Lite CSR subordinate: 4 KiB address space.
    input  logic [11:0]                  csr_awaddr,
    input  logic [2:0]                   csr_awprot,
    input  logic                        csr_awvalid,
    output logic                        csr_awready,

    input  logic [31:0]                  csr_wdata,
    input  logic [3:0]                   csr_wstrb,
    input  logic                        csr_wvalid,
    output logic                        csr_wready,

    output logic [1:0]                   csr_bresp,
    output logic                        csr_bvalid,
    input  logic                        csr_bready,

    input  logic [11:0]                  csr_araddr,
    input  logic [2:0]                   csr_arprot,
    input  logic                        csr_arvalid,
    output logic                        csr_arready,

    output logic [31:0]                  csr_rdata,
    output logic [1:0]                   csr_rresp,
    output logic                        csr_rvalid,
    input  logic                        csr_rready,

    // AXI4 memory manager.
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

    localparam int unsigned BYTES_PER_BEAT = AXI_DATA_WIDTH / 8;
    localparam int unsigned BYTE_SHIFT     = $clog2(BYTES_PER_BEAT);

    localparam logic [2:0] AXI_SIZE = BYTE_SHIFT;
    localparam logic [AXI_ADDR_WIDTH-1:0] ADDR_STEP = BYTES_PER_BEAT;

    localparam logic [1:0] RESP_OKAY   = 2'b00;
    localparam logic [1:0] RESP_SLVERR = 2'b10;

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_WRITE_SEND,
        ST_WRITE_RESP,
        ST_READ_ADDR,
        ST_READ_DATA
    } state_t;

    state_t state;

    // Software configuration registers.
    logic        mode_reg;
    logic [31:0] addr_low_reg;
    logic [31:0] addr_high_reg;
    logic [31:0] length_reg;
    logic [31:0] pattern_reg;

    // Test result registers.
    logic        busy;
    logic        done;
    logic        err_param;
    logic        err_resp;
    logic        err_data;
    logic        err_protocol;
    logic [31:0] error_count;
    logic [31:0] cycle_count;
    logic [31:0] status_word;

    // Independent AXI-Lite AW and W holding registers.
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

    // Configuration validation.
    logic [63:0] cfg_addr;
    logic [64:0] cfg_last_addr;
    logic        cfg_invalid;

    // Active transaction state.
    logic [AXI_ADDR_WIDTH-1:0] address_q;
    logic [31:0] beats_left;
    logic [31:0] pattern_q;
    logic        aw_pending;
    logic        w_pending;
    logic        read_bad_seen;

    logic [AXI_DATA_WIDTH-1:0] expected_data;

    logic aw_fire;
    logic w_fire;
    logic b_fire;
    logic ar_fire;
    logic r_fire;

    logic b_bad_now;
    logic r_resp_bad;
    logic r_data_bad;
    logic r_protocol_bad;
    logic r_bad_now;
    logic transaction_done;
    logic transaction_bad;

    // Byte-enable merge for 32-bit CSR registers.
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

    assign status_word = {
        25'b0,
        err_protocol,
        err_data,
        err_resp,
        err_param,
        (err_param | err_resp | err_data | err_protocol),
        done,
        busy
    };

    // ------------------------------------------------------------
    // CSR write acceptance and command decode.
    // AW and W may arrive in either order.
    // ------------------------------------------------------------

    assign csr_awready = !reset && !csr_aw_have && !csr_bvalid;
    assign csr_wready  = !reset && !csr_w_have  && !csr_bvalid;

    assign csr_wr_commit =
        csr_aw_have && csr_w_have && !csr_bvalid;

    always_comb begin
        csr_wr_allowed = 1'b0;

        case (csr_aw_hold)
            12'h000,
            12'h008,
            12'h00C,
            12'h010,
            12'h014: csr_wr_allowed = !busy;

            default: csr_wr_allowed = 1'b0;
        endcase
    end

    assign csr_wr_ok = csr_wr_commit && csr_wr_allowed;

    assign cmd_start =
        csr_wr_ok &&
        (csr_aw_hold == 12'h000) &&
        csr_wstrb_hold[0] &&
        csr_wdata_hold[0];

    // START takes priority if both START and CLEAR are written.
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

            mode_reg      <= 1'b0;
            addr_low_reg  <= '0;
            addr_high_reg <= '0;
            length_reg    <= '0;
            pattern_reg   <= 32'hA5A5A5A5;
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
                csr_bvalid  <= 1'b1;
                csr_bresp  <= csr_wr_allowed ? RESP_OKAY : RESP_SLVERR;

                if (csr_wr_allowed) begin
                    case (csr_aw_hold)
                        12'h000: begin
                            if (csr_wstrb_hold[0])
                                mode_reg <= csr_wdata_hold[1];
                        end

                        12'h008:
                            addr_low_reg <= merge32(
                                addr_low_reg,
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        12'h00C:
                            addr_high_reg <= merge32(
                                addr_high_reg,
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        12'h010:
                            length_reg <= merge32(
                                length_reg,
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        12'h014:
                            pattern_reg <= merge32(
                                pattern_reg,
                                csr_wdata_hold,
                                csr_wstrb_hold
                            );

                        default: ;
                    endcase
                end
            end
        end
    end

    // ------------------------------------------------------------
    // CSR read channel.
    // Capture a snapshot when AR handshakes; hold until R handshakes.
    // ------------------------------------------------------------

    assign csr_arready = !reset && !csr_rvalid;

    always_comb begin
        csr_read_data = 32'b0;
        csr_read_resp = RESP_OKAY;

        case (csr_araddr)
            12'h000: csr_read_data = {30'b0, mode_reg, 1'b0};
            12'h004: csr_read_data = status_word;
            12'h008: csr_read_data = addr_low_reg;
            12'h00C: csr_read_data = addr_high_reg;
            12'h010: csr_read_data = length_reg;
            12'h014: csr_read_data = pattern_reg;
            12'h018: csr_read_data = error_count;
            12'h01C: csr_read_data = cycle_count;

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

    // ------------------------------------------------------------
    // Reject zero length, unaligned requests and address overflow.
    // LENGTH is a byte count and must be a whole number of beats.
    // ------------------------------------------------------------

    assign cfg_addr = {addr_high_reg, addr_low_reg};

    assign cfg_last_addr =
        {1'b0, cfg_addr} + {33'b0, length_reg} - 65'd1;

    always_comb begin
        cfg_invalid =
            (length_reg == 32'b0) ||
            (cfg_addr[BYTE_SHIFT-1:0] != '0) ||
            (length_reg[BYTE_SHIFT-1:0] != '0) ||
            cfg_last_addr[64];

        if (AXI_ADDR_WIDTH == 32) begin
            cfg_invalid =
                cfg_invalid ||
                (cfg_addr[63:32] != 32'b0) ||
                (cfg_last_addr[63:32] != 32'b0);
        end
    end

    // ------------------------------------------------------------
    // AXI manager outputs.
    // One single-beat INCR transaction at a time, fixed ID = 0.
    // ------------------------------------------------------------

    assign expected_data = {(AXI_DATA_WIDTH/32){pattern_q}};

    assign axi_awid    = '0;
    assign axi_awaddr  = address_q;
    assign axi_awlen   = 8'd0;
    assign axi_awsize  = AXI_SIZE;
    assign axi_awburst = 2'b01;
    assign axi_awlock  = 1'b0;
    assign axi_awcache = 4'b0010;
    assign axi_awprot  = AXI_PROT_VALUE[2:0];
    assign axi_awqos   = 4'b0000;
    assign axi_awvalid = (state == ST_WRITE_SEND) && aw_pending;

    assign axi_wdata   = expected_data;
    assign axi_wstrb   = '1;
    assign axi_wlast   = 1'b1;
    assign axi_wvalid  = (state == ST_WRITE_SEND) && w_pending;

    assign axi_bready  = (state == ST_WRITE_RESP);

    assign axi_arid    = '0;
    assign axi_araddr  = address_q;
    assign axi_arlen   = 8'd0;
    assign axi_arsize  = AXI_SIZE;
    assign axi_arburst = 2'b01;
    assign axi_arlock  = 1'b0;
    assign axi_arcache = 4'b0010;
    assign axi_arprot  = AXI_PROT_VALUE[2:0];
    assign axi_arqos   = 4'b0000;
    assign axi_arvalid = (state == ST_READ_ADDR);

    assign axi_rready  = (state == ST_READ_DATA);

    assign aw_fire = axi_awvalid && axi_awready;
    assign w_fire  = axi_wvalid  && axi_wready;
    assign b_fire  = axi_bvalid  && axi_bready;
    assign ar_fire = axi_arvalid && axi_arready;
    assign r_fire  = axi_rvalid  && axi_rready;

    assign b_bad_now =
        (axi_bresp != RESP_OKAY) || (axi_bid != '0);

    assign r_resp_bad = (axi_rresp != RESP_OKAY);

    // Read data need not be meaningful on an error response.
    assign r_data_bad =
        (axi_rresp == RESP_OKAY) &&
        (axi_rdata != expected_data);

    assign r_protocol_bad =
        (axi_rid != '0) || !axi_rlast;

    assign r_bad_now = r_resp_bad || r_data_bad || r_protocol_bad;

    // A malformed read without RLAST is drained until RLAST.
    // Do not issue the next transaction while that response is open.
    assign transaction_done =
        b_fire || (r_fire && axi_rlast);

    assign transaction_bad =
        b_fire ? b_bad_now : (read_bad_seen || r_bad_now);

    // ------------------------------------------------------------
    // Test engine.
    // All command, configuration and result signals use this clock.
    // ------------------------------------------------------------

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= ST_IDLE;
            address_q     <= '0;
            beats_left    <= '0;
            pattern_q     <= 32'hA5A5A5A5;
            aw_pending    <= 1'b0;
            w_pending     <= 1'b0;
            read_bad_seen <= 1'b0;

            done         <= 1'b0;
            err_param    <= 1'b0;
            err_resp     <= 1'b0;
            err_data     <= 1'b0;
            err_protocol <= 1'b0;
            error_count  <= '0;
            cycle_count  <= '0;
        end else begin
            if (busy && cycle_count != 32'hFFFFFFFF)
                cycle_count <= cycle_count + 32'd1;

            if (cmd_start) begin
                done         <= 1'b0;
                err_param    <= 1'b0;
                err_resp     <= 1'b0;
                err_data     <= 1'b0;
                err_protocol <= 1'b0;
                error_count  <= '0;
                cycle_count  <= '0;

                aw_pending    <= 1'b0;
                w_pending     <= 1'b0;
                read_bad_seen <= 1'b0;
                beats_left    <= '0;

                if (cfg_invalid) begin
                    state     <= ST_IDLE;
                    done      <= 1'b1;
                    err_param <= 1'b1;
                end else begin
                    address_q  <= cfg_addr[AXI_ADDR_WIDTH-1:0];
                    beats_left <= length_reg >> BYTE_SHIFT;
                    pattern_q  <= pattern_reg;

                    // Use mode from the START write itself.
                    // mode_reg is updated on this same edge.
                    if (csr_wdata_hold[1]) begin
                        state <= ST_READ_ADDR;
                    end else begin
                        state      <= ST_WRITE_SEND;
                        aw_pending <= 1'b1;
                        w_pending  <= 1'b1;
                    end
                end
            end else if (cmd_clear) begin
                done          <= 1'b0;
                err_param     <= 1'b0;
                err_resp      <= 1'b0;
                err_data      <= 1'b0;
                err_protocol  <= 1'b0;
                error_count   <= '0;
                cycle_count   <= '0;
                read_bad_seen <= 1'b0;
            end else begin
                case (state)
                    ST_IDLE: begin
                        // Results remain sticky until START or CLEAR.
                    end

                    ST_WRITE_SEND: begin
                        if (aw_fire)
                            aw_pending <= 1'b0;

                        if (w_fire)
                            w_pending <= 1'b0;

                        // Each channel can finish independently.
                        if ((!aw_pending || aw_fire) &&
                            (!w_pending  || w_fire))
                            state <= ST_WRITE_RESP;
                    end

                    ST_WRITE_RESP: begin
                        if (b_fire) begin
                            if (axi_bresp != RESP_OKAY)
                                err_resp <= 1'b1;

                            if (axi_bid != '0)
                                err_protocol <= 1'b1;
                        end
                    end

                    ST_READ_ADDR: begin
                        if (ar_fire)
                            state <= ST_READ_DATA;
                    end

                    ST_READ_DATA: begin
                        if (r_fire) begin
                            if (r_resp_bad)
                                err_resp <= 1'b1;

                            if (r_data_bad)
                                err_data <= 1'b1;

                            if (r_protocol_bad)
                                err_protocol <= 1'b1;

                            read_bad_seen <= read_bad_seen || r_bad_now;
                        end
                    end

                    default: state <= ST_IDLE;
                endcase

                // Advance only after a completed response handshake.
                if (transaction_done) begin
                    read_bad_seen <= 1'b0;

                    if (transaction_bad &&
                        error_count != 32'hFFFFFFFF)
                        error_count <= error_count + 32'd1;

                    if (beats_left == 32'd1) begin
                        beats_left <= '0;
                        state      <= ST_IDLE;
                        done       <= 1'b1;
                    end else begin
                        beats_left <= beats_left - 32'd1;
                        address_q  <= address_q + ADDR_STEP;

                        if (state == ST_WRITE_RESP) begin
                            state      <= ST_WRITE_SEND;
                            aw_pending <= 1'b1;
                            w_pending  <= 1'b1;
                        end else begin
                            state <= ST_READ_ADDR;
                        end
                    end
                end
            end
        end
    end

    // Simulation-time parameter checks.
    // synthesis translate_off
    initial begin
        if (AXI_ADDR_WIDTH != 32 && AXI_ADDR_WIDTH != 64)
            $fatal(1, "AXI_ADDR_WIDTH must be 32 or 64");

        if (AXI_DATA_WIDTH != 64  &&
            AXI_DATA_WIDTH != 128 &&
            AXI_DATA_WIDTH != 256 &&
            AXI_DATA_WIDTH != 512)
            $fatal(1, "Unsupported AXI_DATA_WIDTH");

        if (AXI_ID_WIDTH < 1 || AXI_ID_WIDTH > 16)
            $fatal(1, "AXI_ID_WIDTH must be 1..16");

        if (AXI_PROT_VALUE > 7)
            $fatal(1, "AXI_PROT_VALUE must be 0..7");
    end
    // synthesis translate_on

endmodule