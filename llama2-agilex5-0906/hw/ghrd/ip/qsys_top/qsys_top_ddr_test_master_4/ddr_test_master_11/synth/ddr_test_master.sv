// ddr_test_master.sv - 修复版本
// 根据GPT review修改的关键问题：
// 1. CSR地址宽度改为8位
// 2. AXI4-Lite支持AW/W独立到达
// 3. 正确处理WSTRB
// 4. 所有握手使用VALID && READY
// 5. 修复CDC和错误计数
// 6. 检查RRESP/BRESP

module ddr_test_master #(
    parameter AXI_ADDR_WIDTH = 64,
    parameter AXI_DATA_WIDTH = 128,
    parameter AXI_ID_WIDTH   = 4,
    parameter CSR_ADDR_WIDTH = 8  // 新增：256字节CSR空间
)(
    // ============================================
    // AXI4-Lite 控制接口 (CSR)
    // ============================================
    input  logic                        csr_clk,
    input  logic                        csr_rst,
    
    // 写地址通道
    input  logic [CSR_ADDR_WIDTH-1:0]   csr_awaddr,  // 改为8位
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
    input  logic [CSR_ADDR_WIDTH-1:0]   csr_araddr,  // 改为8位
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
    localparam SYNC_STAGES = 3;
    localparam BYTES_PER_BEAT = AXI_DATA_WIDTH / 8;
    
    // ============================================
    // 控制寄存器定义 (CSR 时钟域)
    // ============================================
    logic [31:0] ctrl_reg;      // 0x00: 控制寄存器
    logic [31:0] status_reg_csr;// 0x04: 状态寄存器
    logic [31:0] addr_low_reg;  // 0x08: 起始地址 [31:0]
    logic [31:0] addr_high_reg; // 0x0C: 起始地址 [63:32]
    logic [31:0] length_reg;    // 0x10: 传输长度
    logic [31:0] pattern_reg;   // 0x14: 测试数据模式
    logic [31:0] error_cnt_csr; // 0x18: 错误计数
    logic [31:0] cycle_cnt_csr; // 0x1C: 周期计数
    
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
    
    // 配置寄存器快照（用于CDC）
    logic [63:0] addr_snapshot;
    logic [31:0] length_snapshot;
    logic [31:0] pattern_snapshot;
    logic        mode_snapshot;
    
    // ============================================
    // 改进的跨时钟域同步 - Toggle-based handshake
    // ============================================
    logic start_toggle_csr;
    logic [SYNC_STAGES-1:0] start_toggle_sync;
    logic start_toggle_axi_prev;
    logic start_pulse_axi;
    
    // CSR域：切换start toggle
    always_ff @(posedge csr_clk or posedge csr_rst) begin
        if (csr_rst) begin
            start_toggle_csr <= 1'b0;
        end else begin
            if (ctrl_reg[0] && !status_reg_csr[0]) begin  // start且非busy
                start_toggle_csr <= ~start_toggle_csr;
            end
        end
    end
    
    // AXI域：同步toggle并生成脉冲
    always_ff @(posedge axi_clk or posedge axi_rst) begin
        if (axi_rst) begin
            start_toggle_sync <= '0;
            start_toggle_axi_prev <= 1'b0;
            start_pulse_axi <= 1'b0;
        end else begin
            start_toggle_sync <= {start_toggle_sync[SYNC_STAGES-2:0], start_toggle_csr};
            start_toggle_axi_prev <= start_toggle_sync[SYNC_STAGES-1];
            start_pulse_axi <= start_toggle_sync[SYNC_STAGES-1] ^ start_toggle_axi_prev;
        end
    end
    
    // ============================================
    // 配置寄存器采样 - 使用handshake
    // ============================================
    always_ff @(posedge axi_clk or posedge axi_rst) begin
        if (axi_rst) begin
            addr_snapshot <= 64'h0;
            length_snapshot <= 32'h0;
            pattern_snapshot <= 32'hA5A5A5A5;
            mode_snapshot <= 1'b0;
        end else if (start_pulse_axi) begin
            addr_snapshot <= addr_reg_axi;
            length_snapshot <= length_reg_axi;
            pattern_snapshot <= pattern_reg_axi;
            mode_snapshot <= test_mode_axi;
        end
    end
    
    // 直接采样（如果时钟相同可以这样，否则需要更复杂的handshake）
    always_ff @(posedge axi_clk or posedge axi_rst) begin
        if (axi_rst) begin
            addr_reg_axi <= 64'h0;
            length_reg_axi <= 32'h0;
            pattern_reg_axi <= 32'hA5A5A5A5;
            test_mode_axi <= 1'b0;
        end else begin
            // 简化版：假设两个时钟相同或已经通过Platform Designer同步
            addr_reg_axi <= {addr_high_reg, addr_low_reg};
            length_reg_axi <= length_reg;
            pattern_reg_axi <= pattern_reg;
            test_mode_axi <= ctrl_reg[1];
        end
    end
    
    // ============================================
    // 状态寄存器同步回CSR域 - Done toggle
    // ============================================
    logic done_toggle_axi;
    logic [SYNC_STAGES-1:0] done_toggle_sync;
    logic done_toggle_csr_prev;
    logic done_pulse_csr;
    
    logic [31:0] status_snapshot;
    logic [31:0] error_snapshot;
    logic [31:0] cycle_snapshot;
    
    // AXI域：测试完成时切换toggle并锁存结果
    always_ff @(posedge axi_clk or posedge axi_rst) begin
        if (axi_rst) begin
            done_toggle_axi <= 1'b0;
            status_snapshot <= 32'h0;
            error_snapshot <= 32'h0;
            cycle_snapshot <= 32'h0;
        end else begin
            if (status_reg_axi[1] && !status_reg_axi[0]) begin  // done且非busy
                done_toggle_axi <= ~done_toggle_axi;
                status_snapshot <= status_reg_axi;
                error_snapshot <= error_cnt_axi;
                cycle_snapshot <= cycle_cnt_axi;
            end
        end
    end
    
    // CSR域：同步done toggle并采样结果
    always_ff @(posedge csr_clk or posedge csr_rst) begin
        if (csr_rst) begin
            done_toggle_sync <= '0;
            done_toggle_csr_prev <= 1'b0;
            done_pulse_csr <= 1'b0;
            status_reg_csr <= 32'h0;
            error_cnt_csr <= 32'h0;
            cycle_cnt_csr <= 32'h0;
        end else begin
            done_toggle_sync <= {done_toggle_sync[SYNC_STAGES-2:0], done_toggle_axi};
            done_toggle_csr_prev <= done_toggle_sync[SYNC_STAGES-1];
            done_pulse_csr <= done_toggle_sync[SYNC_STAGES-1] ^ done_toggle_csr_prev;
            
            if (done_pulse_csr) begin
                status_reg_csr <= status_snapshot;
                error_cnt_csr <= error_snapshot;
                cycle_cnt_csr <= cycle_snapshot;
            end
        end
    end
    
    // ============================================
    // CSR 写逻辑 - 支持AW/W独立到达
    // ============================================
    logic aw_received;
    logic w_received;
    logic [CSR_ADDR_WIDTH-1:0] awaddr_hold;
    logic [31:0] wdata_hold;
    logic [3:0] wstrb_hold;
    
    always_ff @(posedge csr_clk or posedge csr_rst) begin
        if (csr_rst) begin
            aw_received <= 1'b0;
            w_received <= 1'b0;
            awaddr_hold <= '0;
            wdata_hold <= 32'h0;
            wstrb_hold <= 4'h0;
            csr_awready <= 1'b1;
            csr_wready <= 1'b1;
            csr_bvalid <= 1'b0;
            csr_bresp <= 2'b00;
            
            ctrl_reg <= 32'h0;
            addr_low_reg <= 32'h0;
            addr_high_reg <= 32'h0;
            length_reg <= 32'h0;
            pattern_reg <= 32'hA5A5A5A5;
            
        end else begin
            // 接收写地址
            if (csr_awvalid && csr_awready) begin
                awaddr_hold <= csr_awaddr;
                aw_received <= 1'b1;
                csr_awready <= 1'b0;
            end
            
            // 接收写数据
            if (csr_wvalid && csr_wready) begin
                wdata_hold <= csr_wdata;
                wstrb_hold <= csr_wstrb;
                w_received <= 1'b1;
                csr_wready <= 1'b0;
            end
            
            // 两者都收到后执行写操作
            if (aw_received && w_received && !csr_bvalid) begin
                // 按字节处理WSTRB
                case (awaddr_hold)
                    8'h00: begin
                        for (int i = 0; i < 4; i++) begin
                            if (wstrb_hold[i])
                                ctrl_reg[i*8 +: 8] <= wdata_hold[i*8 +: 8];
                        end
                    end
                    8'h08: begin
                        for (int i = 0; i < 4; i++) begin
                            if (wstrb_hold[i])
                                addr_low_reg[i*8 +: 8] <= wdata_hold[i*8 +: 8];
                        end
                    end
                    8'h0C: begin
                        for (int i = 0; i < 4; i++) begin
                            if (wstrb_hold[i])
                                addr_high_reg[i*8 +: 8] <= wdata_hold[i*8 +: 8];
                        end
                    end
                    8'h10: begin
                        for (int i = 0; i < 4; i++) begin
                            if (wstrb_hold[i])
                                length_reg[i*8 +: 8] <= wdata_hold[i*8 +: 8];
                        end
                    end
                    8'h14: begin
                        for (int i = 0; i < 4; i++) begin
                            if (wstrb_hold[i])
                                pattern_reg[i*8 +: 8] <= wdata_hold[i*8 +: 8];
                        end
                    end
                    default: begin
                        // 无效地址，设置错误响应
                        csr_bresp <= 2'b10;  // SLVERR
                    end
                endcase
                
                csr_bvalid <= 1'b1;
                aw_received <= 1'b0;
                w_received <= 1'b0;
            end
            
            // 写响应握手
            if (csr_bvalid && csr_bready) begin
                csr_bvalid <= 1'b0;
                csr_bresp <= 2'b00;
                csr_awready <= 1'b1;
                csr_wready <= 1'b1;
            end
            
            // 自动清除start位
            if (ctrl_reg[0] && status_reg_csr[0]) begin
                ctrl_reg[0] <= 1'b0;
            end
        end
    end
    
    // ============================================
    // CSR 读逻辑
    // ============================================
    logic [CSR_ADDR_WIDTH-1:0] araddr_hold;
    logic ar_received;
    
    always_ff @(posedge csr_clk or posedge csr_rst) begin
        if (csr_rst) begin
            ar_received <= 1'b0;
            araddr_hold <= '0;
            csr_arready <= 1'b1;
            csr_rvalid <= 1'b0;
            csr_rdata <= 32'h0;
            csr_rresp <= 2'b00;
            
        end else begin
            // 接收读地址
            if (csr_arvalid && csr_arready) begin
                araddr_hold <= csr_araddr;
                ar_received <= 1'b1;
                csr_arready <= 1'b0;
            end
            
            // 生成读数据
            if (ar_received && !csr_rvalid) begin
                case (araddr_hold)
                    8'h00: csr_rdata <= ctrl_reg;
                    8'h04: csr_rdata <= status_reg_csr;
                    8'h08: csr_rdata <= addr_low_reg;
                    8'h0C: csr_rdata <= addr_high_reg;
                    8'h10: csr_rdata <= length_reg;
                    8'h14: csr_rdata <= pattern_reg;
                    8'h18: csr_rdata <= error_cnt_csr;
                    8'h1C: csr_rdata <= cycle_cnt_csr;
                    default: begin
                        csr_rdata <= 32'hDEADBEEF;
                        csr_rresp <= 2'b10;  // SLVERR
                    end
                endcase
                csr_rvalid <= 1'b1;
                ar_received <= 1'b0;
            end
            
            // 读数据握手
            if (csr_rvalid && csr_rready) begin
                csr_rvalid <= 1'b0;
                csr_rresp <= 2'b00;
                csr_arready <= 1'b1;
            end
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
    
    state_t state;
    
    // ============================================
    // AXI 主接口控制变量
    // ============================================
    logic [31:0] transfer_cnt;
    logic [31:0] cycle_counter;
    logic [31:0] max_transfers;
    logic [31:0] remaining_bytes;
    logic [AXI_DATA_WIDTH/8-1:0] last_beat_strb;
    
    // ============================================
    // 计算传输参数
    // ============================================
    always_comb begin
        if (length_snapshot == 0) begin
            max_transfers = 0;
            remaining_bytes = 0;
            last_beat_strb = '0;
        end else begin
            max_transfers = (length_snapshot + BYTES_PER_BEAT - 1) / BYTES_PER_BEAT;
            remaining_bytes = length_snapshot - (max_transfers - 1) * BYTES_PER_BEAT;
            
            // 计算最后一个beat的WSTRB
            if (remaining_bytes >= BYTES_PER_BEAT) begin
                last_beat_strb = '1;
            end else begin
                last_beat_strb = (1 << remaining_bytes) - 1;
            end
        end
    end
    
    // ============================================
    // AXI 主接口状态机
    // ============================================
    always_ff @(posedge axi_clk or posedge axi_rst) begin
        if (axi_rst) begin
            state <= IDLE;
            transfer_cnt <= 32'h0;
            cycle_counter <= 32'h0;
            error_cnt_axi <= 32'h0;
            status_reg_axi <= 32'h0;
            cycle_cnt_axi <= 32'h0;
            
            // AXI信号初始化
            axi_awid <= '0;
            axi_awaddr <= '0;
            axi_awlen <= 8'h0;
            axi_awsize <= 3'($clog2(BYTES_PER_BEAT));
            axi_awburst <= 2'b01;
            axi_awlock <= 1'b0;
            axi_awcache <= 4'b0010;
            axi_awprot <= 3'b000;
            axi_awqos <= 4'h0;
            axi_awvalid <= 1'b0;
            
            axi_wdata <= '0;
            axi_wstrb <= '0;
            axi_wlast <= 1'b0;
            axi_wvalid <= 1'b0;
            axi_bready <= 1'b0;
            
            axi_arid <= '0;
            axi_araddr <= '0;
            axi_arlen <= 8'h0;
            axi_arsize <= 3'($clog2(BYTES_PER_BEAT));
            axi_arburst <= 2'b01;
            axi_arlock <= 1'b0;
            axi_arcache <= 4'b0010;
            axi_arprot <= 3'b000;
            axi_arqos <= 4'h0;
            axi_arvalid <= 1'b0;
            axi_rready <= 1'b0;
            
        end else begin
            cycle_counter <= cycle_counter + 1'b1;
            
            case (state)
                IDLE: begin
                    status_reg_axi[0] <= 1'b0;  // not busy
                    
                    if (start_pulse_axi) begin
                        // 检查参数有效性
                        if (length_snapshot == 0) begin
                            // 零长度，直接完成
                            status_reg_axi[1] <= 1'b1;  // done
                            state <= DONE;
                        end else if ((addr_snapshot[3:0] != 0) || 
                                   (length_snapshot % BYTES_PER_BEAT != 0)) begin
                            // 地址或长度未对齐（简化版：要求16字节对齐）
                            status_reg_axi[2] <= 1'b1;  // error
                            status_reg_axi[1] <= 1'b1;  // done
                            error_cnt_axi <= error_cnt_axi + 1'b1;
                            state <= DONE;
                        end else begin
                            // 开始测试
                            status_reg_axi[0] <= 1'b1;  // busy
                            status_reg_axi[1] <= 1'b0;  // not done
                            status_reg_axi[2] <= 1'b0;  // no error
                            transfer_cnt <= 32'h0;
                            cycle_counter <= 32'h0;
                            error_cnt_axi <= 32'h0;
                            
                            if (mode_snapshot == 1'b0)
                                state <= WRITE_ADDR;
                            else
                                state <= READ_ADDR;
                        end
                    end
                end
                
                // ========== 写事务 ==========
                WRITE_ADDR: begin
                    if (!axi_awvalid) begin
                        axi_awid <= AXI_ID_WIDTH'(0);
                        axi_awaddr <= addr_snapshot + (transfer_cnt * BYTES_PER_BEAT);
                        axi_awlen <= 8'h0;  // 单beat
                        axi_awvalid <= 1'b1;
                    end
                    
                    if (axi_awvalid && axi_awready) begin
                        axi_awvalid <= 1'b0;
                        state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (!axi_wvalid) begin
                        axi_wdata <= {(AXI_DATA_WIDTH/32){pattern_snapshot}};
                        
                        // 最后一个beat使用计算的WSTRB
                        if (transfer_cnt == max_transfers - 1)
                            axi_wstrb <= last_beat_strb;
                        else
                            axi_wstrb <= '1;
                            
                        axi_wlast <= 1'b1;
                        axi_wvalid <= 1'b1;
                    end
                    
                    if (axi_wvalid && axi_wready) begin
                        axi_wvalid <= 1'b0;
                        axi_wlast <= 1'b0;
                        state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    axi_bready <= 1'b1;
                    
                    if (axi_bvalid && axi_bready) begin
                        axi_bready <= 1'b0;
                        
                        // 检查响应
                        if (axi_bresp != 2'b00) begin
                            error_cnt_axi <= error_cnt_axi + 1'b1;
                            status_reg_axi[2] <= 1'b1;  // error
                        end
                        
                        // 检查ID（可选）
                        if (axi_bid != AXI_ID_WIDTH'(0)) begin
                            error_cnt_axi <= error_cnt_axi + 1'b1;
                        end
                        
                        transfer_cnt <= transfer_cnt + 1'b1;
                        
                        if (transfer_cnt >= max_transfers - 1)
                            state <= DONE;
                        else
                            state <= WRITE_ADDR;
                    end
                end
                
                // ========== 读事务 ==========
                READ_ADDR: begin
                    if (!axi_arvalid) begin
                        axi_arid <= AXI_ID_WIDTH'(0);
                        axi_araddr <= addr_snapshot + (transfer_cnt * BYTES_PER_BEAT);
                        axi_arlen <= 8'h0;  // 单beat
                        axi_arvalid <= 1'b1;
                    end
                    
                    if (axi_arvalid && axi_arready) begin
                        axi_arvalid <= 1'b0;
                        state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    axi_rready <= 1'b1;
                    
                    if (axi_rvalid && axi_rready) begin
                        axi_rready <= 1'b0;
                        
                        // 检查响应
                        if (axi_rresp != 2'b00) begin
                            error_cnt_axi <= error_cnt_axi + 1'b1;
                            status_reg_axi[2] <= 1'b1;
                        end
                        
                        // 检查RLAST
                        if (!axi_rlast) begin
                            error_cnt_axi <= error_cnt_axi + 1'b1;
                        end
                        
                        // 检查ID
                        if (axi_rid != AXI_ID_WIDTH'(0)) begin
                            error_cnt_axi <= error_cnt_axi + 1'b1;
                        end
                        
                        // 数据校验 - 修复多lane错误计数
                        if (axi_rresp == 2'b00) begin
                            automatic int beat_errors = 0;
                            for (int i = 0; i < AXI_DATA_WIDTH/32; i++) begin
                                if (axi_rdata[i*32 +: 32] != pattern_snapshot)
                                    beat_errors++;
                            end
                            if (beat_errors > 0) begin
                                error_cnt_axi <= error_cnt_axi + beat_errors;
                                status_reg_axi[2] <= 1'b1;
                            end
                        end
                        
                        transfer_cnt <= transfer_cnt + 1'b1;
                        
                        if (transfer_cnt >= max_transfers - 1)
                            state <= DONE;
                        else
                            state <= READ_ADDR;
                    end
                end
                
                // ========== 完成 ==========
                DONE: begin
                    status_reg_axi[0] <= 1'b0;  // not busy
                    status_reg_axi[1] <= 1'b1;  // done
                    cycle_cnt_axi <= cycle_counter;
                    transfer_cnt <= 32'h0;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule