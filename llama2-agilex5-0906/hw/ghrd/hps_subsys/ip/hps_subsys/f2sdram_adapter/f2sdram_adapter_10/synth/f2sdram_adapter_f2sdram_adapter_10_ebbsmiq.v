
//
// SPDX-FileCopyrightText: Copyright (C) 2024 Intel Corporation
// SPDX-License-Identifier: MIT-0
//

`timescale 1 ps / 1 ps
module f2sdram_adapter_f2sdram_adapter_10_ebbsmiq #(
    parameter DATA_WIDTH = 64
) (

	//
	// clock and reset
	//
	input  wire         clk,
	input  wire         reset,

	//
	// AXI4 subordinate
	//
	input  wire [31:0]  sub_araddr,
	input  wire [1:0]   sub_arburst,
	input  wire [3:0]   sub_arcache,
	input  wire [4:0]   sub_arid,
	input  wire [7:0]   sub_arlen,
	input  wire         sub_arlock,
	input  wire [2:0]   sub_arprot,
	input  wire [3:0]   sub_arqos,
	output wire         sub_arready,
	input  wire [2:0]   sub_arsize,
	input  wire         sub_arvalid,
	input  wire [31:0]  sub_awaddr,
	input  wire [1:0]   sub_awburst,
	input  wire [3:0]   sub_awcache,
	input  wire [4:0]   sub_awid,
	input  wire [7:0]   sub_awlen,
	input  wire         sub_awlock,
	input  wire [2:0]   sub_awprot,
	input  wire [3:0]   sub_awqos,
	output wire         sub_awready,
	input  wire [2:0]   sub_awsize,
	input  wire         sub_awvalid,
	output wire [4:0]   sub_bid,
	input  wire         sub_bready,
	output wire [1:0]   sub_bresp,
	output wire         sub_bvalid,
	output wire [DATA_WIDTH-1:0] sub_rdata,
	output wire [4:0]   sub_rid,
	output wire         sub_rlast,
	input  wire         sub_rready,
	output wire [1:0]   sub_rresp,
	output wire         sub_rvalid,
	input  wire [DATA_WIDTH-1:0] sub_wdata,
	input  wire         sub_wlast,
	output wire         sub_wready,
	input  wire [DATA_WIDTH/8-1:0]  sub_wstrb,
	input  wire         sub_wvalid,
	input  wire [7:0]   sub_aruser,
	input  wire [7:0]   sub_awuser,
	input  wire [7:0]   sub_wuser,
	output wire [7:0]   sub_buser,
	input  wire [3:0]   sub_arregion,
	output wire [7:0]   sub_ruser,
	input  wire [3:0]   sub_awregion,

	//
	// AXI4 manager
	//
	output wire [31:0]  man_araddr,
	output wire [1:0]   man_arburst,
	output wire [3:0]   man_arcache,
	output wire [4:0]   man_arid,
	output wire [7:0]   man_arlen,
	output wire         man_arlock,
	output wire [2:0]   man_arprot,
	output wire [3:0]   man_arqos,
	input  wire         man_arready,
	output wire [2:0]   man_arsize,
	output wire         man_arvalid,
	output wire [31:0]  man_awaddr,
	output wire [1:0]   man_awburst,
	output wire [3:0]   man_awcache,
	output wire [4:0]   man_awid,
	output wire [7:0]   man_awlen,
	output wire         man_awlock,
	output wire [2:0]   man_awprot,
	output wire [3:0]   man_awqos,
	input  wire         man_awready,
	output wire [2:0]   man_awsize,
	output wire         man_awvalid,
	input  wire [4:0]   man_bid,
	output wire         man_bready,
	input  wire [1:0]   man_bresp,
	input  wire         man_bvalid,
	input  wire [DATA_WIDTH-1:0] man_rdata,
	input  wire [4:0]   man_rid,
	input  wire         man_rlast,
	output wire         man_rready,
	input  wire [1:0]   man_rresp,
	input  wire         man_rvalid,
	output wire [DATA_WIDTH-1:0] man_wdata,
	output wire         man_wlast,
	input  wire         man_wready,
	output wire [DATA_WIDTH/8-1:0]  man_wstrb,
	output wire         man_wvalid,
	output wire [7:0]   man_aruser,
	output wire [7:0]   man_awuser,
	output wire [7:0]   man_wuser,
	input  wire [7:0]   man_buser,
	output wire [3:0]   man_arregion,
	input  wire [7:0]   man_ruser,
	output wire [3:0]   man_awregion
);

assign sub_ruser   = man_ruser;
assign sub_wready  = man_wready;
assign sub_rid     = man_rid;
assign sub_arready = man_arready;
assign sub_bresp   = man_bresp;
assign sub_rdata   = man_rdata;
assign sub_awready = man_awready;
assign sub_rlast   = man_rlast;
assign sub_buser   = man_buser;
assign sub_rresp   = man_rresp;
assign sub_bid     = man_bid;
assign sub_bvalid  = man_bvalid;
assign sub_rvalid  = man_rvalid;

assign man_wuser    = 8'h00;
assign man_awburst  = sub_awburst;
assign man_arregion = 4'h0;
assign man_arlen    = sub_arlen;
assign man_arqos    = 4'h0;
assign man_awuser   = 8'hE0;
assign man_wstrb    = sub_wstrb;
assign man_rready   = sub_rready;
assign man_awlen    = sub_awlen;
assign man_awqos    = 4'h0;
assign man_arcache  = 4'h2;
assign man_araddr   = sub_araddr;
assign man_wvalid   = sub_wvalid;
assign man_arprot   = 3'b011;
assign man_arvalid  = sub_arvalid;
assign man_awprot   = 3'b011;
assign man_wdata    = sub_wdata;
assign man_arid     = sub_arid;
assign man_awcache  = 4'h2;
assign man_arlock   = 1'b0;
assign man_awlock   = 1'b0;
assign man_awaddr   = sub_awaddr;
assign man_arburst  = sub_arburst;
assign man_arsize   = sub_arsize;
assign man_bready   = sub_bready;
assign man_wlast    = sub_wlast;
assign man_awregion = 4'h0;
assign man_awid     = sub_awid;
assign man_awsize   = sub_awsize;
assign man_awvalid  = sub_awvalid;
assign man_aruser   = 8'hE0;

endmodule
