	component f2sdram_adapter is
		port (
			clk          : in  std_logic                      := 'X';             -- clk
			reset        : in  std_logic                      := 'X';             -- reset
			man_araddr   : out std_logic_vector(31 downto 0);                     -- araddr
			man_arburst  : out std_logic_vector(1 downto 0);                      -- arburst
			man_arcache  : out std_logic_vector(3 downto 0);                      -- arcache
			man_arid     : out std_logic_vector(4 downto 0);                      -- arid
			man_arlen    : out std_logic_vector(7 downto 0);                      -- arlen
			man_arlock   : out std_logic;                                         -- arlock
			man_arprot   : out std_logic_vector(2 downto 0);                      -- arprot
			man_arqos    : out std_logic_vector(3 downto 0);                      -- arqos
			man_arready  : in  std_logic                      := 'X';             -- arready
			man_arsize   : out std_logic_vector(2 downto 0);                      -- arsize
			man_arvalid  : out std_logic;                                         -- arvalid
			man_awaddr   : out std_logic_vector(31 downto 0);                     -- awaddr
			man_awburst  : out std_logic_vector(1 downto 0);                      -- awburst
			man_awcache  : out std_logic_vector(3 downto 0);                      -- awcache
			man_awid     : out std_logic_vector(4 downto 0);                      -- awid
			man_awlen    : out std_logic_vector(7 downto 0);                      -- awlen
			man_awlock   : out std_logic;                                         -- awlock
			man_awprot   : out std_logic_vector(2 downto 0);                      -- awprot
			man_awqos    : out std_logic_vector(3 downto 0);                      -- awqos
			man_awready  : in  std_logic                      := 'X';             -- awready
			man_awsize   : out std_logic_vector(2 downto 0);                      -- awsize
			man_awvalid  : out std_logic;                                         -- awvalid
			man_bid      : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- bid
			man_bready   : out std_logic;                                         -- bready
			man_bresp    : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- bresp
			man_bvalid   : in  std_logic                      := 'X';             -- bvalid
			man_rdata    : in  std_logic_vector(255 downto 0) := (others => 'X'); -- rdata
			man_rid      : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- rid
			man_rlast    : in  std_logic                      := 'X';             -- rlast
			man_rready   : out std_logic;                                         -- rready
			man_rresp    : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- rresp
			man_rvalid   : in  std_logic                      := 'X';             -- rvalid
			man_wdata    : out std_logic_vector(255 downto 0);                    -- wdata
			man_wlast    : out std_logic;                                         -- wlast
			man_wready   : in  std_logic                      := 'X';             -- wready
			man_wstrb    : out std_logic_vector(31 downto 0);                     -- wstrb
			man_wvalid   : out std_logic;                                         -- wvalid
			man_aruser   : out std_logic_vector(7 downto 0);                      -- aruser
			man_awuser   : out std_logic_vector(7 downto 0);                      -- awuser
			man_wuser    : out std_logic_vector(7 downto 0);                      -- wuser
			man_buser    : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- buser
			man_arregion : out std_logic_vector(3 downto 0);                      -- arregion
			man_ruser    : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- ruser
			man_awregion : out std_logic_vector(3 downto 0);                      -- awregion
			sub_araddr   : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- araddr
			sub_arburst  : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- arburst
			sub_arcache  : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arcache
			sub_arid     : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- arid
			sub_arlen    : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- arlen
			sub_arlock   : in  std_logic                      := 'X';             -- arlock
			sub_arprot   : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- arprot
			sub_arqos    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arqos
			sub_arready  : out std_logic;                                         -- arready
			sub_arsize   : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- arsize
			sub_arvalid  : in  std_logic                      := 'X';             -- arvalid
			sub_awaddr   : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- awaddr
			sub_awburst  : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- awburst
			sub_awcache  : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- awcache
			sub_awid     : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- awid
			sub_awlen    : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- awlen
			sub_awlock   : in  std_logic                      := 'X';             -- awlock
			sub_awprot   : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- awprot
			sub_awqos    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- awqos
			sub_awready  : out std_logic;                                         -- awready
			sub_awsize   : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- awsize
			sub_awvalid  : in  std_logic                      := 'X';             -- awvalid
			sub_bid      : out std_logic_vector(4 downto 0);                      -- bid
			sub_bready   : in  std_logic                      := 'X';             -- bready
			sub_bresp    : out std_logic_vector(1 downto 0);                      -- bresp
			sub_bvalid   : out std_logic;                                         -- bvalid
			sub_rdata    : out std_logic_vector(255 downto 0);                    -- rdata
			sub_rid      : out std_logic_vector(4 downto 0);                      -- rid
			sub_rlast    : out std_logic;                                         -- rlast
			sub_rready   : in  std_logic                      := 'X';             -- rready
			sub_rresp    : out std_logic_vector(1 downto 0);                      -- rresp
			sub_rvalid   : out std_logic;                                         -- rvalid
			sub_wdata    : in  std_logic_vector(255 downto 0) := (others => 'X'); -- wdata
			sub_wlast    : in  std_logic                      := 'X';             -- wlast
			sub_wready   : out std_logic;                                         -- wready
			sub_wstrb    : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- wstrb
			sub_wvalid   : in  std_logic                      := 'X';             -- wvalid
			sub_aruser   : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- aruser
			sub_awuser   : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- awuser
			sub_wuser    : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- wuser
			sub_buser    : out std_logic_vector(7 downto 0);                      -- buser
			sub_arregion : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arregion
			sub_ruser    : out std_logic_vector(7 downto 0);                      -- ruser
			sub_awregion : in  std_logic_vector(3 downto 0)   := (others => 'X')  -- awregion
		);
	end component f2sdram_adapter;

	u0 : component f2sdram_adapter
		port map (
			clk          => CONNECTED_TO_clk,          --    clock.clk
			reset        => CONNECTED_TO_reset,        --    reset.reset
			man_araddr   => CONNECTED_TO_man_araddr,   -- axi4_man.araddr
			man_arburst  => CONNECTED_TO_man_arburst,  --         .arburst
			man_arcache  => CONNECTED_TO_man_arcache,  --         .arcache
			man_arid     => CONNECTED_TO_man_arid,     --         .arid
			man_arlen    => CONNECTED_TO_man_arlen,    --         .arlen
			man_arlock   => CONNECTED_TO_man_arlock,   --         .arlock
			man_arprot   => CONNECTED_TO_man_arprot,   --         .arprot
			man_arqos    => CONNECTED_TO_man_arqos,    --         .arqos
			man_arready  => CONNECTED_TO_man_arready,  --         .arready
			man_arsize   => CONNECTED_TO_man_arsize,   --         .arsize
			man_arvalid  => CONNECTED_TO_man_arvalid,  --         .arvalid
			man_awaddr   => CONNECTED_TO_man_awaddr,   --         .awaddr
			man_awburst  => CONNECTED_TO_man_awburst,  --         .awburst
			man_awcache  => CONNECTED_TO_man_awcache,  --         .awcache
			man_awid     => CONNECTED_TO_man_awid,     --         .awid
			man_awlen    => CONNECTED_TO_man_awlen,    --         .awlen
			man_awlock   => CONNECTED_TO_man_awlock,   --         .awlock
			man_awprot   => CONNECTED_TO_man_awprot,   --         .awprot
			man_awqos    => CONNECTED_TO_man_awqos,    --         .awqos
			man_awready  => CONNECTED_TO_man_awready,  --         .awready
			man_awsize   => CONNECTED_TO_man_awsize,   --         .awsize
			man_awvalid  => CONNECTED_TO_man_awvalid,  --         .awvalid
			man_bid      => CONNECTED_TO_man_bid,      --         .bid
			man_bready   => CONNECTED_TO_man_bready,   --         .bready
			man_bresp    => CONNECTED_TO_man_bresp,    --         .bresp
			man_bvalid   => CONNECTED_TO_man_bvalid,   --         .bvalid
			man_rdata    => CONNECTED_TO_man_rdata,    --         .rdata
			man_rid      => CONNECTED_TO_man_rid,      --         .rid
			man_rlast    => CONNECTED_TO_man_rlast,    --         .rlast
			man_rready   => CONNECTED_TO_man_rready,   --         .rready
			man_rresp    => CONNECTED_TO_man_rresp,    --         .rresp
			man_rvalid   => CONNECTED_TO_man_rvalid,   --         .rvalid
			man_wdata    => CONNECTED_TO_man_wdata,    --         .wdata
			man_wlast    => CONNECTED_TO_man_wlast,    --         .wlast
			man_wready   => CONNECTED_TO_man_wready,   --         .wready
			man_wstrb    => CONNECTED_TO_man_wstrb,    --         .wstrb
			man_wvalid   => CONNECTED_TO_man_wvalid,   --         .wvalid
			man_aruser   => CONNECTED_TO_man_aruser,   --         .aruser
			man_awuser   => CONNECTED_TO_man_awuser,   --         .awuser
			man_wuser    => CONNECTED_TO_man_wuser,    --         .wuser
			man_buser    => CONNECTED_TO_man_buser,    --         .buser
			man_arregion => CONNECTED_TO_man_arregion, --         .arregion
			man_ruser    => CONNECTED_TO_man_ruser,    --         .ruser
			man_awregion => CONNECTED_TO_man_awregion, --         .awregion
			sub_araddr   => CONNECTED_TO_sub_araddr,   -- axi4_sub.araddr
			sub_arburst  => CONNECTED_TO_sub_arburst,  --         .arburst
			sub_arcache  => CONNECTED_TO_sub_arcache,  --         .arcache
			sub_arid     => CONNECTED_TO_sub_arid,     --         .arid
			sub_arlen    => CONNECTED_TO_sub_arlen,    --         .arlen
			sub_arlock   => CONNECTED_TO_sub_arlock,   --         .arlock
			sub_arprot   => CONNECTED_TO_sub_arprot,   --         .arprot
			sub_arqos    => CONNECTED_TO_sub_arqos,    --         .arqos
			sub_arready  => CONNECTED_TO_sub_arready,  --         .arready
			sub_arsize   => CONNECTED_TO_sub_arsize,   --         .arsize
			sub_arvalid  => CONNECTED_TO_sub_arvalid,  --         .arvalid
			sub_awaddr   => CONNECTED_TO_sub_awaddr,   --         .awaddr
			sub_awburst  => CONNECTED_TO_sub_awburst,  --         .awburst
			sub_awcache  => CONNECTED_TO_sub_awcache,  --         .awcache
			sub_awid     => CONNECTED_TO_sub_awid,     --         .awid
			sub_awlen    => CONNECTED_TO_sub_awlen,    --         .awlen
			sub_awlock   => CONNECTED_TO_sub_awlock,   --         .awlock
			sub_awprot   => CONNECTED_TO_sub_awprot,   --         .awprot
			sub_awqos    => CONNECTED_TO_sub_awqos,    --         .awqos
			sub_awready  => CONNECTED_TO_sub_awready,  --         .awready
			sub_awsize   => CONNECTED_TO_sub_awsize,   --         .awsize
			sub_awvalid  => CONNECTED_TO_sub_awvalid,  --         .awvalid
			sub_bid      => CONNECTED_TO_sub_bid,      --         .bid
			sub_bready   => CONNECTED_TO_sub_bready,   --         .bready
			sub_bresp    => CONNECTED_TO_sub_bresp,    --         .bresp
			sub_bvalid   => CONNECTED_TO_sub_bvalid,   --         .bvalid
			sub_rdata    => CONNECTED_TO_sub_rdata,    --         .rdata
			sub_rid      => CONNECTED_TO_sub_rid,      --         .rid
			sub_rlast    => CONNECTED_TO_sub_rlast,    --         .rlast
			sub_rready   => CONNECTED_TO_sub_rready,   --         .rready
			sub_rresp    => CONNECTED_TO_sub_rresp,    --         .rresp
			sub_rvalid   => CONNECTED_TO_sub_rvalid,   --         .rvalid
			sub_wdata    => CONNECTED_TO_sub_wdata,    --         .wdata
			sub_wlast    => CONNECTED_TO_sub_wlast,    --         .wlast
			sub_wready   => CONNECTED_TO_sub_wready,   --         .wready
			sub_wstrb    => CONNECTED_TO_sub_wstrb,    --         .wstrb
			sub_wvalid   => CONNECTED_TO_sub_wvalid,   --         .wvalid
			sub_aruser   => CONNECTED_TO_sub_aruser,   --         .aruser
			sub_awuser   => CONNECTED_TO_sub_awuser,   --         .awuser
			sub_wuser    => CONNECTED_TO_sub_wuser,    --         .wuser
			sub_buser    => CONNECTED_TO_sub_buser,    --         .buser
			sub_arregion => CONNECTED_TO_sub_arregion, --         .arregion
			sub_ruser    => CONNECTED_TO_sub_ruser,    --         .ruser
			sub_awregion => CONNECTED_TO_sub_awregion  --         .awregion
		);

