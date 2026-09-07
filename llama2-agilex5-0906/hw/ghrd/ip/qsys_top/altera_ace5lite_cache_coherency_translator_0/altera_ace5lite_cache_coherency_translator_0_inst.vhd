	component altera_ace5lite_cache_coherency_translator_0 is
		generic (
			WSTRB_WIDTH : integer := 32;
			USER_WIDTH  : integer := 8
		);
		port (
			clk                      : in  std_logic                      := 'X';             -- clk
			reset                    : in  std_logic                      := 'X';             -- reset
			m_ace5lite_awid          : out std_logic_vector(4 downto 0);                      -- awid
			m_ace5lite_awaddr        : out std_logic_vector(31 downto 0);                     -- awaddr
			m_ace5lite_awdomain      : out std_logic_vector(1 downto 0);                      -- awdomain
			m_ace5lite_awsnoop       : out std_logic_vector(3 downto 0);                      -- awsnoop
			m_ace5lite_awlen         : out std_logic_vector(7 downto 0);                      -- awlen
			m_ace5lite_awsize        : out std_logic_vector(2 downto 0);                      -- awsize
			m_ace5lite_arsize        : out std_logic_vector(2 downto 0);                      -- arsize
			m_ace5lite_awburst       : out std_logic_vector(1 downto 0);                      -- awburst
			m_ace5lite_awlock        : out std_logic;                                         -- awlock
			m_ace5lite_awcache       : out std_logic_vector(3 downto 0);                      -- awcache
			m_ace5lite_awprot        : out std_logic_vector(2 downto 0);                      -- awprot
			m_ace5lite_awqos         : out std_logic_vector(3 downto 0);                      -- awqos
			m_ace5lite_awstashnid    : out std_logic_vector(10 downto 0);                     -- awstashnid
			m_ace5lite_awstashniden  : out std_logic;                                         -- awstashniden
			m_ace5lite_awstashlpid   : out std_logic_vector(4 downto 0);                      -- awstashlpid
			m_ace5lite_awstashlpiden : out std_logic;                                         -- awstashlpiden
			m_ace5lite_awatop        : out std_logic_vector(5 downto 0);                      -- awatop
			m_ace5lite_awvalid       : out std_logic;                                         -- awvalid
			m_ace5lite_awready       : in  std_logic                      := 'X';             -- awready
			m_ace5lite_wdata         : out std_logic_vector(255 downto 0);                    -- wdata
			m_ace5lite_wstrb         : out std_logic_vector(31 downto 0);                     -- wstrb
			m_ace5lite_wlast         : out std_logic;                                         -- wlast
			m_ace5lite_wvalid        : out std_logic;                                         -- wvalid
			m_ace5lite_wready        : in  std_logic                      := 'X';             -- wready
			m_ace5lite_bid           : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- bid
			m_ace5lite_bresp         : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- bresp
			m_ace5lite_bvalid        : in  std_logic                      := 'X';             -- bvalid
			m_ace5lite_bready        : out std_logic;                                         -- bready
			m_ace5lite_arid          : out std_logic_vector(4 downto 0);                      -- arid
			m_ace5lite_araddr        : out std_logic_vector(31 downto 0);                     -- araddr
			m_ace5lite_ardomain      : out std_logic_vector(1 downto 0);                      -- ardomain
			m_ace5lite_arsnoop       : out std_logic_vector(3 downto 0);                      -- arsnoop
			m_ace5lite_arlen         : out std_logic_vector(7 downto 0);                      -- arlen
			m_ace5lite_arburst       : out std_logic_vector(1 downto 0);                      -- arburst
			m_ace5lite_arlock        : out std_logic;                                         -- arlock
			m_ace5lite_arcache       : out std_logic_vector(3 downto 0);                      -- arcache
			m_ace5lite_arprot        : out std_logic_vector(2 downto 0);                      -- arprot
			m_ace5lite_arqos         : out std_logic_vector(3 downto 0);                      -- arqos
			m_ace5lite_arvalid       : out std_logic;                                         -- arvalid
			m_ace5lite_arready       : in  std_logic                      := 'X';             -- arready
			m_ace5lite_rid           : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- rid
			m_ace5lite_rdata         : in  std_logic_vector(255 downto 0) := (others => 'X'); -- rdata
			m_ace5lite_rresp         : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- rresp
			m_ace5lite_rlast         : in  std_logic                      := 'X';             -- rlast
			m_ace5lite_rvalid        : in  std_logic                      := 'X';             -- rvalid
			m_ace5lite_rready        : out std_logic;                                         -- rready
			m_ace5lite_aruser        : out std_logic_vector(7 downto 0);                      -- aruser
			m_ace5lite_awuser        : out std_logic_vector(7 downto 0);                      -- awuser
			m_ace5lite_arregion      : out std_logic_vector(3 downto 0);                      -- arregion
			m_ace5lite_awregion      : out std_logic_vector(3 downto 0);                      -- awregion
			m_ace5lite_wuser         : out std_logic_vector(7 downto 0);                      -- wuser
			m_ace5lite_buser         : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- buser
			m_ace5lite_ruser         : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- ruser
			s_axi_awid               : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- awid
			s_axi_awaddr             : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- awaddr
			s_axi_awlen              : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- awlen
			s_axi_awsize             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- awsize
			s_axi_awburst            : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- awburst
			s_axi_awlock             : in  std_logic                      := 'X';             -- awlock
			s_axi_awcache            : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- awcache
			s_axi_awprot             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- awprot
			s_axi_awqos              : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- awqos
			s_axi_awvalid            : in  std_logic                      := 'X';             -- awvalid
			s_axi_awready            : out std_logic;                                         -- awready
			s_axi_awregion           : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- awregion
			s_axi_wdata              : in  std_logic_vector(255 downto 0) := (others => 'X'); -- wdata
			s_axi_wstrb              : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- wstrb
			s_axi_wlast              : in  std_logic                      := 'X';             -- wlast
			s_axi_wvalid             : in  std_logic                      := 'X';             -- wvalid
			s_axi_wready             : out std_logic;                                         -- wready
			s_axi_wuser              : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- wuser
			s_axi_bid                : out std_logic_vector(4 downto 0);                      -- bid
			s_axi_bresp              : out std_logic_vector(1 downto 0);                      -- bresp
			s_axi_bvalid             : out std_logic;                                         -- bvalid
			s_axi_bready             : in  std_logic                      := 'X';             -- bready
			s_axi_buser              : out std_logic_vector(7 downto 0);                      -- buser
			s_axi_arid               : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- arid
			s_axi_araddr             : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- araddr
			s_axi_arlen              : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- arlen
			s_axi_arsize             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- arsize
			s_axi_arburst            : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- arburst
			s_axi_arlock             : in  std_logic                      := 'X';             -- arlock
			s_axi_arcache            : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arcache
			s_axi_arprot             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- arprot
			s_axi_arqos              : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arqos
			s_axi_arvalid            : in  std_logic                      := 'X';             -- arvalid
			s_axi_arready            : out std_logic;                                         -- arready
			s_axi_arregion           : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arregion
			s_axi_rid                : out std_logic_vector(4 downto 0);                      -- rid
			s_axi_rdata              : out std_logic_vector(255 downto 0);                    -- rdata
			s_axi_rresp              : out std_logic_vector(1 downto 0);                      -- rresp
			s_axi_rlast              : out std_logic;                                         -- rlast
			s_axi_rvalid             : out std_logic;                                         -- rvalid
			s_axi_rready             : in  std_logic                      := 'X';             -- rready
			s_axi_ruser              : out std_logic_vector(7 downto 0)                       -- ruser
		);
	end component altera_ace5lite_cache_coherency_translator_0;

	u0 : component altera_ace5lite_cache_coherency_translator_0
		generic map (
			WSTRB_WIDTH => INTEGER_VALUE_FOR_WSTRB_WIDTH,
			USER_WIDTH  => INTEGER_VALUE_FOR_USER_WIDTH
		)
		port map (
			clk                      => CONNECTED_TO_clk,                      --        clk.clk
			reset                    => CONNECTED_TO_reset,                    --      reset.reset
			m_ace5lite_awid          => CONNECTED_TO_m_ace5lite_awid,          -- m_ace5lite.awid
			m_ace5lite_awaddr        => CONNECTED_TO_m_ace5lite_awaddr,        --           .awaddr
			m_ace5lite_awdomain      => CONNECTED_TO_m_ace5lite_awdomain,      --           .awdomain
			m_ace5lite_awsnoop       => CONNECTED_TO_m_ace5lite_awsnoop,       --           .awsnoop
			m_ace5lite_awlen         => CONNECTED_TO_m_ace5lite_awlen,         --           .awlen
			m_ace5lite_awsize        => CONNECTED_TO_m_ace5lite_awsize,        --           .awsize
			m_ace5lite_arsize        => CONNECTED_TO_m_ace5lite_arsize,        --           .arsize
			m_ace5lite_awburst       => CONNECTED_TO_m_ace5lite_awburst,       --           .awburst
			m_ace5lite_awlock        => CONNECTED_TO_m_ace5lite_awlock,        --           .awlock
			m_ace5lite_awcache       => CONNECTED_TO_m_ace5lite_awcache,       --           .awcache
			m_ace5lite_awprot        => CONNECTED_TO_m_ace5lite_awprot,        --           .awprot
			m_ace5lite_awqos         => CONNECTED_TO_m_ace5lite_awqos,         --           .awqos
			m_ace5lite_awstashnid    => CONNECTED_TO_m_ace5lite_awstashnid,    --           .awstashnid
			m_ace5lite_awstashniden  => CONNECTED_TO_m_ace5lite_awstashniden,  --           .awstashniden
			m_ace5lite_awstashlpid   => CONNECTED_TO_m_ace5lite_awstashlpid,   --           .awstashlpid
			m_ace5lite_awstashlpiden => CONNECTED_TO_m_ace5lite_awstashlpiden, --           .awstashlpiden
			m_ace5lite_awatop        => CONNECTED_TO_m_ace5lite_awatop,        --           .awatop
			m_ace5lite_awvalid       => CONNECTED_TO_m_ace5lite_awvalid,       --           .awvalid
			m_ace5lite_awready       => CONNECTED_TO_m_ace5lite_awready,       --           .awready
			m_ace5lite_wdata         => CONNECTED_TO_m_ace5lite_wdata,         --           .wdata
			m_ace5lite_wstrb         => CONNECTED_TO_m_ace5lite_wstrb,         --           .wstrb
			m_ace5lite_wlast         => CONNECTED_TO_m_ace5lite_wlast,         --           .wlast
			m_ace5lite_wvalid        => CONNECTED_TO_m_ace5lite_wvalid,        --           .wvalid
			m_ace5lite_wready        => CONNECTED_TO_m_ace5lite_wready,        --           .wready
			m_ace5lite_bid           => CONNECTED_TO_m_ace5lite_bid,           --           .bid
			m_ace5lite_bresp         => CONNECTED_TO_m_ace5lite_bresp,         --           .bresp
			m_ace5lite_bvalid        => CONNECTED_TO_m_ace5lite_bvalid,        --           .bvalid
			m_ace5lite_bready        => CONNECTED_TO_m_ace5lite_bready,        --           .bready
			m_ace5lite_arid          => CONNECTED_TO_m_ace5lite_arid,          --           .arid
			m_ace5lite_araddr        => CONNECTED_TO_m_ace5lite_araddr,        --           .araddr
			m_ace5lite_ardomain      => CONNECTED_TO_m_ace5lite_ardomain,      --           .ardomain
			m_ace5lite_arsnoop       => CONNECTED_TO_m_ace5lite_arsnoop,       --           .arsnoop
			m_ace5lite_arlen         => CONNECTED_TO_m_ace5lite_arlen,         --           .arlen
			m_ace5lite_arburst       => CONNECTED_TO_m_ace5lite_arburst,       --           .arburst
			m_ace5lite_arlock        => CONNECTED_TO_m_ace5lite_arlock,        --           .arlock
			m_ace5lite_arcache       => CONNECTED_TO_m_ace5lite_arcache,       --           .arcache
			m_ace5lite_arprot        => CONNECTED_TO_m_ace5lite_arprot,        --           .arprot
			m_ace5lite_arqos         => CONNECTED_TO_m_ace5lite_arqos,         --           .arqos
			m_ace5lite_arvalid       => CONNECTED_TO_m_ace5lite_arvalid,       --           .arvalid
			m_ace5lite_arready       => CONNECTED_TO_m_ace5lite_arready,       --           .arready
			m_ace5lite_rid           => CONNECTED_TO_m_ace5lite_rid,           --           .rid
			m_ace5lite_rdata         => CONNECTED_TO_m_ace5lite_rdata,         --           .rdata
			m_ace5lite_rresp         => CONNECTED_TO_m_ace5lite_rresp,         --           .rresp
			m_ace5lite_rlast         => CONNECTED_TO_m_ace5lite_rlast,         --           .rlast
			m_ace5lite_rvalid        => CONNECTED_TO_m_ace5lite_rvalid,        --           .rvalid
			m_ace5lite_rready        => CONNECTED_TO_m_ace5lite_rready,        --           .rready
			m_ace5lite_aruser        => CONNECTED_TO_m_ace5lite_aruser,        --           .aruser
			m_ace5lite_awuser        => CONNECTED_TO_m_ace5lite_awuser,        --           .awuser
			m_ace5lite_arregion      => CONNECTED_TO_m_ace5lite_arregion,      --           .arregion
			m_ace5lite_awregion      => CONNECTED_TO_m_ace5lite_awregion,      --           .awregion
			m_ace5lite_wuser         => CONNECTED_TO_m_ace5lite_wuser,         --           .wuser
			m_ace5lite_buser         => CONNECTED_TO_m_ace5lite_buser,         --           .buser
			m_ace5lite_ruser         => CONNECTED_TO_m_ace5lite_ruser,         --           .ruser
			s_axi_awid               => CONNECTED_TO_s_axi_awid,               --      s_axi.awid
			s_axi_awaddr             => CONNECTED_TO_s_axi_awaddr,             --           .awaddr
			s_axi_awlen              => CONNECTED_TO_s_axi_awlen,              --           .awlen
			s_axi_awsize             => CONNECTED_TO_s_axi_awsize,             --           .awsize
			s_axi_awburst            => CONNECTED_TO_s_axi_awburst,            --           .awburst
			s_axi_awlock             => CONNECTED_TO_s_axi_awlock,             --           .awlock
			s_axi_awcache            => CONNECTED_TO_s_axi_awcache,            --           .awcache
			s_axi_awprot             => CONNECTED_TO_s_axi_awprot,             --           .awprot
			s_axi_awqos              => CONNECTED_TO_s_axi_awqos,              --           .awqos
			s_axi_awvalid            => CONNECTED_TO_s_axi_awvalid,            --           .awvalid
			s_axi_awready            => CONNECTED_TO_s_axi_awready,            --           .awready
			s_axi_awregion           => CONNECTED_TO_s_axi_awregion,           --           .awregion
			s_axi_wdata              => CONNECTED_TO_s_axi_wdata,              --           .wdata
			s_axi_wstrb              => CONNECTED_TO_s_axi_wstrb,              --           .wstrb
			s_axi_wlast              => CONNECTED_TO_s_axi_wlast,              --           .wlast
			s_axi_wvalid             => CONNECTED_TO_s_axi_wvalid,             --           .wvalid
			s_axi_wready             => CONNECTED_TO_s_axi_wready,             --           .wready
			s_axi_wuser              => CONNECTED_TO_s_axi_wuser,              --           .wuser
			s_axi_bid                => CONNECTED_TO_s_axi_bid,                --           .bid
			s_axi_bresp              => CONNECTED_TO_s_axi_bresp,              --           .bresp
			s_axi_bvalid             => CONNECTED_TO_s_axi_bvalid,             --           .bvalid
			s_axi_bready             => CONNECTED_TO_s_axi_bready,             --           .bready
			s_axi_buser              => CONNECTED_TO_s_axi_buser,              --           .buser
			s_axi_arid               => CONNECTED_TO_s_axi_arid,               --           .arid
			s_axi_araddr             => CONNECTED_TO_s_axi_araddr,             --           .araddr
			s_axi_arlen              => CONNECTED_TO_s_axi_arlen,              --           .arlen
			s_axi_arsize             => CONNECTED_TO_s_axi_arsize,             --           .arsize
			s_axi_arburst            => CONNECTED_TO_s_axi_arburst,            --           .arburst
			s_axi_arlock             => CONNECTED_TO_s_axi_arlock,             --           .arlock
			s_axi_arcache            => CONNECTED_TO_s_axi_arcache,            --           .arcache
			s_axi_arprot             => CONNECTED_TO_s_axi_arprot,             --           .arprot
			s_axi_arqos              => CONNECTED_TO_s_axi_arqos,              --           .arqos
			s_axi_arvalid            => CONNECTED_TO_s_axi_arvalid,            --           .arvalid
			s_axi_arready            => CONNECTED_TO_s_axi_arready,            --           .arready
			s_axi_arregion           => CONNECTED_TO_s_axi_arregion,           --           .arregion
			s_axi_rid                => CONNECTED_TO_s_axi_rid,                --           .rid
			s_axi_rdata              => CONNECTED_TO_s_axi_rdata,              --           .rdata
			s_axi_rresp              => CONNECTED_TO_s_axi_rresp,              --           .rresp
			s_axi_rlast              => CONNECTED_TO_s_axi_rlast,              --           .rlast
			s_axi_rvalid             => CONNECTED_TO_s_axi_rvalid,             --           .rvalid
			s_axi_rready             => CONNECTED_TO_s_axi_rready,             --           .rready
			s_axi_ruser              => CONNECTED_TO_s_axi_ruser               --           .ruser
		);

