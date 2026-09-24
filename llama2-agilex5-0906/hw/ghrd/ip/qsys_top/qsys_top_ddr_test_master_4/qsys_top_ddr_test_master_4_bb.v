module qsys_top_ddr_test_master_4 (
		input  wire         csr_clk,     //    csr_clk.clk
		input  wire         csr_rst,     //    csr_rst.reset
		input  wire [7:0]   csr_awaddr,  //  csr_slave.awaddr
		input  wire [2:0]   csr_awprot,  //           .awprot
		input  wire         csr_awvalid, //           .awvalid
		output wire         csr_awready, //           .awready
		input  wire [31:0]  csr_wdata,   //           .wdata
		input  wire [3:0]   csr_wstrb,   //           .wstrb
		input  wire         csr_wvalid,  //           .wvalid
		output wire         csr_wready,  //           .wready
		output wire [1:0]   csr_bresp,   //           .bresp
		output wire         csr_bvalid,  //           .bvalid
		input  wire         csr_bready,  //           .bready
		input  wire [7:0]   csr_araddr,  //           .araddr
		input  wire [2:0]   csr_arprot,  //           .arprot
		input  wire         csr_arvalid, //           .arvalid
		output wire         csr_arready, //           .arready
		output wire [31:0]  csr_rdata,   //           .rdata
		output wire [1:0]   csr_rresp,   //           .rresp
		output wire         csr_rvalid,  //           .rvalid
		input  wire         csr_rready,  //           .rready
		input  wire         axi_clk,     //    axi_clk.clk
		input  wire         axi_rst,     //    axi_rst.reset
		output wire [3:0]   axi_awid,    // axi_master.awid
		output wire [63:0]  axi_awaddr,  //           .awaddr
		output wire [7:0]   axi_awlen,   //           .awlen
		output wire [2:0]   axi_awsize,  //           .awsize
		output wire [1:0]   axi_awburst, //           .awburst
		output wire         axi_awlock,  //           .awlock
		output wire [3:0]   axi_awcache, //           .awcache
		output wire [2:0]   axi_awprot,  //           .awprot
		output wire [3:0]   axi_awqos,   //           .awqos
		output wire         axi_awvalid, //           .awvalid
		input  wire         axi_awready, //           .awready
		output wire [127:0] axi_wdata,   //           .wdata
		output wire [15:0]  axi_wstrb,   //           .wstrb
		output wire         axi_wlast,   //           .wlast
		output wire         axi_wvalid,  //           .wvalid
		input  wire         axi_wready,  //           .wready
		input  wire [3:0]   axi_bid,     //           .bid
		input  wire [1:0]   axi_bresp,   //           .bresp
		input  wire         axi_bvalid,  //           .bvalid
		output wire         axi_bready,  //           .bready
		output wire [3:0]   axi_arid,    //           .arid
		output wire [63:0]  axi_araddr,  //           .araddr
		output wire [7:0]   axi_arlen,   //           .arlen
		output wire [2:0]   axi_arsize,  //           .arsize
		output wire [1:0]   axi_arburst, //           .arburst
		output wire         axi_arlock,  //           .arlock
		output wire [3:0]   axi_arcache, //           .arcache
		output wire [2:0]   axi_arprot,  //           .arprot
		output wire [3:0]   axi_arqos,   //           .arqos
		output wire         axi_arvalid, //           .arvalid
		input  wire         axi_arready, //           .arready
		input  wire [3:0]   axi_rid,     //           .rid
		input  wire [127:0] axi_rdata,   //           .rdata
		input  wire [1:0]   axi_rresp,   //           .rresp
		input  wire         axi_rlast,   //           .rlast
		input  wire         axi_rvalid,  //           .rvalid
		output wire         axi_rready   //           .rready
	);
endmodule

