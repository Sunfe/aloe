module altera_ace5lite_cache_coherency_translator_0 #(
		parameter WSTRB_WIDTH = 32,
		parameter USER_WIDTH  = 8
	) (
		input  wire         clk,                      //        clk.clk
		input  wire         reset,                    //      reset.reset
		output wire [4:0]   m_ace5lite_awid,          // m_ace5lite.awid
		output wire [31:0]  m_ace5lite_awaddr,        //           .awaddr
		output wire [1:0]   m_ace5lite_awdomain,      //           .awdomain
		output wire [3:0]   m_ace5lite_awsnoop,       //           .awsnoop
		output wire [7:0]   m_ace5lite_awlen,         //           .awlen
		output wire [2:0]   m_ace5lite_awsize,        //           .awsize
		output wire [2:0]   m_ace5lite_arsize,        //           .arsize
		output wire [1:0]   m_ace5lite_awburst,       //           .awburst
		output wire         m_ace5lite_awlock,        //           .awlock
		output wire [3:0]   m_ace5lite_awcache,       //           .awcache
		output wire [2:0]   m_ace5lite_awprot,        //           .awprot
		output wire [3:0]   m_ace5lite_awqos,         //           .awqos
		output wire [10:0]  m_ace5lite_awstashnid,    //           .awstashnid
		output wire         m_ace5lite_awstashniden,  //           .awstashniden
		output wire [4:0]   m_ace5lite_awstashlpid,   //           .awstashlpid
		output wire         m_ace5lite_awstashlpiden, //           .awstashlpiden
		output wire [5:0]   m_ace5lite_awatop,        //           .awatop
		output wire         m_ace5lite_awvalid,       //           .awvalid
		input  wire         m_ace5lite_awready,       //           .awready
		output wire [255:0] m_ace5lite_wdata,         //           .wdata
		output wire [31:0]  m_ace5lite_wstrb,         //           .wstrb
		output wire         m_ace5lite_wlast,         //           .wlast
		output wire         m_ace5lite_wvalid,        //           .wvalid
		input  wire         m_ace5lite_wready,        //           .wready
		input  wire [4:0]   m_ace5lite_bid,           //           .bid
		input  wire [1:0]   m_ace5lite_bresp,         //           .bresp
		input  wire         m_ace5lite_bvalid,        //           .bvalid
		output wire         m_ace5lite_bready,        //           .bready
		output wire [4:0]   m_ace5lite_arid,          //           .arid
		output wire [31:0]  m_ace5lite_araddr,        //           .araddr
		output wire [1:0]   m_ace5lite_ardomain,      //           .ardomain
		output wire [3:0]   m_ace5lite_arsnoop,       //           .arsnoop
		output wire [7:0]   m_ace5lite_arlen,         //           .arlen
		output wire [1:0]   m_ace5lite_arburst,       //           .arburst
		output wire         m_ace5lite_arlock,        //           .arlock
		output wire [3:0]   m_ace5lite_arcache,       //           .arcache
		output wire [2:0]   m_ace5lite_arprot,        //           .arprot
		output wire [3:0]   m_ace5lite_arqos,         //           .arqos
		output wire         m_ace5lite_arvalid,       //           .arvalid
		input  wire         m_ace5lite_arready,       //           .arready
		input  wire [4:0]   m_ace5lite_rid,           //           .rid
		input  wire [255:0] m_ace5lite_rdata,         //           .rdata
		input  wire [1:0]   m_ace5lite_rresp,         //           .rresp
		input  wire         m_ace5lite_rlast,         //           .rlast
		input  wire         m_ace5lite_rvalid,        //           .rvalid
		output wire         m_ace5lite_rready,        //           .rready
		output wire [7:0]   m_ace5lite_aruser,        //           .aruser
		output wire [7:0]   m_ace5lite_awuser,        //           .awuser
		output wire [3:0]   m_ace5lite_arregion,      //           .arregion
		output wire [3:0]   m_ace5lite_awregion,      //           .awregion
		output wire [7:0]   m_ace5lite_wuser,         //           .wuser
		input  wire [7:0]   m_ace5lite_buser,         //           .buser
		input  wire [7:0]   m_ace5lite_ruser,         //           .ruser
		input  wire [4:0]   s_axi_awid,               //      s_axi.awid
		input  wire [31:0]  s_axi_awaddr,             //           .awaddr
		input  wire [7:0]   s_axi_awlen,              //           .awlen
		input  wire [2:0]   s_axi_awsize,             //           .awsize
		input  wire [1:0]   s_axi_awburst,            //           .awburst
		input  wire         s_axi_awlock,             //           .awlock
		input  wire [3:0]   s_axi_awcache,            //           .awcache
		input  wire [2:0]   s_axi_awprot,             //           .awprot
		input  wire [3:0]   s_axi_awqos,              //           .awqos
		input  wire         s_axi_awvalid,            //           .awvalid
		output wire         s_axi_awready,            //           .awready
		input  wire [3:0]   s_axi_awregion,           //           .awregion
		input  wire [255:0] s_axi_wdata,              //           .wdata
		input  wire [31:0]  s_axi_wstrb,              //           .wstrb
		input  wire         s_axi_wlast,              //           .wlast
		input  wire         s_axi_wvalid,             //           .wvalid
		output wire         s_axi_wready,             //           .wready
		input  wire [7:0]   s_axi_wuser,              //           .wuser
		output wire [4:0]   s_axi_bid,                //           .bid
		output wire [1:0]   s_axi_bresp,              //           .bresp
		output wire         s_axi_bvalid,             //           .bvalid
		input  wire         s_axi_bready,             //           .bready
		output wire [7:0]   s_axi_buser,              //           .buser
		input  wire [4:0]   s_axi_arid,               //           .arid
		input  wire [31:0]  s_axi_araddr,             //           .araddr
		input  wire [7:0]   s_axi_arlen,              //           .arlen
		input  wire [2:0]   s_axi_arsize,             //           .arsize
		input  wire [1:0]   s_axi_arburst,            //           .arburst
		input  wire         s_axi_arlock,             //           .arlock
		input  wire [3:0]   s_axi_arcache,            //           .arcache
		input  wire [2:0]   s_axi_arprot,             //           .arprot
		input  wire [3:0]   s_axi_arqos,              //           .arqos
		input  wire         s_axi_arvalid,            //           .arvalid
		output wire         s_axi_arready,            //           .arready
		input  wire [3:0]   s_axi_arregion,           //           .arregion
		output wire [4:0]   s_axi_rid,                //           .rid
		output wire [255:0] s_axi_rdata,              //           .rdata
		output wire [1:0]   s_axi_rresp,              //           .rresp
		output wire         s_axi_rlast,              //           .rlast
		output wire         s_axi_rvalid,             //           .rvalid
		input  wire         s_axi_rready,             //           .rready
		output wire [7:0]   s_axi_ruser               //           .ruser
	);
endmodule

