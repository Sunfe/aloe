	component hps_subsys is
		port (
			h2f_reset_reset                       : out   std_logic;                                         -- reset
			hps2fpga_clk_clk                      : in    std_logic                      := 'X';             -- clk
			hps2fpga_rst_reset                    : in    std_logic                      := 'X';             -- reset
			hps2fpga_awid                         : out   std_logic_vector(3 downto 0);                      -- awid
			hps2fpga_awaddr                       : out   std_logic_vector(37 downto 0);                     -- awaddr
			hps2fpga_awlen                        : out   std_logic_vector(7 downto 0);                      -- awlen
			hps2fpga_awsize                       : out   std_logic_vector(2 downto 0);                      -- awsize
			hps2fpga_awburst                      : out   std_logic_vector(1 downto 0);                      -- awburst
			hps2fpga_awlock                       : out   std_logic;                                         -- awlock
			hps2fpga_awcache                      : out   std_logic_vector(3 downto 0);                      -- awcache
			hps2fpga_awprot                       : out   std_logic_vector(2 downto 0);                      -- awprot
			hps2fpga_awvalid                      : out   std_logic;                                         -- awvalid
			hps2fpga_awready                      : in    std_logic                      := 'X';             -- awready
			hps2fpga_wdata                        : out   std_logic_vector(127 downto 0);                    -- wdata
			hps2fpga_wstrb                        : out   std_logic_vector(15 downto 0);                     -- wstrb
			hps2fpga_wlast                        : out   std_logic;                                         -- wlast
			hps2fpga_wvalid                       : out   std_logic;                                         -- wvalid
			hps2fpga_wready                       : in    std_logic                      := 'X';             -- wready
			hps2fpga_bid                          : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- bid
			hps2fpga_bresp                        : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- bresp
			hps2fpga_bvalid                       : in    std_logic                      := 'X';             -- bvalid
			hps2fpga_bready                       : out   std_logic;                                         -- bready
			hps2fpga_arid                         : out   std_logic_vector(3 downto 0);                      -- arid
			hps2fpga_araddr                       : out   std_logic_vector(37 downto 0);                     -- araddr
			hps2fpga_arlen                        : out   std_logic_vector(7 downto 0);                      -- arlen
			hps2fpga_arsize                       : out   std_logic_vector(2 downto 0);                      -- arsize
			hps2fpga_arburst                      : out   std_logic_vector(1 downto 0);                      -- arburst
			hps2fpga_arlock                       : out   std_logic;                                         -- arlock
			hps2fpga_arcache                      : out   std_logic_vector(3 downto 0);                      -- arcache
			hps2fpga_arprot                       : out   std_logic_vector(2 downto 0);                      -- arprot
			hps2fpga_arvalid                      : out   std_logic;                                         -- arvalid
			hps2fpga_arready                      : in    std_logic                      := 'X';             -- arready
			hps2fpga_rid                          : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- rid
			hps2fpga_rdata                        : in    std_logic_vector(127 downto 0) := (others => 'X'); -- rdata
			hps2fpga_rresp                        : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- rresp
			hps2fpga_rlast                        : in    std_logic                      := 'X';             -- rlast
			hps2fpga_rvalid                       : in    std_logic                      := 'X';             -- rvalid
			hps2fpga_rready                       : out   std_logic;                                         -- rready
			lwhps2fpga_clk_clk                    : in    std_logic                      := 'X';             -- clk
			lwhps2fpga_rst_reset                  : in    std_logic                      := 'X';             -- reset
			lwhps2fpga_awid                       : out   std_logic_vector(3 downto 0);                      -- awid
			lwhps2fpga_awaddr                     : out   std_logic_vector(28 downto 0);                     -- awaddr
			lwhps2fpga_awlen                      : out   std_logic_vector(7 downto 0);                      -- awlen
			lwhps2fpga_awsize                     : out   std_logic_vector(2 downto 0);                      -- awsize
			lwhps2fpga_awburst                    : out   std_logic_vector(1 downto 0);                      -- awburst
			lwhps2fpga_awlock                     : out   std_logic;                                         -- awlock
			lwhps2fpga_awcache                    : out   std_logic_vector(3 downto 0);                      -- awcache
			lwhps2fpga_awprot                     : out   std_logic_vector(2 downto 0);                      -- awprot
			lwhps2fpga_awvalid                    : out   std_logic;                                         -- awvalid
			lwhps2fpga_awready                    : in    std_logic                      := 'X';             -- awready
			lwhps2fpga_wdata                      : out   std_logic_vector(31 downto 0);                     -- wdata
			lwhps2fpga_wstrb                      : out   std_logic_vector(3 downto 0);                      -- wstrb
			lwhps2fpga_wlast                      : out   std_logic;                                         -- wlast
			lwhps2fpga_wvalid                     : out   std_logic;                                         -- wvalid
			lwhps2fpga_wready                     : in    std_logic                      := 'X';             -- wready
			lwhps2fpga_bid                        : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- bid
			lwhps2fpga_bresp                      : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- bresp
			lwhps2fpga_bvalid                     : in    std_logic                      := 'X';             -- bvalid
			lwhps2fpga_bready                     : out   std_logic;                                         -- bready
			lwhps2fpga_arid                       : out   std_logic_vector(3 downto 0);                      -- arid
			lwhps2fpga_araddr                     : out   std_logic_vector(28 downto 0);                     -- araddr
			lwhps2fpga_arlen                      : out   std_logic_vector(7 downto 0);                      -- arlen
			lwhps2fpga_arsize                     : out   std_logic_vector(2 downto 0);                      -- arsize
			lwhps2fpga_arburst                    : out   std_logic_vector(1 downto 0);                      -- arburst
			lwhps2fpga_arlock                     : out   std_logic;                                         -- arlock
			lwhps2fpga_arcache                    : out   std_logic_vector(3 downto 0);                      -- arcache
			lwhps2fpga_arprot                     : out   std_logic_vector(2 downto 0);                      -- arprot
			lwhps2fpga_arvalid                    : out   std_logic;                                         -- arvalid
			lwhps2fpga_arready                    : in    std_logic                      := 'X';             -- arready
			lwhps2fpga_rid                        : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- rid
			lwhps2fpga_rdata                      : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- rdata
			lwhps2fpga_rresp                      : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- rresp
			lwhps2fpga_rlast                      : in    std_logic                      := 'X';             -- rlast
			lwhps2fpga_rvalid                     : in    std_logic                      := 'X';             -- rvalid
			lwhps2fpga_rready                     : out   std_logic;                                         -- rready
			h2f_warm_reset_handshake_reset_req    : out   std_logic;                                         -- reset_req
			h2f_warm_reset_handshake_reset_ack    : in    std_logic                      := 'X';             -- reset_ack
			hps_io_hps_osc_clk                    : in    std_logic                      := 'X';             -- hps_osc_clk
			hps_io_sdmmc_data0                    : inout std_logic                      := 'X';             -- sdmmc_data0
			hps_io_sdmmc_data1                    : inout std_logic                      := 'X';             -- sdmmc_data1
			hps_io_sdmmc_cclk                     : out   std_logic;                                         -- sdmmc_cclk
			hps_io_sdmmc_data2                    : inout std_logic                      := 'X';             -- sdmmc_data2
			hps_io_sdmmc_data3                    : inout std_logic                      := 'X';             -- sdmmc_data3
			hps_io_sdmmc_cmd                      : inout std_logic                      := 'X';             -- sdmmc_cmd
			hps_io_usb0_clk                       : in    std_logic                      := 'X';             -- usb0_clk
			hps_io_usb0_stp                       : out   std_logic;                                         -- usb0_stp
			hps_io_usb0_dir                       : in    std_logic                      := 'X';             -- usb0_dir
			hps_io_usb0_data0                     : inout std_logic                      := 'X';             -- usb0_data0
			hps_io_usb0_data1                     : inout std_logic                      := 'X';             -- usb0_data1
			hps_io_usb0_nxt                       : in    std_logic                      := 'X';             -- usb0_nxt
			hps_io_usb0_data2                     : inout std_logic                      := 'X';             -- usb0_data2
			hps_io_usb0_data3                     : inout std_logic                      := 'X';             -- usb0_data3
			hps_io_usb0_data4                     : inout std_logic                      := 'X';             -- usb0_data4
			hps_io_usb0_data5                     : inout std_logic                      := 'X';             -- usb0_data5
			hps_io_usb0_data6                     : inout std_logic                      := 'X';             -- usb0_data6
			hps_io_usb0_data7                     : inout std_logic                      := 'X';             -- usb0_data7
			hps_io_emac0_tx_clk                   : out   std_logic;                                         -- emac0_tx_clk
			hps_io_emac0_tx_ctl                   : out   std_logic;                                         -- emac0_tx_ctl
			hps_io_emac0_rx_clk                   : in    std_logic                      := 'X';             -- emac0_rx_clk
			hps_io_emac0_rx_ctl                   : in    std_logic                      := 'X';             -- emac0_rx_ctl
			hps_io_emac0_txd0                     : out   std_logic;                                         -- emac0_txd0
			hps_io_emac0_txd1                     : out   std_logic;                                         -- emac0_txd1
			hps_io_emac0_rxd0                     : in    std_logic                      := 'X';             -- emac0_rxd0
			hps_io_emac0_rxd1                     : in    std_logic                      := 'X';             -- emac0_rxd1
			hps_io_emac0_txd2                     : out   std_logic;                                         -- emac0_txd2
			hps_io_emac0_txd3                     : out   std_logic;                                         -- emac0_txd3
			hps_io_emac0_rxd2                     : in    std_logic                      := 'X';             -- emac0_rxd2
			hps_io_emac0_rxd3                     : in    std_logic                      := 'X';             -- emac0_rxd3
			hps_io_mdio0_mdio                     : inout std_logic                      := 'X';             -- mdio0_mdio
			hps_io_mdio0_mdc                      : out   std_logic;                                         -- mdio0_mdc
			hps_io_spim0_clk                      : out   std_logic;                                         -- spim0_clk
			hps_io_spim0_mosi                     : out   std_logic;                                         -- spim0_mosi
			hps_io_spim0_ss0_n                    : out   std_logic;                                         -- spim0_ss0_n
			hps_io_uart1_tx                       : out   std_logic;                                         -- uart1_tx
			hps_io_uart1_rx                       : in    std_logic                      := 'X';             -- uart1_rx
			hps_io_i2c1_sda                       : inout std_logic                      := 'X';             -- i2c1_sda
			hps_io_i2c1_scl                       : inout std_logic                      := 'X';             -- i2c1_scl
			hps_io_gpio28                         : inout std_logic                      := 'X';             -- gpio28
			hps_io_gpio32                         : inout std_logic                      := 'X';             -- gpio32
			hps_io_gpio33                         : inout std_logic                      := 'X';             -- gpio33
			hps_io_gpio34                         : inout std_logic                      := 'X';             -- gpio34
			hps_io_gpio35                         : inout std_logic                      := 'X';             -- gpio35
			hps_io_gpio40                         : inout std_logic                      := 'X';             -- gpio40
			hps_io_gpio41                         : inout std_logic                      := 'X';             -- gpio41
			hps_io_gpio42                         : inout std_logic                      := 'X';             -- gpio42
			f2h_irq1_in_irq                       : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- irq
			f2h_irq0_in_irq                       : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- irq
			f2sdram_clk_clk                       : in    std_logic                      := 'X';             -- clk
			f2sdram_rst_reset                     : in    std_logic                      := 'X';             -- reset
			fpga2hps_clk_clk                      : in    std_logic                      := 'X';             -- clk
			fpga2hps_rst_reset                    : in    std_logic                      := 'X';             -- reset
			fpga2hps_awid                         : in    std_logic_vector(4 downto 0)   := (others => 'X'); -- awid
			fpga2hps_awaddr                       : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- awaddr
			fpga2hps_awdomain                     : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- awdomain
			fpga2hps_awsnoop                      : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- awsnoop
			fpga2hps_awlen                        : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- awlen
			fpga2hps_awsize                       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- awsize
			fpga2hps_arsize                       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- arsize
			fpga2hps_awburst                      : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- awburst
			fpga2hps_awlock                       : in    std_logic                      := 'X';             -- awlock
			fpga2hps_awcache                      : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- awcache
			fpga2hps_awprot                       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- awprot
			fpga2hps_awqos                        : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- awqos
			fpga2hps_awvalid                      : in    std_logic                      := 'X';             -- awvalid
			fpga2hps_awready                      : out   std_logic;                                         -- awready
			fpga2hps_wdata                        : in    std_logic_vector(255 downto 0) := (others => 'X'); -- wdata
			fpga2hps_wstrb                        : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- wstrb
			fpga2hps_wlast                        : in    std_logic                      := 'X';             -- wlast
			fpga2hps_wvalid                       : in    std_logic                      := 'X';             -- wvalid
			fpga2hps_wready                       : out   std_logic;                                         -- wready
			fpga2hps_awstashnid                   : in    std_logic_vector(10 downto 0)  := (others => 'X'); -- awstashnid
			fpga2hps_awstashniden                 : in    std_logic                      := 'X';             -- awstashniden
			fpga2hps_awstashlpid                  : in    std_logic_vector(4 downto 0)   := (others => 'X'); -- awstashlpid
			fpga2hps_awstashlpiden                : in    std_logic                      := 'X';             -- awstashlpiden
			fpga2hps_awatop                       : in    std_logic_vector(5 downto 0)   := (others => 'X'); -- awatop
			fpga2hps_bid                          : out   std_logic_vector(4 downto 0);                      -- bid
			fpga2hps_bresp                        : out   std_logic_vector(1 downto 0);                      -- bresp
			fpga2hps_bvalid                       : out   std_logic;                                         -- bvalid
			fpga2hps_bready                       : in    std_logic                      := 'X';             -- bready
			fpga2hps_arid                         : in    std_logic_vector(4 downto 0)   := (others => 'X'); -- arid
			fpga2hps_araddr                       : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- araddr
			fpga2hps_ardomain                     : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- ardomain
			fpga2hps_arsnoop                      : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- arsnoop
			fpga2hps_arlen                        : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- arlen
			fpga2hps_arburst                      : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- arburst
			fpga2hps_arlock                       : in    std_logic                      := 'X';             -- arlock
			fpga2hps_arcache                      : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- arcache
			fpga2hps_arprot                       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- arprot
			fpga2hps_arqos                        : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- arqos
			fpga2hps_arvalid                      : in    std_logic                      := 'X';             -- arvalid
			fpga2hps_arready                      : out   std_logic;                                         -- arready
			fpga2hps_rid                          : out   std_logic_vector(4 downto 0);                      -- rid
			fpga2hps_rdata                        : out   std_logic_vector(255 downto 0);                    -- rdata
			fpga2hps_rresp                        : out   std_logic_vector(1 downto 0);                      -- rresp
			fpga2hps_rlast                        : out   std_logic;                                         -- rlast
			fpga2hps_rvalid                       : out   std_logic;                                         -- rvalid
			fpga2hps_rready                       : in    std_logic                      := 'X';             -- rready
			fpga2hps_aruser                       : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- aruser
			fpga2hps_awuser                       : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- awuser
			fpga2hps_arregion                     : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- arregion
			fpga2hps_awregion                     : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- awregion
			fpga2hps_wuser                        : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- wuser
			fpga2hps_buser                        : out   std_logic_vector(7 downto 0);                      -- buser
			fpga2hps_ruser                        : out   std_logic_vector(7 downto 0);                      -- ruser
			emif_hps_emif_mem_0_mem_cke           : out   std_logic_vector(0 downto 0);                      -- mem_cke
			emif_hps_emif_mem_0_mem_odt           : out   std_logic_vector(0 downto 0);                      -- mem_odt
			emif_hps_emif_mem_0_mem_cs_n          : out   std_logic_vector(0 downto 0);                      -- mem_cs_n
			emif_hps_emif_mem_0_mem_a             : out   std_logic_vector(16 downto 0);                     -- mem_a
			emif_hps_emif_mem_0_mem_ba            : out   std_logic_vector(1 downto 0);                      -- mem_ba
			emif_hps_emif_mem_0_mem_bg            : out   std_logic_vector(0 downto 0);                      -- mem_bg
			emif_hps_emif_mem_0_mem_act_n         : out   std_logic;                                         -- mem_act_n
			emif_hps_emif_mem_0_mem_par           : out   std_logic;                                         -- mem_par
			emif_hps_emif_mem_0_mem_dq            : inout std_logic_vector(31 downto 0)  := (others => 'X'); -- mem_dq
			emif_hps_emif_mem_0_mem_dqs_t         : inout std_logic_vector(3 downto 0)   := (others => 'X'); -- mem_dqs_t
			emif_hps_emif_mem_0_mem_dqs_c         : inout std_logic_vector(3 downto 0)   := (others => 'X'); -- mem_dqs_c
			emif_hps_emif_mem_0_mem_alert_n       : in    std_logic                      := 'X';             -- mem_alert_n
			emif_hps_emif_mem_0_mem_dbi_n         : inout std_logic_vector(3 downto 0)   := (others => 'X'); -- mem_dbi_n
			emif_hps_emif_mem_ck_0_mem_ck_t       : out   std_logic_vector(0 downto 0);                      -- mem_ck_t
			emif_hps_emif_mem_ck_0_mem_ck_c       : out   std_logic_vector(0 downto 0);                      -- mem_ck_c
			emif_hps_emif_mem_reset_n_mem_reset_n : out   std_logic;                                         -- mem_reset_n
			emif_hps_emif_oct_0_oct_rzqin         : in    std_logic                      := 'X';             -- oct_rzqin
			emif_hps_emif_ref_clk_clk             : in    std_logic                      := 'X';             -- clk
			f2sdram_adapter_clk_clk               : in    std_logic                      := 'X';             -- clk
			f2sdram_adapter_rst_reset             : in    std_logic                      := 'X';             -- reset
			f2sdram_adapter_axi4_sub_araddr       : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- araddr
			f2sdram_adapter_axi4_sub_arburst      : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- arburst
			f2sdram_adapter_axi4_sub_arcache      : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- arcache
			f2sdram_adapter_axi4_sub_arid         : in    std_logic_vector(4 downto 0)   := (others => 'X'); -- arid
			f2sdram_adapter_axi4_sub_arlen        : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- arlen
			f2sdram_adapter_axi4_sub_arlock       : in    std_logic                      := 'X';             -- arlock
			f2sdram_adapter_axi4_sub_arprot       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- arprot
			f2sdram_adapter_axi4_sub_arqos        : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- arqos
			f2sdram_adapter_axi4_sub_arready      : out   std_logic;                                         -- arready
			f2sdram_adapter_axi4_sub_arsize       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- arsize
			f2sdram_adapter_axi4_sub_arvalid      : in    std_logic                      := 'X';             -- arvalid
			f2sdram_adapter_axi4_sub_awaddr       : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- awaddr
			f2sdram_adapter_axi4_sub_awburst      : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- awburst
			f2sdram_adapter_axi4_sub_awcache      : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- awcache
			f2sdram_adapter_axi4_sub_awid         : in    std_logic_vector(4 downto 0)   := (others => 'X'); -- awid
			f2sdram_adapter_axi4_sub_awlen        : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- awlen
			f2sdram_adapter_axi4_sub_awlock       : in    std_logic                      := 'X';             -- awlock
			f2sdram_adapter_axi4_sub_awprot       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- awprot
			f2sdram_adapter_axi4_sub_awqos        : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- awqos
			f2sdram_adapter_axi4_sub_awready      : out   std_logic;                                         -- awready
			f2sdram_adapter_axi4_sub_awsize       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- awsize
			f2sdram_adapter_axi4_sub_awvalid      : in    std_logic                      := 'X';             -- awvalid
			f2sdram_adapter_axi4_sub_bid          : out   std_logic_vector(4 downto 0);                      -- bid
			f2sdram_adapter_axi4_sub_bready       : in    std_logic                      := 'X';             -- bready
			f2sdram_adapter_axi4_sub_bresp        : out   std_logic_vector(1 downto 0);                      -- bresp
			f2sdram_adapter_axi4_sub_bvalid       : out   std_logic;                                         -- bvalid
			f2sdram_adapter_axi4_sub_rdata        : out   std_logic_vector(255 downto 0);                    -- rdata
			f2sdram_adapter_axi4_sub_rid          : out   std_logic_vector(4 downto 0);                      -- rid
			f2sdram_adapter_axi4_sub_rlast        : out   std_logic;                                         -- rlast
			f2sdram_adapter_axi4_sub_rready       : in    std_logic                      := 'X';             -- rready
			f2sdram_adapter_axi4_sub_rresp        : out   std_logic_vector(1 downto 0);                      -- rresp
			f2sdram_adapter_axi4_sub_rvalid       : out   std_logic;                                         -- rvalid
			f2sdram_adapter_axi4_sub_wdata        : in    std_logic_vector(255 downto 0) := (others => 'X'); -- wdata
			f2sdram_adapter_axi4_sub_wlast        : in    std_logic                      := 'X';             -- wlast
			f2sdram_adapter_axi4_sub_wready       : out   std_logic;                                         -- wready
			f2sdram_adapter_axi4_sub_wstrb        : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- wstrb
			f2sdram_adapter_axi4_sub_wvalid       : in    std_logic                      := 'X';             -- wvalid
			f2sdram_adapter_axi4_sub_aruser       : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- aruser
			f2sdram_adapter_axi4_sub_awuser       : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- awuser
			f2sdram_adapter_axi4_sub_wuser        : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- wuser
			f2sdram_adapter_axi4_sub_buser        : out   std_logic_vector(7 downto 0);                      -- buser
			f2sdram_adapter_axi4_sub_arregion     : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- arregion
			f2sdram_adapter_axi4_sub_ruser        : out   std_logic_vector(7 downto 0);                      -- ruser
			f2sdram_adapter_axi4_sub_awregion     : in    std_logic_vector(3 downto 0)   := (others => 'X')  -- awregion
		);
	end component hps_subsys;

	u0 : component hps_subsys
		port map (
			h2f_reset_reset                       => CONNECTED_TO_h2f_reset_reset,                       --                 h2f_reset.reset
			hps2fpga_clk_clk                      => CONNECTED_TO_hps2fpga_clk_clk,                      --              hps2fpga_clk.clk
			hps2fpga_rst_reset                    => CONNECTED_TO_hps2fpga_rst_reset,                    --              hps2fpga_rst.reset
			hps2fpga_awid                         => CONNECTED_TO_hps2fpga_awid,                         --                  hps2fpga.awid
			hps2fpga_awaddr                       => CONNECTED_TO_hps2fpga_awaddr,                       --                          .awaddr
			hps2fpga_awlen                        => CONNECTED_TO_hps2fpga_awlen,                        --                          .awlen
			hps2fpga_awsize                       => CONNECTED_TO_hps2fpga_awsize,                       --                          .awsize
			hps2fpga_awburst                      => CONNECTED_TO_hps2fpga_awburst,                      --                          .awburst
			hps2fpga_awlock                       => CONNECTED_TO_hps2fpga_awlock,                       --                          .awlock
			hps2fpga_awcache                      => CONNECTED_TO_hps2fpga_awcache,                      --                          .awcache
			hps2fpga_awprot                       => CONNECTED_TO_hps2fpga_awprot,                       --                          .awprot
			hps2fpga_awvalid                      => CONNECTED_TO_hps2fpga_awvalid,                      --                          .awvalid
			hps2fpga_awready                      => CONNECTED_TO_hps2fpga_awready,                      --                          .awready
			hps2fpga_wdata                        => CONNECTED_TO_hps2fpga_wdata,                        --                          .wdata
			hps2fpga_wstrb                        => CONNECTED_TO_hps2fpga_wstrb,                        --                          .wstrb
			hps2fpga_wlast                        => CONNECTED_TO_hps2fpga_wlast,                        --                          .wlast
			hps2fpga_wvalid                       => CONNECTED_TO_hps2fpga_wvalid,                       --                          .wvalid
			hps2fpga_wready                       => CONNECTED_TO_hps2fpga_wready,                       --                          .wready
			hps2fpga_bid                          => CONNECTED_TO_hps2fpga_bid,                          --                          .bid
			hps2fpga_bresp                        => CONNECTED_TO_hps2fpga_bresp,                        --                          .bresp
			hps2fpga_bvalid                       => CONNECTED_TO_hps2fpga_bvalid,                       --                          .bvalid
			hps2fpga_bready                       => CONNECTED_TO_hps2fpga_bready,                       --                          .bready
			hps2fpga_arid                         => CONNECTED_TO_hps2fpga_arid,                         --                          .arid
			hps2fpga_araddr                       => CONNECTED_TO_hps2fpga_araddr,                       --                          .araddr
			hps2fpga_arlen                        => CONNECTED_TO_hps2fpga_arlen,                        --                          .arlen
			hps2fpga_arsize                       => CONNECTED_TO_hps2fpga_arsize,                       --                          .arsize
			hps2fpga_arburst                      => CONNECTED_TO_hps2fpga_arburst,                      --                          .arburst
			hps2fpga_arlock                       => CONNECTED_TO_hps2fpga_arlock,                       --                          .arlock
			hps2fpga_arcache                      => CONNECTED_TO_hps2fpga_arcache,                      --                          .arcache
			hps2fpga_arprot                       => CONNECTED_TO_hps2fpga_arprot,                       --                          .arprot
			hps2fpga_arvalid                      => CONNECTED_TO_hps2fpga_arvalid,                      --                          .arvalid
			hps2fpga_arready                      => CONNECTED_TO_hps2fpga_arready,                      --                          .arready
			hps2fpga_rid                          => CONNECTED_TO_hps2fpga_rid,                          --                          .rid
			hps2fpga_rdata                        => CONNECTED_TO_hps2fpga_rdata,                        --                          .rdata
			hps2fpga_rresp                        => CONNECTED_TO_hps2fpga_rresp,                        --                          .rresp
			hps2fpga_rlast                        => CONNECTED_TO_hps2fpga_rlast,                        --                          .rlast
			hps2fpga_rvalid                       => CONNECTED_TO_hps2fpga_rvalid,                       --                          .rvalid
			hps2fpga_rready                       => CONNECTED_TO_hps2fpga_rready,                       --                          .rready
			lwhps2fpga_clk_clk                    => CONNECTED_TO_lwhps2fpga_clk_clk,                    --            lwhps2fpga_clk.clk
			lwhps2fpga_rst_reset                  => CONNECTED_TO_lwhps2fpga_rst_reset,                  --            lwhps2fpga_rst.reset
			lwhps2fpga_awid                       => CONNECTED_TO_lwhps2fpga_awid,                       --                lwhps2fpga.awid
			lwhps2fpga_awaddr                     => CONNECTED_TO_lwhps2fpga_awaddr,                     --                          .awaddr
			lwhps2fpga_awlen                      => CONNECTED_TO_lwhps2fpga_awlen,                      --                          .awlen
			lwhps2fpga_awsize                     => CONNECTED_TO_lwhps2fpga_awsize,                     --                          .awsize
			lwhps2fpga_awburst                    => CONNECTED_TO_lwhps2fpga_awburst,                    --                          .awburst
			lwhps2fpga_awlock                     => CONNECTED_TO_lwhps2fpga_awlock,                     --                          .awlock
			lwhps2fpga_awcache                    => CONNECTED_TO_lwhps2fpga_awcache,                    --                          .awcache
			lwhps2fpga_awprot                     => CONNECTED_TO_lwhps2fpga_awprot,                     --                          .awprot
			lwhps2fpga_awvalid                    => CONNECTED_TO_lwhps2fpga_awvalid,                    --                          .awvalid
			lwhps2fpga_awready                    => CONNECTED_TO_lwhps2fpga_awready,                    --                          .awready
			lwhps2fpga_wdata                      => CONNECTED_TO_lwhps2fpga_wdata,                      --                          .wdata
			lwhps2fpga_wstrb                      => CONNECTED_TO_lwhps2fpga_wstrb,                      --                          .wstrb
			lwhps2fpga_wlast                      => CONNECTED_TO_lwhps2fpga_wlast,                      --                          .wlast
			lwhps2fpga_wvalid                     => CONNECTED_TO_lwhps2fpga_wvalid,                     --                          .wvalid
			lwhps2fpga_wready                     => CONNECTED_TO_lwhps2fpga_wready,                     --                          .wready
			lwhps2fpga_bid                        => CONNECTED_TO_lwhps2fpga_bid,                        --                          .bid
			lwhps2fpga_bresp                      => CONNECTED_TO_lwhps2fpga_bresp,                      --                          .bresp
			lwhps2fpga_bvalid                     => CONNECTED_TO_lwhps2fpga_bvalid,                     --                          .bvalid
			lwhps2fpga_bready                     => CONNECTED_TO_lwhps2fpga_bready,                     --                          .bready
			lwhps2fpga_arid                       => CONNECTED_TO_lwhps2fpga_arid,                       --                          .arid
			lwhps2fpga_araddr                     => CONNECTED_TO_lwhps2fpga_araddr,                     --                          .araddr
			lwhps2fpga_arlen                      => CONNECTED_TO_lwhps2fpga_arlen,                      --                          .arlen
			lwhps2fpga_arsize                     => CONNECTED_TO_lwhps2fpga_arsize,                     --                          .arsize
			lwhps2fpga_arburst                    => CONNECTED_TO_lwhps2fpga_arburst,                    --                          .arburst
			lwhps2fpga_arlock                     => CONNECTED_TO_lwhps2fpga_arlock,                     --                          .arlock
			lwhps2fpga_arcache                    => CONNECTED_TO_lwhps2fpga_arcache,                    --                          .arcache
			lwhps2fpga_arprot                     => CONNECTED_TO_lwhps2fpga_arprot,                     --                          .arprot
			lwhps2fpga_arvalid                    => CONNECTED_TO_lwhps2fpga_arvalid,                    --                          .arvalid
			lwhps2fpga_arready                    => CONNECTED_TO_lwhps2fpga_arready,                    --                          .arready
			lwhps2fpga_rid                        => CONNECTED_TO_lwhps2fpga_rid,                        --                          .rid
			lwhps2fpga_rdata                      => CONNECTED_TO_lwhps2fpga_rdata,                      --                          .rdata
			lwhps2fpga_rresp                      => CONNECTED_TO_lwhps2fpga_rresp,                      --                          .rresp
			lwhps2fpga_rlast                      => CONNECTED_TO_lwhps2fpga_rlast,                      --                          .rlast
			lwhps2fpga_rvalid                     => CONNECTED_TO_lwhps2fpga_rvalid,                     --                          .rvalid
			lwhps2fpga_rready                     => CONNECTED_TO_lwhps2fpga_rready,                     --                          .rready
			h2f_warm_reset_handshake_reset_req    => CONNECTED_TO_h2f_warm_reset_handshake_reset_req,    --  h2f_warm_reset_handshake.reset_req
			h2f_warm_reset_handshake_reset_ack    => CONNECTED_TO_h2f_warm_reset_handshake_reset_ack,    --                          .reset_ack
			hps_io_hps_osc_clk                    => CONNECTED_TO_hps_io_hps_osc_clk,                    --                    hps_io.hps_osc_clk
			hps_io_sdmmc_data0                    => CONNECTED_TO_hps_io_sdmmc_data0,                    --                          .sdmmc_data0
			hps_io_sdmmc_data1                    => CONNECTED_TO_hps_io_sdmmc_data1,                    --                          .sdmmc_data1
			hps_io_sdmmc_cclk                     => CONNECTED_TO_hps_io_sdmmc_cclk,                     --                          .sdmmc_cclk
			hps_io_sdmmc_data2                    => CONNECTED_TO_hps_io_sdmmc_data2,                    --                          .sdmmc_data2
			hps_io_sdmmc_data3                    => CONNECTED_TO_hps_io_sdmmc_data3,                    --                          .sdmmc_data3
			hps_io_sdmmc_cmd                      => CONNECTED_TO_hps_io_sdmmc_cmd,                      --                          .sdmmc_cmd
			hps_io_usb0_clk                       => CONNECTED_TO_hps_io_usb0_clk,                       --                          .usb0_clk
			hps_io_usb0_stp                       => CONNECTED_TO_hps_io_usb0_stp,                       --                          .usb0_stp
			hps_io_usb0_dir                       => CONNECTED_TO_hps_io_usb0_dir,                       --                          .usb0_dir
			hps_io_usb0_data0                     => CONNECTED_TO_hps_io_usb0_data0,                     --                          .usb0_data0
			hps_io_usb0_data1                     => CONNECTED_TO_hps_io_usb0_data1,                     --                          .usb0_data1
			hps_io_usb0_nxt                       => CONNECTED_TO_hps_io_usb0_nxt,                       --                          .usb0_nxt
			hps_io_usb0_data2                     => CONNECTED_TO_hps_io_usb0_data2,                     --                          .usb0_data2
			hps_io_usb0_data3                     => CONNECTED_TO_hps_io_usb0_data3,                     --                          .usb0_data3
			hps_io_usb0_data4                     => CONNECTED_TO_hps_io_usb0_data4,                     --                          .usb0_data4
			hps_io_usb0_data5                     => CONNECTED_TO_hps_io_usb0_data5,                     --                          .usb0_data5
			hps_io_usb0_data6                     => CONNECTED_TO_hps_io_usb0_data6,                     --                          .usb0_data6
			hps_io_usb0_data7                     => CONNECTED_TO_hps_io_usb0_data7,                     --                          .usb0_data7
			hps_io_emac0_tx_clk                   => CONNECTED_TO_hps_io_emac0_tx_clk,                   --                          .emac0_tx_clk
			hps_io_emac0_tx_ctl                   => CONNECTED_TO_hps_io_emac0_tx_ctl,                   --                          .emac0_tx_ctl
			hps_io_emac0_rx_clk                   => CONNECTED_TO_hps_io_emac0_rx_clk,                   --                          .emac0_rx_clk
			hps_io_emac0_rx_ctl                   => CONNECTED_TO_hps_io_emac0_rx_ctl,                   --                          .emac0_rx_ctl
			hps_io_emac0_txd0                     => CONNECTED_TO_hps_io_emac0_txd0,                     --                          .emac0_txd0
			hps_io_emac0_txd1                     => CONNECTED_TO_hps_io_emac0_txd1,                     --                          .emac0_txd1
			hps_io_emac0_rxd0                     => CONNECTED_TO_hps_io_emac0_rxd0,                     --                          .emac0_rxd0
			hps_io_emac0_rxd1                     => CONNECTED_TO_hps_io_emac0_rxd1,                     --                          .emac0_rxd1
			hps_io_emac0_txd2                     => CONNECTED_TO_hps_io_emac0_txd2,                     --                          .emac0_txd2
			hps_io_emac0_txd3                     => CONNECTED_TO_hps_io_emac0_txd3,                     --                          .emac0_txd3
			hps_io_emac0_rxd2                     => CONNECTED_TO_hps_io_emac0_rxd2,                     --                          .emac0_rxd2
			hps_io_emac0_rxd3                     => CONNECTED_TO_hps_io_emac0_rxd3,                     --                          .emac0_rxd3
			hps_io_mdio0_mdio                     => CONNECTED_TO_hps_io_mdio0_mdio,                     --                          .mdio0_mdio
			hps_io_mdio0_mdc                      => CONNECTED_TO_hps_io_mdio0_mdc,                      --                          .mdio0_mdc
			hps_io_spim0_clk                      => CONNECTED_TO_hps_io_spim0_clk,                      --                          .spim0_clk
			hps_io_spim0_mosi                     => CONNECTED_TO_hps_io_spim0_mosi,                     --                          .spim0_mosi
			hps_io_spim0_ss0_n                    => CONNECTED_TO_hps_io_spim0_ss0_n,                    --                          .spim0_ss0_n
			hps_io_uart1_tx                       => CONNECTED_TO_hps_io_uart1_tx,                       --                          .uart1_tx
			hps_io_uart1_rx                       => CONNECTED_TO_hps_io_uart1_rx,                       --                          .uart1_rx
			hps_io_i2c1_sda                       => CONNECTED_TO_hps_io_i2c1_sda,                       --                          .i2c1_sda
			hps_io_i2c1_scl                       => CONNECTED_TO_hps_io_i2c1_scl,                       --                          .i2c1_scl
			hps_io_gpio28                         => CONNECTED_TO_hps_io_gpio28,                         --                          .gpio28
			hps_io_gpio32                         => CONNECTED_TO_hps_io_gpio32,                         --                          .gpio32
			hps_io_gpio33                         => CONNECTED_TO_hps_io_gpio33,                         --                          .gpio33
			hps_io_gpio34                         => CONNECTED_TO_hps_io_gpio34,                         --                          .gpio34
			hps_io_gpio35                         => CONNECTED_TO_hps_io_gpio35,                         --                          .gpio35
			hps_io_gpio40                         => CONNECTED_TO_hps_io_gpio40,                         --                          .gpio40
			hps_io_gpio41                         => CONNECTED_TO_hps_io_gpio41,                         --                          .gpio41
			hps_io_gpio42                         => CONNECTED_TO_hps_io_gpio42,                         --                          .gpio42
			f2h_irq1_in_irq                       => CONNECTED_TO_f2h_irq1_in_irq,                       --               f2h_irq1_in.irq
			f2h_irq0_in_irq                       => CONNECTED_TO_f2h_irq0_in_irq,                       --               f2h_irq0_in.irq
			f2sdram_clk_clk                       => CONNECTED_TO_f2sdram_clk_clk,                       --               f2sdram_clk.clk
			f2sdram_rst_reset                     => CONNECTED_TO_f2sdram_rst_reset,                     --               f2sdram_rst.reset
			fpga2hps_clk_clk                      => CONNECTED_TO_fpga2hps_clk_clk,                      --              fpga2hps_clk.clk
			fpga2hps_rst_reset                    => CONNECTED_TO_fpga2hps_rst_reset,                    --              fpga2hps_rst.reset
			fpga2hps_awid                         => CONNECTED_TO_fpga2hps_awid,                         --                  fpga2hps.awid
			fpga2hps_awaddr                       => CONNECTED_TO_fpga2hps_awaddr,                       --                          .awaddr
			fpga2hps_awdomain                     => CONNECTED_TO_fpga2hps_awdomain,                     --                          .awdomain
			fpga2hps_awsnoop                      => CONNECTED_TO_fpga2hps_awsnoop,                      --                          .awsnoop
			fpga2hps_awlen                        => CONNECTED_TO_fpga2hps_awlen,                        --                          .awlen
			fpga2hps_awsize                       => CONNECTED_TO_fpga2hps_awsize,                       --                          .awsize
			fpga2hps_arsize                       => CONNECTED_TO_fpga2hps_arsize,                       --                          .arsize
			fpga2hps_awburst                      => CONNECTED_TO_fpga2hps_awburst,                      --                          .awburst
			fpga2hps_awlock                       => CONNECTED_TO_fpga2hps_awlock,                       --                          .awlock
			fpga2hps_awcache                      => CONNECTED_TO_fpga2hps_awcache,                      --                          .awcache
			fpga2hps_awprot                       => CONNECTED_TO_fpga2hps_awprot,                       --                          .awprot
			fpga2hps_awqos                        => CONNECTED_TO_fpga2hps_awqos,                        --                          .awqos
			fpga2hps_awvalid                      => CONNECTED_TO_fpga2hps_awvalid,                      --                          .awvalid
			fpga2hps_awready                      => CONNECTED_TO_fpga2hps_awready,                      --                          .awready
			fpga2hps_wdata                        => CONNECTED_TO_fpga2hps_wdata,                        --                          .wdata
			fpga2hps_wstrb                        => CONNECTED_TO_fpga2hps_wstrb,                        --                          .wstrb
			fpga2hps_wlast                        => CONNECTED_TO_fpga2hps_wlast,                        --                          .wlast
			fpga2hps_wvalid                       => CONNECTED_TO_fpga2hps_wvalid,                       --                          .wvalid
			fpga2hps_wready                       => CONNECTED_TO_fpga2hps_wready,                       --                          .wready
			fpga2hps_awstashnid                   => CONNECTED_TO_fpga2hps_awstashnid,                   --                          .awstashnid
			fpga2hps_awstashniden                 => CONNECTED_TO_fpga2hps_awstashniden,                 --                          .awstashniden
			fpga2hps_awstashlpid                  => CONNECTED_TO_fpga2hps_awstashlpid,                  --                          .awstashlpid
			fpga2hps_awstashlpiden                => CONNECTED_TO_fpga2hps_awstashlpiden,                --                          .awstashlpiden
			fpga2hps_awatop                       => CONNECTED_TO_fpga2hps_awatop,                       --                          .awatop
			fpga2hps_bid                          => CONNECTED_TO_fpga2hps_bid,                          --                          .bid
			fpga2hps_bresp                        => CONNECTED_TO_fpga2hps_bresp,                        --                          .bresp
			fpga2hps_bvalid                       => CONNECTED_TO_fpga2hps_bvalid,                       --                          .bvalid
			fpga2hps_bready                       => CONNECTED_TO_fpga2hps_bready,                       --                          .bready
			fpga2hps_arid                         => CONNECTED_TO_fpga2hps_arid,                         --                          .arid
			fpga2hps_araddr                       => CONNECTED_TO_fpga2hps_araddr,                       --                          .araddr
			fpga2hps_ardomain                     => CONNECTED_TO_fpga2hps_ardomain,                     --                          .ardomain
			fpga2hps_arsnoop                      => CONNECTED_TO_fpga2hps_arsnoop,                      --                          .arsnoop
			fpga2hps_arlen                        => CONNECTED_TO_fpga2hps_arlen,                        --                          .arlen
			fpga2hps_arburst                      => CONNECTED_TO_fpga2hps_arburst,                      --                          .arburst
			fpga2hps_arlock                       => CONNECTED_TO_fpga2hps_arlock,                       --                          .arlock
			fpga2hps_arcache                      => CONNECTED_TO_fpga2hps_arcache,                      --                          .arcache
			fpga2hps_arprot                       => CONNECTED_TO_fpga2hps_arprot,                       --                          .arprot
			fpga2hps_arqos                        => CONNECTED_TO_fpga2hps_arqos,                        --                          .arqos
			fpga2hps_arvalid                      => CONNECTED_TO_fpga2hps_arvalid,                      --                          .arvalid
			fpga2hps_arready                      => CONNECTED_TO_fpga2hps_arready,                      --                          .arready
			fpga2hps_rid                          => CONNECTED_TO_fpga2hps_rid,                          --                          .rid
			fpga2hps_rdata                        => CONNECTED_TO_fpga2hps_rdata,                        --                          .rdata
			fpga2hps_rresp                        => CONNECTED_TO_fpga2hps_rresp,                        --                          .rresp
			fpga2hps_rlast                        => CONNECTED_TO_fpga2hps_rlast,                        --                          .rlast
			fpga2hps_rvalid                       => CONNECTED_TO_fpga2hps_rvalid,                       --                          .rvalid
			fpga2hps_rready                       => CONNECTED_TO_fpga2hps_rready,                       --                          .rready
			fpga2hps_aruser                       => CONNECTED_TO_fpga2hps_aruser,                       --                          .aruser
			fpga2hps_awuser                       => CONNECTED_TO_fpga2hps_awuser,                       --                          .awuser
			fpga2hps_arregion                     => CONNECTED_TO_fpga2hps_arregion,                     --                          .arregion
			fpga2hps_awregion                     => CONNECTED_TO_fpga2hps_awregion,                     --                          .awregion
			fpga2hps_wuser                        => CONNECTED_TO_fpga2hps_wuser,                        --                          .wuser
			fpga2hps_buser                        => CONNECTED_TO_fpga2hps_buser,                        --                          .buser
			fpga2hps_ruser                        => CONNECTED_TO_fpga2hps_ruser,                        --                          .ruser
			emif_hps_emif_mem_0_mem_cke           => CONNECTED_TO_emif_hps_emif_mem_0_mem_cke,           --       emif_hps_emif_mem_0.mem_cke
			emif_hps_emif_mem_0_mem_odt           => CONNECTED_TO_emif_hps_emif_mem_0_mem_odt,           --                          .mem_odt
			emif_hps_emif_mem_0_mem_cs_n          => CONNECTED_TO_emif_hps_emif_mem_0_mem_cs_n,          --                          .mem_cs_n
			emif_hps_emif_mem_0_mem_a             => CONNECTED_TO_emif_hps_emif_mem_0_mem_a,             --                          .mem_a
			emif_hps_emif_mem_0_mem_ba            => CONNECTED_TO_emif_hps_emif_mem_0_mem_ba,            --                          .mem_ba
			emif_hps_emif_mem_0_mem_bg            => CONNECTED_TO_emif_hps_emif_mem_0_mem_bg,            --                          .mem_bg
			emif_hps_emif_mem_0_mem_act_n         => CONNECTED_TO_emif_hps_emif_mem_0_mem_act_n,         --                          .mem_act_n
			emif_hps_emif_mem_0_mem_par           => CONNECTED_TO_emif_hps_emif_mem_0_mem_par,           --                          .mem_par
			emif_hps_emif_mem_0_mem_dq            => CONNECTED_TO_emif_hps_emif_mem_0_mem_dq,            --                          .mem_dq
			emif_hps_emif_mem_0_mem_dqs_t         => CONNECTED_TO_emif_hps_emif_mem_0_mem_dqs_t,         --                          .mem_dqs_t
			emif_hps_emif_mem_0_mem_dqs_c         => CONNECTED_TO_emif_hps_emif_mem_0_mem_dqs_c,         --                          .mem_dqs_c
			emif_hps_emif_mem_0_mem_alert_n       => CONNECTED_TO_emif_hps_emif_mem_0_mem_alert_n,       --                          .mem_alert_n
			emif_hps_emif_mem_0_mem_dbi_n         => CONNECTED_TO_emif_hps_emif_mem_0_mem_dbi_n,         --                          .mem_dbi_n
			emif_hps_emif_mem_ck_0_mem_ck_t       => CONNECTED_TO_emif_hps_emif_mem_ck_0_mem_ck_t,       --    emif_hps_emif_mem_ck_0.mem_ck_t
			emif_hps_emif_mem_ck_0_mem_ck_c       => CONNECTED_TO_emif_hps_emif_mem_ck_0_mem_ck_c,       --                          .mem_ck_c
			emif_hps_emif_mem_reset_n_mem_reset_n => CONNECTED_TO_emif_hps_emif_mem_reset_n_mem_reset_n, -- emif_hps_emif_mem_reset_n.mem_reset_n
			emif_hps_emif_oct_0_oct_rzqin         => CONNECTED_TO_emif_hps_emif_oct_0_oct_rzqin,         --       emif_hps_emif_oct_0.oct_rzqin
			emif_hps_emif_ref_clk_clk             => CONNECTED_TO_emif_hps_emif_ref_clk_clk,             --     emif_hps_emif_ref_clk.clk
			f2sdram_adapter_clk_clk               => CONNECTED_TO_f2sdram_adapter_clk_clk,               --       f2sdram_adapter_clk.clk
			f2sdram_adapter_rst_reset             => CONNECTED_TO_f2sdram_adapter_rst_reset,             --       f2sdram_adapter_rst.reset
			f2sdram_adapter_axi4_sub_araddr       => CONNECTED_TO_f2sdram_adapter_axi4_sub_araddr,       --  f2sdram_adapter_axi4_sub.araddr
			f2sdram_adapter_axi4_sub_arburst      => CONNECTED_TO_f2sdram_adapter_axi4_sub_arburst,      --                          .arburst
			f2sdram_adapter_axi4_sub_arcache      => CONNECTED_TO_f2sdram_adapter_axi4_sub_arcache,      --                          .arcache
			f2sdram_adapter_axi4_sub_arid         => CONNECTED_TO_f2sdram_adapter_axi4_sub_arid,         --                          .arid
			f2sdram_adapter_axi4_sub_arlen        => CONNECTED_TO_f2sdram_adapter_axi4_sub_arlen,        --                          .arlen
			f2sdram_adapter_axi4_sub_arlock       => CONNECTED_TO_f2sdram_adapter_axi4_sub_arlock,       --                          .arlock
			f2sdram_adapter_axi4_sub_arprot       => CONNECTED_TO_f2sdram_adapter_axi4_sub_arprot,       --                          .arprot
			f2sdram_adapter_axi4_sub_arqos        => CONNECTED_TO_f2sdram_adapter_axi4_sub_arqos,        --                          .arqos
			f2sdram_adapter_axi4_sub_arready      => CONNECTED_TO_f2sdram_adapter_axi4_sub_arready,      --                          .arready
			f2sdram_adapter_axi4_sub_arsize       => CONNECTED_TO_f2sdram_adapter_axi4_sub_arsize,       --                          .arsize
			f2sdram_adapter_axi4_sub_arvalid      => CONNECTED_TO_f2sdram_adapter_axi4_sub_arvalid,      --                          .arvalid
			f2sdram_adapter_axi4_sub_awaddr       => CONNECTED_TO_f2sdram_adapter_axi4_sub_awaddr,       --                          .awaddr
			f2sdram_adapter_axi4_sub_awburst      => CONNECTED_TO_f2sdram_adapter_axi4_sub_awburst,      --                          .awburst
			f2sdram_adapter_axi4_sub_awcache      => CONNECTED_TO_f2sdram_adapter_axi4_sub_awcache,      --                          .awcache
			f2sdram_adapter_axi4_sub_awid         => CONNECTED_TO_f2sdram_adapter_axi4_sub_awid,         --                          .awid
			f2sdram_adapter_axi4_sub_awlen        => CONNECTED_TO_f2sdram_adapter_axi4_sub_awlen,        --                          .awlen
			f2sdram_adapter_axi4_sub_awlock       => CONNECTED_TO_f2sdram_adapter_axi4_sub_awlock,       --                          .awlock
			f2sdram_adapter_axi4_sub_awprot       => CONNECTED_TO_f2sdram_adapter_axi4_sub_awprot,       --                          .awprot
			f2sdram_adapter_axi4_sub_awqos        => CONNECTED_TO_f2sdram_adapter_axi4_sub_awqos,        --                          .awqos
			f2sdram_adapter_axi4_sub_awready      => CONNECTED_TO_f2sdram_adapter_axi4_sub_awready,      --                          .awready
			f2sdram_adapter_axi4_sub_awsize       => CONNECTED_TO_f2sdram_adapter_axi4_sub_awsize,       --                          .awsize
			f2sdram_adapter_axi4_sub_awvalid      => CONNECTED_TO_f2sdram_adapter_axi4_sub_awvalid,      --                          .awvalid
			f2sdram_adapter_axi4_sub_bid          => CONNECTED_TO_f2sdram_adapter_axi4_sub_bid,          --                          .bid
			f2sdram_adapter_axi4_sub_bready       => CONNECTED_TO_f2sdram_adapter_axi4_sub_bready,       --                          .bready
			f2sdram_adapter_axi4_sub_bresp        => CONNECTED_TO_f2sdram_adapter_axi4_sub_bresp,        --                          .bresp
			f2sdram_adapter_axi4_sub_bvalid       => CONNECTED_TO_f2sdram_adapter_axi4_sub_bvalid,       --                          .bvalid
			f2sdram_adapter_axi4_sub_rdata        => CONNECTED_TO_f2sdram_adapter_axi4_sub_rdata,        --                          .rdata
			f2sdram_adapter_axi4_sub_rid          => CONNECTED_TO_f2sdram_adapter_axi4_sub_rid,          --                          .rid
			f2sdram_adapter_axi4_sub_rlast        => CONNECTED_TO_f2sdram_adapter_axi4_sub_rlast,        --                          .rlast
			f2sdram_adapter_axi4_sub_rready       => CONNECTED_TO_f2sdram_adapter_axi4_sub_rready,       --                          .rready
			f2sdram_adapter_axi4_sub_rresp        => CONNECTED_TO_f2sdram_adapter_axi4_sub_rresp,        --                          .rresp
			f2sdram_adapter_axi4_sub_rvalid       => CONNECTED_TO_f2sdram_adapter_axi4_sub_rvalid,       --                          .rvalid
			f2sdram_adapter_axi4_sub_wdata        => CONNECTED_TO_f2sdram_adapter_axi4_sub_wdata,        --                          .wdata
			f2sdram_adapter_axi4_sub_wlast        => CONNECTED_TO_f2sdram_adapter_axi4_sub_wlast,        --                          .wlast
			f2sdram_adapter_axi4_sub_wready       => CONNECTED_TO_f2sdram_adapter_axi4_sub_wready,       --                          .wready
			f2sdram_adapter_axi4_sub_wstrb        => CONNECTED_TO_f2sdram_adapter_axi4_sub_wstrb,        --                          .wstrb
			f2sdram_adapter_axi4_sub_wvalid       => CONNECTED_TO_f2sdram_adapter_axi4_sub_wvalid,       --                          .wvalid
			f2sdram_adapter_axi4_sub_aruser       => CONNECTED_TO_f2sdram_adapter_axi4_sub_aruser,       --                          .aruser
			f2sdram_adapter_axi4_sub_awuser       => CONNECTED_TO_f2sdram_adapter_axi4_sub_awuser,       --                          .awuser
			f2sdram_adapter_axi4_sub_wuser        => CONNECTED_TO_f2sdram_adapter_axi4_sub_wuser,        --                          .wuser
			f2sdram_adapter_axi4_sub_buser        => CONNECTED_TO_f2sdram_adapter_axi4_sub_buser,        --                          .buser
			f2sdram_adapter_axi4_sub_arregion     => CONNECTED_TO_f2sdram_adapter_axi4_sub_arregion,     --                          .arregion
			f2sdram_adapter_axi4_sub_ruser        => CONNECTED_TO_f2sdram_adapter_axi4_sub_ruser,        --                          .ruser
			f2sdram_adapter_axi4_sub_awregion     => CONNECTED_TO_f2sdram_adapter_axi4_sub_awregion      --                          .awregion
		);

