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



module agilex_hps_intel_sundancemesa_mpfe_100_b5hkkay(
  input wire [0 : 0 ] f2sdram_clk
 ,input wire [0 : 0 ] f2sdram_rst
 ,input wire [31 : 0 ] f2sdram_araddr
 ,input wire [1 : 0 ] f2sdram_arburst
 ,input wire [3 : 0 ] f2sdram_arcache
 ,input wire [4 : 0 ] f2sdram_arid
 ,input wire [7 : 0 ] f2sdram_arlen
 ,input wire [0 : 0 ] f2sdram_arlock
 ,input wire [2 : 0 ] f2sdram_arprot
 ,input wire [3 : 0 ] f2sdram_arqos
 ,output wire [0 : 0 ] f2sdram_arready
 ,input wire [2 : 0 ] f2sdram_arsize
 ,input wire [0 : 0 ] f2sdram_arvalid
 ,input wire [31 : 0 ] f2sdram_awaddr
 ,input wire [1 : 0 ] f2sdram_awburst
 ,input wire [3 : 0 ] f2sdram_awcache
 ,input wire [4 : 0 ] f2sdram_awid
 ,input wire [7 : 0 ] f2sdram_awlen
 ,input wire [0 : 0 ] f2sdram_awlock
 ,input wire [2 : 0 ] f2sdram_awprot
 ,input wire [3 : 0 ] f2sdram_awqos
 ,output wire [0 : 0 ] f2sdram_awready
 ,input wire [2 : 0 ] f2sdram_awsize
 ,input wire [0 : 0 ] f2sdram_awvalid
 ,output wire [4 : 0 ] f2sdram_bid
 ,input wire [0 : 0 ] f2sdram_bready
 ,output wire [1 : 0 ] f2sdram_bresp
 ,output wire [0 : 0 ] f2sdram_bvalid
 ,output wire [255 : 0 ] f2sdram_rdata
 ,output wire [4 : 0 ] f2sdram_rid
 ,output wire [0 : 0 ] f2sdram_rlast
 ,input wire [0 : 0 ] f2sdram_rready
 ,output wire [1 : 0 ] f2sdram_rresp
 ,output wire [0 : 0 ] f2sdram_rvalid
 ,input wire [255 : 0 ] f2sdram_wdata
 ,input wire [0 : 0 ] f2sdram_wlast
 ,output wire [0 : 0 ] f2sdram_wready
 ,input wire [31 : 0 ] f2sdram_wstrb
 ,input wire [0 : 0 ] f2sdram_wvalid
 ,input wire [7 : 0 ] f2sdram_aruser
 ,input wire [7 : 0 ] f2sdram_awuser
 ,input wire [7 : 0 ] f2sdram_wuser
 ,output wire [7 : 0 ] f2sdram_buser
 ,input wire [3 : 0 ] f2sdram_arregion
 ,output wire [7 : 0 ] f2sdram_ruser
 ,input wire [3 : 0 ] f2sdram_awregion
 ,input wire [0 : 0 ] sdram_bridge_rst_n
 ,output wire [0 : 0 ] sdram_bridge_ack
 ,input wire [0 : 0 ] sdram_bridge_req
 ,output wire [0 : 0 ] sdram_tbu_pmu_irpt
 ,output wire [0 : 0 ] sdram_tbu_ras_irpt
 ,input wire [0 : 0 ] fpga2hps_clk
 ,input wire [0 : 0 ] fpga2hps_rst
 ,input wire [4 : 0 ] fpga2hps_awid
 ,input wire [31 : 0 ] fpga2hps_awaddr
 ,input wire [1 : 0 ] fpga2hps_awdomain
 ,input wire [3 : 0 ] fpga2hps_awsnoop
 ,input wire [7 : 0 ] fpga2hps_awlen
 ,input wire [2 : 0 ] fpga2hps_awsize
 ,input wire [2 : 0 ] fpga2hps_arsize
 ,input wire [1 : 0 ] fpga2hps_awburst
 ,input wire [0 : 0 ] fpga2hps_awlock
 ,input wire [3 : 0 ] fpga2hps_awcache
 ,input wire [2 : 0 ] fpga2hps_awprot
 ,input wire [3 : 0 ] fpga2hps_awqos
 ,input wire [0 : 0 ] fpga2hps_awvalid
 ,output wire [0 : 0 ] fpga2hps_awready
 ,input wire [255 : 0 ] fpga2hps_wdata
 ,input wire [31 : 0 ] fpga2hps_wstrb
 ,input wire [0 : 0 ] fpga2hps_wlast
 ,input wire [0 : 0 ] fpga2hps_wvalid
 ,output wire [0 : 0 ] fpga2hps_wready
 ,input wire [10 : 0 ] fpga2hps_awstashnid
 ,input wire [0 : 0 ] fpga2hps_awstashniden
 ,input wire [4 : 0 ] fpga2hps_awstashlpid
 ,input wire [0 : 0 ] fpga2hps_awstashlpiden
 ,input wire [5 : 0 ] fpga2hps_awatop
 ,output wire [4 : 0 ] fpga2hps_bid
 ,output wire [1 : 0 ] fpga2hps_bresp
 ,output wire [0 : 0 ] fpga2hps_bvalid
 ,input wire [0 : 0 ] fpga2hps_bready
 ,input wire [4 : 0 ] fpga2hps_arid
 ,input wire [31 : 0 ] fpga2hps_araddr
 ,input wire [1 : 0 ] fpga2hps_ardomain
 ,input wire [3 : 0 ] fpga2hps_arsnoop
 ,input wire [7 : 0 ] fpga2hps_arlen
 ,input wire [1 : 0 ] fpga2hps_arburst
 ,input wire [0 : 0 ] fpga2hps_arlock
 ,input wire [3 : 0 ] fpga2hps_arcache
 ,input wire [2 : 0 ] fpga2hps_arprot
 ,input wire [3 : 0 ] fpga2hps_arqos
 ,input wire [0 : 0 ] fpga2hps_arvalid
 ,output wire [0 : 0 ] fpga2hps_arready
 ,output wire [4 : 0 ] fpga2hps_rid
 ,output wire [255 : 0 ] fpga2hps_rdata
 ,output wire [1 : 0 ] fpga2hps_rresp
 ,output wire [0 : 0 ] fpga2hps_rlast
 ,output wire [0 : 0 ] fpga2hps_rvalid
 ,input wire [0 : 0 ] fpga2hps_rready
 ,input wire [7 : 0 ] fpga2hps_aruser
 ,input wire [7 : 0 ] fpga2hps_awuser
 ,input wire [3 : 0 ] fpga2hps_arregion
 ,input wire [3 : 0 ] fpga2hps_awregion
 ,input wire [7 : 0 ] fpga2hps_wuser
 ,output wire [7 : 0 ] fpga2hps_buser
 ,output wire [7 : 0 ] fpga2hps_ruser
 ,input wire [0 : 0 ] emif_csr_axi_clk
 ,input wire [0 : 0 ] emif_csr_axi_rst
 ,input wire [0 : 0 ] emif_mem_cfg_arready
 ,input wire [0 : 0 ] emif_mem_cfg_awready
 ,input wire [1 : 0 ] emif_mem_cfg_bresp
 ,input wire [0 : 0 ] emif_mem_cfg_bvalid
 ,input wire [31 : 0 ] emif_mem_cfg_rdata
 ,input wire [1 : 0 ] emif_mem_cfg_rresp
 ,input wire [0 : 0 ] emif_mem_cfg_rvalid
 ,input wire [0 : 0 ] emif_mem_cfg_wready
 ,output wire [26 : 0 ] emif_mem_cfg_araddr
 ,output wire [0 : 0 ] emif_mem_cfg_arvalid
 ,output wire [26 : 0 ] emif_mem_cfg_awaddr
 ,output wire [0 : 0 ] emif_mem_cfg_awvalid
 ,output wire [0 : 0 ] emif_mem_cfg_bready
 ,output wire [0 : 0 ] emif_mem_cfg_rready
 ,output wire [31 : 0 ] emif_mem_cfg_wdata
 ,output wire [3 : 0 ] emif_mem_cfg_wstrb
 ,output wire [0 : 0 ] emif_mem_cfg_wvalid
 ,output wire [2 : 0 ] emif_mem_cfg_arprot
 ,output wire [2 : 0 ] emif_mem_cfg_awprot
 ,input wire [0 : 0 ] emif_ch0_axi_clk
 ,input wire [0 : 0 ] emif_ch0_axi_rst
 ,input wire [0 : 0 ] emif0_arready
 ,input wire [0 : 0 ] emif0_awready
 ,input wire [6 : 0 ] emif0_bid
 ,input wire [1 : 0 ] emif0_bresp
 ,input wire [0 : 0 ] emif0_bvalid
 ,input wire [255 : 0 ] emif0_rdata
 ,input wire [6 : 0 ] emif0_rid
 ,input wire [0 : 0 ] emif0_rlast
 ,input wire [1 : 0 ] emif0_rresp
 ,input wire [31 : 0 ] emif0_ruser
 ,input wire [0 : 0 ] emif0_rvalid
 ,input wire [0 : 0 ] emif0_wready
 ,output wire [39 : 0 ] emif0_araddr
 ,output wire [1 : 0 ] emif0_arburst
 ,output wire [6 : 0 ] emif0_arid
 ,output wire [7 : 0 ] emif0_arlen
 ,output wire [0 : 0 ] emif0_arlock
 ,output wire [3 : 0 ] emif0_arqos
 ,output wire [2 : 0 ] emif0_arsize
 ,output wire [13 : 0 ] emif0_aruser
 ,output wire [0 : 0 ] emif0_arvalid
 ,output wire [39 : 0 ] emif0_awaddr
 ,output wire [1 : 0 ] emif0_awburst
 ,output wire [6 : 0 ] emif0_awid
 ,output wire [7 : 0 ] emif0_awlen
 ,output wire [0 : 0 ] emif0_awlock
 ,output wire [3 : 0 ] emif0_awqos
 ,output wire [2 : 0 ] emif0_awsize
 ,output wire [13 : 0 ] emif0_awuser
 ,output wire [0 : 0 ] emif0_awvalid
 ,output wire [0 : 0 ] emif0_bready
 ,output wire [0 : 0 ] emif0_rready
 ,output wire [255 : 0 ] emif0_wdata
 ,output wire [0 : 0 ] emif0_wlast
 ,output wire [31 : 0 ] emif0_wstrb
 ,output wire [31 : 0 ] emif0_wuser
 ,output wire [0 : 0 ] emif0_wvalid
 ,output wire [2 : 0 ] emif0_arprot
 ,output wire [2 : 0 ] emif0_awprot
 ,output wire [0 : 0 ] mpfe2hps_clk
 ,output wire [0 : 0 ] mpfe2hps_rst
 ,output wire [39 : 0 ] mpfe2hps_araddr
 ,output wire [1 : 0 ] mpfe2hps_arburst
 ,output wire [3 : 0 ] mpfe2hps_arcache
 ,output wire [4 : 0 ] mpfe2hps_arid
 ,output wire [7 : 0 ] mpfe2hps_arlen
 ,output wire [0 : 0 ] mpfe2hps_arlock
 ,output wire [2 : 0 ] mpfe2hps_arprot
 ,output wire [3 : 0 ] mpfe2hps_arqos
 ,input wire [0 : 0 ] mpfe2hps_arready
 ,output wire [3 : 0 ] mpfe2hps_arregion
 ,output wire [2 : 0 ] mpfe2hps_arsize
 ,output wire [7 : 0 ] mpfe2hps_aruser
 ,output wire [0 : 0 ] mpfe2hps_arvalid
 ,output wire [39 : 0 ] mpfe2hps_awaddr
 ,output wire [1 : 0 ] mpfe2hps_awburst
 ,output wire [3 : 0 ] mpfe2hps_awcache
 ,output wire [4 : 0 ] mpfe2hps_awid
 ,output wire [7 : 0 ] mpfe2hps_awlen
 ,output wire [0 : 0 ] mpfe2hps_awlock
 ,output wire [2 : 0 ] mpfe2hps_awprot
 ,output wire [3 : 0 ] mpfe2hps_awqos
 ,input wire [0 : 0 ] mpfe2hps_awready
 ,output wire [3 : 0 ] mpfe2hps_awregion
 ,output wire [2 : 0 ] mpfe2hps_awsize
 ,output wire [7 : 0 ] mpfe2hps_awuser
 ,output wire [0 : 0 ] mpfe2hps_awvalid
 ,input wire [4 : 0 ] mpfe2hps_bid
 ,output wire [0 : 0 ] mpfe2hps_bready
 ,input wire [1 : 0 ] mpfe2hps_bresp
 ,input wire [7 : 0 ] mpfe2hps_buser
 ,input wire [0 : 0 ] mpfe2hps_bvalid
 ,input wire [255 : 0 ] mpfe2hps_rdata
 ,input wire [4 : 0 ] mpfe2hps_rid
 ,input wire [0 : 0 ] mpfe2hps_rlast
 ,output wire [0 : 0 ] mpfe2hps_rready
 ,input wire [1 : 0 ] mpfe2hps_rresp
 ,input wire [7 : 0 ] mpfe2hps_ruser
 ,input wire [0 : 0 ] mpfe2hps_rvalid
 ,output wire [255 : 0 ] mpfe2hps_wdata
 ,output wire [0 : 0 ] mpfe2hps_wlast
 ,input wire [0 : 0 ] mpfe2hps_wready
 ,output wire [31 : 0 ] mpfe2hps_wstrb
 ,output wire [7 : 0 ] mpfe2hps_wuser
 ,output wire [0 : 0 ] mpfe2hps_wvalid
 ,output wire [1 : 0 ] mpfe2hps_ardomain
 ,output wire [3 : 0 ] mpfe2hps_arsnoop
 ,output wire [5 : 0 ] mpfe2hps_awatop
 ,output wire [1 : 0 ] mpfe2hps_awdomain
 ,output wire [3 : 0 ] mpfe2hps_awsnoop
 ,output wire [4 : 0 ] mpfe2hps_awstashlpid
 ,output wire [0 : 0 ] mpfe2hps_awstashlpiden
 ,output wire [10 : 0 ] mpfe2hps_awstashnid
 ,output wire [0 : 0 ] mpfe2hps_awstashniden
 ,input wire [0 : 0 ] hps2mpfe_ccu_clk
 ,input wire [0 : 0 ] hps2mpfe_ccu_rst
 ,input wire [43 : 0 ] hps2mpfe_dmi0_araddr
 ,input wire [1 : 0 ] hps2mpfe_dmi0_arburst
 ,input wire [3 : 0 ] hps2mpfe_dmi0_arcache
 ,input wire [9 : 0 ] hps2mpfe_dmi0_arid
 ,input wire [7 : 0 ] hps2mpfe_dmi0_arlen
 ,input wire [0 : 0 ] hps2mpfe_dmi0_arlock
 ,input wire [2 : 0 ] hps2mpfe_dmi0_arprot
 ,input wire [3 : 0 ] hps2mpfe_dmi0_arqos
 ,output wire [0 : 0 ] hps2mpfe_dmi0_arready
 ,input wire [2 : 0 ] hps2mpfe_dmi0_arsize
 ,input wire [7 : 0 ] hps2mpfe_dmi0_aruser
 ,input wire [0 : 0 ] hps2mpfe_dmi0_arvalid
 ,input wire [43 : 0 ] hps2mpfe_dmi0_awaddr
 ,input wire [1 : 0 ] hps2mpfe_dmi0_awburst
 ,input wire [3 : 0 ] hps2mpfe_dmi0_awcache
 ,input wire [9 : 0 ] hps2mpfe_dmi0_awid
 ,input wire [7 : 0 ] hps2mpfe_dmi0_awlen
 ,input wire [0 : 0 ] hps2mpfe_dmi0_awlock
 ,input wire [2 : 0 ] hps2mpfe_dmi0_awprot
 ,input wire [3 : 0 ] hps2mpfe_dmi0_awqos
 ,output wire [0 : 0 ] hps2mpfe_dmi0_awready
 ,input wire [2 : 0 ] hps2mpfe_dmi0_awsize
 ,input wire [7 : 0 ] hps2mpfe_dmi0_awuser
 ,input wire [0 : 0 ] hps2mpfe_dmi0_awvalid
 ,output wire [9 : 0 ] hps2mpfe_dmi0_bid
 ,input wire [0 : 0 ] hps2mpfe_dmi0_bready
 ,output wire [1 : 0 ] hps2mpfe_dmi0_bresp
 ,output wire [0 : 0 ] hps2mpfe_dmi0_bvalid
 ,output wire [255 : 0 ] hps2mpfe_dmi0_rdata
 ,output wire [9 : 0 ] hps2mpfe_dmi0_rid
 ,output wire [0 : 0 ] hps2mpfe_dmi0_rlast
 ,input wire [0 : 0 ] hps2mpfe_dmi0_rready
 ,output wire [1 : 0 ] hps2mpfe_dmi0_rresp
 ,output wire [0 : 0 ] hps2mpfe_dmi0_rvalid
 ,input wire [255 : 0 ] hps2mpfe_dmi0_wdata
 ,input wire [0 : 0 ] hps2mpfe_dmi0_wlast
 ,output wire [0 : 0 ] hps2mpfe_dmi0_wready
 ,input wire [31 : 0 ] hps2mpfe_dmi0_wstrb
 ,input wire [0 : 0 ] hps2mpfe_dmi0_wvalid
 ,input wire [43 : 0 ] hps2mpfe_dmi1_araddr
 ,input wire [1 : 0 ] hps2mpfe_dmi1_arburst
 ,input wire [3 : 0 ] hps2mpfe_dmi1_arcache
 ,input wire [9 : 0 ] hps2mpfe_dmi1_arid
 ,input wire [7 : 0 ] hps2mpfe_dmi1_arlen
 ,input wire [0 : 0 ] hps2mpfe_dmi1_arlock
 ,input wire [2 : 0 ] hps2mpfe_dmi1_arprot
 ,input wire [3 : 0 ] hps2mpfe_dmi1_arqos
 ,output wire [0 : 0 ] hps2mpfe_dmi1_arready
 ,input wire [2 : 0 ] hps2mpfe_dmi1_arsize
 ,input wire [7 : 0 ] hps2mpfe_dmi1_aruser
 ,input wire [0 : 0 ] hps2mpfe_dmi1_arvalid
 ,input wire [43 : 0 ] hps2mpfe_dmi1_awaddr
 ,input wire [1 : 0 ] hps2mpfe_dmi1_awburst
 ,input wire [3 : 0 ] hps2mpfe_dmi1_awcache
 ,input wire [9 : 0 ] hps2mpfe_dmi1_awid
 ,input wire [7 : 0 ] hps2mpfe_dmi1_awlen
 ,input wire [0 : 0 ] hps2mpfe_dmi1_awlock
 ,input wire [2 : 0 ] hps2mpfe_dmi1_awprot
 ,input wire [3 : 0 ] hps2mpfe_dmi1_awqos
 ,output wire [0 : 0 ] hps2mpfe_dmi1_awready
 ,input wire [2 : 0 ] hps2mpfe_dmi1_awsize
 ,input wire [7 : 0 ] hps2mpfe_dmi1_awuser
 ,input wire [0 : 0 ] hps2mpfe_dmi1_awvalid
 ,output wire [9 : 0 ] hps2mpfe_dmi1_bid
 ,input wire [0 : 0 ] hps2mpfe_dmi1_bready
 ,output wire [1 : 0 ] hps2mpfe_dmi1_bresp
 ,output wire [0 : 0 ] hps2mpfe_dmi1_bvalid
 ,output wire [255 : 0 ] hps2mpfe_dmi1_rdata
 ,output wire [9 : 0 ] hps2mpfe_dmi1_rid
 ,output wire [0 : 0 ] hps2mpfe_dmi1_rlast
 ,input wire [0 : 0 ] hps2mpfe_dmi1_rready
 ,output wire [1 : 0 ] hps2mpfe_dmi1_rresp
 ,output wire [0 : 0 ] hps2mpfe_dmi1_rvalid
 ,input wire [255 : 0 ] hps2mpfe_dmi1_wdata
 ,input wire [0 : 0 ] hps2mpfe_dmi1_wlast
 ,output wire [0 : 0 ] hps2mpfe_dmi1_wready
 ,input wire [31 : 0 ] hps2mpfe_dmi1_wstrb
 ,input wire [0 : 0 ] hps2mpfe_dmi1_wvalid
 ,input wire [43 : 0 ] hps2mpfe_csr_araddr
 ,input wire [1 : 0 ] hps2mpfe_csr_arburst
 ,input wire [3 : 0 ] hps2mpfe_csr_arcache
 ,input wire [9 : 0 ] hps2mpfe_csr_arid
 ,input wire [7 : 0 ] hps2mpfe_csr_arlen
 ,input wire [0 : 0 ] hps2mpfe_csr_arlock
 ,input wire [2 : 0 ] hps2mpfe_csr_arprot
 ,output wire [0 : 0 ] hps2mpfe_csr_arready
 ,input wire [2 : 0 ] hps2mpfe_csr_arsize
 ,input wire [7 : 0 ] hps2mpfe_csr_aruser
 ,input wire [0 : 0 ] hps2mpfe_csr_arvalid
 ,input wire [43 : 0 ] hps2mpfe_csr_awaddr
 ,input wire [1 : 0 ] hps2mpfe_csr_awburst
 ,input wire [3 : 0 ] hps2mpfe_csr_awcache
 ,input wire [9 : 0 ] hps2mpfe_csr_awid
 ,input wire [7 : 0 ] hps2mpfe_csr_awlen
 ,input wire [0 : 0 ] hps2mpfe_csr_awlock
 ,input wire [2 : 0 ] hps2mpfe_csr_awprot
 ,output wire [0 : 0 ] hps2mpfe_csr_awready
 ,input wire [2 : 0 ] hps2mpfe_csr_awsize
 ,input wire [7 : 0 ] hps2mpfe_csr_awuser
 ,input wire [0 : 0 ] hps2mpfe_csr_awvalid
 ,output wire [9 : 0 ] hps2mpfe_csr_bid
 ,input wire [0 : 0 ] hps2mpfe_csr_bready
 ,output wire [1 : 0 ] hps2mpfe_csr_bresp
 ,output wire [0 : 0 ] hps2mpfe_csr_bvalid
 ,output wire [63 : 0 ] hps2mpfe_csr_rdata
 ,output wire [9 : 0 ] hps2mpfe_csr_rid
 ,output wire [0 : 0 ] hps2mpfe_csr_rlast
 ,input wire [0 : 0 ] hps2mpfe_csr_rready
 ,output wire [1 : 0 ] hps2mpfe_csr_rresp
 ,output wire [0 : 0 ] hps2mpfe_csr_rvalid
 ,input wire [63 : 0 ] hps2mpfe_csr_wdata
 ,input wire [0 : 0 ] hps2mpfe_csr_wlast
 ,output wire [0 : 0 ] hps2mpfe_csr_wready
 ,input wire [7 : 0 ] hps2mpfe_csr_wstrb
 ,input wire [0 : 0 ] hps2mpfe_csr_wvalid
);

