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
    // 控制寄存器定义
    // ============================================
    logic [31:0] ctrl_reg;      // 0x00: 控制寄存器 (bit0: start, bit1: mode)
    logic [31:0] status_reg;    // 0x04: 状态寄存器 (bit0: busy, bit1: done, bit2: error)
    logic [31:0] addr_low_reg;  // 0x08: 起始地址 [31:0]
    logic [31:0] addr_high_reg; // 0x0C: 起始地址 [63:32]
    logic [31:0] length_reg;    // 0x10: 传输长度 (字节数)
    logic [31:0] pattern_reg;   // 0x14: 测试数据模式
    logic [31:0] error_cnt_reg; // 0x18: 错误计数
    logic [31:0] cycle_cnt_reg; // 0x1C: 周期计数
    
    logic [63:0] addr_reg;
    assign addr_reg = {addr_high_reg, addr_low_reg};
    
    // ============================================
    // CSR 写逻辑
    // ============================================
    logic [31:0] csr_waddr_reg;
    
    always_ff @(posedge csr_clk) begin
        if (csr_rst) begin
            ctrl_reg <= 32'h0;
            addr_low_reg <= 32'h0;
            addr_high_reg <= 32'h0;
            length_reg <= 32'h0;
            pattern_reg <= 32'hA5A5A5A5;
            csr_awready <= 1'b1;
            csr_wready <= 1'b1;
            csr_bvalid <= 1'b0;
            csr_waddr_reg <= 32'h0;
        end else begin
            // 写地址握手
            if (csr_awvalid && csr_awready) begin
                csr_waddr_reg <= csr_awaddr;
                csr_awready <= 1'b0;
            end
            
            // 写数据握手
            if (csr_wvalid && csr_wready) begin
                case (csr_waddr_reg[7:0])
                    8'h00: ctrl_reg <= csr_wdata;
                    8'h08: addr_low_reg <= csr_wdata;
                    8'h0C: addr_high_reg <= csr_wdata;
                    8'h10: length_reg <= csr_wdata;
                    8'h14: pattern_reg <= csr_wdata;
                    default: ; // 只读寄存器或无效地址
                endcase
                csr_wready <= 1'b0;
                csr_bvalid <= 1'b1;
            end
            
            // 写响应握手
            if (csr_bvalid && csr_bready) begin
                csr_bvalid <= 1'b0;
                csr_awready <= 1'b1;
                csr_wready <= 1'b1;
            end
            
            // 自动清除 start 位
            if (ctrl_reg[0]) begin
                ctrl_reg[0] <= 1'b0;
            end
        end
    end
    
    assign csr_bresp = 2'b00; // OKAY
    
    // ============================================
    // CSR 读逻辑
    // ============================================
    always_ff @(posedge csr_clk) begin
        if (csr_rst) begin
            csr_arready <= 1'b1;
            csr_rvalid <= 1'b0;
            csr_rdata <= 32'h0;
        end else begin
            if (csr_arvalid && csr_arready) begin
                csr_arready <= 1'b0;
                case (csr_araddr[7:0])
                    8'h00: csr_rdata <= ctrl_reg;
                    8'h04: csr_rdata <= status_reg;
                    8'h08: csr_rdata <= addr_low_reg;
                    8'h0C: csr_rdata <= addr_high_reg;
                    8'h10: csr_rdata <= length_reg;
                    8'h14: csr_rdata <= pattern_reg;
                    8'h18: csr_rdata <= error_cnt_reg;
                    8'h1C: csr_rdata <= cycle_cnt_reg;
                    default: csr_rdata <= 32'hDEADBEEF;
                endcase
                csr_rvalid <= 1'b1;
            end
            
            if (csr_rvalid && csr_rready) begin
                csr_rvalid <= 1'b0;
                csr_arready <= 1'b1;
            end
        end
    end
    
    assign csr_rresp = 2'b00; // OKAY
    
    // ============================================
    // AXI 主接口状态机
    // ============================================
    typedef enum logic [2:0] {
        IDLE,
        WRITE_ADDR,
        WRITE_DATA,
        WRITE_RESP,
        READ_ADDR,
        READ_DATA,
        DONE
    } state_t;
    
    state_t state;
    logic [31:0] transfer_cnt;
    logic [31:0] cycle_counter;
    logic test_start;
    logic test_mode; // 0: write, 1: read
    
    // 跨时钟域同步
    logic [1:0] start_sync;
    always_ff @(posedge axi_clk) begin
        start_sync <= {start_sync[0], ctrl_reg[0]};
    end
    assign test_start = start_sync[1];
    assign test_mode = ctrl_reg[1];
    
    always_ff @(posedge axi_clk) begin
        if (axi_rst) begin
            state <= IDLE;
            transfer_cnt <= 32'h0;
            cycle_counter <= 32'h0;
            error_cnt_reg <= 32'h0;
            status_reg <= 32'h0;
            
            axi_awid <= '0;
            axi_awaddr <= '0;
            axi_awlen <= 8'h0;
            axi_awsize <= 3'b100; // 16 bytes (128 bits)
            axi_awburst <= 2'b01; // INCR
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
            
            axi_arid <= '0;
            axi_araddr <= '0;
            axi_arlen <= 8'h0;
            axi_arsize <= 3'b100;
            axi_arburst <= 2'b01;
            axi_arlock <= 1'b0;
            axi_arcache <= 4'b0010;
            axi_arprot <= 3'b000;
            axi_arqos <= 4'h0;
            axi_arvalid <= 1'b0;
            
            axi_rready <= 1'b0;
            
        end else begin
            cycle_counter <= cycle_counter + 1;
            
            case (state)
                IDLE: begin
                    status_reg[0] <= 1'b0; // not busy
                    status_reg[1] <= 1'b0; // not done
                    
                    if (test_start) begin
                        status_reg[0] <= 1'b1; // busy
                        transfer_cnt <= 32'h0;
                        cycle_counter <= 32'h0;
                        
                        if (test_mode == 1'b0) begin
                            state <= WRITE_ADDR;
                        end else begin
                            state <= READ_ADDR;
                        end
                    end
                end
                
                WRITE_ADDR: begin
                    axi_awid <= 4'h1;
                    axi_awaddr <= addr_reg + (transfer_cnt * (AXI_DATA_WIDTH/8));
                    axi_awlen <= 8'h0; // 1 transfer
                    axi_awvalid <= 1'b1;
                    
                    if (axi_awready) begin
                        axi_awvalid <= 1'b0;
                        state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    axi_wdata <= {(AXI_DATA_WIDTH/32){pattern_reg}};
                    axi_wstrb <= '1;
                    axi_wlast <= 1'b1;
                    axi_wvalid <= 1'b1;
                    
                    if (axi_wready) begin
                        axi_wvalid <= 1'b0;
                        axi_wlast <= 1'b0;
                        state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    axi_bready <= 1'b1;
                    
                    if (axi_bvalid) begin
                        axi_bready <= 1'b0;
                        transfer_cnt <= transfer_cnt + 1;
                        
                        if (axi_bresp != 2'b00) begin
                            error_cnt_reg <= error_cnt_reg + 1;
                            status_reg[2] <= 1'b1; // error
                        end
                        
                        if (transfer_cnt >= (length_reg / (AXI_DATA_WIDTH/8))) begin
                            state <= DONE;
                        end else begin
                            state <= WRITE_ADDR;
                        end
                    end
                end
                
                READ_ADDR: begin
                    axi_arid <= 4'h1;
                    axi_araddr <= addr_reg + (transfer_cnt * (AXI_DATA_WIDTH/8));
                    axi_arlen <= 8'h0;
                    axi_arvalid <= 1'b1;
                    
                    if (axi_arready) begin
                        axi_arvalid <= 1'b0;
                        state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    axi_rready <= 1'b1;
                    
                    if (axi_rvalid) begin
                        axi_rready <= 1'b0;
                        transfer_cnt <= transfer_cnt + 1;
                        
                        // 简单的数据校验（检查每个32位字）
                        for (int i = 0; i < AXI_DATA_WIDTH/32; i++) begin
                            if (axi_rdata[i*32 +: 32] != pattern_reg) begin
                                error_cnt_reg <= error_cnt_reg + 1;
                                status_reg[2] <= 1'b1;
                            end
                        end
                        
                        if (transfer_cnt >= (length_reg / (AXI_DATA_WIDTH/8))) begin
                            state <= DONE;
                        end else begin
                            state <= READ_ADDR;
                        end
                    end
                end
                
                DONE: begin
                    status_reg[0] <= 1'b0; // not busy
                    status_reg[1] <= 1'b1; // done
                    cycle_cnt_reg <= cycle_counter;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule