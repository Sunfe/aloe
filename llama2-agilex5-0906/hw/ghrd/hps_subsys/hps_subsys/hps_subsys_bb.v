module hps_subsys (
		output wire         h2f_reset_reset,                       //                 h2f_reset.reset
		input  wire         hps2fpga_clk_clk,                      //              hps2fpga_clk.clk
		input  wire         hps2fpga_rst_reset,                    //              hps2fpga_rst.reset
		output wire [3:0]   hps2fpga_awid,                         //                  hps2fpga.awid
		output wire [37:0]  hps2fpga_awaddr,                       //                          .awaddr
		output wire [7:0]   hps2fpga_awlen,                        //                          .awlen
		output wire [2:0]   hps2fpga_awsize,                       //                          .awsize
		output wire [1:0]   hps2fpga_awburst,                      //                          .awburst
		output wire         hps2fpga_awlock,                       //                          .awlock
		output wire [3:0]   hps2fpga_awcache,                      //                          .awcache
		output wire [2:0]   hps2fpga_awprot,                       //                          .awprot
		output wire         hps2fpga_awvalid,                      //                          .awvalid
		input  wire         hps2fpga_awready,                      //                          .awready
		output wire [127:0] hps2fpga_wdata,                        //                          .wdata
		output wire [15:0]  hps2fpga_wstrb,                        //                          .wstrb
		output wire         hps2fpga_wlast,                        //                          .wlast
		output wire         hps2fpga_wvalid,                       //                          .wvalid
		input  wire         hps2fpga_wready,                       //                          .wready
		input  wire [3:0]   hps2fpga_bid,                          //                          .bid
		input  wire [1:0]   hps2fpga_bresp,                        //                          .bresp
		input  wire         hps2fpga_bvalid,                       //                          .bvalid
		output wire         hps2fpga_bready,                       //                          .bready
		output wire [3:0]   hps2fpga_arid,                         //                          .arid
		output wire [37:0]  hps2fpga_araddr,                       //                          .araddr
		output wire [7:0]   hps2fpga_arlen,                        //                          .arlen
		output wire [2:0]   hps2fpga_arsize,                       //                          .arsize
		output wire [1:0]   hps2fpga_arburst,                      //                          .arburst
		output wire         hps2fpga_arlock,                       //                          .arlock
		output wire [3:0]   hps2fpga_arcache,                      //                          .arcache
		output wire [2:0]   hps2fpga_arprot,                       //                          .arprot
		output wire         hps2fpga_arvalid,                      //                          .arvalid
		input  wire         hps2fpga_arready,                      //                          .arready
		input  wire [3:0]   hps2fpga_rid,                          //                          .rid
		input  wire [127:0] hps2fpga_rdata,                        //                          .rdata
		input  wire [1:0]   hps2fpga_rresp,                        //                          .rresp
		input  wire         hps2fpga_rlast,                        //                          .rlast
		input  wire         hps2fpga_rvalid,                       //                          .rvalid
		output wire         hps2fpga_rready,                       //                          .rready
		input  wire         lwhps2fpga_clk_clk,                    //            lwhps2fpga_clk.clk
		input  wire         lwhps2fpga_rst_reset,                  //            lwhps2fpga_rst.reset
		output wire [3:0]   lwhps2fpga_awid,                       //                lwhps2fpga.awid
		output wire [28:0]  lwhps2fpga_awaddr,                     //                          .awaddr
		output wire [7:0]   lwhps2fpga_awlen,                      //                          .awlen
		output wire [2:0]   lwhps2fpga_awsize,                     //                          .awsize
		output wire [1:0]   lwhps2fpga_awburst,                    //                          .awburst
		output wire         lwhps2fpga_awlock,                     //                          .awlock
		output wire [3:0]   lwhps2fpga_awcache,                    //                          .awcache
		output wire [2:0]   lwhps2fpga_awprot,                     //                          .awprot
		output wire         lwhps2fpga_awvalid,                    //                          .awvalid
		input  wire         lwhps2fpga_awready,                    //                          .awready
		output wire [31:0]  lwhps2fpga_wdata,                      //                          .wdata
		output wire [3:0]   lwhps2fpga_wstrb,                      //                          .wstrb
		output wire         lwhps2fpga_wlast,                      //                          .wlast
		output wire         lwhps2fpga_wvalid,                     //                          .wvalid
		input  wire         lwhps2fpga_wready,                     //                          .wready
		input  wire [3:0]   lwhps2fpga_bid,                        //                          .bid
		input  wire [1:0]   lwhps2fpga_bresp,                      //                          .bresp
		input  wire         lwhps2fpga_bvalid,                     //                          .bvalid
		output wire         lwhps2fpga_bready,                     //                          .bready
		output wire [3:0]   lwhps2fpga_arid,                       //                          .arid
		output wire [28:0]  lwhps2fpga_araddr,                     //                          .araddr
		output wire [7:0]   lwhps2fpga_arlen,                      //                          .arlen
		output wire [2:0]   lwhps2fpga_arsize,                     //                          .arsize
		output wire [1:0]   lwhps2fpga_arburst,                    //                          .arburst
		output wire         lwhps2fpga_arlock,                     //                          .arlock
		output wire [3:0]   lwhps2fpga_arcache,                    //                          .arcache
		output wire [2:0]   lwhps2fpga_arprot,                     //                          .arprot
		output wire         lwhps2fpga_arvalid,                    //                          .arvalid
		input  wire         lwhps2fpga_arready,                    //                          .arready
		input  wire [3:0]   lwhps2fpga_rid,                        //                          .rid
		input  wire [31:0]  lwhps2fpga_rdata,                      //                          .rdata
		input  wire [1:0]   lwhps2fpga_rresp,                      //                          .rresp
		input  wire         lwhps2fpga_rlast,                      //                          .rlast
		input  wire         lwhps2fpga_rvalid,                     //                          .rvalid
		output wire         lwhps2fpga_rready,                     //                          .rready
		output wire         h2f_warm_reset_handshake_reset_req,    //  h2f_warm_reset_handshake.reset_req
		input  wire         h2f_warm_reset_handshake_reset_ack,    //                          .reset_ack
		input  wire         hps_io_hps_osc_clk,                    //                    hps_io.hps_osc_clk
		inout  wire         hps_io_sdmmc_data0,                    //                          .sdmmc_data0
		inout  wire         hps_io_sdmmc_data1,                    //                          .sdmmc_data1
		output wire         hps_io_sdmmc_cclk,                     //                          .sdmmc_cclk
		inout  wire         hps_io_sdmmc_data2,                    //                          .sdmmc_data2
		inout  wire         hps_io_sdmmc_data3,                    //                          .sdmmc_data3
		inout  wire         hps_io_sdmmc_cmd,                      //                          .sdmmc_cmd
		input  wire         hps_io_usb0_clk,                       //                          .usb0_clk
		output wire         hps_io_usb0_stp,                       //                          .usb0_stp
		input  wire         hps_io_usb0_dir,                       //                          .usb0_dir
		inout  wire         hps_io_usb0_data0,                     //                          .usb0_data0
		inout  wire         hps_io_usb0_data1,                     //                          .usb0_data1
		input  wire         hps_io_usb0_nxt,                       //                          .usb0_nxt
		inout  wire         hps_io_usb0_data2,                     //                          .usb0_data2
		inout  wire         hps_io_usb0_data3,                     //                          .usb0_data3
		inout  wire         hps_io_usb0_data4,                     //                          .usb0_data4
		inout  wire         hps_io_usb0_data5,                     //                          .usb0_data5
		inout  wire         hps_io_usb0_data6,                     //                          .usb0_data6
		inout  wire         hps_io_usb0_data7,                     //                          .usb0_data7
		output wire         hps_io_emac0_tx_clk,                   //                          .emac0_tx_clk
		output wire         hps_io_emac0_tx_ctl,                   //                          .emac0_tx_ctl
		input  wire         hps_io_emac0_rx_clk,                   //                          .emac0_rx_clk
		input  wire         hps_io_emac0_rx_ctl,                   //                          .emac0_rx_ctl
		output wire         hps_io_emac0_txd0,                     //                          .emac0_txd0
		output wire         hps_io_emac0_txd1,                     //                          .emac0_txd1
		input  wire         hps_io_emac0_rxd0,                     //                          .emac0_rxd0
		input  wire         hps_io_emac0_rxd1,                     //                          .emac0_rxd1
		output wire         hps_io_emac0_txd2,                     //                          .emac0_txd2
		output wire         hps_io_emac0_txd3,                     //                          .emac0_txd3
		input  wire         hps_io_emac0_rxd2,                     //                          .emac0_rxd2
		input  wire         hps_io_emac0_rxd3,                     //                          .emac0_rxd3
		inout  wire         hps_io_mdio0_mdio,                     //                          .mdio0_mdio
		output wire         hps_io_mdio0_mdc,                      //                          .mdio0_mdc
		output wire         hps_io_spim0_clk,                      //                          .spim0_clk
		output wire         hps_io_spim0_mosi,                     //                          .spim0_mosi
		output wire         hps_io_spim0_ss0_n,                    //                          .spim0_ss0_n
		output wire         hps_io_uart1_tx,                       //                          .uart1_tx
		input  wire         hps_io_uart1_rx,                       //                          .uart1_rx
		inout  wire         hps_io_i2c1_sda,                       //                          .i2c1_sda
		inout  wire         hps_io_i2c1_scl,                       //                          .i2c1_scl
		inout  wire         hps_io_gpio28,                         //                          .gpio28
		inout  wire         hps_io_gpio32,                         //                          .gpio32
		inout  wire         hps_io_gpio33,                         //                          .gpio33
		inout  wire         hps_io_gpio34,                         //                          .gpio34
		inout  wire         hps_io_gpio35,                         //                          .gpio35
		inout  wire         hps_io_gpio40,                         //                          .gpio40
		inout  wire         hps_io_gpio41,                         //                          .gpio41
		inout  wire         hps_io_gpio42,                         //                          .gpio42
		input  wire [31:0]  f2h_irq1_in_irq,                       //               f2h_irq1_in.irq
		input  wire [31:0]  f2h_irq0_in_irq,                       //               f2h_irq0_in.irq
		input  wire         f2sdram_clk_clk,                       //               f2sdram_clk.clk
		input  wire         f2sdram_rst_reset,                     //               f2sdram_rst.reset
		input  wire         fpga2hps_clk_clk,                      //              fpga2hps_clk.clk
		input  wire         fpga2hps_rst_reset,                    //              fpga2hps_rst.reset
		input  wire [4:0]   fpga2hps_awid,                         //                  fpga2hps.awid
		input  wire [31:0]  fpga2hps_awaddr,                       //                          .awaddr
		input  wire [1:0]   fpga2hps_awdomain,                     //                          .awdomain
		input  wire [3:0]   fpga2hps_awsnoop,                      //                          .awsnoop
		input  wire [7:0]   fpga2hps_awlen,                        //                          .awlen
		input  wire [2:0]   fpga2hps_awsize,                       //                          .awsize
		input  wire [2:0]   fpga2hps_arsize,                       //                          .arsize
		input  wire [1:0]   fpga2hps_awburst,                      //                          .awburst
		input  wire         fpga2hps_awlock,                       //                          .awlock
		input  wire [3:0]   fpga2hps_awcache,                      //                          .awcache
		input  wire [2:0]   fpga2hps_awprot,                       //                          .awprot
		input  wire [3:0]   fpga2hps_awqos,                        //                          .awqos
		input  wire         fpga2hps_awvalid,                      //                          .awvalid
		output wire         fpga2hps_awready,                      //                          .awready
		input  wire [255:0] fpga2hps_wdata,                        //                          .wdata
		input  wire [31:0]  fpga2hps_wstrb,                        //                          .wstrb
		input  wire         fpga2hps_wlast,                        //                          .wlast
		input  wire         fpga2hps_wvalid,                       //                          .wvalid
		output wire         fpga2hps_wready,                       //                          .wready
		input  wire [10:0]  fpga2hps_awstashnid,                   //                          .awstashnid
		input  wire         fpga2hps_awstashniden,                 //                          .awstashniden
		input  wire [4:0]   fpga2hps_awstashlpid,                  //                          .awstashlpid
		input  wire         fpga2hps_awstashlpiden,                //                          .awstashlpiden
		input  wire [5:0]   fpga2hps_awatop,                       //                          .awatop
		output wire [4:0]   fpga2hps_bid,                          //                          .bid
		output wire [1:0]   fpga2hps_bresp,                        //                          .bresp
		output wire         fpga2hps_bvalid,                       //                          .bvalid
		input  wire         fpga2hps_bready,                       //                          .bready
		input  wire [4:0]   fpga2hps_arid,                         //                          .arid
		input  wire [31:0]  fpga2hps_araddr,                       //                          .araddr
		input  wire [1:0]   fpga2hps_ardomain,                     //                          .ardomain
		input  wire [3:0]   fpga2hps_arsnoop,                      //                          .arsnoop
		input  wire [7:0]   fpga2hps_arlen,                        //                          .arlen
		input  wire [1:0]   fpga2hps_arburst,                      //                          .arburst
		input  wire         fpga2hps_arlock,                       //                          .arlock
		input  wire [3:0]   fpga2hps_arcache,                      //                          .arcache
		input  wire [2:0]   fpga2hps_arprot,                       //                          .arprot
		input  wire [3:0]   fpga2hps_arqos,                        //                          .arqos
		input  wire         fpga2hps_arvalid,                      //                          .arvalid
		output wire         fpga2hps_arready,                      //                          .arready
		output wire [4:0]   fpga2hps_rid,                          //                          .rid
		output wire [255:0] fpga2hps_rdata,                        //                          .rdata
		output wire [1:0]   fpga2hps_rresp,                        //                          .rresp
		output wire         fpga2hps_rlast,                        //                          .rlast
		output wire         fpga2hps_rvalid,                       //                          .rvalid
		input  wire         fpga2hps_rready,                       //                          .rready
		input  wire [7:0]   fpga2hps_aruser,                       //                          .aruser
		input  wire [7:0]   fpga2hps_awuser,                       //                          .awuser
		input  wire [3:0]   fpga2hps_arregion,                     //                          .arregion
		input  wire [3:0]   fpga2hps_awregion,                     //                          .awregion
		input  wire [7:0]   fpga2hps_wuser,                        //                          .wuser
		output wire [7:0]   fpga2hps_buser,                        //                          .buser
		output wire [7:0]   fpga2hps_ruser,                        //                          .ruser
		output wire [0:0]   emif_hps_emif_mem_0_mem_cke,           //       emif_hps_emif_mem_0.mem_cke
		output wire [0:0]   emif_hps_emif_mem_0_mem_odt,           //                          .mem_odt
		output wire [0:0]   emif_hps_emif_mem_0_mem_cs_n,          //                          .mem_cs_n
		output wire [16:0]  emif_hps_emif_mem_0_mem_a,             //                          .mem_a
		output wire [1:0]   emif_hps_emif_mem_0_mem_ba,            //                          .mem_ba
		output wire [0:0]   emif_hps_emif_mem_0_mem_bg,            //                          .mem_bg
		output wire         emif_hps_emif_mem_0_mem_act_n,         //                          .mem_act_n
		output wire         emif_hps_emif_mem_0_mem_par,           //                          .mem_par
		inout  wire [31:0]  emif_hps_emif_mem_0_mem_dq,            //                          .mem_dq
		inout  wire [3:0]   emif_hps_emif_mem_0_mem_dqs_t,         //                          .mem_dqs_t
		inout  wire [3:0]   emif_hps_emif_mem_0_mem_dqs_c,         //                          .mem_dqs_c
		input  wire         emif_hps_emif_mem_0_mem_alert_n,       //                          .mem_alert_n
		inout  wire [3:0]   emif_hps_emif_mem_0_mem_dbi_n,         //                          .mem_dbi_n
		output wire [0:0]   emif_hps_emif_mem_ck_0_mem_ck_t,       //    emif_hps_emif_mem_ck_0.mem_ck_t
		output wire [0:0]   emif_hps_emif_mem_ck_0_mem_ck_c,       //                          .mem_ck_c
		output wire         emif_hps_emif_mem_reset_n_mem_reset_n, // emif_hps_emif_mem_reset_n.mem_reset_n
		input  wire         emif_hps_emif_oct_0_oct_rzqin,         //       emif_hps_emif_oct_0.oct_rzqin
		input  wire         emif_hps_emif_ref_clk_clk,             //     emif_hps_emif_ref_clk.clk
		input  wire         f2sdram_adapter_clk_clk,               //       f2sdram_adapter_clk.clk
		input  wire         f2sdram_adapter_rst_reset,             //       f2sdram_adapter_rst.reset
		input  wire [31:0]  f2sdram_adapter_axi4_sub_araddr,       //  f2sdram_adapter_axi4_sub.araddr
		input  wire [1:0]   f2sdram_adapter_axi4_sub_arburst,      //                          .arburst
		input  wire [3:0]   f2sdram_adapter_axi4_sub_arcache,      //                          .arcache
		input  wire [4:0]   f2sdram_adapter_axi4_sub_arid,         //                          .arid
		input  wire [7:0]   f2sdram_adapter_axi4_sub_arlen,        //                          .arlen
		input  wire         f2sdram_adapter_axi4_sub_arlock,       //                          .arlock
		input  wire [2:0]   f2sdram_adapter_axi4_sub_arprot,       //                          .arprot
		input  wire [3:0]   f2sdram_adapter_axi4_sub_arqos,        //                          .arqos
		output wire         f2sdram_adapter_axi4_sub_arready,      //                          .arready
		input  wire [2:0]   f2sdram_adapter_axi4_sub_arsize,       //                          .arsize
		input  wire         f2sdram_adapter_axi4_sub_arvalid,      //                          .arvalid
		input  wire [31:0]  f2sdram_adapter_axi4_sub_awaddr,       //                          .awaddr
		input  wire [1:0]   f2sdram_adapter_axi4_sub_awburst,      //                          .awburst
		input  wire [3:0]   f2sdram_adapter_axi4_sub_awcache,      //                          .awcache
		input  wire [4:0]   f2sdram_adapter_axi4_sub_awid,         //                          .awid
		input  wire [7:0]   f2sdram_adapter_axi4_sub_awlen,        //                          .awlen
		input  wire         f2sdram_adapter_axi4_sub_awlock,       //                          .awlock
		input  wire [2:0]   f2sdram_adapter_axi4_sub_awprot,       //                          .awprot
		input  wire [3:0]   f2sdram_adapter_axi4_sub_awqos,        //                          .awqos
		output wire         f2sdram_adapter_axi4_sub_awready,      //                          .awready
		input  wire [2:0]   f2sdram_adapter_axi4_sub_awsize,       //                          .awsize
		input  wire         f2sdram_adapter_axi4_sub_awvalid,      //                          .awvalid
		output wire [4:0]   f2sdram_adapter_axi4_sub_bid,          //                          .bid
		input  wire         f2sdram_adapter_axi4_sub_bready,       //                          .bready
		output wire [1:0]   f2sdram_adapter_axi4_sub_bresp,        //                          .bresp
		output wire         f2sdram_adapter_axi4_sub_bvalid,       //                          .bvalid
		output wire [255:0] f2sdram_adapter_axi4_sub_rdata,        //                          .rdata
		output wire [4:0]   f2sdram_adapter_axi4_sub_rid,          //                          .rid
		output wire         f2sdram_adapter_axi4_sub_rlast,        //                          .rlast
		input  wire         f2sdram_adapter_axi4_sub_rready,       //                          .rready
		output wire [1:0]   f2sdram_adapter_axi4_sub_rresp,        //                          .rresp
		output wire         f2sdram_adapter_axi4_sub_rvalid,       //                          .rvalid
		input  wire [255:0] f2sdram_adapter_axi4_sub_wdata,        //                          .wdata
		input  wire         f2sdram_adapter_axi4_sub_wlast,        //                          .wlast
		output wire         f2sdram_adapter_axi4_sub_wready,       //                          .wready
		input  wire [31:0]  f2sdram_adapter_axi4_sub_wstrb,        //                          .wstrb
		input  wire         f2sdram_adapter_axi4_sub_wvalid,       //                          .wvalid
		input  wire [7:0]   f2sdram_adapter_axi4_sub_aruser,       //                          .aruser
		input  wire [7:0]   f2sdram_adapter_axi4_sub_awuser,       //                          .awuser
		input  wire [7:0]   f2sdram_adapter_axi4_sub_wuser,        //                          .wuser
		output wire [7:0]   f2sdram_adapter_axi4_sub_buser,        //                          .buser
		input  wire [3:0]   f2sdram_adapter_axi4_sub_arregion,     //                          .arregion
		output wire [7:0]   f2sdram_adapter_axi4_sub_ruser,        //                          .ruser
		input  wire [3:0]   f2sdram_adapter_axi4_sub_awregion      //                          .awregion
	);
endmodule