// assignments for top ports
assign emif0_arprot = 3'd0;
assign emif0_arlen[7] = 1'b0;
assign emif0_arqos[3:2] = 2'b00;
assign emif_mem_cfg_arprot = 3'd0;
assign emif0_awprot = 3'd0;
assign mpfe2hps_rst = 1'd0;
assign emif0_awlen[7] = 1'b0;
assign emif0_awqos[3:2] = 2'b00;
assign emif_mem_cfg_awprot = 3'd0;




wire [0 : 0] f2sdram_clk_intr;
wire [0 : 0] f2sdram_rst_intr;
wire [31 : 0] f2sdram_araddr_intr;
wire [1 : 0] f2sdram_arburst_intr;
wire [3 : 0] f2sdram_arcache_intr;
wire [4 : 0] f2sdram_arid_intr;
wire [7 : 0] f2sdram_arlen_intr;
wire [0 : 0] f2sdram_arlock_intr;
wire [2 : 0] f2sdram_arprot_intr;
wire [3 : 0] f2sdram_arqos_intr;
wire [0 : 0] f2sdram_arready_intr;
wire [2 : 0] f2sdram_arsize_intr;
wire [0 : 0] f2sdram_arvalid_intr;
wire [31 : 0] f2sdram_awaddr_intr;
wire [1 : 0] f2sdram_awburst_intr;
wire [3 : 0] f2sdram_awcache_intr;
wire [4 : 0] f2sdram_awid_intr;
wire [7 : 0] f2sdram_awlen_intr;
wire [0 : 0] f2sdram_awlock_intr;
wire [2 : 0] f2sdram_awprot_intr;
wire [3 : 0] f2sdram_awqos_intr;
wire [0 : 0] f2sdram_awready_intr;
wire [2 : 0] f2sdram_awsize_intr;
wire [0 : 0] f2sdram_awvalid_intr;
wire [4 : 0] f2sdram_bid_intr;
wire [0 : 0] f2sdram_bready_intr;
wire [1 : 0] f2sdram_bresp_intr;
wire [0 : 0] f2sdram_bvalid_intr;
wire [255 : 0] f2sdram_rdata_intr;
wire [4 : 0] f2sdram_rid_intr;
wire [0 : 0] f2sdram_rlast_intr;
wire [0 : 0] f2sdram_rready_intr;
wire [1 : 0] f2sdram_rresp_intr;
wire [0 : 0] f2sdram_rvalid_intr;
wire [255 : 0] f2sdram_wdata_intr;
wire [0 : 0] f2sdram_wlast_intr;
wire [0 : 0] f2sdram_wready_intr;
wire [31 : 0] f2sdram_wstrb_intr;
wire [0 : 0] f2sdram_wvalid_intr;
wire [7 : 0] f2sdram_aruser_intr;
wire [7 : 0] f2sdram_awuser_intr;
wire [7 : 0] f2sdram_wuser_intr;
wire [7 : 0] f2sdram_buser_intr;
wire [3 : 0] f2sdram_arregion_intr;
wire [7 : 0] f2sdram_ruser_intr;
wire [3 : 0] f2sdram_awregion_intr;

