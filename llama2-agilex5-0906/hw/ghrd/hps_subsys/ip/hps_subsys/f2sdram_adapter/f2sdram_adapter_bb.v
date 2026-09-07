module f2sdram_adapter (
		input  wire         clk,          //    clock.clk
		input  wire         reset,        //    reset.reset
		output wire [31:0]  man_araddr,   // axi4_man.araddr
		output wire [1:0]   man_arburst,  //         .arburst
		output wire [3:0]   man_arcache,  //         .arcache
		output wire [4:0]   man_arid,     //         .arid
		output wire [7:0]   man_arlen,    //         .arlen
		output wire         man_arlock,   //         .arlock
		output wire [2:0]   man_arprot,   //         .arprot
		output wire [3:0]   man_arqos,    //         .arqos
		input  wire         man_arready,  //         .arready
		output wire [2:0]   man_arsize,   //         .arsize
		output wire         man_arvalid,  //         .arvalid
		output wire [31:0]  man_awaddr,   //         .awaddr
		output wire [1:0]   man_awburst,  //         .awburst
		output wire [3:0]   man_awcache,  //         .awcache
		output wire [4:0]   man_awid,     //         .awid
		output wire [7:0]   man_awlen,    //         .awlen
		output wire         man_awlock,   //         .awlock
		output wire [2:0]   man_awprot,   //         .awprot
		output wire [3:0]   man_awqos,    //         .awqos
		input  wire         man_awready,  //         .awready
		output wire [2:0]   man_awsize,   //         .awsize
		output wire         man_awvalid,  //         .awvalid
		input  wire [4:0]   man_bid,      //         .bid
		output wire         man_bready,   //         .bready
		input  wire [1:0]   man_bresp,    //         .bresp
		input  wire         man_bvalid,   //         .bvalid
		input  wire [255:0] man_rdata,    //         .rdata
		input  wire [4:0]   man_rid,      //         .rid
		input  wire         man_rlast,    //         .rlast
		output wire         man_rready,   //         .rready
		input  wire [1:0]   man_rresp,    //         .rresp
		input  wire         man_rvalid,   //         .rvalid
		output wire [255:0] man_wdata,    //         .wdata
		output wire         man_wlast,    //         .wlast
		input  wire         man_wready,   //         .wready
		output wire [31:0]  man_wstrb,    //         .wstrb
		output wire         man_wvalid,   //         .wvalid
		output wire [7:0]   man_aruser,   //         .aruser
		output wire [7:0]   man_awuser,   //         .awuser
		output wire [7:0]   man_wuser,    //         .wuser
		input  wire [7:0]   man_buser,    //         .buser
		output wire [3:0]   man_arregion, //         .arregion
		input  wire [7:0]   man_ruser,    //         .ruser
		output wire [3:0]   man_awregion, //         .awregion
		input  wire [31:0]  sub_araddr,   // axi4_sub.araddr
		input  wire [1:0]   sub_arburst,  //         .arburst
		input  wire [3:0]   sub_arcache,  //         .arcache
		input  wire [4:0]   sub_arid,     //         .arid
		input  wire [7:0]   sub_arlen,    //         .arlen
		input  wire         sub_arlock,   //         .arlock
		input  wire [2:0]   sub_arprot,   //         .arprot
		input  wire [3:0]   sub_arqos,    //         .arqos
		output wire         sub_arready,  //         .arready
		input  wire [2:0]   sub_arsize,   //         .arsize
		input  wire         sub_arvalid,  //         .arvalid
		input  wire [31:0]  sub_awaddr,   //         .awaddr
		input  wire [1:0]   sub_awburst,  //         .awburst
		input  wire [3:0]   sub_awcache,  //         .awcache
		input  wire [4:0]   sub_awid,     //         .awid
		input  wire [7:0]   sub_awlen,    //         .awlen
		input  wire         sub_awlock,   //         .awlock
		input  wire [2:0]   sub_awprot,   //         .awprot
		input  wire [3:0]   sub_awqos,    //         .awqos
		output wire         sub_awready,  //         .awready
		input  wire [2:0]   sub_awsize,   //         .awsize
		input  wire         sub_awvalid,  //         .awvalid
		output wire [4:0]   sub_bid,      //         .bid
		input  wire         sub_bready,   //         .bready
		output wire [1:0]   sub_bresp,    //         .bresp
		output wire         sub_bvalid,   //         .bvalid
		output wire [255:0] sub_rdata,    //         .rdata
		output wire [4:0]   sub_rid,      //         .rid
		output wire         sub_rlast,    //         .rlast
		input  wire         sub_rready,   //         .rready
		output wire [1:0]   sub_rresp,    //         .rresp
		output wire         sub_rvalid,   //         .rvalid
		input  wire [255:0] sub_wdata,    //         .wdata
		input  wire         sub_wlast,    //         .wlast
		output wire         sub_wready,   //         .wready
		input  wire [31:0]  sub_wstrb,    //         .wstrb
		input  wire         sub_wvalid,   //         .wvalid
		input  wire [7:0]   sub_aruser,   //         .aruser
		input  wire [7:0]   sub_awuser,   //         .awuser
		input  wire [7:0]   sub_wuser,    //         .wuser
		output wire [7:0]   sub_buser,    //         .buser
		input  wire [3:0]   sub_arregion, //         .arregion
		output wire [7:0]   sub_ruser,    //         .ruser
		input  wire [3:0]   sub_awregion  //         .awregion
	);
endmodule

