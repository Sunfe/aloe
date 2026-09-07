module agilex_hps (
		output wire         h2f_reset_reset,                    //                h2f_reset.reset,            Active high reset from the HPS Reset Manager.
		input  wire         hps2fpga_axi_clock_clk,             //       hps2fpga_axi_clock.clk,              Clock from a single source in the FPGA.
		input  wire         hps2fpga_axi_reset_reset,           //       hps2fpga_axi_reset.reset,            Async reset to the Bridge logic. This signal is active-HIGH.
		output wire [3:0]   hps2fpga_awid,                      //                 hps2fpga.awid,             Identification tag for a write transaction.
		output wire [37:0]  hps2fpga_awaddr,                    //                         .awaddr,           The address of the first transfer in a write transaction.
		output wire [7:0]   hps2fpga_awlen,                     //                         .awlen,            The exact number of data transfers in a write transaction.
		output wire [2:0]   hps2fpga_awsize,                    //                         .awsize,           The number of bytes in each data transfer in a write transaction.
		output wire [1:0]   hps2fpga_awburst,                   //                         .awburst,          Indicates how address changes between each transfer in a write transaction.
		output wire         hps2fpga_awlock,                    //                         .awlock,           Provides information about the atomic characteristics of a write transaction.
		output wire [3:0]   hps2fpga_awcache,                   //                         .awcache,          Indicates how a write transaction is required to progress through a system.
		output wire [2:0]   hps2fpga_awprot,                    //                         .awprot,           Protection attributes of a write transaction: privilege, security level, and access type.
		output wire         hps2fpga_awvalid,                   //                         .awvalid,          Indicates that the write address channel signals are valid.
		input  wire         hps2fpga_awready,                   //                         .awready,          Indicates that a transfer on the write address channel can be accepted.
		output wire [127:0] hps2fpga_wdata,                     //                         .wdata,            Write data.
		output wire [15:0]  hps2fpga_wstrb,                     //                         .wstrb,            Write strobes, indicate which byte lanes hold valid data.
		output wire         hps2fpga_wlast,                     //                         .wlast,            User-defined extension for the write data channel.
		output wire         hps2fpga_wvalid,                    //                         .wvalid,           Indicates that the write data channel signals are valid.
		input  wire         hps2fpga_wready,                    //                         .wready,           Indicates that a transfer on the write data channel can be accepted.
		input  wire [3:0]   hps2fpga_bid,                       //                         .bid,              Transaction identifier for the write response.
		input  wire [1:0]   hps2fpga_bresp,                     //                         .bresp,            Write response, indicates the status of a write transaction.
		input  wire         hps2fpga_bvalid,                    //                         .bvalid,           Indicates that the write response channel signals are valid.
		output wire         hps2fpga_bready,                    //                         .bready,           Indicates that a transfer on the write response channel can be accepted.
		output wire [3:0]   hps2fpga_arid,                      //                         .arid,             Transaction identifier for the read transaction.
		output wire [37:0]  hps2fpga_araddr,                    //                         .araddr,           The address of the first transfer in a read transaction.
		output wire [7:0]   hps2fpga_arlen,                     //                         .arlen,            The exact number of data transfers in a read transaction.
		output wire [2:0]   hps2fpga_arsize,                    //                         .arsize,           The number of bytes in each data transfer in a read transaction.
		output wire [1:0]   hps2fpga_arburst,                   //                         .arburst,          Indicates how address changes between each transfer in a read transaction.
		output wire         hps2fpga_arlock,                    //                         .arlock,           Provides information about the atomic characteristics of a read transaction.
		output wire [3:0]   hps2fpga_arcache,                   //                         .arcache,          Indicates how a read transaction is required to progress through a system.
		output wire [2:0]   hps2fpga_arprot,                    //                         .arprot,           Protection attributes of a read transaction: privilege, security level, and access type.
		output wire         hps2fpga_arvalid,                   //                         .arvalid,          Indicates that the read address channel signals are valid.
		input  wire         hps2fpga_arready,                   //                         .arready,          Indicates that a transfer on the read address channel can be accepted.
		input  wire [3:0]   hps2fpga_rid,                       //                         .rid,              Identification tag for read data and response.
		input  wire [127:0] hps2fpga_rdata,                     //                         .rdata,            Read data.
		input  wire [1:0]   hps2fpga_rresp,                     //                         .rresp,            Read response, indicates the status of a read transfer.
		input  wire         hps2fpga_rlast,                     //                         .rlast,            Indicates whether this is the last data transfer in a read transaction.
		input  wire         hps2fpga_rvalid,                    //                         .rvalid,           Indicates that the read data channel signals are valid.
		output wire         hps2fpga_rready,                    //                         .rready,           Indicates that a transfer on the read data channel can be accepted.
		input  wire         lwhps2fpga_axi_clock_clk,           //     lwhps2fpga_axi_clock.clk,              clock from a single source in the FPGA.
		input  wire         lwhps2fpga_axi_reset_reset,         //     lwhps2fpga_axi_reset.reset,            Async reset to the Bridge logic. This signal is active-HIGH.
		output wire [3:0]   lwhps2fpga_awid,                    //               lwhps2fpga.awid,             Identification tag for a write transaction.
		output wire [28:0]  lwhps2fpga_awaddr,                  //                         .awaddr,           The address of the first transfer in a write transaction.
		output wire [7:0]   lwhps2fpga_awlen,                   //                         .awlen,            The exact number of data transfers in a write transaction.
		output wire [2:0]   lwhps2fpga_awsize,                  //                         .awsize,           The number of bytes in each data transfer in a write transaction.
		output wire [1:0]   lwhps2fpga_awburst,                 //                         .awburst,          Indicates how address changes between each transfer in a write transaction.
		output wire         lwhps2fpga_awlock,                  //                         .awlock,           Provides information about the atomic characteristics of a write transaction.
		output wire [3:0]   lwhps2fpga_awcache,                 //                         .awcache,          Indicates how a write transaction is required to progress through a system.
		output wire [2:0]   lwhps2fpga_awprot,                  //                         .awprot,           Protection attributes of a write transaction: privilege, security level, and access type.
		output wire         lwhps2fpga_awvalid,                 //                         .awvalid,          Indicates that the write address channel signals are valid.
		input  wire         lwhps2fpga_awready,                 //                         .awready,          Indicates that a transfer on the write address channel can be accepted.
		output wire [31:0]  lwhps2fpga_wdata,                   //                         .wdata,            Write data.
		output wire [3:0]   lwhps2fpga_wstrb,                   //                         .wstrb,            Write strobes, indicate which byte lanes hold valid data.
		output wire         lwhps2fpga_wlast,                   //                         .wlast,            User-defined extension for the write data channel.
		output wire         lwhps2fpga_wvalid,                  //                         .wvalid,           Indicates that the write data channel signals are valid.
		input  wire         lwhps2fpga_wready,                  //                         .wready,           Indicates that a transfer on the write data channel can be accepted.
		input  wire [3:0]   lwhps2fpga_bid,                     //                         .bid,              Transaction identifier for the write response.
		input  wire [1:0]   lwhps2fpga_bresp,                   //                         .bresp,            Write response, indicates the status of a write transaction.
		input  wire         lwhps2fpga_bvalid,                  //                         .bvalid,           Indicates that the write response channel signals are valid.
		output wire         lwhps2fpga_bready,                  //                         .bready,           Indicates that a transfer on the write response channel can be accepted.
		output wire [3:0]   lwhps2fpga_arid,                    //                         .arid,             Transaction identifier for the read transaction.
		output wire [28:0]  lwhps2fpga_araddr,                  //                         .araddr,           The address of the first transfer in a read transaction.
		output wire [7:0]   lwhps2fpga_arlen,                   //                         .arlen,            The exact number of data transfers in a read transaction.
		output wire [2:0]   lwhps2fpga_arsize,                  //                         .arsize,           The number of bytes in each data transfer in a read transaction.
		output wire [1:0]   lwhps2fpga_arburst,                 //                         .arburst,          Indicates how address changes between each transfer in a read transaction.
		output wire         lwhps2fpga_arlock,                  //                         .arlock,           Provides information about the atomic characteristics of a read transaction.
		output wire [3:0]   lwhps2fpga_arcache,                 //                         .arcache,          Indicates how a read transaction is required to progress through a system.
		output wire [2:0]   lwhps2fpga_arprot,                  //                         .arprot,           Protection attributes of a read transaction: privilege, security level, and access type.
		output wire         lwhps2fpga_arvalid,                 //                         .arvalid,          Indicates that the read address channel signals are valid.
		input  wire         lwhps2fpga_arready,                 //                         .arready,          Indicates that a transfer on the read address channel can be accepted.
		input  wire [3:0]   lwhps2fpga_rid,                     //                         .rid,              Identification tag for read data and response.
		input  wire [31:0]  lwhps2fpga_rdata,                   //                         .rdata,            Read data.
		input  wire [1:0]   lwhps2fpga_rresp,                   //                         .rresp,            Read response, indicates the status of a read transfer.
		input  wire         lwhps2fpga_rlast,                   //                         .rlast,            Indicates whether this is the last data transfer in a read transaction.
		input  wire         lwhps2fpga_rvalid,                  //                         .rvalid,           Indicates that the read data channel signals are valid.
		output wire         lwhps2fpga_rready,                  //                         .rready,           Indicates that a transfer on the read data channel can be accepted.
		output wire         emac0_app_rst_reset_n,              //            emac0_app_rst.reset_n,          EMAC0 application clock reset output.
		output wire         h2f_warm_reset_handshake_reset_req, // h2f_warm_reset_handshake.reset_req,        HPS warm reset request. Identical to watchdog reset except this is asserted by SDM.
		input  wire         h2f_warm_reset_handshake_reset_ack, //                         .reset_ack,        HPS warm reset acknowledge response to SDM. Should be asserted when all HPS soft logic is successfully in reset.
		input  wire         hps_io_hps_osc_clk,                 //                   hps_io.hps_osc_clk,      HPS input clock pin for EOSC reference clock.
		inout  wire         hps_io_sdmmc_data0,                 //                         .sdmmc_data0,      SDMMC data[0].
		inout  wire         hps_io_sdmmc_data1,                 //                         .sdmmc_data1,      SDMMC data[1].
		output wire         hps_io_sdmmc_cclk,                  //                         .sdmmc_cclk,       SDMMC output clock.
		inout  wire         hps_io_sdmmc_data2,                 //                         .sdmmc_data2,      SDMMC data[2].
		inout  wire         hps_io_sdmmc_data3,                 //                         .sdmmc_data3,      SDMMC data[3].
		inout  wire         hps_io_sdmmc_cmd,                   //                         .sdmmc_cmd,        SDMMC command.
		input  wire         hps_io_usb0_clk,                    //                         .usb0_clk,         ULPI PHY clock input.
		output wire         hps_io_usb0_stp,                    //                         .usb0_stp,         ULPI stop output control.
		input  wire         hps_io_usb0_dir,                    //                         .usb0_dir,         Data bus control.
		inout  wire         hps_io_usb0_data0,                  //                         .usb0_data0,       USB data[0].
		inout  wire         hps_io_usb0_data1,                  //                         .usb0_data1,       USB data[1].
		input  wire         hps_io_usb0_nxt,                    //                         .usb0_nxt,         ULPI next data control.
		inout  wire         hps_io_usb0_data2,                  //                         .usb0_data2,       USB data[2].
		inout  wire         hps_io_usb0_data3,                  //                         .usb0_data3,       USB data[3].
		inout  wire         hps_io_usb0_data4,                  //                         .usb0_data4,       USB data[4].
		inout  wire         hps_io_usb0_data5,                  //                         .usb0_data5,       USB data[5].
		inout  wire         hps_io_usb0_data6,                  //                         .usb0_data6,       USB data[6].
		inout  wire         hps_io_usb0_data7,                  //                         .usb0_data7,       USB data[7].
		output wire         hps_io_emac0_tx_clk,                //                         .emac0_tx_clk,     EMAC0 transmit clock.
		output wire         hps_io_emac0_tx_ctl,                //                         .emac0_tx_ctl,     EMAC0 transmit data enable.
		input  wire         hps_io_emac0_rx_clk,                //                         .emac0_rx_clk,     EMAC0 receive clock.
		input  wire         hps_io_emac0_rx_ctl,                //                         .emac0_rx_ctl,     EMAC0 receive data enable.
		output wire         hps_io_emac0_txd0,                  //                         .emac0_txd0,       EMAC0 transmit data[0].
		output wire         hps_io_emac0_txd1,                  //                         .emac0_txd1,       EMAC0 transmit data[1].
		input  wire         hps_io_emac0_rxd0,                  //                         .emac0_rxd0,       EMAC0 receive data[0].
		input  wire         hps_io_emac0_rxd1,                  //                         .emac0_rxd1,       EMAC0 receive data[1].
		output wire         hps_io_emac0_txd2,                  //                         .emac0_txd2,       EMAC0 transmit data[2].
		output wire         hps_io_emac0_txd3,                  //                         .emac0_txd3,       EMAC0 transmit data[3].
		input  wire         hps_io_emac0_rxd2,                  //                         .emac0_rxd2,       EMAC0 receive data[2].
		input  wire         hps_io_emac0_rxd3,                  //                         .emac0_rxd3,       EMAC0 receive data[3].
		inout  wire         hps_io_mdio0_mdio,                  //                         .mdio0_mdio,       EMAC0 MDIO data.
		output wire         hps_io_mdio0_mdc,                   //                         .mdio0_mdc,        EMAC0 MDIO clock.
		output wire         hps_io_spim0_clk,                   //                         .spim0_clk,        SPIM0 serial clock.
		output wire         hps_io_spim0_mosi,                  //                         .spim0_mosi,       SPIM0 master out, slave in.
		output wire         hps_io_spim0_ss0_n,                 //                         .spim0_ss0_n,      SPIM0 slave select 0. Necessary for basic functionality.
		output wire         hps_io_uart1_tx,                    //                         .uart1_tx,         UART1 transmit data.
		input  wire         hps_io_uart1_rx,                    //                         .uart1_rx,         UART1 receive data.
		inout  wire         hps_io_i2c1_sda,                    //                         .i2c1_sda,         I2C1 serial data.
		inout  wire         hps_io_i2c1_scl,                    //                         .i2c1_scl,         I2C1 clock.
		inout  wire         hps_io_gpio28,                      //                         .gpio28,           GPIO1 IO4
		inout  wire         hps_io_gpio32,                      //                         .gpio32,           GPIO1 IO8
		inout  wire         hps_io_gpio33,                      //                         .gpio33,           GPIO1 IO9
		inout  wire         hps_io_gpio34,                      //                         .gpio34,           GPIO1 IO10
		inout  wire         hps_io_gpio35,                      //                         .gpio35,           GPIO1 IO11
		inout  wire         hps_io_gpio40,                      //                         .gpio40,           GPIO1 IO16
		inout  wire         hps_io_gpio41,                      //                         .gpio41,           GPIO1 IO17
		inout  wire         hps_io_gpio42,                      //                         .gpio42,           GPIO1 IO18
		input  wire [31:0]  fpga2hps_interrupt_irq1_irq,        //  fpga2hps_interrupt_irq1.irq,              FPGA-to-HPS interrupts (higher 32 bits).
		input  wire [31:0]  fpga2hps_interrupt_irq0_irq,        //  fpga2hps_interrupt_irq0.irq,              FPGA-to-HPS interrupts (lower 32 bits).
		input  wire         f2sdram_axi_clock_clk,              //        f2sdram_axi_clock.clk,              Clock source signal. Synchronous signals are sampled on the rising edge of this clock.
		input  wire         f2sdram_axi_reset_reset,            //        f2sdram_axi_reset.reset,            Active high reset for f2sdram soft logic on FPGA. The actual bridge reset is driven by internal HPS Reset Manager.
		input  wire [31:0]  f2sdram_araddr,                     //                  f2sdram.araddr,           Address of the first transfer in a read transaction.
		input  wire [1:0]   f2sdram_arburst,                    //                         .arburst,          Burst type indicating how address changes between each transfer in a read transaction.
		input  wire [3:0]   f2sdram_arcache,                    //                         .arcache,          Indicates how a read transaction is required to progress through a system.
		input  wire [4:0]   f2sdram_arid,                       //                         .arid,             Identification tag for a read transaction.
		input  wire [7:0]   f2sdram_arlen,                      //                         .arlen,            The exact number of data transfers in a read transaction.
		input  wire         f2sdram_arlock,                     //                         .arlock,           Provides info on atomic characteristics of a read transaction.
		input  wire [2:0]   f2sdram_arprot,                     //                         .arprot,           Protection attributes of a read transaction: privelege, security level, access type.
		input  wire [3:0]   f2sdram_arqos,                      //                         .arqos,            Quality service identifier for a read transaction.
		output wire         f2sdram_arready,                    //                         .arready,          Indicates that a transfer on the read address channel can be accepted.
		input  wire [2:0]   f2sdram_arsize,                     //                         .arsize,           The number of bytes in each data transfer of a read transaction.
		input  wire         f2sdram_arvalid,                    //                         .arvalid,          Indicates the read address channel signals are valid.
		input  wire [31:0]  f2sdram_awaddr,                     //                         .awaddr,           The address of the first transfer in a write transaction.
		input  wire [1:0]   f2sdram_awburst,                    //                         .awburst,          Burst type indicating how address changes between each transfer in a write transaction.
		input  wire [3:0]   f2sdram_awcache,                    //                         .awcache,          Indicates how a write transaction is required to progress through a system.
		input  wire [4:0]   f2sdram_awid,                       //                         .awid,             Identification tag for a write transaction.
		input  wire [7:0]   f2sdram_awlen,                      //                         .awlen,            The exact number of data transfers in a write transaction.
		input  wire         f2sdram_awlock,                     //                         .awlock,           Provides info on atomic characteristics of a write transaction.
		input  wire [2:0]   f2sdram_awprot,                     //                         .awprot,           Protection attributes of a write transaction: privelege, security level, access type.
		input  wire [3:0]   f2sdram_awqos,                      //                         .awqos,            Quality of servide identifier for a write transaction.
		output wire         f2sdram_awready,                    //                         .awready,          Indicates that a transfer on the write channel address can be accepted.
		input  wire [2:0]   f2sdram_awsize,                     //                         .awsize,           The number of bytes in each data transfer of a write transaction.
		input  wire         f2sdram_awvalid,                    //                         .awvalid,          Indicates the write address channel signals are valid.
		output wire [4:0]   f2sdram_bid,                        //                         .bid,              Identification tag for a write response.
		input  wire         f2sdram_bready,                     //                         .bready,           Indicates that a transfer on the write response channel can be accepted.
		output wire [1:0]   f2sdram_bresp,                      //                         .bresp,            Write response indicating the status of a write transaction.
		output wire         f2sdram_bvalid,                     //                         .bvalid,           Indicates that the write response channel signals are valid.
		output wire [255:0] f2sdram_rdata,                      //                         .rdata,            Read data.
		output wire [4:0]   f2sdram_rid,                        //                         .rid,              Identification tag for read data and response.
		output wire         f2sdram_rlast,                      //                         .rlast,            Indicates the last data transfer in a read transaction.
		input  wire         f2sdram_rready,                     //                         .rready,           Indicates a transfer on the read data channel can be accepted.
		output wire [1:0]   f2sdram_rresp,                      //                         .rresp,            Read response indicating the status of a read transfer.
		output wire         f2sdram_rvalid,                     //                         .rvalid,           Indicates the read channel data channel signals are valid.
		input  wire [255:0] f2sdram_wdata,                      //                         .wdata,            Write data.
		input  wire         f2sdram_wlast,                      //                         .wlast,            Indicates the last data transfer in a write transaction.
		output wire         f2sdram_wready,                     //                         .wready,           Indicates a transfer on the write data channel can be accepted.
		input  wire [31:0]  f2sdram_wstrb,                      //                         .wstrb,            Write strobes indicating which bye lanes hold valid data.
		input  wire         f2sdram_wvalid,                     //                         .wvalid,           Indicates the write channel data signals are valid.
		input  wire [7:0]   f2sdram_aruser,                     //                         .aruser,           Extension for the read address channel.
		input  wire [7:0]   f2sdram_awuser,                     //                         .awuser,           Extension for the write address channel.
		input  wire [7:0]   f2sdram_wuser,                      //                         .wuser,            Extension for the write data channel.
		output wire [7:0]   f2sdram_buser,                      //                         .buser,            Extension for the write response channel.
		input  wire [3:0]   f2sdram_arregion,                   //                         .arregion,         Region indicator for a read transaction.
		output wire [7:0]   f2sdram_ruser,                      //                         .ruser,            Extension for the read data channel.
		input  wire [3:0]   f2sdram_awregion,                   //                         .awregion,         Region indicator for a write transaction.
		input  wire         fpga2hps_clock_clk,                 //           fpga2hps_clock.clk,              Clock source signal. Synchronous signals are sampled on the rising edge of this clock.
		input  wire         fpga2hps_reset_reset,               //           fpga2hps_reset.reset,            Active high reset for fpga2hps soft logic on FPGA. The actual bridge reset is driven by internal HPS Reset Manager.
		input  wire [4:0]   fpga2hps_awid,                      //                 fpga2hps.awid,             Identification tag for a write transaction.
		input  wire [31:0]  fpga2hps_awaddr,                    //                         .awaddr,           The address of the first transfer in a write transaction.
		input  wire [1:0]   fpga2hps_awdomain,                  //                         .awdomain,         Indicates the shareability domain of a write transaction.
		input  wire [3:0]   fpga2hps_awsnoop,                   //                         .awsnoop,          Indicates transaction type for a shareable write transaction.
		input  wire [7:0]   fpga2hps_awlen,                     //                         .awlen,            Exact number of data ransfers in a write transaction.
		input  wire [2:0]   fpga2hps_awsize,                    //                         .awsize,           The number of bytes in each data transfer of a write transaction.
		input  wire [2:0]   fpga2hps_arsize,                    //                         .arsize,           The number of bytes in each data transfer of a read transaction.
		input  wire [1:0]   fpga2hps_awburst,                   //                         .awburst,          Burst type indicating how address changes between each transfer of a write transaction.
		input  wire         fpga2hps_awlock,                    //                         .awlock,           Provides info on atomic characteristics of a write transaction.
		input  wire [3:0]   fpga2hps_awcache,                   //                         .awcache,          Indicates how a write transaction is required to progress through a system.
		input  wire [2:0]   fpga2hps_awprot,                    //                         .awprot,           Protection attributes of a write transaction: privelege, security level, and access type.
		input  wire [3:0]   fpga2hps_awqos,                     //                         .awqos,            Quality of service identifier for a write transaction.
		input  wire         fpga2hps_awvalid,                   //                         .awvalid,          Indicates the write address channel signals are valid.
		output wire         fpga2hps_awready,                   //                         .awready,          Indicates a transfer on the write address channel can be accepted.
		input  wire [255:0] fpga2hps_wdata,                     //                         .wdata,            Write data.
		input  wire [31:0]  fpga2hps_wstrb,                     //                         .wstrb,            Write strobes indicating which byte lanes hold valid data.
		input  wire         fpga2hps_wlast,                     //                         .wlast,            Indicates the last data transfer in a write transaction.
		input  wire         fpga2hps_wvalid,                    //                         .wvalid,           Indicates the write data channel signals are valid.
		output wire         fpga2hps_wready,                    //                         .wready,           Indicates a transfer on the write data channel can be accepted.
		input  wire [10:0]  fpga2hps_awstashnid,                //                         .awstashnid,       Node identifier of the target for a stash operation.
		input  wire         fpga2hps_awstashniden,              //                         .awstashniden,     Indicates whether the AWSTASHNID signal is valid.
		input  wire [4:0]   fpga2hps_awstashlpid,               //                         .awstashlpid,      Logical processor identifier within the target for a stash operation.
		input  wire         fpga2hps_awstashlpiden,             //                         .awstashlpiden,    Indicates whether the AWSTASHLPID signal is valid.
		input  wire [5:0]   fpga2hps_awatop,                    //                         .awatop,           Indicates the type and endianness of atomic transactions.
		output wire [4:0]   fpga2hps_bid,                       //                         .bid,              Identification tag for a write response.
		output wire [1:0]   fpga2hps_bresp,                     //                         .bresp,            Write response indicating status of a write transaction.
		output wire         fpga2hps_bvalid,                    //                         .bvalid,           Indicates the write response channel signals are valid.
		input  wire         fpga2hps_bready,                    //                         .bready,           Indicates a transfer on the write response channel can be accepted.
		input  wire [4:0]   fpga2hps_arid,                      //                         .arid,             Identification tag for a read transaction.
		input  wire [31:0]  fpga2hps_araddr,                    //                         .araddr,           The address of the first transfer of a read transaction.
		input  wire [1:0]   fpga2hps_ardomain,                  //                         .ardomain,         Indicates the shareability domain of a read transaction.
		input  wire [3:0]   fpga2hps_arsnoop,                   //                         .arsnoop,          Indicates the transaction type for shareable read transactions.
		input  wire [7:0]   fpga2hps_arlen,                     //                         .arlen,            The exact number of data transfers in a read transaction.
		input  wire [1:0]   fpga2hps_arburst,                   //                         .arburst,          Burst type indicating how address changes between each transfer in a read transaction.
		input  wire         fpga2hps_arlock,                    //                         .arlock,           Provides info on atomic characteristics of a read transaction.
		input  wire [3:0]   fpga2hps_arcache,                   //                         .arcache,          Indicates how a read transaction is required to progress through a system.
		input  wire [2:0]   fpga2hps_arprot,                    //                         .arprot,           Protection attributes of a read transaction: privelege, security level, and access type.
		input  wire [3:0]   fpga2hps_arqos,                     //                         .arqos,            Quality of service identifier for a read transaction.
		input  wire         fpga2hps_arvalid,                   //                         .arvalid,          Indicates the read address channels signals are valid.
		output wire         fpga2hps_arready,                   //                         .arready,          Indicates a transfer on the read address channel can be accepted.
		output wire [4:0]   fpga2hps_rid,                       //                         .rid,              Identification tag for read data and response.
		output wire [255:0] fpga2hps_rdata,                     //                         .rdata,            Read data.
		output wire [1:0]   fpga2hps_rresp,                     //                         .rresp,            Indicates the status of a read transfer.
		output wire         fpga2hps_rlast,                     //                         .rlast,            Indicates the last data transfer in a read transaction.
		output wire         fpga2hps_rvalid,                    //                         .rvalid,           Indicates the read data channel signals are valid.
		input  wire         fpga2hps_rready,                    //                         .rready,           Indicates a transfer on the read data channel can be accepted.
		input  wire [7:0]   fpga2hps_aruser,                    //                         .aruser,           Extension of the read address channel.
		input  wire [7:0]   fpga2hps_awuser,                    //                         .awuser,           Extension of the write address channel.
		input  wire [3:0]   fpga2hps_arregion,                  //                         .arregion,         Region indicator for a read transaction.
		input  wire [3:0]   fpga2hps_awregion,                  //                         .awregion,         Region indicator for a write transaction.
		input  wire [7:0]   fpga2hps_wuser,                     //                         .wuser,            Extension of the write data channel.
		output wire [7:0]   fpga2hps_buser,                     //                         .buser,            Extension of the write response channel.
		output wire [7:0]   fpga2hps_ruser,                     //                         .ruser,            Extension of the read data channel.
		input  wire         io96b0_to_hps_ch0_axil_clk,         //            io96b0_to_hps.ch0_axil_clk,     Clock source signal. Synchronous signals are sampled on the rising edge of this clock.
		input  wire         io96b0_to_hps_ch0_axil_reset_n,     //                         .ch0_axil_reset_n, Required placeholder reset. The actual bridge reset is driven by HPS Reset Manager.
		input  wire         io96b0_to_hps_ch0_axil_arready,     //                         .ch0_axil_arready, Indicates a transfer on the read address channel can be accepted.
		input  wire         io96b0_to_hps_ch0_axil_awready,     //                         .ch0_axil_awready, Indicates a transfer on the write address channel can be accepted.
		input  wire [1:0]   io96b0_to_hps_ch0_axil_bresp,       //                         .ch0_axil_bresp,   Indicates status of write transaction.
		input  wire         io96b0_to_hps_ch0_axil_bvalid,      //                         .ch0_axil_bvalid,  Indicates write response channel signals are valid.
		input  wire [31:0]  io96b0_to_hps_ch0_axil_rdata,       //                         .ch0_axil_rdata,   Read data.
		input  wire [1:0]   io96b0_to_hps_ch0_axil_rresp,       //                         .ch0_axil_rresp,   Indicates status of read transaction.
		input  wire         io96b0_to_hps_ch0_axil_rvalid,      //                         .ch0_axil_rvalid,  Indicates read data channel signals are valid.
		input  wire         io96b0_to_hps_ch0_axil_wready,      //                         .ch0_axil_wready,  Indicates a transfer on the write data channel can be accepted.
		output wire [26:0]  io96b0_to_hps_ch0_axil_araddr,      //                         .ch0_axil_araddr,  The address of the first transfer in a read transaction.
		output wire         io96b0_to_hps_ch0_axil_arvalid,     //                         .ch0_axil_arvalid, Indicates read address channel signals are valid.
		output wire [26:0]  io96b0_to_hps_ch0_axil_awaddr,      //                         .ch0_axil_awaddr,  The address of the first transfer in a write transaction.
		output wire         io96b0_to_hps_ch0_axil_awvalid,     //                         .ch0_axil_awvalid, Indicates write address channel signals are valid.
		output wire         io96b0_to_hps_ch0_axil_bready,      //                         .ch0_axil_bready,  Indicates a transfer on the write response channel can be accepted.
		output wire         io96b0_to_hps_ch0_axil_rready,      //                         .ch0_axil_rready,  Indicates a transfer on the read data channel can be accepted.
		output wire [31:0]  io96b0_to_hps_ch0_axil_wdata,       //                         .ch0_axil_wdata,   Write data.
		output wire [3:0]   io96b0_to_hps_ch0_axil_wstrb,       //                         .ch0_axil_wstrb,   Write strobes indicating which bye lanes hold valid data.
		output wire         io96b0_to_hps_ch0_axil_wvalid,      //                         .ch0_axil_wvalid,  Indicates write data channel signals are valid.
		output wire [2:0]   io96b0_to_hps_ch0_axil_arprot,      //                         .ch0_axil_arprot,  Placeholder ARPROT. Protection attributes not supported for this bridge.
		output wire [2:0]   io96b0_to_hps_ch0_axil_awprot,      //                         .ch0_axil_awprot,  Placegolder AWPROT. Protection attributes not supported for this bridge.
		input  wire         io96b0_to_hps_axi4_ch0_clk,         //                         .axi4_ch0_clk,     Clock source signal. Synchronous signals are sampled on the rising edge of this clock.
		input  wire         io96b0_to_hps_axi4_ch0_reset_n,     //                         .axi4_ch0_reset_n, Required placeholder reset. The actual bridge reset is driven by HPS Reset Manager.
		input  wire         io96b0_to_hps_axi4_ch0_arready,     //                         .axi4_ch0_arready, Indicates a transfer on the read address channel can be accepted.
		input  wire         io96b0_to_hps_axi4_ch0_awready,     //                         .axi4_ch0_awready, Indicates a transfer on the write address channel can be accepted.
		input  wire [6:0]   io96b0_to_hps_axi4_ch0_bid,         //                         .axi4_ch0_bid,     Identification tag for a write response.
		input  wire [1:0]   io96b0_to_hps_axi4_ch0_bresp,       //                         .axi4_ch0_bresp,   Indicates the status of a write transaction.
		input  wire         io96b0_to_hps_axi4_ch0_bvalid,      //                         .axi4_ch0_bvalid,  Indicates write response channel signals are valid.
		input  wire [255:0] io96b0_to_hps_axi4_ch0_rdata,       //                         .axi4_ch0_rdata,   Read data.
		input  wire [6:0]   io96b0_to_hps_axi4_ch0_rid,         //                         .axi4_ch0_rid,     Identification tag for read data and response.
		input  wire         io96b0_to_hps_axi4_ch0_rlast,       //                         .axi4_ch0_rlast,   Indicates the last data transfer in a read transaction.
		input  wire [1:0]   io96b0_to_hps_axi4_ch0_rresp,       //                         .axi4_ch0_rresp,   Indicates the status of a read transfer.
		input  wire [31:0]  io96b0_to_hps_axi4_ch0_ruser,       //                         .axi4_ch0_ruser,   Extension of read data channel.
		input  wire         io96b0_to_hps_axi4_ch0_rvalid,      //                         .axi4_ch0_rvalid,  Indicates read data channel signals are valid.
		input  wire         io96b0_to_hps_axi4_ch0_wready,      //                         .axi4_ch0_wready,  Indicates a transfer on the write data channel can be accepted.
		output wire [39:0]  io96b0_to_hps_axi4_ch0_araddr,      //                         .axi4_ch0_araddr,  The address of the first transfer in a read transaction.
		output wire [1:0]   io96b0_to_hps_axi4_ch0_arburst,     //                         .axi4_ch0_arburst, Burst type indicating how address changes between each transfer in a read transaction.
		output wire [6:0]   io96b0_to_hps_axi4_ch0_arid,        //                         .axi4_ch0_arid,    Identification tag for a read transaction.
		output wire [7:0]   io96b0_to_hps_axi4_ch0_arlen,       //                         .axi4_ch0_arlen,   Exact number of data transfers in a read transaction.
		output wire         io96b0_to_hps_axi4_ch0_arlock,      //                         .axi4_ch0_arlock,  Provides info on atomic characteristics of a read transaction.
		output wire [3:0]   io96b0_to_hps_axi4_ch0_arqos,       //                         .axi4_ch0_arqos,   Quality of service identifier for a read transaction.
		output wire [2:0]   io96b0_to_hps_axi4_ch0_arsize,      //                         .axi4_ch0_arsize,  The number of bytes in each data transfer in a read transaction.
		output wire [13:0]  io96b0_to_hps_axi4_ch0_aruser,      //                         .axi4_ch0_aruser,  Extension of read address channel.
		output wire         io96b0_to_hps_axi4_ch0_arvalid,     //                         .axi4_ch0_arvalid, Indicates read address channel signals are valid.
		output wire [39:0]  io96b0_to_hps_axi4_ch0_awaddr,      //                         .axi4_ch0_awaddr,  The address of the first transfer in a write transaction.
		output wire [1:0]   io96b0_to_hps_axi4_ch0_awburst,     //                         .axi4_ch0_awburst, Burst type indicating how address changes between each transfer in a write transaction.
		output wire [6:0]   io96b0_to_hps_axi4_ch0_awid,        //                         .axi4_ch0_awid,    Identification tag for a write transaction.
		output wire [7:0]   io96b0_to_hps_axi4_ch0_awlen,       //                         .axi4_ch0_awlen,   Exact number of data transfers in a write transaction.
		output wire         io96b0_to_hps_axi4_ch0_awlock,      //                         .axi4_ch0_awlock,  Provides info on atomic characteristics of a write transaction.
		output wire [3:0]   io96b0_to_hps_axi4_ch0_awqos,       //                         .axi4_ch0_awqos,   Quality of service identifier for a write transaction.
		output wire [2:0]   io96b0_to_hps_axi4_ch0_awsize,      //                         .axi4_ch0_awsize,  Number of bytes in each data transfer in a write transaction.
		output wire [13:0]  io96b0_to_hps_axi4_ch0_awuser,      //                         .axi4_ch0_awuser,  Extension of write address channel.
		output wire         io96b0_to_hps_axi4_ch0_awvalid,     //                         .axi4_ch0_awvalid, Indicates write address channel signals are valid.
		output wire         io96b0_to_hps_axi4_ch0_bready,      //                         .axi4_ch0_bready,  Indicates a transfer on write response channel can be accepted.
		output wire         io96b0_to_hps_axi4_ch0_rready,      //                         .axi4_ch0_rready,  Indicates a transfer on read data channel can be accepted.
		output wire [255:0] io96b0_to_hps_axi4_ch0_wdata,       //                         .axi4_ch0_wdata,   Write data.
		output wire         io96b0_to_hps_axi4_ch0_wlast,       //                         .axi4_ch0_wlast,   Indicates the last data transfer in a write transaction.
		output wire [31:0]  io96b0_to_hps_axi4_ch0_wstrb,       //                         .axi4_ch0_wstrb,   Write strobes indicating which byte lanes hold valid data.
		output wire [31:0]  io96b0_to_hps_axi4_ch0_wuser,       //                         .axi4_ch0_wuser,   Extension of the write data channel.
		output wire         io96b0_to_hps_axi4_ch0_wvalid,      //                         .axi4_ch0_wvalid,  Indicates write data channel signals are valid.
		output wire [2:0]   io96b0_to_hps_axi4_ch0_arprot,      //                         .axi4_ch0_arprot,  Placeholder ARPROT. Protection attributes not supported for this bridge.
		output wire [2:0]   io96b0_to_hps_axi4_ch0_awprot       //                         .axi4_ch0_awprot,  Placeholder AWPROT. Protection attributes not supported for this bridge.
	);
endmodule

