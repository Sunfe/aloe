	component jtag_subsys is
		port (
			fpga_m_master_address            : out std_logic_vector(31 downto 0);                    -- address
			fpga_m_master_readdata           : in  std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
			fpga_m_master_read               : out std_logic;                                        -- read
			fpga_m_master_write              : out std_logic;                                        -- write
			fpga_m_master_writedata          : out std_logic_vector(31 downto 0);                    -- writedata
			fpga_m_master_waitrequest        : in  std_logic                     := 'X';             -- waitrequest
			fpga_m_master_readdatavalid      : in  std_logic                     := 'X';             -- readdatavalid
			fpga_m_master_byteenable         : out std_logic_vector(3 downto 0);                     -- byteenable
			hps_f2sdram_master_address       : out std_logic_vector(31 downto 0);                    -- address
			hps_f2sdram_master_readdata      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
			hps_f2sdram_master_read          : out std_logic;                                        -- read
			hps_f2sdram_master_write         : out std_logic;                                        -- write
			hps_f2sdram_master_writedata     : out std_logic_vector(31 downto 0);                    -- writedata
			hps_f2sdram_master_waitrequest   : in  std_logic                     := 'X';             -- waitrequest
			hps_f2sdram_master_readdatavalid : in  std_logic                     := 'X';             -- readdatavalid
			hps_f2sdram_master_byteenable    : out std_logic_vector(3 downto 0);                     -- byteenable
			hps_m_master_address             : out std_logic_vector(31 downto 0);                    -- address
			hps_m_master_readdata            : in  std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
			hps_m_master_read                : out std_logic;                                        -- read
			hps_m_master_write               : out std_logic;                                        -- write
			hps_m_master_writedata           : out std_logic_vector(31 downto 0);                    -- writedata
			hps_m_master_waitrequest         : in  std_logic                     := 'X';             -- waitrequest
			hps_m_master_readdatavalid       : in  std_logic                     := 'X';             -- readdatavalid
			hps_m_master_byteenable          : out std_logic_vector(3 downto 0);                     -- byteenable
			clk_clk                          : in  std_logic                     := 'X';             -- clk
			reset_reset_n                    : in  std_logic                     := 'X'              -- reset_n
		);
	end component jtag_subsys;

	u0 : component jtag_subsys
		port map (
			fpga_m_master_address            => CONNECTED_TO_fpga_m_master_address,            --      fpga_m_master.address
			fpga_m_master_readdata           => CONNECTED_TO_fpga_m_master_readdata,           --                   .readdata
			fpga_m_master_read               => CONNECTED_TO_fpga_m_master_read,               --                   .read
			fpga_m_master_write              => CONNECTED_TO_fpga_m_master_write,              --                   .write
			fpga_m_master_writedata          => CONNECTED_TO_fpga_m_master_writedata,          --                   .writedata
			fpga_m_master_waitrequest        => CONNECTED_TO_fpga_m_master_waitrequest,        --                   .waitrequest
			fpga_m_master_readdatavalid      => CONNECTED_TO_fpga_m_master_readdatavalid,      --                   .readdatavalid
			fpga_m_master_byteenable         => CONNECTED_TO_fpga_m_master_byteenable,         --                   .byteenable
			hps_f2sdram_master_address       => CONNECTED_TO_hps_f2sdram_master_address,       -- hps_f2sdram_master.address
			hps_f2sdram_master_readdata      => CONNECTED_TO_hps_f2sdram_master_readdata,      --                   .readdata
			hps_f2sdram_master_read          => CONNECTED_TO_hps_f2sdram_master_read,          --                   .read
			hps_f2sdram_master_write         => CONNECTED_TO_hps_f2sdram_master_write,         --                   .write
			hps_f2sdram_master_writedata     => CONNECTED_TO_hps_f2sdram_master_writedata,     --                   .writedata
			hps_f2sdram_master_waitrequest   => CONNECTED_TO_hps_f2sdram_master_waitrequest,   --                   .waitrequest
			hps_f2sdram_master_readdatavalid => CONNECTED_TO_hps_f2sdram_master_readdatavalid, --                   .readdatavalid
			hps_f2sdram_master_byteenable    => CONNECTED_TO_hps_f2sdram_master_byteenable,    --                   .byteenable
			hps_m_master_address             => CONNECTED_TO_hps_m_master_address,             --       hps_m_master.address
			hps_m_master_readdata            => CONNECTED_TO_hps_m_master_readdata,            --                   .readdata
			hps_m_master_read                => CONNECTED_TO_hps_m_master_read,                --                   .read
			hps_m_master_write               => CONNECTED_TO_hps_m_master_write,               --                   .write
			hps_m_master_writedata           => CONNECTED_TO_hps_m_master_writedata,           --                   .writedata
			hps_m_master_waitrequest         => CONNECTED_TO_hps_m_master_waitrequest,         --                   .waitrequest
			hps_m_master_readdatavalid       => CONNECTED_TO_hps_m_master_readdatavalid,       --                   .readdatavalid
			hps_m_master_byteenable          => CONNECTED_TO_hps_m_master_byteenable,          --                   .byteenable
			clk_clk                          => CONNECTED_TO_clk_clk,                          --                clk.clk
			reset_reset_n                    => CONNECTED_TO_reset_reset_n                     --              reset.reset_n
		);