ready_latency_reset_synchronizer  hps_ready_latency_adp_axi4_reset_sync(
 .clk(f2sdram_clk)
,.rst_async(f2sdram_rst)
,.rst_sync(f2sdram_rst_intr)
);

hps_ready_latency_adp_axi4 # (.LOG_DEPTH(3), .NUM_PIPELINES(2), .ADDR_WIDTH(32), .DATA_WIDTH(256), .STRB_WIDTH(256/8), .ID_WIDTH(5), .AUSER_WIDTH(8)) sundancemesa_mpfe_ready_latency_adp_inst_f2sdram (  

  .clk(f2sdram_clk)
, .reset(f2sdram_rst_intr)
, .araddr(f2sdram_araddr)
, .arburst(f2sdram_arburst)
, .arcache(f2sdram_arcache)
, .arid(f2sdram_arid)
, .arlen(f2sdram_arlen)
, .arlock(f2sdram_arlock)
, .arprot(f2sdram_arprot)
, .arqos(f2sdram_arqos)
, .arready(f2sdram_arready_intr)
, .arsize(f2sdram_arsize)
, .arvalid(f2sdram_arvalid)
, .awaddr(f2sdram_awaddr)
, .awburst(f2sdram_awburst)
, .awcache(f2sdram_awcache)
, .awid(f2sdram_awid)
, .awlen(f2sdram_awlen)
, .awlock(f2sdram_awlock)
, .awprot(f2sdram_awprot)
, .awqos(f2sdram_awqos)
, .awready(f2sdram_awready_intr)
, .awsize(f2sdram_awsize)
, .awvalid(f2sdram_awvalid)
, .bid(f2sdram_bid_intr)
, .bready(f2sdram_bready)
, .bresp(f2sdram_bresp_intr)
, .bvalid(f2sdram_bvalid_intr)
, .rdata(f2sdram_rdata_intr)
, .rid(f2sdram_rid_intr)
, .rlast(f2sdram_rlast_intr)
, .rready(f2sdram_rready)
, .rresp(f2sdram_rresp_intr)
, .rvalid(f2sdram_rvalid_intr)
, .wdata(f2sdram_wdata)
, .wlast(f2sdram_wlast)
, .wready(f2sdram_wready_intr)
, .wstrb(f2sdram_wstrb)
, .wvalid(f2sdram_wvalid)
, .aruser(f2sdram_aruser)
, .awuser(f2sdram_awuser)
, .wuser(f2sdram_wuser)
, .buser(f2sdram_buser_intr)
, .arregion(f2sdram_arregion)
, .ruser(f2sdram_ruser_intr)
, .awregion(f2sdram_awregion)
, .araddr_r(f2sdram_araddr_intr)
, .arburst_r(f2sdram_arburst_intr)
, .arcache_r(f2sdram_arcache_intr)
, .arid_r(f2sdram_arid_intr)
, .arlen_r(f2sdram_arlen_intr)
, .arlock_r(f2sdram_arlock_intr)
, .arprot_r(f2sdram_arprot_intr)
, .arqos_r(f2sdram_arqos_intr)
, .arready_r(f2sdram_arready)
, .arsize_r(f2sdram_arsize_intr)
, .arvalid_r(f2sdram_arvalid_intr)
, .awaddr_r(f2sdram_awaddr_intr)
, .awburst_r(f2sdram_awburst_intr)
, .awcache_r(f2sdram_awcache_intr)
, .awid_r(f2sdram_awid_intr)
, .awlen_r(f2sdram_awlen_intr)
, .awlock_r(f2sdram_awlock_intr)
, .awprot_r(f2sdram_awprot_intr)
, .awqos_r(f2sdram_awqos_intr)
, .awready_r(f2sdram_awready)
, .awsize_r(f2sdram_awsize_intr)
, .awvalid_r(f2sdram_awvalid_intr)
, .bid_r(f2sdram_bid)
, .bready_r(f2sdram_bready_intr)
, .bresp_r(f2sdram_bresp)
, .bvalid_r(f2sdram_bvalid)
, .rdata_r(f2sdram_rdata)
, .rid_r(f2sdram_rid)
, .rlast_r(f2sdram_rlast)
, .rready_r(f2sdram_rready_intr)
, .rresp_r(f2sdram_rresp)
, .rvalid_r(f2sdram_rvalid)
, .wdata_r(f2sdram_wdata_intr)
, .wlast_r(f2sdram_wlast_intr)
, .wready_r(f2sdram_wready)
, .wstrb_r(f2sdram_wstrb_intr)
, .wvalid_r(f2sdram_wvalid_intr)
, .aruser_r(f2sdram_aruser_intr)
, .awuser_r(f2sdram_awuser_intr)
, .wuser_r(f2sdram_wuser_intr)
, .buser_r(f2sdram_buser)
, .arregion_r(f2sdram_arregion_intr)
, .ruser_r(f2sdram_ruser)
, .awregion_r(f2sdram_awregion_intr)

);




