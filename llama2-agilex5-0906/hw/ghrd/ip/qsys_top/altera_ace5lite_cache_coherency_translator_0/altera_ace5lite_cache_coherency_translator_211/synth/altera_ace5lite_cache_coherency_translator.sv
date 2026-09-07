// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


`timescale 1 ps / 1 ps
module altera_ace5lite_cache_coherency_translator #(
        parameter CONTROL_INTERFACE_EN   = 0,
        parameter AXI_INTERFACE_TYPE     = 0,
        parameter ARDOMAIN_OVERRIDE      = 2'h2,
        // parameter ARBAR_OVERRIDE         = 2'h0,
        parameter ARSNOOP_OVERRIDE       = 4'h0,
        parameter ARCACHE_OVERRIDE_EN    = 1,
        parameter ARCACHE_OVERRIDE       = 4'hF,
        parameter ARUSER_OVERRIDE        = 8'h0,    
        parameter AWDOMAIN_OVERRIDE      = 2'h2,
        // parameter AWBAR_OVERRIDE         = 2'h0,
        parameter AWSNOOP_OVERRIDE       = 3'h0,
        parameter AWCACHE_OVERRIDE_EN    = 1,
        parameter AWCACHE_OVERRIDE       = 4'hF,
        parameter AWUSER_OVERRIDE        = 8'h0,
        parameter AxPROT_OVERRIDE_EN     = 1,
        parameter AxPROT_OVERRIDE        = 3'h3,
        // ACE5Lite signals
        parameter AWSTASHNID_OVERRIDE      = 11'h0 ,
        parameter AWSTASHNIDEN_OVERRIDE    = 1'h0 ,
        parameter AWSTASHLPID_OVERRIDE     = 5'h0 ,
        parameter AWSTASHLPIDEN_OVERRIDE   = 1'h0 ,
        parameter AWATOP_OVERRIDE          = 6'h0 ,
        // parameter AWUNIQUE_OVERRIDE        = 1'h0 ,
        parameter ENABLE_MMU               = 0,
        parameter AWMMUSECSID_OVERRIDE     = 1'h0,
        parameter AWMMUSID_OVERRIDE        = 'h0,
        parameter ARMMUSECSID_OVERRIDE     = 1'h0,
        parameter ARMMUSID_OVERRIDE        = 'h0,
        parameter SID_WIDTH                = 'h1,
        parameter ADDR_WIDTH               = 32,
        parameter DATA_WIDTH               = 128,
        parameter AXM_ID_WIDTH             = 4,
        parameter AXS_ID_WIDTH             = 4,
        parameter USER_WIDTH              = 8,
        parameter WSTRB_WIDTH             = 16,
        localparam CSR_ADDR_WIDTH         = 6

)(
        input  logic         clk,            // clock.clk
        input  logic         reset,          // reset.reset
        
        // AXI4-Lite CSR Interface- synchronous to csr_clk 
        input  logic                        csr_clk,            
        input  logic                        csr_reset,          
        input  logic [CSR_ADDR_WIDTH-1:0]   s_csr_araddr,
        input  logic                        s_csr_arvalid,
        output logic                        s_csr_arready,
        input  logic [CSR_ADDR_WIDTH-1:0]   s_csr_awaddr,
        input  logic                        s_csr_awvalid,
        output logic                        s_csr_awready,
        input  logic [31:0]                 s_csr_wdata,
        input  logic [3:0]                  s_csr_wstrb,
        input  logic                        s_csr_wvalid,
        output logic                        s_csr_wready,
        output logic [1:0]                  s_csr_bresp ,
        output logic                        s_csr_bvalid,
        input  logic                        s_csr_bready,
        output logic  [31:0]                s_csr_rdata,
        output logic  [1:0]                 s_csr_rresp,
        output logic                        s_csr_rvalid,
        input  logic                        s_csr_rready,
        
        // ACE-LITE Master
        output logic [ADDR_WIDTH -1 :0]      m_ace5lite_araddr,  
        // output logic [1:0]                   m_ace5lite_arbar,   
        output logic [1:0]                   m_ace5lite_arburst, 
        output logic [3:0]                   m_ace5lite_arcache, 
        output logic [1:0]                   m_ace5lite_ardomain,
        output logic [AXM_ID_WIDTH -1 :0]    m_ace5lite_arid,    
        output logic [7:0]                   m_ace5lite_arlen,   
        output logic                         m_ace5lite_arlock,  
        output logic [2:0]                   m_ace5lite_arprot,  
        output logic [3:0]                   m_ace5lite_arqos,   
        input  logic                         m_ace5lite_arready, 
        output logic [2:0]                   m_ace5lite_arsize,  
        output logic [3:0]                   m_ace5lite_arregion, 
        output logic [3:0]                   m_ace5lite_arsnoop, 
        output logic [7:0]                   m_ace5lite_aruser,  
        output [1-1:0]                       m_ace5lite_armmusecsid,
        output [SID_WIDTH-1:0]               m_ace5lite_armmusid,
        output logic                         m_ace5lite_arvalid, 
        
        output logic [ADDR_WIDTH -1 :0]      m_ace5lite_awaddr,  
        // output logic [1:0]                   m_ace5lite_awbar,    
        output logic [1:0]                   m_ace5lite_awburst, 
        output logic [3:0]                   m_ace5lite_awcache, 
        output logic [1:0]                   m_ace5lite_awdomain, 
        output logic [AXM_ID_WIDTH -1 :0]    m_ace5lite_awid,    
        output logic [7:0]                   m_ace5lite_awlen,   
        output logic                         m_ace5lite_awlock,  
        output logic [2:0]                   m_ace5lite_awprot,  
        output logic [3:0]                   m_ace5lite_awqos,   
        input  logic                         m_ace5lite_awready, 
        output logic [2:0]                   m_ace5lite_awsize,  
        output logic [3:0]                   m_ace5lite_awregion,  
        output logic [3:0]                   m_ace5lite_awsnoop,  
        output logic [7:0]                   m_ace5lite_awuser,  
        // output logic [1-1:0]                 m_ace5lite_awunique,
        output logic [11-1:0]                m_ace5lite_awstashnid,
        output logic [1-1:0]                 m_ace5lite_awstashniden,
        output logic [5-1:0]                 m_ace5lite_awstashlpid,
        output logic [1-1:0]                 m_ace5lite_awstashlpiden,
        output logic [6-1:0]                 m_ace5lite_awatop,
        output logic [1-1:0]                 m_ace5lite_awmmusecsid,
        output logic [SID_WIDTH-1:0]         m_ace5lite_awmmusid,
        output logic                         m_ace5lite_awvalid, 
        
        input  logic [AXM_ID_WIDTH -1 :0]    m_ace5lite_bid,     
        output logic                         m_ace5lite_bready,  
        input  logic [1:0]                   m_ace5lite_bresp,   
        input  logic                         m_ace5lite_bvalid,  
        input  logic [USER_WIDTH-1:0]        m_ace5lite_buser,   
        input  logic [DATA_WIDTH -1:0]       m_ace5lite_rdata,   
        input  logic [AXM_ID_WIDTH -1 :0]    m_ace5lite_rid,     
        input  logic                         m_ace5lite_rlast,   
        input  logic [USER_WIDTH-1:0]        m_ace5lite_ruser,   
        output logic                         m_ace5lite_rready,  
        input  logic [1:0]                   m_ace5lite_rresp,   
        input  logic                         m_ace5lite_rvalid,  
        output logic [DATA_WIDTH -1:0]       m_ace5lite_wdata,   
        output logic                         m_ace5lite_wlast,   
        input  logic                         m_ace5lite_wready,  
        output logic [WSTRB_WIDTH -1:0]      m_ace5lite_wstrb,   
        output logic [USER_WIDTH-1:0]        m_ace5lite_wuser,  
        output logic                         m_ace5lite_wvalid,  

        // AXI-4 subordinate
        input  logic [ADDR_WIDTH -1 :0]      s_axi_araddr,  
        input  logic [1:0]                   s_axi_arburst, 
        input  logic [3:0]                   s_axi_arcache, 
        input  logic [AXS_ID_WIDTH-1:0]      s_axi_arid,    
        input  logic [7:0]                   s_axi_arlen,   
        input  logic                         s_axi_arlock,  
        input  logic [2:0]                   s_axi_arprot,  
        input  logic [3:0]                   s_axi_arregion,  
        input  logic [3:0]                   s_axi_arqos,  
        output logic                         s_axi_arready, 
        input  logic [2:0]                   s_axi_arsize,  
        // input  logic [USER_WIDTH-1:0]        s_axi_aruser,  
        input  logic                         s_axi_arvalid, 
        input  logic [ADDR_WIDTH -1 :0]      s_axi_awaddr,  
        input  logic [1:0]                   s_axi_awburst, 
        input  logic [3:0]                   s_axi_awcache, 
        input  logic [AXS_ID_WIDTH-1:0]      s_axi_awid,    
        input  logic [7:0]                   s_axi_awlen,   
        input  logic                         s_axi_awlock,  
        input  logic [2:0]                   s_axi_awprot,  
        input  logic [3:0]                   s_axi_awregion,  
        input  logic [3:0]                   s_axi_awqos,  
        // input  logic [USER_WIDTH-1:0]        s_axi_awuser,  
        output logic                         s_axi_awready, 
        input  logic [2:0]                   s_axi_awsize,  
        input  logic                         s_axi_awvalid, 
        output logic [AXS_ID_WIDTH-1:0]      s_axi_bid,     
        input  logic                         s_axi_bready,  
        output logic [1:0]                   s_axi_bresp,   
        output logic [USER_WIDTH-1:0]        s_axi_buser,  
        output logic                         s_axi_bvalid,  
        output logic [DATA_WIDTH -1:0]       s_axi_rdata,   
        output logic [AXS_ID_WIDTH-1:0]      s_axi_rid,     
        output logic                         s_axi_rlast,   
        input  logic                         s_axi_rready,  
        output logic [1:0]                   s_axi_rresp,   
        output logic [USER_WIDTH-1:0]        s_axi_ruser,  
        output logic                         s_axi_rvalid,  
        input  logic [DATA_WIDTH -1:0]       s_axi_wdata,   
        input  logic                         s_axi_wlast,   
        output logic                         s_axi_wready,  
        input  logic [WSTRB_WIDTH -1:0]      s_axi_wstrb,   
        input  logic                         s_axi_wvalid,   
        input  logic [USER_WIDTH-1:0]        s_axi_wuser ,  
      
        // additional AXI-5 subordinate ports 
        input logic  [ 6-1:0 ]              s_axi_awatop ,
        input logic  [ 1-1:0 ]              s_axi_awmmusecsid ,
        input logic  [16-1:0 ]              s_axi_awmmusid , 
        input logic  [ 1-1:0 ]              s_axi_armmusecsid ,
        input logic  [16-1:0 ]              s_axi_armmusid 
    );
    
    // CSR reg address
    localparam [CSR_ADDR_WIDTH-1:0] CTRL_REG_0 = 'h0 ;
    localparam [CSR_ADDR_WIDTH-1:0] CTRL_REG_1 = 'h4 ;
    localparam [CSR_ADDR_WIDTH-1:0] CTRL_REG_2 = 'h8 ;

    logic [1:0]           csr_ardomain;
    // logic [1:0]  csr_arbar;
    logic [3:0]           csr_arsnoop;
    logic [3:0]           csr_arcache;
    logic [1:0]           csr_awdomain;
    // logic [1:0]  csr_awbar;
    logic [3:0]           csr_awsnoop;
    logic [3:0]           csr_awcache;
    logic [7:0]           csr_awuser;
    logic [7:0]           csr_aruser;
    logic [2:0]           csr_axprot;
    
    // logic         csr_awunique ;
    logic                 csr_awmmusecsid ;
    logic [SID_WIDTH-1:0] csr_awmmusid ;
    logic                 csr_armmusecsid ;
    logic [SID_WIDTH-1:0] csr_armmusid ;
    
    logic write_done ;
    logic valid_rd ;
    logic [6-1 :0] wr_addr_reg ;
    logic [31:0] rdata ;
    logic [3:0] ready_reg ;


    assign m_ace5lite_araddr    = s_axi_araddr;
    assign m_ace5lite_arburst   = s_axi_arburst;
    assign m_ace5lite_arlen     = s_axi_arlen;
    assign m_ace5lite_arlock    = s_axi_arlock;
    assign m_ace5lite_arsize    = s_axi_arsize;
    assign m_ace5lite_arregion  = s_axi_arregion;
    assign m_ace5lite_arvalid   = s_axi_arvalid;
    assign m_ace5lite_arqos     = s_axi_arqos;
    assign m_ace5lite_awaddr    = s_axi_awaddr;
    assign m_ace5lite_awburst   = s_axi_awburst;
    assign m_ace5lite_awlen     = s_axi_awlen;
    assign m_ace5lite_awlock    = s_axi_awlock;
    assign m_ace5lite_awqos     = s_axi_awqos;
    assign m_ace5lite_awsize    = s_axi_awsize;
    assign m_ace5lite_awregion  = s_axi_awregion;
    assign m_ace5lite_awvalid   = s_axi_awvalid;
    assign m_ace5lite_bready    = s_axi_bready;
    assign m_ace5lite_rready    = s_axi_rready;
    assign m_ace5lite_wdata     = s_axi_wdata;
    assign m_ace5lite_wlast     = s_axi_wlast;
    assign m_ace5lite_wstrb     = s_axi_wstrb;
    assign m_ace5lite_wvalid    = s_axi_wvalid;
    assign m_ace5lite_wuser     = s_axi_wuser;
    assign s_axi_arready        = m_ace5lite_arready;
    assign s_axi_awready        = m_ace5lite_awready;
    assign s_axi_bresp          = m_ace5lite_bresp;
    assign s_axi_bvalid         = m_ace5lite_bvalid;
    assign s_axi_buser          = m_ace5lite_buser;
    assign s_axi_ruser          = m_ace5lite_ruser;
    assign s_axi_rdata          = m_ace5lite_rdata;
    assign s_axi_rlast          = m_ace5lite_rlast;
    assign s_axi_rresp          = m_ace5lite_rresp;
    assign s_axi_rvalid         = m_ace5lite_rvalid;
    assign s_axi_wready         = m_ace5lite_wready;

    if (AXM_ID_WIDTH == AXS_ID_WIDTH) begin
        assign m_ace5lite_arid      = s_axi_arid;
        assign m_ace5lite_awid      = s_axi_awid;
        assign s_axi_bid            = m_ace5lite_bid;
        assign s_axi_rid            = m_ace5lite_rid;
    end else if (AXM_ID_WIDTH > AXS_ID_WIDTH) begin
        assign m_ace5lite_arid      = {{(AXM_ID_WIDTH-AXS_ID_WIDTH){1'b0}}, s_axi_arid[AXS_ID_WIDTH-1:0]};
        assign m_ace5lite_awid      = {{(AXM_ID_WIDTH-AXS_ID_WIDTH){1'b0}}, s_axi_awid[AXS_ID_WIDTH-1:0]};
        assign s_axi_bid            = m_ace5lite_bid[AXS_ID_WIDTH-1:0];
        assign s_axi_rid            = m_ace5lite_rid[AXS_ID_WIDTH-1:0];
    end

 
    if (CONTROL_INTERFACE_EN == 1) begin
        assign m_ace5lite_ardomain      = csr_ardomain;
        // assign m_ace5lite_arbar         = csr_arbar;
        assign m_ace5lite_arsnoop       = csr_arsnoop;
        assign m_ace5lite_arcache       = (ARCACHE_OVERRIDE_EN) ? csr_arcache : s_axi_arcache;        
        assign m_ace5lite_awdomain      = csr_awdomain;
        // assign m_ace5lite_awbar         = csr_awbar;
        assign m_ace5lite_awsnoop       = csr_awsnoop;
        // assign m_ace5lite_awunique      = csr_awunique ;
        assign m_ace5lite_awstashnid    = 'h0 ; 
        assign m_ace5lite_awstashniden  = 'h0 ; 
        assign m_ace5lite_awstashlpid   = 'h0 ; 
        assign m_ace5lite_awstashlpiden = 'h0 ; 

        // for now - passthrough mmu and atomics
        assign m_ace5lite_awatop        = (AXI_INTERFACE_TYPE) ? s_axi_awatop      : 'h0 ;
        assign m_ace5lite_armmusecsid   = (AXI_INTERFACE_TYPE) ? s_axi_armmusecsid : csr_armmusecsid ;
        assign m_ace5lite_armmusid      = (AXI_INTERFACE_TYPE) ? s_axi_armmusid    : csr_armmusid    ;
        assign m_ace5lite_awmmusecsid   = (AXI_INTERFACE_TYPE) ? s_axi_awmmusecsid : csr_awmmusecsid ;
        assign m_ace5lite_awmmusid      = (AXI_INTERFACE_TYPE) ? s_axi_awmmusid    : csr_awmmusid    ;

        assign m_ace5lite_awcache       = (AWCACHE_OVERRIDE_EN) ? csr_awcache : s_axi_awcache ;        
        assign m_ace5lite_awuser        = csr_awuser;
        assign m_ace5lite_aruser        = csr_aruser;
        assign m_ace5lite_awprot        = (AxPROT_OVERRIDE_EN) ? csr_axprot : s_axi_awprot;
        assign m_ace5lite_arprot        = (AxPROT_OVERRIDE_EN) ? csr_axprot : s_axi_arprot;
        
    end else begin
        assign m_ace5lite_ardomain      = ARDOMAIN_OVERRIDE;
        // assign m_ace5lite_arbar         = ARBAR_OVERRIDE;
        assign m_ace5lite_arsnoop       = ARSNOOP_OVERRIDE;
        assign m_ace5lite_arcache       = (ARCACHE_OVERRIDE_EN) ? ARCACHE_OVERRIDE : s_axi_arcache;
        assign m_ace5lite_awdomain      = AWDOMAIN_OVERRIDE;
        // assign m_ace5lite_awbar         = AWBAR_OVERRIDE;
        assign m_ace5lite_awsnoop       = AWSNOOP_OVERRIDE;
        // assign m_ace5lite_awunique      = AWUNIQUE_OVERRIDE ;
        assign m_ace5lite_awstashnid    = AWSTASHNID_OVERRIDE ;
        assign m_ace5lite_awstashniden  = AWSTASHNIDEN_OVERRIDE ;
        assign m_ace5lite_awstashlpid   = AWSTASHLPID_OVERRIDE ;
        assign m_ace5lite_awstashlpiden = AWSTASHLPIDEN_OVERRIDE ;

        // for now - passthrough stash and atomicsAXI_INTERFACE_TYPE
        assign m_ace5lite_awatop        = (AXI_INTERFACE_TYPE) ? s_axi_awatop        : AWATOP_OVERRIDE ;    
        assign m_ace5lite_armmusecsid   = (AXI_INTERFACE_TYPE) ? s_axi_armmusecsid :ARMMUSECSID_OVERRIDE ;
        assign m_ace5lite_armmusid      = (AXI_INTERFACE_TYPE) ? s_axi_armmusid    :ARMMUSID_OVERRIDE ;
        assign m_ace5lite_awmmusecsid   = (AXI_INTERFACE_TYPE) ? s_axi_awmmusecsid :AWMMUSECSID_OVERRIDE ;
        assign m_ace5lite_awmmusid      = (AXI_INTERFACE_TYPE) ? s_axi_awmmusid    :AWMMUSID_OVERRIDE ;        

        assign m_ace5lite_awuser        = AWUSER_OVERRIDE;
        assign m_ace5lite_aruser        = ARUSER_OVERRIDE;
        assign m_ace5lite_awcache       = (AWCACHE_OVERRIDE_EN) ? AWCACHE_OVERRIDE : s_axi_awcache ;    
        assign m_ace5lite_awprot        = (AxPROT_OVERRIDE_EN) ? AxPROT_OVERRIDE : s_axi_awprot;
        assign m_ace5lite_arprot        = (AxPROT_OVERRIDE_EN) ? AxPROT_OVERRIDE : s_axi_arprot;
        end

    if (CONTROL_INTERFACE_EN == 1) begin
        logic [31:0]      csr_reg0;
        logic [31:0]      csr_reg1;
        logic [31:0]      csr_reg2;
        logic [31:0]      sync_csr_reg0;
        logic [31:0]      sync_csr_reg1;
        logic [31:0]      sync_csr_reg2;

        // ***************************************************************************************
        // Write Logic 

        always @(posedge csr_clk ) begin
            if (csr_reset == 1'h1) begin
            
                csr_reg0[1:0]              <= ARDOMAIN_OVERRIDE;
                csr_reg0[3:2]              <= 'h0; // ARBAR_OVERRIDE;
                csr_reg0[7:4]              <= ARSNOOP_OVERRIDE;
                csr_reg0[11:8]             <= ARCACHE_OVERRIDE; 
                csr_reg0[13:12]            <= AWDOMAIN_OVERRIDE;
                csr_reg0[15:14]            <= 'h0; // AWBAR_OVERRIDE;
                csr_reg0[19:16]            <= AWSNOOP_OVERRIDE;
                csr_reg0[23:20]            <= AWCACHE_OVERRIDE ; 
                csr_reg0[26:24]            <= AxPROT_OVERRIDE ;  
                csr_reg0[31:27]            <= 'h0 ; // Reserved
                
                csr_reg1[7:0]              <= ARUSER_OVERRIDE ;
                csr_reg1[SID_WIDTH-1+8: 8] <= ARMMUSID_OVERRIDE ; 
                csr_reg1[SID_WIDTH+8]      <= ARMMUSECSID_OVERRIDE ; 
                csr_reg1[31:25]            <= 'h0;  // Reserved
                
                csr_reg2[7:0]              <= AWUSER_OVERRIDE ;
                csr_reg2[SID_WIDTH-1+8: 8] <= AWMMUSID_OVERRIDE ; 
                csr_reg2[SID_WIDTH+8]      <= AWMMUSECSID_OVERRIDE ; 
                csr_reg2[31:25]            <= 'h0;  // Reserved
                
                ready_reg[3:0]             <= 4'h0001 ;
                
                s_csr_awready              <= 1'h0 ;
                s_csr_wready               <= 1'h0 ;
            end 
            else begin 
            
                ready_reg[3:1] <= ready_reg[2:0] ;
                ready_reg[0]   <= 'h0            ; 
                
                if (s_csr_awvalid && s_csr_awready) begin
                    s_csr_awready <= 1'h0 ;
                end 
                else if (s_csr_bvalid && s_csr_bready )begin
                    s_csr_awready <= 1'h1 ;
                end 
                else if (ready_reg[3]) begin
                    s_csr_awready <= 1'h1 ;
                end
                
                if (s_csr_wvalid && s_csr_wready) begin
                    s_csr_wready <= 1'h0 ;
                end
                else if (s_csr_awvalid && s_csr_awready) begin
                    s_csr_wready <= 1'h1 ;
                end
                
                if (s_csr_awvalid && s_csr_awready) begin
                    wr_addr_reg <= s_csr_awaddr ;
                end  
                
                if (s_csr_wvalid && s_csr_wready) begin
                    write_done <= 1'h1 ;
                    if (wr_addr_reg[CSR_ADDR_WIDTH-1:2] == CTRL_REG_0[CSR_ADDR_WIDTH-1:2]) begin
                        if (s_csr_wstrb[0] == 1'h1 ) 
                            csr_reg0[1:0]       <= s_csr_wdata[1:0];  
                            csr_reg0[3:2]       <= 'h0;  
                            csr_reg0[7:4]       <= s_csr_wdata[7:4];  
                        if (s_csr_wstrb[1] == 1'h1 ) begin
                            csr_reg0[11:8]      <= (ARCACHE_OVERRIDE_EN) ? s_csr_wdata[11:8] : csr_reg0[11:8];
                            csr_reg0[13:12]     <= s_csr_wdata[13:12]; 
                            csr_reg0[15:14]     <= 'h0; 
                        end
                        if (s_csr_wstrb[2] == 1'h1 ) begin
                            csr_reg0[19:16]     <= s_csr_wdata[19:16]; 
                            csr_reg0[23:20]     <= (AWCACHE_OVERRIDE_EN) ? s_csr_wdata[23:20] : csr_reg0[23:20];
                        end
                        if (s_csr_wstrb[3] == 1'h1 ) begin
                            csr_reg0[26:24]     <= (AxPROT_OVERRIDE_EN) ? s_csr_wdata[26:24] : csr_reg0[26:24];
                        end
                        
                        csr_reg0[31:27]  <= 'h0 ; // Reserved
                    end
                    
                    
                    if (wr_addr_reg[CSR_ADDR_WIDTH-1:2] == CTRL_REG_1[CSR_ADDR_WIDTH-1:2]) begin
                        if (s_csr_wstrb[0] == 1'h1 )
                            csr_reg1[7:0] <= s_csr_wdata[7:0] ;
                        if (s_csr_wstrb[1] == 1'h1 )
                            csr_reg1[15:8] <= ENABLE_MMU ? s_csr_wdata[15:8] : csr_reg1[15:8] ;
                        if (s_csr_wstrb[2] == 1'h1 )
                            csr_reg1[SID_WIDTH-1+8:16] <= ENABLE_MMU ? s_csr_wdata[SID_WIDTH-1+8:16] : csr_reg1[SID_WIDTH-1+8:16] ;
                        if (s_csr_wstrb[3] == 1'h1 )
                            csr_reg1[SID_WIDTH+8] <= ENABLE_MMU ? s_csr_wdata[SID_WIDTH+8] : csr_reg1[SID_WIDTH+8];
                        csr_reg1[31:25] <= 'h0;  // Reserved
                    end
                    
                    if (wr_addr_reg[CSR_ADDR_WIDTH-1:2] == CTRL_REG_2[CSR_ADDR_WIDTH-1:2]) begin
                        if (s_csr_wstrb[0] == 1'h1 )
                            csr_reg2[7:0] <= s_csr_wdata[7:0] ;
                        if (s_csr_wstrb[1] == 1'h1 )
                            csr_reg2[15:8] <= ENABLE_MMU ? s_csr_wdata[15:8] : csr_reg2[15:8] ;
                        if (s_csr_wstrb[2] == 1'h1 )
                            csr_reg2[SID_WIDTH-1+8:16] <= ENABLE_MMU ? s_csr_wdata[SID_WIDTH-1+8:16] : csr_reg2[SID_WIDTH-1+8:16] ;
                        if (s_csr_wstrb[3] == 1'h1 )
                            csr_reg2[SID_WIDTH+8] <= ENABLE_MMU ? s_csr_wdata[SID_WIDTH+8] : csr_reg2[SID_WIDTH+8];
                        csr_reg2[31:25] <= 'h0;  // Reserved
                    end
                    
                end
                else begin
                    write_done <= 1'h0 ;
                end
            end
        end
        
        always_ff@(posedge csr_clk) begin
            if (csr_reset) begin
                s_csr_bvalid <= 1'h0 ;
            end
            else begin 
                if (write_done) begin 
                    s_csr_bvalid <= 1'h1 ;
                    if ( wr_addr_reg[CSR_ADDR_WIDTH-1:2] == CTRL_REG_0[CSR_ADDR_WIDTH-1:2] || 
                         wr_addr_reg[CSR_ADDR_WIDTH-1:2] == CTRL_REG_1[CSR_ADDR_WIDTH-1:2] || 
                         wr_addr_reg[CSR_ADDR_WIDTH-1:2] == CTRL_REG_2[CSR_ADDR_WIDTH-1:2] )
                         s_csr_bresp  <= 2'h0 ; // OKAY
                    else  
                        s_csr_bresp  <= 2'h2 ; // SLVERR 
                end 
                else if (s_csr_bvalid && s_csr_bready) begin
                    s_csr_bvalid <= 1'h0 ;
                end
                
            end
        end
        
        // ***************************************************************************************
        // Read Logic 
        
        always_ff@(posedge csr_clk) begin
            if (csr_reset) begin
                    s_csr_arready <= 1'h0 ;
            end 
            else begin
                if (s_csr_arvalid && s_csr_arready) begin
                    s_csr_arready <= 1'h0 ;
                end 
                else if (s_csr_rvalid && s_csr_rready )begin
                    s_csr_arready <= 1'h1 ;
                end 
                else if (ready_reg[3]) begin
                    s_csr_arready <= 1'h1 ;
                end
            end
        end
        
        always_comb begin
            if (s_csr_arvalid && s_csr_arready) begin
                valid_rd = 1'h1 ;
                rdata = 32'h0 ;
                case (s_csr_araddr) 
                    CTRL_REG_0: begin
                            rdata[23:0]     = csr_reg0[23:0];
                            rdata[26:24]    = csr_reg0[26:24];
                            rdata[31:27]    = 'h0;
                    end
                    CTRL_REG_1: begin
                            rdata[7:0]     = csr_reg1[7:0];
                            if (ENABLE_MMU) 
                                rdata[SID_WIDTH+8:8] = csr_reg1[SID_WIDTH+8:8] ;
                            else 
                                rdata[SID_WIDTH+8:8] = 'h0 ;
                            rdata[31:SID_WIDTH+8+1]  = 'h0; 
                    end
                    CTRL_REG_2: begin
                            rdata[7:0]     = csr_reg2[7:0];
                            if (ENABLE_MMU) 
                                rdata[SID_WIDTH+8:8] = csr_reg2[SID_WIDTH+8:8] ;
                            else 
                                rdata[SID_WIDTH+8:8] = 'h0 ;
                            rdata[31:SID_WIDTH+8+1] = 'h0; 
                    end
                    default: begin
                                rdata = 32'h0 ;
                    end
                endcase
            end
            else begin
                valid_rd = 1'h0 ;
                rdata    = 32'h0 ;
            end
        end
        
        always_ff @(posedge csr_clk) begin
            if (csr_reset) begin
                s_csr_rvalid <= 1'h0 ;
            end 
            else begin
                if (valid_rd) begin
                    if ( s_csr_araddr[CSR_ADDR_WIDTH-1:2] == CTRL_REG_0[CSR_ADDR_WIDTH-1:2] || 
                         s_csr_araddr[CSR_ADDR_WIDTH-1:2] == CTRL_REG_1[CSR_ADDR_WIDTH-1:2] || 
                         s_csr_araddr[CSR_ADDR_WIDTH-1:2] == CTRL_REG_2[CSR_ADDR_WIDTH-1:2] ) begin
                        s_csr_rvalid <= 1'h1 ;
                        s_csr_rdata  <= rdata ;
                        s_csr_rresp  <= 2'h0 ; // OKAY
                    end 
                    else begin
                        s_csr_rvalid <= 1'h1 ;
                        s_csr_rdata  <= 32'h0 ;
                        s_csr_rresp  <= 2'h2 ; // SLVERR
                    end
                end
                else if (s_csr_rvalid && s_csr_rready) begin 
                    s_csr_rvalid <= 1'h0 ;
                end
            end
        end
        
        // ***************************************************************************************
        // Clock Domain Crossing
        
        mux_data_synchronizer #(
            .DEPTH(3),
            .DATA_WIDTH(32)
            ) csr_reg0_sync_inst (
            .clk_dest        ( clk ),
            .rst_dest        ( reset ),
            .dvalid_in_src   ( write_done ),
            .data_in_src     ( csr_reg0 ),
            .data_out_dest   ( sync_csr_reg0 )
        ) ;
        
        mux_data_synchronizer #(
            .DEPTH(3),
            .DATA_WIDTH(32)
            ) csr_reg1_sync_inst (
            .clk_dest        ( clk ),
            .rst_dest        ( reset ),
            .dvalid_in_src   ( write_done ),
            .data_in_src     ( csr_reg1 ),
            .data_out_dest   ( sync_csr_reg1 )
        ) ;
        
        mux_data_synchronizer #(
            .DEPTH(3),
            .DATA_WIDTH(32)
            ) csr_reg2_sync_inst (
            .clk_dest        ( clk ),
            .rst_dest        ( reset ),
            .dvalid_in_src   ( write_done ),
            .data_in_src     ( csr_reg2 ),
            .data_out_dest   ( sync_csr_reg2 )
        ) ;
        

        assign csr_ardomain      = sync_csr_reg0[1:0];
        // assign csr_arbar         = sync_csr_reg0[3:2];
        assign csr_arsnoop       = sync_csr_reg0[7:4];
        assign csr_arcache       = sync_csr_reg0[11:8];
        assign csr_awdomain      = sync_csr_reg0[13:12];
        // assign csr_awbar         = sync_csr_reg0[15:14];
        assign csr_awsnoop       = sync_csr_reg0[19:16];
        assign csr_awcache       = sync_csr_reg0[23:20];
        assign csr_axprot        = sync_csr_reg0[26:24];
        
        assign csr_awuser        = sync_csr_reg1[7:0];
        assign csr_awmmusid      = sync_csr_reg1[23:8] ;
        assign csr_awmmusecsid   = sync_csr_reg1[24] ;
        
        assign csr_aruser        = sync_csr_reg2[7:0];
        assign csr_armmusid      = sync_csr_reg2[23:8] ;
        assign csr_armmusecsid   = sync_csr_reg2[24] ;
        
   end


endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "Jv8lNbjFdP1RG6ZlRGDPQ18y9rK8xNjZPJSXRJP5QnPWfqyqNCZgAFckZeIKAKwNoSPIIpIipc8Lr+b9a/FWzIYgzMxpzrkpOByg+HoJBnaTRP9US7VEnPfzFsP4DZjz4ZfQo3AjGuPZdXoEPcUpMMVVVaUENWSiX6AT97YYkfX+YrBm5cVHUlgFZ8gk9eg+R0Z3hxyPZcAjv5lGd5X5M6DoA6WnB+Wn6k6+/EbGEiR777xsFgU/TH6t+lLQnSbid3UjJjtb3Hz9FK8naox5CvxwzIsqnjyQk0FDCMRtEX3qWEuqLobqs5UdBl5rh2odoHye45+3V/Ds+v8W1fgcB9eRzn3I0EjCZ+zj/tOBtI7dFoTDzGwpuZTsEIWE9JxSzGv7YThyUNQlswZt0BTkt83DaA9aOHhLb6GR/67034lJuU2t+ejjQwdPcDKaAv7jyQ+lGZhhxtbVz1UJkttfdSXyrt3BBGsC3qmu2q+SLBQwWB3VApPfZ/zufD5WiWxt2pzqDAJ0rlkmKHtqWKQ5xtIvDprvOFLb4TW9XdfSgRwx+gy/NilhljteS5xmL8SbDsu9W9STbLGESex5B6oOT0q3DRqcP7i5D27iIWFePZn+1e9X9xmI/8bWDr0FXOniVxqElpsPaFqDf8yUOXiuGhoH4cq0nJsFQbNVmWHnsWXQuoddisIvcG/QABaCdegxbN+3Oc1ezRpdY8d7MipPEMA4HTbPOMbaHEVIAjRjyxdcf9Ao6rSM75TL1V9YL+PyQiiI5VwrpTZU3pnuBkHRy06bIsOHvqU2WJkjmFbdQHowVH/vw1fCdHAwI8agx1Ep5aqp6R45a2dJDinJkw9R5LM4Ia8Kp9SeO63dNl8aB1vOcJwafnTVj7xT5VNKeUsyyN+lsd8hVqfSo3RJKLCgQr5+bg+KRTtq1qVZabHDHAKj8CJCw0iwch8bAV6ZT9AVq2ankP1B+/znwZhjSy/YksY+dlPbw1AEJAQ5pm+zYgxjTIVnjHFNN38R2H83vGWh"
`endif