// axi_slave.sv
// AXI4-Lite 从设备：寄存器读写
// HPS 通过 Lightweight HPS-to-FPGA bridge 访问

module axi_lite_slave (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite
    input  logic [11:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    input  logic [31:0] s_axi_wdata,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,
    input  logic [11:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // 寄存器
    output logic [31:0] reg_ctrl,
    input  logic [31:0] reg_status,
    output logic [31:0] reg_op_type,
    output logic [31:0] reg_param0,
    output logic [31:0] reg_param1,
    output logic [31:0] reg_param2,
    output logic [31:0] reg_src_addr,
    output logic [31:0] reg_wgt_addr,
    output logic [31:0] reg_dst_addr,
    input  logic [31:0] reg_cycles
);

    // 地址映射
    localparam ADDR_CTRL     = 12'h000;
    localparam ADDR_STATUS   = 12'h004;
    localparam ADDR_OP_TYPE  = 12'h008;
    localparam ADDR_PARAM0   = 12'h00C;
    localparam ADDR_PARAM1   = 12'h010;
    localparam ADDR_PARAM2   = 12'h014;
    localparam ADDR_SRC      = 12'h020;
    localparam ADDR_WGT      = 12'h024;
    localparam ADDR_DST      = 12'h028;
    localparam ADDR_CYCLES   = 12'h02C;

    // ---- 写通道 ----
    logic [11:0] aw_addr_reg;
    logic aw_valid, w_valid;

    assign s_axi_awready = !aw_valid;
    assign s_axi_wready  = aw_valid && !w_valid;
    assign s_axi_bresp   = 2'b00;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_valid     <= 0;
            w_valid      <= 0;
            s_axi_bvalid <= 0;
            reg_ctrl     <= 0;
            reg_op_type  <= 0;
            reg_param0   <= 0;
            reg_param1   <= 0;
            reg_param2   <= 0;
            reg_src_addr <= 0;
            reg_wgt_addr <= 0;
            reg_dst_addr <= 0;
        end else begin
            // 地址阶段
            if (s_axi_awvalid && s_axi_awready) begin
                aw_addr_reg <= s_axi_awaddr;
                aw_valid    <= 1;
            end

            // 数据阶段
            if (s_axi_wvalid && s_axi_wready && aw_valid) begin
                case (aw_addr_reg)
                    ADDR_CTRL:    reg_ctrl     <= s_axi_wdata;
                    ADDR_OP_TYPE: reg_op_type  <= s_axi_wdata;
                    ADDR_PARAM0:  reg_param0   <= s_axi_wdata;
                    ADDR_PARAM1:  reg_param1   <= s_axi_wdata;
                    ADDR_PARAM2:  reg_param2   <= s_axi_wdata;
                    ADDR_SRC:     reg_src_addr <= s_axi_wdata;
                    ADDR_WGT:     reg_wgt_addr <= s_axi_wdata;
                    ADDR_DST:     reg_dst_addr <= s_axi_wdata;
                    default: ;
                endcase
                s_axi_bvalid <= 1;
                aw_valid     <= 0;
            end

            // 写响应握手
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 0;
            end

            // ctrl 自动清零 (start 是脉冲)
            if (reg_ctrl[0]) reg_ctrl[0] <= 0;
        end
    end

    // ---- 读通道 ----
    assign s_axi_arready = 1;
    assign s_axi_rresp   = 2'b00;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 0;
            s_axi_rdata  <= 0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1;
                case (s_axi_araddr)
                    ADDR_CTRL:    s_axi_rdata <= reg_ctrl;
                    ADDR_STATUS:  s_axi_rdata <= reg_status;
                    ADDR_OP_TYPE: s_axi_rdata <= reg_op_type;
                    ADDR_PARAM0:  s_axi_rdata <= reg_param0;
                    ADDR_PARAM1:  s_axi_rdata <= reg_param1;
                    ADDR_PARAM2:  s_axi_rdata <= reg_param2;
                    ADDR_SRC:     s_axi_rdata <= reg_src_addr;
                    ADDR_WGT:     s_axi_rdata <= reg_wgt_addr;
                    ADDR_DST:     s_axi_rdata <= reg_dst_addr;
                    ADDR_CYCLES:  s_axi_rdata <= reg_cycles;
                    default:      s_axi_rdata <= 32'hDEADBEEF;
                endcase
            end
            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 0;
            end
        end
    end

endmodule