wire [0 : 0] fpga2hps_clk_intr;
wire [0 : 0] fpga2hps_rst_intr;
wire [4 : 0] fpga2hps_awid_intr;
wire [31 : 0] fpga2hps_awaddr_intr;
wire [1 : 0] fpga2hps_awdomain_intr;
wire [3 : 0] fpga2hps_awsnoop_intr;
wire [7 : 0] fpga2hps_awlen_intr;
wire [2 : 0] fpga2hps_awsize_intr;
wire [2 : 0] fpga2hps_arsize_intr;
wire [1 : 0] fpga2hps_awburst_intr;
wire [0 : 0] fpga2hps_awlock_intr;
wire [3 : 0] fpga2hps_awcache_intr;
wire [2 : 0] fpga2hps_awprot_intr;
wire [3 : 0] fpga2hps_awqos_intr;
wire [0 : 0] fpga2hps_awvalid_intr;
wire [0 : 0] fpga2hps_awready_intr;
wire [255 : 0] fpga2hps_wdata_intr;
wire [31 : 0] fpga2hps_wstrb_intr;
wire [0 : 0] fpga2hps_wlast_intr;
wire [0 : 0] fpga2hps_wvalid_intr;
wire [0 : 0] fpga2hps_wready_intr;
wire [10 : 0] fpga2hps_awstashnid_intr;
wire [0 : 0] fpga2hps_awstashniden_intr;
wire [4 : 0] fpga2hps_awstashlpid_intr;
wire [0 : 0] fpga2hps_awstashlpiden_intr;
wire [5 : 0] fpga2hps_awatop_intr;
wire [4 : 0] fpga2hps_bid_intr;
wire [1 : 0] fpga2hps_bresp_intr;
wire [0 : 0] fpga2hps_bvalid_intr;
wire [0 : 0] fpga2hps_bready_intr;
wire [4 : 0] fpga2hps_arid_intr;
wire [31 : 0] fpga2hps_araddr_intr;
wire [1 : 0] fpga2hps_ardomain_intr;
wire [3 : 0] fpga2hps_arsnoop_intr;
wire [7 : 0] fpga2hps_arlen_intr;
wire [1 : 0] fpga2hps_arburst_intr;
wire [0 : 0] fpga2hps_arlock_intr;
wire [3 : 0] fpga2hps_arcache_intr;
wire [2 : 0] fpga2hps_arprot_intr;
wire [3 : 0] fpga2hps_arqos_intr;
wire [0 : 0] fpga2hps_arvalid_intr;
wire [0 : 0] fpga2hps_arready_intr;
wire [4 : 0] fpga2hps_rid_intr;
wire [255 : 0] fpga2hps_rdata_intr;
wire [1 : 0] fpga2hps_rresp_intr;
wire [0 : 0] fpga2hps_rlast_intr;
wire [0 : 0] fpga2hps_rvalid_intr;
wire [0 : 0] fpga2hps_rready_intr;
wire [7 : 0] fpga2hps_aruser_intr;
wire [7 : 0] fpga2hps_awuser_intr;
wire [3 : 0] fpga2hps_arregion_intr;
wire [3 : 0] fpga2hps_awregion_intr;
wire [7 : 0] fpga2hps_wuser_intr;
wire [7 : 0] fpga2hps_buser_intr;
wire [7 : 0] fpga2hps_ruser_intr;

ready_latency_reset_synchronizer  hps_f2soc_ready_latency_adp_ace5lite_reset_sync(
 .clk(fpga2hps_clk)
,.rst_async(fpga2hps_rst)
,.rst_sync(fpga2hps_rst_intr)
);

hps_f2soc_ready_latency_adp_ace5lite # (.LOG_DEPTH(3), .NUM_PIPELINES(2), .ADDR_WIDTH(32), .DATA_WIDTH(256), .STRB_WIDTH(256/8), .ID_WIDTH(5), .AUSER_WIDTH(8)) sundancemesa_mpfe_ready_latency_adp_inst_fpga2hps (  

  .clk(fpga2hps_clk)
