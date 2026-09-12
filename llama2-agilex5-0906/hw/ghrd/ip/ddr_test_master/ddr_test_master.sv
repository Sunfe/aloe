module ddr_test_master #(
    parameter AXI_ADDR_WIDTH = 64,
    parameter AXI_DATA_WIDTH = 128,
    parameter AXI_ID_WIDTH   = 4
)(
    // ============================================
    // AXI4-Lite 控制接口 (CSR)
    // ============================================
    input  logic                        csr_clk,
    input  logic                        csr_rst,
    
    // 写地址通道
    input  logic [31:0]                 csr_awaddr,
    input  logic [2:0]                  csr_awprot,
    input  logic                        csr_awvalid,
    output logic                        csr_awready,
    
    // 写数据通道
    input  logic [31:0]                 csr_wdata,
    input  logic [3:0]                  csr_wstrb,
    input  logic                        csr_wvalid,
    output logic                        csr_wready,
    
    // 写响应通道
    output logic [1:0]                  csr_bresp,
    output logic                        csr_bvalid,
    input  logic                        csr_bready,
    
    // 读地址通道
    input  logic [31:0]                 csr_araddr,
    input  logic [2:0]                  csr_arprot,
    input  logic                        csr_arvalid,
    output logic                        csr_arready,
    
    // 读数据通道
    output logic [31:0]                 csr_rdata,
    output logic [1:0]                  csr_rresp,
    output logic                        csr_rvalid,
    input  logic                        csr_rready,
    
    // ============================================
    // AXI4 主接口 (访问 DDR)
    // ============================================
    input  logic                        axi_clk,
    input  logic                        axi_rst,
    
    // 写地址通道
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
    
    // 写数据通道
    output logic [AXI_DATA_WIDTH-1:0]   axi_wdata,
    output logic [AXI_DATA_WIDTH/8-1:0] axi_wstrb,
    output logic                        axi_wlast,
    output logic                        axi_wvalid,
    input  logic                        axi_wready,
    
    // 写响应通道
    input  logic [AXI_ID_WIDTH-1:0]     axi_bid,
    input  logic [1:0]                  axi_bresp,
    input  logic                        axi_bvalid,
    output logic                        axi_bready,
    
    // 读地址通道
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
    input  logic                        axi_arready,
    
    // 读数据通道
    input  logic [AXI_ID_WIDTH-1:0]     axi_rid,
    input  logic [AXI_DATA_WIDTH-1:0]   axi_rdata,
    input  logic [1:0]                  axi_rresp,
    input  logic                        axi_rlast,
    input  logic                        axi_rvalid,
    output logic                        axi_rready
);

    // ============================================
    // 本地参数
    // ============================================
    localparam SYNC_STAGES = 3;  // 增加同步级数以提高可靠性
    
    // ============================================
    // 控制寄存器定义 (CSR 时钟域)
    // ============================================
    logic [31:0] ctrl_reg;      // 0x00: 控制寄存器
    logic [31:0] status_reg_csr;// 0x04: 状态寄存器 (CSR域副本)
    logic [31:0] addr_low_reg;  // 0x08: 起始地址 [31:0]
    logic [31:0] addr_high_reg; // 0x0C: 起始地址 [63:32]
    logic [31:0] length_reg;    // 0x10: 传输长度
    logic [31:0] pattern_reg;   // 0x14: 测试数据模式
    logic [31:0] error_cnt_csr; // 0x18: 错误计数 (CSR域副本)
    logic [31:0] cycle_cnt_csr; // 0x1C: 周期计数 (CSR域副本)
    
    // ============================================
    // AXI 时钟域寄存器
    // ============================================
    logic [31:0] status_reg_axi;
    logic [31:0] error_cnt_axi;
    logic [31:0] cycle_cnt_axi;
    logic [63:0] addr_reg_axi;
    logic [31:0] length_reg_axi;
    logic [31:0] pattern_reg_axi;
    logic        test_mode_axi;
    
    // ============================================
    // 改进的跨时钟域同步
    // ============================================
    logic [SYNC_STAGES-1:0] start_sync;
    logic start_pulse_axi;
    logic start_req_csr;
    logic start_ack_axi;
    logic [SYNC_STAGES-1:0] start_ack_sync;
    
    // CSR域：生成启动请求
    always_ff @(posedge csr_clk or posedge csr_rst) begin
        if (csr_rst) begin
            start_req_csr <= 1'b0;
        end else begin
            if (ctrl_reg[0] && !start_req_csr && !start_ack_sync[SYNC_STAGES-1]) begin
                start_req_csr <= 1'b1;
            end else if (start_ack_sync[SYNC_STAGES-1]) begin
                start_req_csr <= 1'b0;
            end
        end
    end
    
    // AXI域：同步启动请求
    always_ff @(posedge axi_clk or posedge axi_rst) begin
        if (axi_rst) begin
            start_sync <= '0;
            start_pulse_axi <= 1'b0;
            start_ack_axi <= 1'b0;
        end else begin
            start_sync <= {start_sync[SYNC_STAGES-2:0], start_req_csr};
            start_pulse_axi <= start_sync[SYNC_STAGES-1] && !start_sync[SYNC_STAGES-2];
            
            if (start_sync[SYNC_STAGES-1]) begin
                start_ack_axi <= 1'b1;
            end else begin
                start_ack_axi <= 1'b0;
            end
        end
    end
    
    // CSR域：同步应答
    always_ff @(posedge csr_clk or posedge csr_rst) begin
        if (csr_rst) begin
            start_ack_sync <= '0;
        end else begin
            start_ack_sync <= {start_ack_sync[SYNC_STAGES-2:0], start_ack_axi};
        end
    end
    
    // ============================================
    // 状态机类型定义
    // ============================================
    typedef enum logic [2:0] {
        IDLE        = 3'b000,
        WRITE_ADDR  = 3'b001,
        WRITE_DATA  = 3'b010,
        WRITE_RESP  = 3'b011,
        READ_ADDR   = 3'b100,
        READ_DATA   = 3'b101,
        DONE        = 3'b110
    } state_t;
    
    state_t state, state_next;
    
    // ============================================
    // CSR 写逻辑
    // ============================================
    typedef enum logic [1:0] {
        CSR_IDLE,
        CSR_WRITE,
        CSR_RESP
    } csr_write_state_t;
    
    csr_write_state_t csr_wr_state;
    logic [31:0] csr_waddr_reg;
    
    always_ff @(posedge csr_clk or posedge csr_rst) begin
        if (csr_rst) begin
            csr_wr_state <= CSR_IDLE;
            ctrl_reg <= 32'h0;
            addr_low_reg <= 32'h0;
            addr_high_reg <= 32'h0;
            length_reg <= 32'h0;
            pattern_reg <= 32'hA5A5A5A5;
            csr_waddr_reg <= 32'h0;
            csr_awready <= 1'b0;
            csr_wready <= 1'b0;
            csr_bvalid <= 1'b0;
        end else begin
            case (csr_wr_state)
                CSR_IDLE: begin
                    csr_awready <= 1'b1;
                    csr_wready <= 1'b1;
                    csr_bvalid <= 1'b0;
                    
                    if (csr_awvalid && csr_awready) begin
                        csr_waddr_reg <= csr_awaddr;
                        csr_awready <= 1'b0;
                        if (csr_wvalid) begin
                            // 同时收到地址和数据
                            case (csr_awaddr[7:0])
                                8'h00: ctrl_reg <= csr_wdata;
                                8'h08: addr_low_reg <= csr_wdata;
                                8'h0C: addr_high_reg <= csr_wdata;
                                8'h10: length_reg <= csr_wdata;
                                8'h14: pattern_reg <= csr_wdata;
                                default: ;
                            endcase
                            csr_wready <= 1'b0;
                            csr_wr_state <= CSR_RESP;
                        end else begin
                            csr_wr_state <= CSR_WRITE;
                        end
                    end
                end
                
                CSR_WRITE: begin
                    if (csr_wvalid && csr_wready) begin
                        case (csr_waddr_reg[7:0])
                            8'h00: ctrl_reg <= csr_wdata;
                            8'h08: addr_low_reg <= csr_wdata;
                            8'h0C: addr_high_reg <= csr_wdata;
                            8'h10: length_reg <= csr_wdata;
                            8'h14: pattern_reg <= csr_wdata;
                            default: ;
                        endcase
                        csr_wready <= 1'b0;
                        csr_wr_state <= CSR_RESP;
                    end
                end
                
                CSR_RESP: begin
                    csr_bvalid <= 1'b1;
                    if (csr_bready) begin
                        csr_wr_state <= CSR_IDLE;
                    end
                end
            endcase
            
            // 自动清除 start 位
            if (ctrl_reg[0] && start_ack_sync[SYNC_STAGES-1]) begin
                ctrl_reg[0] <= 1'b0;
            end
        end
    end
    
    assign csr_bresp = 2'b00; // OKAY
    
    // ============================================
    // CSR 读逻辑
    // ============================================
    typedef enum logic [1:0] {
        CSR_RD_IDLE,
        CSR_RD_DATA
    } csr_read_state_t;
    
    csr_read_state_t csr_rd_state;
    logic [7:0] csr_raddr_reg;
    
    always_ff @(posedge csr_clk or posedge csr_rst) begin
        if (csr_rst) begin
            csr_rd_state <= CSR_RD_IDLE;
            csr_arready <= 1'b0;
            csr_rvalid <= 1'b0;
            csr_rdata <= 32'h0;
            csr_raddr_reg <= 8'h0;
        end else begin
            case (csr_rd_state)
                CSR_RD_IDLE: begin
                    csr_arready <= 1'b1;
                    csr_rvalid <= 1'b0;
                    
                    if (csr_arvalid && csr_arready) begin
                        csr_raddr_reg <= csr_araddr[7:0];
                        csr_arready <= 1'b0;
                        csr_rd_state <= CSR_RD_DATA;
                    end
                end
                
                CSR_RD_DATA: begin
                    case (csr_raddr_reg)
                        8'h00: csr_rdata <= ctrl_reg;
                        8'h04: csr_rdata <= status_reg_csr;
                        8'h08: csr_rdata <= addr_low_reg;
                        8'h0C: csr_rdata <= addr_high_reg;
                        8'h10: csr_rdata <= length_reg;
                        8'h14: csr_rdata <= pattern_reg;
                        8'h18: csr_rdata <= error_cnt_csr;
                        8'h1C: csr_rdata <= cycle_cnt_csr;
                        default: csr_rdata <= 32'hDEADBEEF;
                    endcase
                    csr_rvalid <= 1'b1;
                    
                    if (csr_rready) begin
                        csr_rd_state <= CSR_RD_IDLE;
                    end
                end
            endcase
        end
    end
    
    assign csr_rresp = 2'b00; // OKAY
    
    // ============================================
    // 将配置寄存器同步到 AXI 时钟域
    // ============================================
    logic [SYNC_STAGES-1:0] config_valid_sync;
    logic config_req_csr;
    logic config_ack_axi;
    
    always_ff @(posedge csr_clk or posedge csr_rst) begin
        if (csr_rst) begin
            config_req_csr <= 1'b0;
        end else begin
            if (ctrl_reg[0] && !config_req_csr) begin
                config_req_csr <= 1'b1;
            end else if (start_ack_sync[SYNC_STAGES-1]) begin
                config_req_csr <= 1'b0;
            end
        end
    end
    
    always_ff @(posedge axi_clk or posedge axi_rst) begin
        if (axi_rst) begin
            config_valid_sync <= '0;
            addr_reg_axi <= 64'h0;
            length_reg_axi <= 32'h0;
            pattern_reg_axi <= 32'hA5A5A5A5;
            test_mode_axi <= 1'b0;
        end else begin
            config_valid_sync <= {config_valid_sync[SYNC_STAGES-2:0], config_req_csr};
            
            if (config_valid_sync[SYNC_STAGES-1] && !config_valid_sync[SYNC_STAGES-2]) begin
                addr_reg_axi <= {addr_high_reg, addr_low_reg};
                length_reg_axi <= length_reg;
                pattern_reg_axi <= pattern_reg;
                test_mode_axi <= ctrl_reg[1];
            end
        end
    end
    
    // ============================================
    // 将状态寄存器同步回 CSR 时钟域
    // ============================================
    logic [SYNC_STAGES-1:0] status_valid_sync;
    
    always_ff @(posedge csr_clk or posedge csr_rst) begin
        if (csr_rst) begin
            status_valid_sync <= '0;
            status_reg_csr <= 32'h0;
            error_cnt_csr <= 32'h0;
            cycle_cnt_csr <= 32'h0;
        end else begin
            status_valid_sync <= {status_valid_sync[SYNC_STAGES-2:0], 1'b1};
            status_reg_csr <= status_reg_axi;
            error_cnt_csr <= error_cnt_axi;
            cycle_cnt_csr <= cycle_cnt_axi;
        end
    end
    
    // ============================================
    // AXI 主接口状态机 (组合逻辑部分)
    // ============================================
    logic [31:0] transfer_cnt;
    logic [31:0] cycle_counter;
    logic [31:0] max_transfers;
    
    always_comb begin
        // 默认值
        state_next = state;
        max_transfers = (length_reg_axi + (AXI_DATA_WIDTH/8) - 1) / (AXI_DATA_WIDTH/8);
        
        case (state)
            IDLE: begin
                if (start_pulse_axi) begin
                    if (test_mode_axi == 1'b0)
                        state_next = WRITE_ADDR;
                    else
                        state_next = READ_ADDR;
                end
            end
            
            WRITE_ADDR: begin
                if (axi_awready)
                    state_next = WRITE_DATA;
            end
            
            WRITE_DATA: begin
                if (axi_wready)
                    state_next = WRITE_RESP;
            end
            
            WRITE_RESP: begin
                if (axi_bvalid) begin
                    if (transfer_cnt >= max_transfers - 1)
                        state_next = DONE;
                    else
                        state_next = WRITE_ADDR;
                end
            end
            
            READ_ADDR: begin
                if (axi_arready)
                    state_next = READ_DATA;
            end
            
            READ_DATA: begin
                if (axi_rvalid) begin
                    if (transfer_cnt >= max_transfers - 1)
                        state_next = DONE;
                    else
                        state_next = READ_ADDR;
                end
            end
            
            DONE: begin
                state_next = IDLE;
            end
            
            default: state_next = IDLE;
        endcase
    end
    
    // ============================================
    // AXI 主接口状态机 (时序逻辑部分)
    // ============================================
    always_ff @(posedge axi_clk or posedge axi_rst) begin
        if (axi_rst) begin
            state <= IDLE;
            transfer_cnt <= 32'h0;
            cycle_counter <= 32'h0;
            error_cnt_axi <= 32'h0;
            status_reg_axi <= 32'h0;
            cycle_cnt_axi <= 32'h0;
            
            // 写通道初始化
            axi_awid <= '0;
            axi_awaddr <= '0;
            axi_awlen <= 8'h0;
            axi_awsize <= 3'($clog2(AXI_DATA_WIDTH/8));
            axi_awburst <= 2'b01;
            axi_awlock <= 1'b0;
            axi_awcache <= 4'b0010;
            axi_awprot <= 3'b000;
            axi_awqos <= 4'h0;
            axi_awvalid <= 1'b0;
            
            axi_wdata <= '0;
            axi_wstrb <= '1;
            axi_wlast <= 1'b0;
            axi_wvalid <= 1'b0;
            
            axi_bready <= 1'b0;
            
            // 读通道初始化
            axi_arid <= '0;
            axi_araddr <= '0;
            axi_arlen <= 8'h0;
            axi_arsize <= 3'($clog2(AXI_DATA_WIDTH/8));
            axi_arburst <= 2'b01;
            axi_arlock <= 1'b0;
            axi_arcache <= 4'b0010;
            axi_arprot <= 3'b000;
            axi_arqos <= 4'h0;
            axi_arvalid <= 1'b0;
            
            axi_rready <= 1'b0;
            
        end else begin
            state <= state_next;
            cycle_counter <= cycle_counter + 1'b1;
            
            case (state)
                IDLE: begin
                    status_reg_axi[0] <= 1'b0; // not busy
                    status_reg_axi[1] <= 1'b0; // not done
                    
                    if (start_pulse_axi) begin
                        status_reg_axi[0] <= 1'b1; // busy
                        transfer_cnt <= 32'h0;
                        cycle_counter <= 32'h0;
                    end
                end
                
                WRITE_ADDR: begin
                    if (!axi_awvalid || axi_awready) begin
                        axi_awid <= 4'h1;
                        axi_awaddr <= addr_reg_axi + (transfer_cnt * (AXI_DATA_WIDTH/8));
                        axi_awlen <= 8'h0;
                        axi_awvalid <= 1'b1;
                    end
                end
                
                WRITE_DATA: begin
                    if (axi_awready && axi_awvalid) begin
                        axi_awvalid <= 1'b0;
                    end
                    
                    if (!axi_wvalid || axi_wready) begin
                        axi_wdata <= {(AXI_DATA_WIDTH/32){pattern_reg_axi}};
                        axi_wstrb <= '1;
                        axi_wlast <= 1'b1;
                        axi_wvalid <= 1'b1;
                    end
                end
                
                WRITE_RESP: begin
                    if (axi_wready && axi_wvalid) begin
                        axi_wvalid <= 1'b0;
                        axi_wlast <= 1'b0;
                    end
                    
                    axi_bready <= 1'b1;
                    
                    if (axi_bvalid && axi_bready) begin
                        axi_bready <= 1'b0;
                        transfer_cnt <= transfer_cnt + 1'b1;
                        
                        if (axi_bresp != 2'b00) begin
                            error_cnt_axi <= error_cnt_axi + 1'b1;
                            status_reg_axi[2] <= 1'b1; // error
                        end
                    end
                end
                
                READ_ADDR: begin
                    if (!axi_arvalid || axi_arready) begin
                        axi_arid <= 4'h1;
                        axi_araddr <= addr_reg_axi + (transfer_cnt * (AXI_DATA_WIDTH/8));
                        axi_arlen <= 8'h0;
                        axi_arvalid <= 1'b1;
                    end
                end
                
                READ_DATA: begin
                    if (axi_arready && axi_arvalid) begin
                        axi_arvalid <= 1'b0;
                    end
                    
                    axi_rready <= 1'b1;
                    
                    if (axi_rvalid && axi_rready) begin
                        axi_rready <= 1'b0;
                        transfer_cnt <= transfer_cnt + 1'b1;
                        
                        // 数据校验
                        for (int i = 0; i < AXI_DATA_WIDTH/32; i++) begin
                            if (axi_rdata[i*32 +: 32] != pattern_reg_axi) begin
                                error_cnt_axi <= error_cnt_axi + 1'b1;
                                status_reg_axi[2] <= 1'b1;
                            end
                        end
                    end
                end
                
                DONE: begin
                    status_reg_axi[0] <= 1'b0; // not busy
                    status_reg_axi[1] <= 1'b1; // done
                    cycle_cnt_axi <= cycle_counter;
                    transfer_cnt <= 32'h0;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule