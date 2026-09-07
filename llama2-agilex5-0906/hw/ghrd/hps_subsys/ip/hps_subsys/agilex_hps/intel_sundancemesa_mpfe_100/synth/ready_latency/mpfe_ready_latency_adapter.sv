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


module hps_f2soc_ready_latency_adp_ace5lite # (

parameter LOG_DEPTH =3 ,
parameter NUM_PIPELINES =2,
parameter ID_WIDTH = 5,
parameter ADDR_WIDTH =44,
parameter DATA_WIDTH = 256,
parameter STRB_WIDTH = DATA_WIDTH/8,
parameter AUSER_WIDTH = 8

 ) (

input logic clk,
input logic reset,
 
  
// aw channel

 input  logic awready,
 output logic awvalid_r,
 output logic [ID_WIDTH-1:0] awid_r,
 output logic [ADDR_WIDTH-1:0] awaddr_r,
 output logic [7:0] awlen_r,
 output logic [2:0] awsize_r,
 output logic [1:0] awburst_r,
 output logic awlock_r,
 output logic [AUSER_WIDTH-1:0] awuser_r,
 output logic awmmusecsid_r,
 output logic [15:0] awmmusid_r,
 output logic [3:0] awqos_r,
 output logic [3:0] awcache_r,
 output logic [1:0] awdomain_r,
 output logic [2:0] awprot_r,
 output logic [3:0] awsnoop_r,
 output logic [3:0]  awregion_r,
 output logic [10:0] awstashnid_r,		     
 output logic awstashniden_r,	     
 output logic [4:0]  awstashlpid_r,	     
 output logic awstashlpiden_r,	     
 output logic [5:0]  awatop_r,		

 output logic  awready_r,
 input logic awvalid,
 input logic [ID_WIDTH-1:0] awid,
 input logic [ADDR_WIDTH-1:0] awaddr,
 input logic [7:0] awlen,
 input logic [2:0] awsize,
 input logic [1:0] awburst,
 input logic awlock,
 input logic [AUSER_WIDTH-1:0] awuser,
 input logic awmmusecsid,
 input logic [15:0] awmmusid,
 input logic [3:0] awqos,
 input logic [3:0] awcache,
 input logic [1:0] awdomain,
 input logic [2:0] awprot,
 input logic [3:0] awsnoop,
 input logic [3:0] awregion,
 input logic [10:0] awstashnid,		  	   		
 input logic awstashniden,		   	   		
 input logic [4:0]  awstashlpid,		    	   
 input logic awstashlpiden,		   		
 input logic [5:0]  awatop,		           

 // ar channel

 input  logic arready,
 output logic arvalid_r,
 output logic [ID_WIDTH-1:0] arid_r,
 output logic [ADDR_WIDTH-1:0] araddr_r,
 output logic [7:0] arlen_r,
 output logic [2:0] arsize_r,
 output logic [1:0] arburst_r,
 output logic arlock_r,
 output logic [AUSER_WIDTH-1:0] aruser_r,
 output logic armmusecsid_r,
 output logic [15:0] armmusid_r,
 output logic [3:0] arqos_r,
 output logic [3:0] arcache_r,
 output logic [1:0] ardomain_r,
 output logic [2:0] arprot_r,
 output logic [3:0] arsnoop_r,
 output logic [3:0] arregion_r,



 output logic arready_r,
 input logic arvalid,
 input logic [ID_WIDTH-1:0] arid,
 input logic [ADDR_WIDTH-1:0] araddr,
 input logic [7:0] arlen,
 input logic [2:0] arsize,
 input logic [1:0] arburst,
 input logic arlock,
 input logic [AUSER_WIDTH-1:0] aruser,
 input logic armmusecsid,
 input logic [15:0] armmusid,
 input logic [3:0] arqos,
 input logic [3:0] arcache,
 input logic [1:0] ardomain,
 input logic [2:0] arprot,
 input logic [3:0] arsnoop,
 input logic [3:0] arregion,

 //w channel

 input logic wready,
 
 output logic wvalid_r,
 output logic [DATA_WIDTH-1:0] wdata_r,
 output logic wlast_r,
 output logic [STRB_WIDTH-1:0] wstrb_r,
 output logic [7:0]wuser_r,


 output logic wready_r,
 
 input logic wvalid,
 input logic [DATA_WIDTH-1:0] wdata,
 input logic wlast,
 input logic [STRB_WIDTH-1:0] wstrb,
 input logic [7:0]wuser,




 // response channel

  input logic bvalid ,
  input logic [ID_WIDTH-1:0] bid,
  input logic [1:0] bresp,
  input logic [7:0] buser,

  output logic  bready_r,

  output logic  bvalid_r ,
  output logic  [ID_WIDTH-1:0] bid_r,
  output logic  [1:0] bresp_r,
  output logic  [7:0] buser_r,

  input logic bready ,


  input logic rvalid,
  input logic [ID_WIDTH-1:0] rid,
  input logic [DATA_WIDTH-1:0] rdata,
  input logic [1:0] rresp,
  input logic rlast,
  input logic [7:0] ruser,


  output logic rready_r,


  output logic rvalid_r,
  output logic [ID_WIDTH-1:0] rid_r,
  output logic [DATA_WIDTH-1:0] rdata_r,
  output logic [1:0] rresp_r,
  output logic rlast_r,
  output logic [7:0] ruser_r,

  input logic rready
      
  );

 // awlen(8),awprot(3),awsnoop(4),awsize(3) = 18
 // awlock(1),awqos(4),awcache(4),awdomain(2),awburst(2) = 13
 // awregion(4),awstashnid(11),awstashniden(1),awstashlpid(5),awstashlpiden(1),awatop(6) = 28
 // awmmusecsid(1),awmmusid(16) = 17
 // 18 + 13 + 28 + 17 = 76 -- does not include awready and awvalid
 localparam FIXED_WIDTH_AW =76;
 localparam DATA_WIDTH_AW = ID_WIDTH + ADDR_WIDTH + AUSER_WIDTH + FIXED_WIDTH_AW;
 // arlen(8),arsize(3),arburst(2),arlock(1),arqos(4) = 18
 // arcache(4),ardomain(2),arprot(3),arsnoop(4),arregion(4) = 17 
 // armmusecsid(1), armmusid(16) = 17
 // 18 + 17 + 17 = 52 -- does not include arready and arvalid
 localparam FIXED_WIDTH_AR = 52;
 localparam DATA_WIDTH_AR = ID_WIDTH + ADDR_WIDTH + AUSER_WIDTH + FIXED_WIDTH_AR;
 // 2+8: bresp(2) + buser(8) -- this does not include bready & bvalid
 localparam DATA_WIDTH_B = ID_WIDTH + 2 + 8;
 // 1+8: wlast + wuser(8) -- does not include wready & wvalid
 localparam DATA_WIDTH_W = DATA_WIDTH + STRB_WIDTH + 1 + 8;
 // 3+8: rlast,rresp(2) + ruser(8) -- does not include rready & rvalid
 localparam DATA_WIDTH_R = DATA_WIDTH + ID_WIDTH + 3 + 8;

 localparam FLOP_DEPTH = NUM_PIPELINES/2; // half flops on cmd, rest on rsp path

  logic bvalid_b, rvalid_b;
  logic [DATA_WIDTH_AW-1:0] indata_aw, tempdata_aw,outdata_aw;
  logic [DATA_WIDTH_AR-1:0] indata_ar, tempdata_ar,outdata_ar;
  logic [DATA_WIDTH_B -1 :0] indata_b,tempdata_b, bdata_f;

  logic [DATA_WIDTH_R -1 :0] indata_r,tempdata_r, rdata_f;


  logic [DATA_WIDTH_W -1 :0] indata_w, tempdata_w,outdata_w;


  generate if ( NUM_PIPELINES == 0 ) begin : no_pipeline

    assign {awready_r,awvalid_r,awid_r,awaddr_r,awlen_r,awsize_r,awburst_r,awlock_r,awuser_r,awmmusecsid_r,awmmusid_r,awqos_r,awcache_r,awdomain_r,awprot_r,awsnoop_r,awregion_r,awstashnid_r,awstashniden_r,awstashlpid_r,awstashlpiden_r,awatop_r } ={awready,awvalid,awid,awaddr,awlen,awsize,awburst,awlock,awuser,awmmusecsid,awmmusid,awqos,awcache,awdomain,awprot,awsnoop,awregion,awstashnid,awstashniden,awstashlpid,awstashlpiden,awatop }; 

    assign {arready_r,arvalid_r,arid_r,araddr_r,arlen_r,arsize_r,arburst_r,arlock_r,aruser_r,armmusecsid_r,armmusid_r,arqos_r,arcache_r,ardomain_r,arprot_r,arsnoop_r,arregion_r} ={arready,arvalid,arid,araddr,arlen,arsize,arburst,arlock,aruser,armmusecsid,armmusid,arqos,arcache,ardomain,arprot,arsnoop,arregion};

    assign {wready_r,wvalid_r,wdata_r,wstrb_r,wlast_r,wuser_r} = {wready,wvalid,wdata,wstrb,wlast,wuser};

    assign {bready_r,bvalid_r,bid_r,bresp_r,buser_r} = {bready,bvalid,bid,bresp,buser};
    
    assign {rready_r,rvalid_r,rid_r,rresp_r,rdata_r,rlast_r,ruser_r} = {rready,rvalid,rid,rresp,rdata,rlast,ruser}; 

  end
  else begin


 // aw channel 

  assign indata_aw = {awid,awaddr,awlen,awsize,awburst,awlock,awuser,awmmusecsid,awmmusid,awqos,awcache,awdomain,awprot,awsnoop,awregion,awstashnid,awstashniden,awstashlpid,awstashlpiden,awatop };
 
  ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (DATA_WIDTH_AW)

  ) aw_inst (

  .clk (clk),
  .in_data (indata_aw),
  .out_data (tempdata_aw)

  );
   
  ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (1)

  ) awvalid_inst (

  .clk (clk),
  .in_data (awvalid),
  .out_data (awvalid_b)
  );
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),
  .DATA_WIDTH (1)
  ) awready_inst (
  .clk (clk),
  .in_data (awready_f),
  .out_data (awready_r)

  );

  ready_latency_adapter # (
     .READY_LATENCY_OUT (NUM_PIPELINES),
     .PAYLOAD_WIDTH (DATA_WIDTH_AW),
     .LOG_DEPTH (LOG_DEPTH) 
    ) aw_inst_skid_buf (
     .clk (clk),
     .reset (reset),
     .in_ready (awready_f), // noc ready output 
     .in_valid (awvalid_b),
     .in_data (tempdata_aw),

     .out_ready (awready), // axi ready 0 latency
     .out_valid (awvalid_r),
     .out_data (outdata_aw)
 
    );



  assign {awid_r,awaddr_r,awlen_r,awsize_r,awburst_r,awlock_r,awuser_r,awmmusecsid_r,awmmusid_r,awqos_r,awcache_r,awdomain_r,awprot_r,awsnoop_r,awregion_r,awstashnid_r,awstashniden_r,awstashlpid_r,awstashlpiden_r,awatop_r } = outdata_aw;


 // ar channel 

 assign indata_ar = {arid,araddr,arlen,arsize,arburst,arlock,aruser,armmusecsid,armmusid,arqos,arcache,ardomain,arprot,arsnoop,arregion};
 
ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (DATA_WIDTH_AR)

  ) ar_inst_data (

  .clk (clk),
  .in_data (indata_ar),
  .out_data (tempdata_ar)

  );

   
  ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (1)

  ) arvalid_inst (

  .clk (clk),
  .in_data (arvalid),
  .out_data (arvalid_b)
  );
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),
  .DATA_WIDTH (1)
  ) arready_inst (
  .clk (clk),
  .in_data (arready_f),
  .out_data (arready_r)

  );

  ready_latency_adapter # (
     .READY_LATENCY_OUT (NUM_PIPELINES),
     .PAYLOAD_WIDTH (DATA_WIDTH_AR),
     .LOG_DEPTH (LOG_DEPTH) 
    ) ar_inst_skid_buf (
     .clk (clk),
     .reset (reset),
     .in_ready (arready_f), // noc ready output 
     .in_valid (arvalid_b),
     .in_data (tempdata_ar),

     .out_ready (arready), // axi ready 0 latency
     .out_valid (arvalid_r),
     .out_data (outdata_ar)
 
    );




  assign {arid_r,araddr_r,arlen_r,arsize_r,arburst_r,arlock_r,aruser_r,armmusecsid_r,armmusid_r,arqos_r,arcache_r,ardomain_r,arprot_r,arsnoop_r,arregion_r} = outdata_ar;
 

 // w channel 

 assign indata_w = {wdata,wlast,wstrb,wuser};
 
 ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (DATA_WIDTH_W)

  ) w_inst_data (

  .clk (clk),
  .in_data (indata_w),
  .out_data (tempdata_w)

  );

   
  ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (1)

  ) wvalid_inst (

  .clk (clk),
  .in_data (wvalid),
  .out_data (wvalid_b)

  );

  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),
  .DATA_WIDTH (1)
  ) wready_inst (
  .clk (clk),
  .in_data (wready_f),
  .out_data (wready_r)
  );

  ready_latency_adapter # (
     .READY_LATENCY_OUT (NUM_PIPELINES),
     .PAYLOAD_WIDTH (DATA_WIDTH_W),
     .LOG_DEPTH (LOG_DEPTH) 
    ) w_inst_skid_buf (
     .clk (clk),
     .reset (reset),
     .in_ready (wready_f), // noc ready output 
     .in_valid (wvalid_b),
     .in_data (tempdata_w),

     .out_ready (wready), // axi ready 0 latency
     .out_valid (wvalid_r),
     .out_data (outdata_w)
 
    );




  assign {wdata_r,wlast_r,wstrb_r,wuser_r} = outdata_w;
 


  // write response channel

  assign indata_b = {bid,bresp,buser};

  // data 
  
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (DATA_WIDTH_B)

  ) b_inst_data (

  .clk (clk),
  .in_data (indata_b),
  .out_data (tempdata_b)

  );

   
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),
  .DATA_WIDTH (1)
  ) bvalid_inst (
  .clk (clk),
  .in_data (bvalid),
  .out_data (bvalid_b)
  );
  ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (1)

  ) bready_inst (

  .clk (clk),
  .in_data (bready_f),
  .out_data (bready_r)

  );


  ready_latency_adapter # (
     .READY_LATENCY_OUT (NUM_PIPELINES),
     .PAYLOAD_WIDTH (DATA_WIDTH_B),
     .LOG_DEPTH (LOG_DEPTH) 
    ) bresp_inst (
     .clk (clk),
     .reset (reset),
     .in_ready (bready_f), // noc ready output 
     .in_valid (bvalid_b),
     .in_data (tempdata_b),

     .out_ready (bready), // axi ready 0 latency
     .out_valid (bvalid_f),
     .out_data (bdata_f)
 
    );


 assign bvalid_r = bvalid_f;
 assign {bid_r,bresp_r,buser_r} = bdata_f;



 // read response channel

  assign indata_r = {rid,rresp,rdata,rlast,ruser};

  // data 
  
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (DATA_WIDTH_R)

  ) r_inst_data (

  .clk (clk),
  .in_data (indata_r),
  .out_data (tempdata_r)

  );

   
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),
  .DATA_WIDTH (1)
  ) rvalid_inst (
  .clk (clk),
  .in_data (rvalid),
  .out_data (rvalid_b)
  );
  ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (1)

  ) rready_inst (

  .clk (clk),
  .in_data (rready_f),
  .out_data (rready_r)

  );


  ready_latency_adapter # (
     .READY_LATENCY_OUT (NUM_PIPELINES),
     .PAYLOAD_WIDTH (DATA_WIDTH_R),
     .LOG_DEPTH (LOG_DEPTH) 
    ) rresp_inst (
     .clk (clk),
     .reset (reset),
     .in_ready (rready_f), // noc ready output 
     .in_valid (rvalid_b),
     .in_data (tempdata_r),

     .out_ready (rready), // axi ready 0 latency
     .out_valid (rvalid_f),
     .out_data (rdata_f)
 
    );


 assign rvalid_r = rvalid_f;
 assign {rid_r,rresp_r,rdata_r,rlast_r,ruser_r} = rdata_f;

 end
 endgenerate



  