, .reset(fpga2hps_rst_intr)
, .awid(fpga2hps_awid)
, .awaddr(fpga2hps_awaddr)
, .awdomain(fpga2hps_awdomain)
, .awsnoop(fpga2hps_awsnoop)
, .awlen(fpga2hps_awlen)
, .awsize(fpga2hps_awsize)
, .arsize(fpga2hps_arsize)
, .awburst(fpga2hps_awburst)
, .awlock(fpga2hps_awlock)
, .awcache(fpga2hps_awcache)
, .awprot(fpga2hps_awprot)
, .awqos(fpga2hps_awqos)
, .awvalid(fpga2hps_awvalid)
, .awready(fpga2hps_awready_intr)
, .wdata(fpga2hps_wdata)
, .wstrb(fpga2hps_wstrb)
, .wlast(fpga2hps_wlast)
, .wvalid(fpga2hps_wvalid)
, .wready(fpga2hps_wready_intr)
, .awstashnid(fpga2hps_awstashnid)
, .awstashniden(fpga2hps_awstashniden)
, .awstashlpid(fpga2hps_awstashlpid)
, .awstashlpiden(fpga2hps_awstashlpiden)
, .awatop(fpga2hps_awatop)
, .bid(fpga2hps_bid_intr)
, .bresp(fpga2hps_bresp_intr)
, .bvalid(fpga2hps_bvalid_intr)
, .bready(fpga2hps_bready)
, .arid(fpga2hps_arid)
, .araddr(fpga2hps_araddr)
, .ardomain(fpga2hps_ardomain)
, .arsnoop(fpga2hps_arsnoop)
, .arlen(fpga2hps_arlen)
, .arburst(fpga2hps_arburst)
, .arlock(fpga2hps_arlock)
, .arcache(fpga2hps_arcache)
, .arprot(fpga2hps_arprot)
, .arqos(fpga2hps_arqos)
, .arvalid(fpga2hps_arvalid)
, .arready(fpga2hps_arready_intr)
, .rid(fpga2hps_rid_intr)
, .rdata(fpga2hps_rdata_intr)
, .rresp(fpga2hps_rresp_intr)
, .rlast(fpga2hps_rlast_intr)
, .rvalid(fpga2hps_rvalid_intr)
, .rready(fpga2hps_rready)
, .aruser(fpga2hps_aruser)
, .awuser(fpga2hps_awuser)
, .arregion(fpga2hps_arregion)
, .awregion(fpga2hps_awregion)
, .wuser(fpga2hps_wuser)
, .buser(fpga2hps_buser_intr)
, .ruser(fpga2hps_ruser_intr)
, .awid_r(fpga2hps_awid_intr)
, .awaddr_r(fpga2hps_awaddr_intr)
, .awdomain_r(fpga2hps_awdomain_intr)
, .awsnoop_r(fpga2hps_awsnoop_intr)
, .awlen_r(fpga2hps_awlen_intr)
, .awsize_r(fpga2hps_awsize_intr)
, .arsize_r(fpga2hps_arsize_intr)
, .awburst_r(fpga2hps_awburst_intr)
, .awlock_r(fpga2hps_awlock_intr)
, .awcache_r(fpga2hps_awcache_intr)
, .awprot_r(fpga2hps_awprot_intr)
, .awqos_r(fpga2hps_awqos_intr)
, .awvalid_r(fpga2hps_awvalid_intr)
, .awready_r(fpga2hps_awready)
, .wdata_r(fpga2hps_wdata_intr)
, .wstrb_r(fpga2hps_wstrb_intr)
, .wlast_r(fpga2hps_wlast_intr)
, .wvalid_r(fpga2hps_wvalid_intr)
, .wready_r(fpga2hps_wready)
, .awstashnid_r(fpga2hps_awstashnid_intr)
, .awstashniden_r(fpga2hps_awstashniden_intr)
, .awstashlpid_r(fpga2hps_awstashlpid_intr)
, .awstashlpiden_r(fpga2hps_awstashlpiden_intr)
, .awatop_r(fpga2hps_awatop_intr)
, .bid_r(fpga2hps_bid)
, .bresp_r(fpga2hps_bresp)
, .bvalid_r(fpga2hps_bvalid)
, .bready_r(fpga2hps_bready_intr)
, .arid_r(fpga2hps_arid_intr)
, .araddr_r(fpga2hps_araddr_intr)
, .ardomain_r(fpga2hps_ardomain_intr)
, .arsnoop_r(fpga2hps_arsnoop_intr)
, .arlen_r(fpga2hps_arlen_intr)
, .arburst_r(fpga2hps_arburst_intr)
, .arlock_r(fpga2hps_arlock_intr)
, .arcache_r(fpga2hps_arcache_intr)
, .arprot_r(fpga2hps_arprot_intr)
, .arqos_r(fpga2hps_arqos_intr)
, .arvalid_r(fpga2hps_arvalid_intr)
, .arready_r(fpga2hps_arready)
, .rid_r(fpga2hps_rid)
, .rdata_r(fpga2hps_rdata)
, .rresp_r(fpga2hps_rresp)
, .rlast_r(fpga2hps_rlast)
, .rvalid_r(fpga2hps_rvalid)
, .rready_r(fpga2hps_rready_intr)
, .aruser_r(fpga2hps_aruser_intr)
, .awuser_r(fpga2hps_awuser_intr)
, .arregion_r(fpga2hps_arregion_intr)
, .awregion_r(fpga2hps_awregion_intr)
, .wuser_r(fpga2hps_wuser_intr)
, .buser_r(fpga2hps_buser)
, .ruser_r(fpga2hps_ruser)

);


	
(* preserve *)(* altera_attribute = "-name PRESERVE_FANOUT_FREE_WYSIWYG ON" *) 
tennm_sm_soc_mpfe #(
.mpfe_enable("MPFE_ENABLE_ENABLE")
,.mpfe_f2sdram_port_width("MPFE_F2SDRAM_PORT_WIDTH_DATA_WIDTH_256")
,.topology("TOPOLOGY_SINGLE_32_BIT")
,.f2h_addr_width(32'b00000000000000000000000000100000)
,.f2h_data_width(32'b00000000000000000000000100000000)
,.f2sdram_addr_width(32'b00000000000000000000000000100000)
,.f2sdram_data_width(32'b00000000000000000000000100000000)
 ) sundancemesa_mpfe_inst (
  .ccu_dmi1_awcache({
     hps2mpfe_dmi1_awcache[3:0]
  })
 ,.mpfe_csr_wlast({
     hps2mpfe_csr_wlast[0:0]
  })
 ,.f2sdram_awsize({
     f2sdram_awsize_intr[2:0]
  })
 ,.io96b0_p0_clk({
     emif_ch0_axi_clk[0:0]
  })
 ,.f2sdram_bresp({
     f2sdram_bresp_intr[1:0]
  })
 ,.f2soc_wuser({
     fpga2hps_wuser_intr[7:0]
  })
 ,.f2soc_rid({
     fpga2hps_rid_intr[4:0]
  })
 ,.f2sdram_bid({
     f2sdram_bid_intr[4:0]
  })
 ,.f2soc_wstrb({
     fpga2hps_wstrb_intr[31:0]
  })
 ,.f2sdram_aruser({
     17'b00000000000000011
    ,f2sdram_aruser_intr[7:0]
  })
 ,.f2soc_wready({
     fpga2hps_wready_intr[0:0]
  })
 ,.f2soc_rlast({
     fpga2hps_rlast_intr[0:0]
  })
 ,.f2soc_araddr({
     8'b00000000
    ,fpga2hps_araddr_intr[31:0]
  })
 ,.f2sdram_arlock({
     f2sdram_arlock_intr[0:0]
  })
 ,.mpfe_csr_rdata({
     hps2mpfe_csr_rdata[63:0]
  })
 ,.f2soc_arregion({
     fpga2hps_arregion_intr[3:0]
  })
 ,.ccu_dmi1_awlen({
     hps2mpfe_dmi1_awlen[7:0]
  })
 ,.f2sdram_arqos({
     f2sdram_arqos_intr[3:0]
  })
 ,.io96b0_p0_wuser({
     emif0_wuser[31:0]
  })
 ,.ccu_dmi0_bvalid({
     hps2mpfe_dmi0_bvalid[0:0]
  })
 ,.ccu_dmi0_awqos({
     hps2mpfe_dmi0_awqos[3:0]
  })
 ,.mpfe_csr_awburst({
     hps2mpfe_csr_awburst[1:0]
  })
 ,.f2sdram_wdata({
     f2sdram_wdata_intr[255:0]
  })
 ,.f2sdram_flush_req({
     sdram_bridge_req[0:0]
  })
 ,.io96b0_p0_wstrb({
     emif0_wstrb[31:0]
  })
 ,.mpfe_csr_arvalid({
     hps2mpfe_csr_arvalid[0:0]
  })
 ,.f2sdram_rresp({
     f2sdram_rresp_intr[1:0]
  })
 ,.fpga2soc_arprot({
     mpfe2hps_arprot[2:0]
  })
 ,.io96b0_p0_rlast({
     emif0_rlast[0:0]
  })
 ,.f2sdram_rid({
     f2sdram_rid_intr[4:0]
  })
 ,.ccu_dmi1_rvalid({
     hps2mpfe_dmi1_rvalid[0:0]
  })
 ,.fpga2soc_awqos({
     mpfe2hps_awqos[3:0]
  })
 ,.io96b0_p0_awburst({
     emif0_awburst[1:0]
  })
 ,.f2soc_awcache({
     fpga2hps_awcache_intr[3:0]
  })
 ,.f2sdram_arlen({
     f2sdram_arlen_intr[7:0]
  })
 ,.fpga2soc_arsize({
     mpfe2hps_arsize[2:0]
  })
 ,.io96b0_p0_arvalid({
     emif0_arvalid[0:0]
  })
 ,.ccu_dmi0_awlen({
     hps2mpfe_dmi0_awlen[7:0]
  })
 ,.ccu_dmi0_awuser({
     hps2mpfe_dmi0_awuser[7:0]
  })
 ,.io96b0_csr_wready({
     emif_mem_cfg_wready[0:0]
  })
 ,.mpfe_csr_awprot({
     hps2mpfe_csr_awprot[2:0]
  })
 ,.fpga2soc_awburst({
     mpfe2hps_awburst[1:0]
  })
 ,.f2soc_arid({
     fpga2hps_arid_intr[4:0]
  })
 ,.ccu_dmi0_awlock({
     hps2mpfe_dmi0_awlock[0:0]
  })
 ,.f2soc_arbar({
     2'b00
  })
 ,.f2sdram_arcache({
     f2sdram_arcache_intr[3:0]
  })
 ,.mpfe_csr_rready({
     hps2mpfe_csr_rready[0:0]
  })
 ,.mpfe_csr_wvalid({
     hps2mpfe_csr_wvalid[0:0]
  })
 ,.io96b0_csr_araddr({
     emif_mem_cfg_araddr[26:0]
  })
 ,.io96b0_p0_rready({
     emif0_rready[0:0]
  })
 ,.io96b0_p0_wvalid({
     emif0_wvalid[0:0]
  })
 ,.fpga2soc_arvalid({
     mpfe2hps_arvalid[0:0]
  })
 ,.fpga2soc_awatop({
     mpfe2hps_awatop[5:0]
  })
 ,.f2sdram_bvalid({
     f2sdram_bvalid_intr[0:0]
  })
 ,.mpfe_csr_awsize({
     hps2mpfe_csr_awsize[2:0]
  })
 ,.ccu_dmi1_awready({
     hps2mpfe_dmi1_awready[0:0]
  })
 ,.mpfe_csr_bresp({
     hps2mpfe_csr_bresp[1:0]
  })
 ,.io96b0_p0_awsize({
     emif0_awsize[2:0]
  })
 ,.fpga2soc_awlen({
     mpfe2hps_awlen[7:0]
  })
 ,.f2soc_awdomain({
     fpga2hps_awdomain_intr[1:0]
  })
 ,.io96b0_p0_awid({
     emif0_awid[6:0]
  })
 ,.mpfe_csr_bid({
     hps2mpfe_csr_bid[9:0]
  })
 ,.mpfe_csr_aruser({
     hps2mpfe_csr_aruser[7:0]
  })
 ,.io96b0_p0_aruser({
     emif0_aruser[13:0]
  })
 ,.mpfe_csr_arlock({
     hps2mpfe_csr_arlock[0:0]
  })
 ,.f2soc_bready({
     fpga2hps_bready_intr[0:0]
  })
 ,.io96b0_p0_arlock({
     emif0_arlock[0:0]
  })
 ,.f2sdram_awuser({
     17'b00000000000000011
    ,f2sdram_awuser_intr[7:0]
  })
 ,.mpfe_csr_wdata({
     hps2mpfe_csr_wdata[63:0]
  })
 ,.f2sdram_awlock({
     f2sdram_awlock_intr[0:0]
  })
 ,.f2soc_awaddr({
     8'b00000000
    ,fpga2hps_awaddr_intr[31:0]
  })
 ,.f2soc_wlast({
     fpga2hps_wlast_intr[0:0]
  })
 ,.ccu_dmi0_awid({
     hps2mpfe_dmi0_awid[9:0]
  })
 ,.f2sdram_tbu_pmu_irpt({
     sdram_tbu_pmu_irpt[0:0]
  })
 ,.io96b0_csr_clk({
     emif_csr_axi_clk[0:0]
  })
 ,.fpga2soc_awid({
     mpfe2hps_awid[4:0]
  })
 ,.mpfe_csr_rresp({
     hps2mpfe_csr_rresp[1:0]
  })
 ,.mpfe_csr_rid({
     hps2mpfe_csr_rid[9:0]
  })
 ,.ccu_dmi1_arburst({
     hps2mpfe_dmi1_arburst[1:0]
  })
 ,.ccu_dmi0_wready({
     hps2mpfe_dmi0_wready[0:0]
  })
 ,.mpfe_csr_arlen({
     hps2mpfe_csr_arlen[7:0]
  })
 ,.f2soc_rdata({
     fpga2hps_rdata_intr[255:0]
  })
 ,.ccu_dmi0_araddr({
     hps2mpfe_dmi0_araddr[43:0]
  })
 ,.f2soc_awready({
     fpga2hps_awready_intr[0:0]
  })
 ,.fpga2soc_awprot({
     mpfe2hps_awprot[2:0]
  })
 ,.ccu_dmi0_bid({
     hps2mpfe_dmi0_bid[9:0]
  })
 ,.io96b0_p0_wlast({
     emif0_wlast[0:0]
  })
 ,.fpga2soc_wvalid({
     mpfe2hps_wvalid[0:0]
  })
 ,.fpga2soc_rready({
     mpfe2hps_rready[0:0]
  })
 ,.ccu_dmi1_arprot({
     hps2mpfe_dmi1_arprot[2:0]
  })
 ,.mpfe_csr_arcache({
     hps2mpfe_csr_arcache[3:0]
  })
 ,.f2sdram_awvalid({
     f2sdram_awvalid_intr[0:0]
  })
 ,.f2sdram_arready({
     f2sdram_arready_intr[0:0]
  })
 ,.io96b0_csr_bready({
     emif_mem_cfg_bready[0:0]
  })
 ,.fpga2soc_awsize({
     mpfe2hps_awsize[2:0]
  })
 ,.mpfe_csr_bvalid({
     hps2mpfe_csr_bvalid[0:0]
  })
 ,.fpga2soc_awregion({
     mpfe2hps_awregion[3:0]
  })
 ,.io96b0_csr_wstrb({
     emif_mem_cfg_wstrb[3:0]
  })
 ,.io96b0_p0_bvalid({
     emif0_bvalid[0:0]
  })
 ,.f2soc_clk_fdo_aps({
     mpfe2hps_clk[0:0]
  })
 ,.ccu_dmi1_arsize({
     hps2mpfe_dmi1_arsize[2:0]
  })
 ,.io96b0_csr_awaddr({
     emif_mem_cfg_awaddr[26:0]
  })
 ,.f2soc_awmmusid({
     16'b0000000000000001
  })
 ,.ccu_dmi0_awburst({
     hps2mpfe_dmi0_awburst[1:0]
  })
 ,.f2soc_awsnoop({
     fpga2hps_awsnoop_intr[3:0]
  })
 ,.io96b0_p0_rdata({
     emif0_rdata[255:0]
  })
 ,.ccu_dmi1_arid({
     hps2mpfe_dmi1_arid[9:0]
  })
 ,.ccu_dmi0_arvalid({
     hps2mpfe_dmi0_arvalid[0:0]
  })
 ,.fpga2soc_aruser({
     mpfe2hps_aruser[7:0]
  })
 ,.fpga2soc_arlock({
     mpfe2hps_arlock[0:0]
  })
 ,.f2sdram_awqos({
     f2sdram_awqos_intr[3:0]
  })
 ,.ccu_dmi0_rid({
     hps2mpfe_dmi0_rid[9:0]
  })
 ,.f2sdram_wready({
     f2sdram_wready_intr[0:0]
  })
 ,.io96b0_csr_arvalid({
     emif_mem_cfg_arvalid[0:0]
  })
 ,.fpga2soc_arcache({
     mpfe2hps_arcache[3:0]
  })
 ,.f2sdram_araddr({
     12'b000000000000
    ,f2sdram_araddr_intr[31:0]
  })
 ,.mpfe_csr_awuser({
     hps2mpfe_csr_awuser[7:0]
  })
 ,.fpga2soc_buser({
     mpfe2hps_buser[7:0]
  })
 ,.io96b0_p0_awuser({
     emif0_awuser[13:0]
  })
 ,.mpfe_csr_awlock({
     hps2mpfe_csr_awlock[0:0]
  })
 ,.f2soc_arburst({
     fpga2hps_arburst_intr[1:0]
  })
 ,.f2soc_bresp({
     fpga2hps_bresp_intr[1:0]
  })
 ,.io96b0_p0_awlock({
     emif0_awlock[0:0]
  })
 ,.fpga2soc_awstashnid({
     mpfe2hps_awstashnid[10:0]
  })
 ,.f2sdram_awid({
     f2sdram_awid_intr[4:0]
  })
 ,.f2sdram_awlen({
     f2sdram_awlen_intr[7:0]
  })
 ,.f2soc_awbar({
     2'b00
  })
 ,.ccu_dmi0_bready({
     hps2mpfe_dmi0_bready[0:0]
  })
 ,.f2soc_arqos({
     fpga2hps_arqos_intr[3:0]
  })
 ,.io96b0_p0_bresp({
     emif0_bresp[1:0]
  })
 ,.fpga2soc_ruser({
     mpfe2hps_ruser[7:0]
  })
 ,.f2soc_wdata({
     fpga2hps_wdata_intr[255:0]
  })
 ,.mpfe_csr_awvalid({
     hps2mpfe_csr_awvalid[0:0]
  })
 ,.mpfe_csr_arready({
     hps2mpfe_csr_arready[0:0]
  })
 ,.ccu_dmi0_awaddr({
     hps2mpfe_dmi0_awaddr[43:0]
  })
 ,.fpga2soc_bvalid({
     mpfe2hps_bvalid[0:0]
  })
 ,.f2soc_rresp({
     fpga2hps_rresp_intr[1:0]
  })
 ,.ccu_dmi1_awprot({
     hps2mpfe_dmi1_awprot[2:0]
  })
 ,.ccu_dmi1_wvalid({
     hps2mpfe_dmi1_wvalid[0:0]
  })
 ,.ccu_dmi1_rready({
     hps2mpfe_dmi1_rready[0:0]
  })
 ,.io96b0_p0_arqos({
     emif0_arqos[3:0]
  })
 ,.f2soc_clk({
     fpga2hps_clk[0:0]
  })
 ,.f2soc_arlen({
     fpga2hps_arlen_intr[7:0]
  })
 ,.ccu_dmi1_awsize({
     hps2mpfe_dmi1_awsize[2:0]
  })
 ,.io96b0_p0_arready({
     emif0_arready[0:0]
  })
 ,.io96b0_p0_awvalid({
     emif0_awvalid[0:0]
  })
 ,.io96b0_p0_wdata({
     emif0_wdata[255:0]
  })
 ,.mpfe_csr_wready({
     hps2mpfe_csr_wready[0:0]
  })
 ,.f2sdram_awcache({
     f2sdram_awcache_intr[3:0]
  })
 ,.io96b0_p0_rresp({
     emif0_rresp[1:0]
  })
 ,.io96b0_p0_wready({
     emif0_wready[0:0]
  })
 ,.fpga2soc_awuser({
     mpfe2hps_awuser[7:0]
  })
 ,.mpfe_csr_araddr({
     hps2mpfe_csr_araddr[43:0]
  })
 ,.fpga2soc_arready({
     mpfe2hps_arready[0:0]
  })
 ,.fpga2soc_awvalid({
     mpfe2hps_awvalid[0:0]
  })
 ,.f2sdram_bready({
     f2sdram_bready_intr[0:0]
  })
 ,.f2soc_awstashniden({
     fpga2hps_awstashniden_intr[0:0]
  })
 ,.io96b0_p0_araddr({
     emif0_araddr[39:0]
  })
 ,.fpga2soc_awlock({
     mpfe2hps_awlock[0:0]
  })
 ,.ccu_dmi1_wstrb({
     hps2mpfe_dmi1_wstrb[31:0]
  })
 ,.ccu_dmi1_aruser({
     hps2mpfe_dmi1_aruser[7:0]
  })
 ,.f2soc_rvalid({
     fpga2hps_rvalid_intr[0:0]
  })
 ,.f2soc_ardomain({
     fpga2hps_ardomain_intr[1:0]
  })
 ,.ccu_dmi1_arlock({
     hps2mpfe_dmi1_arlock[0:0]
  })
 ,.f2sdram_awaddr({
     12'b000000000000
    ,f2sdram_awaddr_intr[31:0]
  })
 ,.io96b0_p0_arlen({
     emif0_arlen[7:0]
  })
 ,.ccu_dmi1_rlast({
     hps2mpfe_dmi1_rlast[0:0]
  })
 ,.ccu_dmi0_arcache({
     hps2mpfe_dmi0_arcache[3:0]
  })
 ,.mpfe_csr_awid({
     hps2mpfe_csr_awid[9:0]
  })
 ,.fpga2soc_awstashlpiden({
     mpfe2hps_awstashlpiden[0:0]
  })
 ,.io96b0_csr_rdata({
     emif_mem_cfg_rdata[31:0]
  })
 ,.fpga2soc_bid({
     mpfe2hps_bid[4:0]
  })
 ,.mpfe_csr_awlen({
     hps2mpfe_csr_awlen[7:0]
  })
 ,.fpga2soc_arsnoop({
     mpfe2hps_arsnoop[3:0]
  })
 ,.f2sdram_bridge_rst_n({
     sdram_bridge_rst_n[0:0]
  })
 ,.f2sdram_clk({
     f2sdram_clk[0:0]
  })
 ,.f2soc_awstashlpid({
     fpga2hps_awstashlpid_intr[4:0]
  })
 ,.f2soc_armmusecsid({
     1'b1
  })
 ,.ccu_dmi0_wstrb({
     hps2mpfe_dmi0_wstrb[31:0]
  })
 ,.mpu_ccu_clk({
     hps2mpfe_ccu_clk[0:0]
  })
 ,.f2sdram_buser({
     f2sdram_buser_intr[7:0]
  })
 ,.ccu_dmi0_rlast({
     hps2mpfe_dmi0_rlast[0:0]
  })
 ,.io96b0_csr_rvalid({
     emif_mem_cfg_rvalid[0:0]
  })
 ,.fpga2soc_wuser({
     mpfe2hps_wuser[7:0]
  })
 ,.fpga2soc_rid({
     mpfe2hps_rid[4:0]
  })
 ,.ccu_dmi1_awburst({
     hps2mpfe_dmi1_awburst[1:0]
  })
 ,.f2sdram_tbu_ras_irpt({
     sdram_tbu_ras_irpt[0:0]
  })
 ,.ccu_dmi1_bvalid({
     hps2mpfe_dmi1_bvalid[0:0]
  })
 ,.fpga2soc_wstrb({
     mpfe2hps_wstrb[31:0]
  })
 ,.ccu_dmi1_arvalid({
     hps2mpfe_dmi1_arvalid[0:0]
  })
 ,.fpga2soc_wready({
     mpfe2hps_wready[0:0]
  })
 ,.fpga2soc_araddr({
     mpfe2hps_araddr[39:0]
  })
 ,.fpga2soc_rlast({
     mpfe2hps_rlast[0:0]
  })
 ,.mpfe_csr_awcache({
     hps2mpfe_csr_awcache[3:0]
  })
 ,.fpga2soc_arregion({
     mpfe2hps_arregion[3:0]
  })
 ,.io96b0_csr_bresp({
     emif_mem_cfg_bresp[1:0]
  })
 ,.f2sdram_awready({
     f2sdram_awready_intr[0:0]
  })
 ,.mpfe_csr_bready({
     hps2mpfe_csr_bready[0:0]
  })
 ,.io96b0_p0_bready({
     emif0_bready[0:0]
  })
 ,.io96b0_p0_bid({
     emif0_bid[6:0]
  })
 ,.f2soc_armmusid({
     16'b0000000000000001
  })
 ,.io96b0_p0_arid({
     emif0_arid[6:0]
  })
 ,.f2sdram_ruser({
     f2sdram_ruser_intr[7:0]
  })
 ,.mpfe_csr_awaddr({
     hps2mpfe_csr_awaddr[43:0]
  })
 ,.io96b0_p0_awaddr({
     emif0_awaddr[39:0]
  })
 ,.ccu_dmi0_arready({
     hps2mpfe_dmi0_arready[0:0]
  })
 ,.ccu_dmi0_awvalid({
     hps2mpfe_dmi0_awvalid[0:0]
  })
 ,.ccu_dmi1_awuser({
     hps2mpfe_dmi1_awuser[7:0]
  })
 ,.f2soc_arprot({
     fpga2hps_arprot_intr[2:0]
  })
 ,.ccu_dmi1_awlock({
     hps2mpfe_dmi1_awlock[0:0]
  })
 ,.f2sdram_flush_ack({
     sdram_bridge_ack[0:0]
  })
 ,.io96b0_csr_awvalid({
     emif_mem_cfg_awvalid[0:0]
  })
 ,.io96b0_csr_arready({
     emif_mem_cfg_arready[0:0]
  })
 ,.f2soc_awqos({
     fpga2hps_awqos_intr[3:0]
  })
 ,.ccu_dmi1_wlast({
     hps2mpfe_dmi1_wlast[0:0]
  })
 ,.fpga2soc_awcache({
     mpfe2hps_awcache[3:0]
  })
 ,.io96b0_csr_wdata({
     emif_mem_cfg_wdata[31:0]
  })
 ,.f2soc_arsize({
     fpga2hps_arsize_intr[2:0]
  })
 ,.io96b0_csr_rresp({
     emif_mem_cfg_rresp[1:0]
  })
 ,.ccu_dmi0_arid({
     hps2mpfe_dmi0_arid[9:0]
  })
 ,.fpga2soc_arid({
     mpfe2hps_arid[4:0]
  })
 ,.f2soc_awburst({
     fpga2hps_awburst_intr[1:0]
  })
 ,.ccu_dmi0_rvalid({
     hps2mpfe_dmi0_rvalid[0:0]
  })
 ,.io96b0_p0_rid({
     emif0_rid[6:0]
  })
 ,.f2soc_arvalid({
     fpga2hps_arvalid_intr[0:0]
  })
 ,.f2soc_awatop({
     fpga2hps_awatop_intr[5:0]
  })
 ,.ccu_dmi1_rdata({
     hps2mpfe_dmi1_rdata[255:0]
  })
 ,.f2sdram_arburst({
     f2sdram_arburst_intr[1:0]
  })
 ,.io96b0_p0_awqos({
     emif0_awqos[3:0]
  })
 ,.f2sdram_awregion({
     f2sdram_awregion_intr[3:0]
  })
 ,.f2soc_awlen({
     fpga2hps_awlen_intr[7:0]
  })
 ,.fpga2soc_awdomain({
     mpfe2hps_awdomain[1:0]
  })
 ,.ccu_dmi0_wlast({
     hps2mpfe_dmi0_wlast[0:0]
  })
 ,.fpga2soc_bready({
     mpfe2hps_bready[0:0]
  })
 ,.mpfe_csr_awready({
     hps2mpfe_csr_awready[0:0]
  })
 ,.io96b0_p0_awlen({
     emif0_awlen[7:0]
  })
 ,.fpga2soc_awaddr({
     mpfe2hps_awaddr[39:0]
  })
 ,.fpga2soc_wlast({
     mpfe2hps_wlast[0:0]
  })
 ,.ccu_dmi0_rdata({
     hps2mpfe_dmi0_rdata[255:0]
  })
 ,.f2sdram_rvalid({
     f2sdram_rvalid_intr[0:0]
  })
 ,.ccu_dmi1_wready({
     hps2mpfe_dmi1_wready[0:0]
  })
 ,.f2soc_awid({
     fpga2hps_awid_intr[4:0]
  })
 ,.ccu_dmi1_araddr({
     hps2mpfe_dmi1_araddr[43:0]
  })
 ,.ccu_dmi1_arcache({
     hps2mpfe_dmi1_arcache[3:0]
  })
 ,.io96b0_p0_awready({
     emif0_awready[0:0]
  })
 ,.f2sdram_wuser({
     f2sdram_wuser_intr[7:0]
  })
 ,.f2sdram_wstrb({
     f2sdram_wstrb_intr[31:0]
  })
 ,.fpga2soc_rdata({
     mpfe2hps_rdata[255:0]
  })
 ,.ccu_dmi1_bresp({
     hps2mpfe_dmi1_bresp[1:0]
  })
 ,.fpga2soc_awready({
     mpfe2hps_awready[0:0]
  })
 ,.f2soc_awprot({
     fpga2hps_awprot_intr[2:0]
  })
 ,.f2soc_rready({
     fpga2hps_rready_intr[0:0]
  })
 ,.f2soc_wvalid({
     fpga2hps_wvalid_intr[0:0]
  })
 ,.f2sdram_rlast({
     f2sdram_rlast_intr[0:0]
  })
 ,.f2sdram_arid({
     f2sdram_arid_intr[4:0]
  })
 ,.f2soc_awsize({
     fpga2hps_awsize_intr[2:0]
  })
 ,.ccu_dmi0_awcache({
     hps2mpfe_dmi0_awcache[3:0]
  })
 ,.f2soc_awregion({
     fpga2hps_awregion_intr[3:0]
  })
 ,.mpfe_csr_arburst({
     hps2mpfe_csr_arburst[1:0]
  })
 ,.ccu_dmi1_arqos({
     hps2mpfe_dmi1_arqos[3:0]
  })
 ,.fpga2soc_awsnoop({
     mpfe2hps_awsnoop[3:0]
  })
 ,.ccu_dmi0_arprot({
     hps2mpfe_dmi0_arprot[2:0]
  })
 ,.ccu_dmi1_wdata({
     hps2mpfe_dmi1_wdata[255:0]
  })
 ,.f2soc_aruser({
     fpga2hps_aruser_intr[7:0]
  })
 ,.ccu_dmi0_bresp({
     hps2mpfe_dmi0_bresp[1:0]
  })
 ,.f2soc_arlock({
     fpga2hps_arlock_intr[0:0]
  })
 ,.ccu_dmi1_rresp({
     hps2mpfe_dmi1_rresp[1:0]
  })
 ,.ccu_dmi0_arsize({
     hps2mpfe_dmi0_arsize[2:0]
  })
 ,.io96b0_p0_arburst({
     emif0_arburst[1:0]
  })
 ,.f2sdram_port_size_config({
     2'b10
  })
 ,.f2soc_arcache({
     fpga2hps_arcache_intr[3:0]
  })
 ,.f2soc_buser({
     fpga2hps_buser_intr[7:0]
  })
 ,.io96b0_csr_wvalid({
     emif_mem_cfg_wvalid[0:0]
  })
 ,.io96b0_csr_rready({
     emif_mem_cfg_rready[0:0]
  })
 ,.ccu_dmi1_arlen({
     hps2mpfe_dmi1_arlen[7:0]
  })
 ,.fpga2soc_arburst({
     mpfe2hps_arburst[1:0]
  })
 ,.fpga2soc_bresp({
     mpfe2hps_bresp[1:0]
  })
 ,.mpfe_csr_rvalid({
     hps2mpfe_csr_rvalid[0:0]
  })
 ,.io96b0_p0_rvalid({
     emif0_rvalid[0:0]
  })
 ,.ccu_dmi0_arqos({
     hps2mpfe_dmi0_arqos[3:0]
  })
 ,.f2soc_awstashnid({
     fpga2hps_awstashnid_intr[10:0]
  })
 ,.ccu_dmi1_bready({
     hps2mpfe_dmi1_bready[0:0]
  })
 ,.ccu_dmi0_wdata({
     hps2mpfe_dmi0_wdata[255:0]
  })
 ,.ccu_dmi1_arready({
     hps2mpfe_dmi1_arready[0:0]
  })
 ,.ccu_dmi1_awvalid({
     hps2mpfe_dmi1_awvalid[0:0]
  })
 ,.f2sdram_arprot({
     f2sdram_arprot_intr[2:0]
  })
 ,.ccu_dmi0_rresp({
     hps2mpfe_dmi0_rresp[1:0]
  })
 ,.ccu_dmi1_awaddr({
     hps2mpfe_dmi1_awaddr[43:0]
  })
 ,.mpfe_csr_wstrb({
     hps2mpfe_csr_wstrb[7:0]
  })
 ,.ccu_dmi1_awid({
     hps2mpfe_dmi1_awid[9:0]
  })
 ,.fpga2soc_arqos({
     mpfe2hps_arqos[3:0]
  })
 ,.ccu_dmi1_bid({
     hps2mpfe_dmi1_bid[9:0]
  })
 ,.f2sdram_arsize({
     f2sdram_arsize_intr[2:0]
  })
 ,.mpfe_csr_rlast({
     hps2mpfe_csr_rlast[0:0]
  })
 ,.f2soc_ruser({
     fpga2hps_ruser_intr[7:0]
  })
 ,.fpga2soc_wdata({
     mpfe2hps_wdata[255:0]
  })
 ,.ccu_dmi0_arlen({
     hps2mpfe_dmi0_arlen[7:0]
  })
 ,.f2soc_bvalid({
     fpga2hps_bvalid_intr[0:0]
  })
 ,.mpfe_csr_arid({
     hps2mpfe_csr_arid[9:0]
  })
 ,.fpga2soc_rresp({
     mpfe2hps_rresp[1:0]
  })
 ,.ccu_dmi0_awready({
     hps2mpfe_dmi0_awready[0:0]
  })
 ,.f2sdram_wlast({
     f2sdram_wlast_intr[0:0]
  })
 ,.io96b0_csr_awready({
     emif_mem_cfg_awready[0:0]
  })
 ,.fpga2soc_arlen({
     mpfe2hps_arlen[7:0]
  })
 ,.f2soc_awmmusecsid({
     1'b1
  })
 ,.io96b0_p0_ruser({
     emif0_ruser[31:0]
  })
 ,.ccu_dmi0_awprot({
     hps2mpfe_dmi0_awprot[2:0]
  })
 ,.f2sdram_rdata({
     f2sdram_rdata_intr[255:0]
  })
 ,.ccu_dmi0_rready({
     hps2mpfe_dmi0_rready[0:0]
  })
 ,.ccu_dmi0_wvalid({
     hps2mpfe_dmi0_wvalid[0:0]
  })
 ,.f2soc_awuser({
     fpga2hps_awuser_intr[7:0]
  })
 ,.ccu_dmi1_rid({
     hps2mpfe_dmi1_rid[9:0]
  })
 ,.f2soc_arready({
     fpga2hps_arready_intr[0:0]
  })
 ,.f2soc_awvalid({
     fpga2hps_awvalid_intr[0:0]
  })
 ,.f2soc_awlock({
     fpga2hps_awlock_intr[0:0]
  })
 ,.f2sdram_arregion({
     f2sdram_arregion_intr[3:0]
  })
 ,.fpga2soc_awstashniden({
     mpfe2hps_awstashniden[0:0]
  })
 ,.f2sdram_awburst({
     f2sdram_awburst_intr[1:0]
  })
 ,.fpga2soc_rvalid({
     mpfe2hps_rvalid[0:0]
  })
 ,.ccu_dmi0_awsize({
     hps2mpfe_dmi0_awsize[2:0]
  })
 ,.fpga2soc_ardomain({
     mpfe2hps_ardomain[1:0]
  })
 ,.io96b0_csr_bvalid({
     emif_mem_cfg_bvalid[0:0]
  })
 ,.f2sdram_arvalid({
     f2sdram_arvalid_intr[0:0]
  })
 ,.f2soc_bid({
     fpga2hps_bid_intr[4:0]
  })
 ,.f2soc_awstashlpiden({
     fpga2hps_awstashlpiden_intr[0:0]
  })
 ,.ccu_dmi0_aruser({
     hps2mpfe_dmi0_aruser[7:0]
  })
 ,.f2soc_arsnoop({
     fpga2hps_arsnoop_intr[3:0]
  })
 ,.ccu_dmi0_arburst({
     hps2mpfe_dmi0_arburst[1:0]
  })
 ,.mpfe_csr_arprot({
     hps2mpfe_csr_arprot[2:0]
  })
 ,.ccu_dmi0_arlock({
     hps2mpfe_dmi0_arlock[0:0]
  })
 ,.fpga2soc_awstashlpid({
     mpfe2hps_awstashlpid[4:0]
  })
 ,.f2sdram_awprot({
     f2sdram_awprot_intr[2:0]
  })
 ,.mpfe_csr_arsize({
     hps2mpfe_csr_arsize[2:0]
  })
 ,.io96b0_p0_arsize({
     emif0_arsize[2:0]
  })
 ,.f2sdram_rready({
     f2sdram_rready_intr[0:0]
  })
 ,.f2sdram_wvalid({
     f2sdram_wvalid_intr[0:0]
  })
 ,.ccu_dmi1_awqos({
     hps2mpfe_dmi1_awqos[3:0]
  })
);




endmodule


