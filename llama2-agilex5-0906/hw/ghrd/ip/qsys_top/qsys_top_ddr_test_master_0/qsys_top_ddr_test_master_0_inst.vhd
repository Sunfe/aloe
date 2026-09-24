	component qsys_top_ddr_test_master_0 is
		port (
			csr_clk     : in  std_logic                      := 'X';             -- clk
			csr_rst     : in  std_logic                      := 'X';             -- reset
			csr_awaddr  : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- awaddr
			csr_awprot  : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- awprot
			csr_awvalid : in  std_logic                      := 'X';             -- awvalid
			csr_awready : out std_logic;                                         -- awready
			csr_wdata   : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- wdata
			csr_wstrb   : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- wstrb
			csr_wvalid  : in  std_logic                      := 'X';             -- wvalid
			csr_wready  : out std_logic;                                         -- wready
			csr_bresp   : out std_logic_vector(1 downto 0);                      -- bresp
			csr_bvalid  : out std_logic;                                         -- bvalid
			csr_bready  : in  std_logic                      := 'X';             -- bready
			csr_araddr  : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- araddr
			csr_arprot  : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- arprot
			csr_arvalid : in  std_logic                      := 'X';             -- arvalid
			csr_arready : out std_logic;                                         -- arready
			csr_rdata   : out std_logic_vector(31 downto 0);                     -- rdata
			csr_rresp   : out std_logic_vector(1 downto 0);                      -- rresp
			csr_rvalid  : out std_logic;                                         -- rvalid
			csr_rready  : in  std_logic                      := 'X';             -- rready
			axi_clk     : in  std_logic                      := 'X';             -- clk
			axi_rst     : in  std_logic                      := 'X';             -- reset
			axi_awid    : out std_logic_vector(7 downto 0);                      -- awid
			axi_awaddr  : out std_logic_vector(63 downto 0);                     -- awaddr
			axi_awlen   : out std_logic_vector(7 downto 0);                      -- awlen
			axi_awsize  : out std_logic_vector(2 downto 0);                      -- awsize
			axi_awburst : out std_logic_vector(1 downto 0);                      -- awburst
			axi_awlock  : out std_logic;                                         -- awlock
			axi_awcache : out std_logic_vector(3 downto 0);                      -- awcache
			axi_awprot  : out std_logic_vector(2 downto 0);                      -- awprot
			axi_awqos   : out std_logic_vector(3 downto 0);                      -- awqos
			axi_awvalid : out std_logic;                                         -- awvalid
			axi_awready : in  std_logic                      := 'X';             -- awready
			axi_wdata   : out std_logic_vector(127 downto 0);                    -- wdata
			axi_wstrb   : out std_logic_vector(15 downto 0);                     -- wstrb
			axi_wlast   : out std_logic;                                         -- wlast
			axi_wvalid  : out std_logic;                                         -- wvalid
			axi_wready  : in  std_logic                      := 'X';             -- wready
			axi_bid     : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- bid
			axi_bresp   : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- bresp
			axi_bvalid  : in  std_logic                      := 'X';             -- bvalid
			axi_bready  : out std_logic;                                         -- bready
			axi_arid    : out std_logic_vector(7 downto 0);                      -- arid
			axi_araddr  : out std_logic_vector(63 downto 0);                     -- araddr
			axi_arlen   : out std_logic_vector(7 downto 0);                      -- arlen
			axi_arsize  : out std_logic_vector(2 downto 0);                      -- arsize
			axi_arburst : out std_logic_vector(1 downto 0);                      -- arburst
			axi_arlock  : out std_logic;                                         -- arlock
			axi_arcache : out std_logic_vector(3 downto 0);                      -- arcache
			axi_arprot  : out std_logic_vector(2 downto 0);                      -- arprot
			axi_arqos   : out std_logic_vector(3 downto 0);                      -- arqos
			axi_arvalid : out std_logic;                                         -- arvalid
			axi_arready : in  std_logic                      := 'X';             -- arready
			axi_rid     : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rid
			axi_rdata   : in  std_logic_vector(127 downto 0) := (others => 'X'); -- rdata
			axi_rresp   : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- rresp
			axi_rlast   : in  std_logic                      := 'X';             -- rlast
			axi_rvalid  : in  std_logic                      := 'X';             -- rvalid
			axi_rready  : out std_logic                                          -- rready
		);
	end component qsys_top_ddr_test_master_0;

	u0 : component qsys_top_ddr_test_master_0
		port map (
			csr_clk     => CONNECTED_TO_csr_clk,     --    csr_clk.clk
			csr_rst     => CONNECTED_TO_csr_rst,     --    csr_rst.reset
			csr_awaddr  => CONNECTED_TO_csr_awaddr,  --  csr_slave.awaddr
			csr_awprot  => CONNECTED_TO_csr_awprot,  --           .awprot
			csr_awvalid => CONNECTED_TO_csr_awvalid, --           .awvalid
			csr_awready => CONNECTED_TO_csr_awready, --           .awready
			csr_wdata   => CONNECTED_TO_csr_wdata,   --           .wdata
			csr_wstrb   => CONNECTED_TO_csr_wstrb,   --           .wstrb
			csr_wvalid  => CONNECTED_TO_csr_wvalid,  --           .wvalid
			csr_wready  => CONNECTED_TO_csr_wready,  --           .wready
			csr_bresp   => CONNECTED_TO_csr_bresp,   --           .bresp
			csr_bvalid  => CONNECTED_TO_csr_bvalid,  --           .bvalid
			csr_bready  => CONNECTED_TO_csr_bready,  --           .bready
			csr_araddr  => CONNECTED_TO_csr_araddr,  --           .araddr
			csr_arprot  => CONNECTED_TO_csr_arprot,  --           .arprot
			csr_arvalid => CONNECTED_TO_csr_arvalid, --           .arvalid
			csr_arready => CONNECTED_TO_csr_arready, --           .arready
			csr_rdata   => CONNECTED_TO_csr_rdata,   --           .rdata
			csr_rresp   => CONNECTED_TO_csr_rresp,   --           .rresp
			csr_rvalid  => CONNECTED_TO_csr_rvalid,  --           .rvalid
			csr_rready  => CONNECTED_TO_csr_rready,  --           .rready
			axi_clk     => CONNECTED_TO_axi_clk,     --    axi_clk.clk
			axi_rst     => CONNECTED_TO_axi_rst,     --    axi_rst.reset
			axi_awid    => CONNECTED_TO_axi_awid,    -- axi_master.awid
			axi_awaddr  => CONNECTED_TO_axi_awaddr,  --           .awaddr
			axi_awlen   => CONNECTED_TO_axi_awlen,   --           .awlen
			axi_awsize  => CONNECTED_TO_axi_awsize,  --           .awsize
			axi_awburst => CONNECTED_TO_axi_awburst, --           .awburst
			axi_awlock  => CONNECTED_TO_axi_awlock,  --           .awlock
			axi_awcache => CONNECTED_TO_axi_awcache, --           .awcache
			axi_awprot  => CONNECTED_TO_axi_awprot,  --           .awprot
			axi_awqos   => CONNECTED_TO_axi_awqos,   --           .awqos
			axi_awvalid => CONNECTED_TO_axi_awvalid, --           .awvalid
			axi_awready => CONNECTED_TO_axi_awready, --           .awready
			axi_wdata   => CONNECTED_TO_axi_wdata,   --           .wdata
			axi_wstrb   => CONNECTED_TO_axi_wstrb,   --           .wstrb
			axi_wlast   => CONNECTED_TO_axi_wlast,   --           .wlast
			axi_wvalid  => CONNECTED_TO_axi_wvalid,  --           .wvalid
			axi_wready  => CONNECTED_TO_axi_wready,  --           .wready
			axi_bid     => CONNECTED_TO_axi_bid,     --           .bid
			axi_bresp   => CONNECTED_TO_axi_bresp,   --           .bresp
			axi_bvalid  => CONNECTED_TO_axi_bvalid,  --           .bvalid
			axi_bready  => CONNECTED_TO_axi_bready,  --           .bready
			axi_arid    => CONNECTED_TO_axi_arid,    --           .arid
			axi_araddr  => CONNECTED_TO_axi_araddr,  --           .araddr
			axi_arlen   => CONNECTED_TO_axi_arlen,   --           .arlen
			axi_arsize  => CONNECTED_TO_axi_arsize,  --           .arsize
			axi_arburst => CONNECTED_TO_axi_arburst, --           .arburst
			axi_arlock  => CONNECTED_TO_axi_arlock,  --           .arlock
			axi_arcache => CONNECTED_TO_axi_arcache, --           .arcache
			axi_arprot  => CONNECTED_TO_axi_arprot,  --           .arprot
			axi_arqos   => CONNECTED_TO_axi_arqos,   --           .arqos
			axi_arvalid => CONNECTED_TO_axi_arvalid, --           .arvalid
			axi_arready => CONNECTED_TO_axi_arready, --           .arready
			axi_rid     => CONNECTED_TO_axi_rid,     --           .rid
			axi_rdata   => CONNECTED_TO_axi_rdata,   --           .rdata
			axi_rresp   => CONNECTED_TO_axi_rresp,   --           .rresp
			axi_rlast   => CONNECTED_TO_axi_rlast,   --           .rlast
			axi_rvalid  => CONNECTED_TO_axi_rvalid,  --           .rvalid
			axi_rready  => CONNECTED_TO_axi_rready   --           .rready
		);