endmodule 



module hps_ready_latency_adp_axi4 # (

parameter LOG_DEPTH =3 ,
parameter NUM_PIPELINES =2,
parameter ID_WIDTH = 5,
parameter ADDR_WIDTH =44,
parameter DATA_WIDTH = 256,
parameter STRB_WIDTH = DATA_WIDTH/8,
parameter AUSER_WIDTH = 8

 ) (

input logic clk,
input logic reset,
 
  
// aw channel

 input  logic awready,
 output logic awvalid_r,
 output logic [ID_WIDTH-1:0] awid_r,
 output logic [ADDR_WIDTH-1:0] awaddr_r,
 output logic [7:0] awlen_r,
 output logic [2:0] awsize_r,
 output logic [1:0] awburst_r,
 output logic awlock_r,
 output logic [AUSER_WIDTH-1:0] awuser_r,
 output logic [3:0] awqos_r,
 output logic [3:0] awcache_r,
 output logic [2:0] awprot_r,
 output logic [3:0] awregion_r,

 output logic  awready_r,
 input logic awvalid,
 input logic [ID_WIDTH-1:0] awid,
 input logic [ADDR_WIDTH-1:0] awaddr,
 input logic [7:0] awlen,
 input logic [2:0] awsize,
 input logic [1:0] awburst,
 input logic awlock,
 input logic [AUSER_WIDTH-1:0] awuser,
 input logic [3:0] awqos,
 input logic [3:0] awcache,
 input logic [2:0] awprot,
 input logic [3:0] awregion,

 // ar channel

 input  logic arready,
 output logic arvalid_r,
 output logic [ID_WIDTH-1:0] arid_r,
 output logic [ADDR_WIDTH-1:0] araddr_r,
 output logic [7:0] arlen_r,
 output logic [2:0] arsize_r,
 output logic [1:0] arburst_r,
 output logic arlock_r,
 output logic [AUSER_WIDTH-1:0] aruser_r,
 output logic [3:0] arqos_r,
 output logic [3:0] arcache_r,
 output logic [2:0] arprot_r,
 output logic [3:0] arregion_r,



 output logic arready_r,
 input logic arvalid,
 input logic [ID_WIDTH-1:0] arid,
 input logic [ADDR_WIDTH-1:0] araddr,
 input logic [7:0] arlen,
 input logic [2:0] arsize,
 input logic [1:0] arburst,
 input logic arlock,
 input logic [AUSER_WIDTH-1:0] aruser,
 input logic [3:0] arqos,
 input logic [3:0] arcache,
 input logic [2:0] arprot,
 input logic [3:0] arregion,

 //w channel

 input logic wready,
 
 output logic wvalid_r,
 output logic [DATA_WIDTH-1:0] wdata_r,
 output logic wlast_r,
 output logic [STRB_WIDTH-1:0] wstrb_r,
 output logic [7:0]wuser_r,


 output logic wready_r,
 
 input logic wvalid,
 input logic [DATA_WIDTH-1:0] wdata,
 input logic wlast,
 input logic [STRB_WIDTH-1:0] wstrb,
 input logic [7:0]wuser,




 // response channel

  input logic bvalid ,
  input logic [ID_WIDTH-1:0] bid,
  input logic [1:0] bresp,
  input logic [7:0] buser,

  output logic  bready_r,

  output logic  bvalid_r ,
  output logic  [ID_WIDTH-1:0] bid_r,
  output logic  [1:0] bresp_r,
  output logic  [7:0] buser_r,

  input logic bready ,


  input logic rvalid,
  input logic [ID_WIDTH-1:0] rid,
  input logic [DATA_WIDTH-1:0] rdata,
  input logic [1:0] rresp,
  input logic rlast,
  input logic [7:0] ruser,


  output logic rready_r,


  output logic rvalid_r,
  output logic [ID_WIDTH-1:0] rid_r,
  output logic [DATA_WIDTH-1:0] rdata_r,
  output logic [1:0] rresp_r,
  output logic rlast_r,
  output logic [7:0] ruser_r,

  input logic rready

  
  //additional ports to support ace-lite interface

      
  );

 // awvalid(1),awlen(8),awsize(3),awburst(2),awlock(1),awqos(4),awcache(4),awprot(3),awregion(4) -- excludes awready 
 localparam FIXED_WIDTH_AW =30;
 localparam DATA_WIDTH_AW = ID_WIDTH + ADDR_WIDTH + AUSER_WIDTH + FIXED_WIDTH_AW;
 // arvalid,arlen(8),arsize(3),arburst(2),arlock(1),arqos(4),arcache(4),arprot(3),arregion(4) -- excludes arready
 localparam FIXED_WIDTH_AR =30;
 localparam DATA_WIDTH_AR = ID_WIDTH + ADDR_WIDTH + AUSER_WIDTH + FIXED_WIDTH_AR;
 // 2+8: bresp(2) + buser(8) -- excludes bready & bvalid
 localparam DATA_WIDTH_B = ID_WIDTH + 2 + 8;
 // 2+8: wlast,wvalid,wuser(8) -- excludes wready
 localparam DATA_WIDTH_W = DATA_WIDTH + STRB_WIDTH + 2 + 8;
 // 3+8: rlast,rresp(2) + ruser(8) -- excludes rready & rvalid
 localparam DATA_WIDTH_R = DATA_WIDTH + ID_WIDTH + 3 + 8;

 localparam FLOP_DEPTH = NUM_PIPELINES/2; // half flops on cmd, rest on rsp path

  logic bvalid_b, rvalid_b;
  logic [DATA_WIDTH_AW-1:0] indata_aw, outdata_aw;
  logic [DATA_WIDTH_AR-1:0] indata_ar, outdata_ar;
  logic [DATA_WIDTH_B -1 :0] indata_b,tempdata_b, bdata_f;

  logic [DATA_WIDTH_R -1 :0] indata_r,tempdata_r, rdata_f;


  logic [DATA_WIDTH_W -1 :0] indata_w, outdata_w;


  generate if ( NUM_PIPELINES == 0 ) begin : no_pipeline

    assign {awready_r,awvalid_r,awid_r,awaddr_r,awlen_r,awsize_r,awburst_r,awlock_r,awuser_r,awqos_r,awcache_r,awprot_r,awregion_r} ={awready,awvalid,awid,awaddr,awlen,awsize,awburst,awlock,awuser,awqos,awcache,awprot,awregion}; 

    assign {arready_r,arvalid_r,arid_r,araddr_r,arlen_r,arsize_r,arburst_r,arlock_r,aruser_r,arqos_r,arcache_r,arprot_r,arregion_r} ={arready,arvalid,arid,araddr,arlen,arsize,arburst,arlock,aruser,arqos,arcache,arprot,arregion};

    assign {wready_r,wvalid_r,wdata_r,wstrb_r,wlast_r,wuser_r} = {wready,wvalid,wdata,wstrb,wlast,wuser};

    assign {bready_r,bvalid_r,bid_r,bresp_r,buser_r} = {bready,bvalid,bid,bresp,buser};
    
    assign {rready_r,rvalid_r,rid_r,rresp_r,rdata_r,rlast_r,ruser_r} = {rready,rvalid,rid,rresp,rdata,rlast,ruser}; 

  end
  else begin


 // aw channel 

  assign indata_aw = {awvalid,awid,awaddr,awlen,awsize,awburst,awlock,awuser,awqos,awcache,awprot,awregion};
 

  ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (DATA_WIDTH_AW)

  ) aw_inst (

  .clk (clk),
  .in_data (indata_aw),
  .out_data ( outdata_aw)

  );

  assign {awvalid_r,awid_r,awaddr_r,awlen_r,awsize_r,awburst_r,awlock_r,awuser_r,awqos_r,awcache_r,awprot_r,awregion_r} = outdata_aw;

  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (1)
  ) awready_inst (
  .clk (clk),
  .in_data (awready),
  .out_data (awready_r)
  );
 // ar channel 

 assign indata_ar = {arvalid,arid,araddr,arlen,arsize,arburst,arlock,aruser,arqos,arcache,arprot,arregion};
 

  ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (DATA_WIDTH_AR)

  ) ar_inst (

  .clk (clk),
  .in_data (indata_ar),
  .out_data ( outdata_ar)

  );

  assign {arvalid_r,arid_r,araddr_r,arlen_r,arsize_r,arburst_r,arlock_r,aruser_r,arqos_r,arcache_r,arprot_r,arregion_r} = outdata_ar;
 
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (1)
  ) arready_inst (
  .clk (clk),
  .in_data (arready),
  .out_data (arready_r)
  );
 // w channel 

 assign indata_w = {wvalid,wdata,wlast,wstrb,wuser};
 

  ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (DATA_WIDTH_W)

  ) w_inst (

  .clk (clk),
  .in_data (indata_w),
  .out_data ( outdata_w)

  );

  assign {wvalid_r,wdata_r,wlast_r,wstrb_r,wuser_r} = outdata_w;
 
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),
  .DATA_WIDTH (1)
  ) wready_inst (
  .clk (clk),
  .in_data (wready),
  .out_data (wready_r)
  );
 

  // write response channel

  assign indata_b = {bid,bresp,buser};

  // data 
  
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (DATA_WIDTH_B)

  ) b_inst_data (

  .clk (clk),
  .in_data (indata_b),
  .out_data (tempdata_b)

  );

   
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),
  .DATA_WIDTH (1)
  ) bvalid_inst (
  .clk (clk),
  .in_data (bvalid),
  .out_data (bvalid_b)
  );
  ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (1)

  ) bready_inst (

  .clk (clk),
  .in_data (bready_f),
  .out_data (bready_r)

  );


  ready_latency_adapter # (
     .READY_LATENCY_OUT (NUM_PIPELINES),
     .PAYLOAD_WIDTH (DATA_WIDTH_B),
     .LOG_DEPTH (LOG_DEPTH) 
    ) bresp_inst (
     .clk (clk),
     .reset (reset),
     .in_ready (bready_f), // noc ready output 
     .in_valid (bvalid_b),
     .in_data (tempdata_b),

     .out_ready (bready), // axi ready 0 latency
     .out_valid (bvalid_f),
     .out_data (bdata_f)
 
    );


 assign bvalid_r = bvalid_f;
 assign {bid_r,bresp_r,buser_r} = bdata_f;



 // read response channel

  assign indata_r = {rid,rresp,rdata,rlast,ruser};

  // data 
  
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (DATA_WIDTH_R)

  ) r_inst_data (

  .clk (clk),
  .in_data (indata_r),
  .out_data (tempdata_r)

  );

   
  ff_macro_p2c # (
  .NUM_FLOPS (FLOP_DEPTH),
  .DATA_WIDTH (1)
  ) rvalid_inst (
  .clk (clk),
  .in_data (rvalid),
  .out_data (rvalid_b)
  );
  ff_macro_c2p # (
  .NUM_FLOPS (FLOP_DEPTH),

  .DATA_WIDTH (1)

  ) rready_inst (

  .clk (clk),
  .in_data (rready_f),
  .out_data (rready_r)

  );


  ready_latency_adapter # (
     .READY_LATENCY_OUT (NUM_PIPELINES),
     .PAYLOAD_WIDTH (DATA_WIDTH_R),
     .LOG_DEPTH (LOG_DEPTH) 
    ) rresp_inst (
     .clk (clk),
     .reset (reset),
     .in_ready (rready_f), // noc ready output 
     .in_valid (rvalid_b),
     .in_data (tempdata_r),

     .out_ready (rready), // axi ready 0 latency
     .out_valid (rvalid_f),
     .out_data (rdata_f)
 
    );


 assign rvalid_r = rvalid_f;
 assign {rid_r,rresp_r,rdata_r,rlast_r,ruser_r} = rdata_f;

 end
 endgenerate



  



