	jtag_subsys u0 (
		.fpga_m_master_address            (_connected_to_fpga_m_master_address_),            //  output,  width = 32,      fpga_m_master.address
		.fpga_m_master_readdata           (_connected_to_fpga_m_master_readdata_),           //   input,  width = 32,                   .readdata
		.fpga_m_master_read               (_connected_to_fpga_m_master_read_),               //  output,   width = 1,                   .read
		.fpga_m_master_write              (_connected_to_fpga_m_master_write_),              //  output,   width = 1,                   .write
		.fpga_m_master_writedata          (_connected_to_fpga_m_master_writedata_),          //  output,  width = 32,                   .writedata
		.fpga_m_master_waitrequest        (_connected_to_fpga_m_master_waitrequest_),        //   input,   width = 1,                   .waitrequest
		.fpga_m_master_readdatavalid      (_connected_to_fpga_m_master_readdatavalid_),      //   input,   width = 1,                   .readdatavalid
		.fpga_m_master_byteenable         (_connected_to_fpga_m_master_byteenable_),         //  output,   width = 4,                   .byteenable
		.hps_f2sdram_master_address       (_connected_to_hps_f2sdram_master_address_),       //  output,  width = 32, hps_f2sdram_master.address
		.hps_f2sdram_master_readdata      (_connected_to_hps_f2sdram_master_readdata_),      //   input,  width = 32,                   .readdata
		.hps_f2sdram_master_read          (_connected_to_hps_f2sdram_master_read_),          //  output,   width = 1,                   .read
		.hps_f2sdram_master_write         (_connected_to_hps_f2sdram_master_write_),         //  output,   width = 1,                   .write
		.hps_f2sdram_master_writedata     (_connected_to_hps_f2sdram_master_writedata_),     //  output,  width = 32,                   .writedata
		.hps_f2sdram_master_waitrequest   (_connected_to_hps_f2sdram_master_waitrequest_),   //   input,   width = 1,                   .waitrequest
		.hps_f2sdram_master_readdatavalid (_connected_to_hps_f2sdram_master_readdatavalid_), //   input,   width = 1,                   .readdatavalid
		.hps_f2sdram_master_byteenable    (_connected_to_hps_f2sdram_master_byteenable_),    //  output,   width = 4,                   .byteenable
		.hps_m_master_address             (_connected_to_hps_m_master_address_),             //  output,  width = 32,       hps_m_master.address
		.hps_m_master_readdata            (_connected_to_hps_m_master_readdata_),            //   input,  width = 32,                   .readdata
		.hps_m_master_read                (_connected_to_hps_m_master_read_),                //  output,   width = 1,                   .read
		.hps_m_master_write               (_connected_to_hps_m_master_write_),               //  output,   width = 1,                   .write
		.hps_m_master_writedata           (_connected_to_hps_m_master_writedata_),           //  output,  width = 32,                   .writedata
		.hps_m_master_waitrequest         (_connected_to_hps_m_master_waitrequest_),         //   input,   width = 1,                   .waitrequest
		.hps_m_master_readdatavalid       (_connected_to_hps_m_master_readdatavalid_),       //   input,   width = 1,                   .readdatavalid
		.hps_m_master_byteenable          (_connected_to_hps_m_master_byteenable_),          //  output,   width = 4,                   .byteenable
		.clk_clk                          (_connected_to_clk_clk_),                          //   input,   width = 1,                clk.clk
		.reset_reset_n                    (_connected_to_reset_reset_n_)                     //   input,   width = 1,              reset.reset_n
	);