endmodule 



`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "vGGwV9/jjs6QnNBdvpbyE8DieIGVVENMsSoCIwKxtHzdYH+IzMxzuhJSfwjG6mrHB/ivPH4w577noKJF0xZrZhNKwzNCVJD3SXXj+N9WviHFcEMP9MZTPTDFT10J/ZKaS3Ief1cgzn1V+qynYlv/V7o8opAd9PtzcLtjSgKrfZTOjEmVIkpPtC+3RViQ4+khW+Z915hcic8JZUze9sUTsLwBCwU8S4KymDxnB7XfqtTeB9COSfp6Yn2itN5RthA0837c+sdPzwO2gL8VmkYcrMZg8fTHvqxJn4sXY1WMiP1d1SbZ/WK3to/oQY8ahZ8Oz5jPYGzT7HH8NCdF/totEw8WLZrA/zdeGxmipVyS1a+dVgM2HzNSmjLqEb5djRAuyhO4LWUAJlb5IE9m5sk61J/Ska9gtMBA0dEIwXJVBJ9WgejdVBp2ZEbPbTgaNH6BzXCcwtky7lEodj7E/lWTpyPorUG/cWkLKWIUfvdgdQOk9zDjEQdtFvTmesP3VwN0OJcW/IHDEam35yVCnxmDYlqbZESrIiX6RJ4xpRXz8g3z6mHPAMCie2ta5y/EF/2GdmPb5JGfLqAugDXHXB+SSo4DfQ6VyX1kihrxE7lgTioO3a5ZGAd4qSrH9YAouiEMx/lHXwGRc+n1AhgJPfbBkql1174Yd7KsHzIKYYzToz6bjfbq+jCZDv82owEPkPdhyKHxkS2DdmOHTKN4z74AoYpnrpXGryeZDXJQ40WK8/pvHeBgYNKq7Sq0BmCdyMuiA1ZkRAKHlhvqKT6Djn4GeNIgYzjbqyIqnmudD0DGcH/M2PoB9byVGGU5HRrQRwO76Th2pFQyUDQZ8WgRuzl6mzGIDHL07NDTBqZhqjjE6inDDVr6WV52ISRjJK1a303I/nrW4n69Kz2JqN0btECHMP6xlHdsrIH1R1oDP3dnJXe8d9clxAsAp+iOa4PtcSf4Wgi4TF4AWn6b7UCoIiV4xwf+wq9gPrah6rqxyLrFqZVsg/eD8RzrNjMobKnKgZed"
`endif