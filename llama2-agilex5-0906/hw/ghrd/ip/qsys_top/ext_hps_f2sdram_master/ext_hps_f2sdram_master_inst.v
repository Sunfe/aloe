	ext_hps_f2sdram_master #(
		.SYNC_RESET (INTEGER_VALUE_FOR_SYNC_RESET)
	) u0 (
		.clk                  (_connected_to_clk_),                  //   input,   width = 1,           clock.clk
		.reset                (_connected_to_reset_),                //   input,   width = 1,           reset.reset
		.avs_s0_address       (_connected_to_avs_s0_address_),       //   input,  width = 30,  windowed_slave.address
		.avs_s0_read          (_connected_to_avs_s0_read_),          //   input,   width = 1,                .read
		.avs_s0_readdata      (_connected_to_avs_s0_readdata_),      //  output,  width = 32,                .readdata
		.avs_s0_write         (_connected_to_avs_s0_write_),         //   input,   width = 1,                .write
		.avs_s0_writedata     (_connected_to_avs_s0_writedata_),     //   input,  width = 32,                .writedata
		.avs_s0_readdatavalid (_connected_to_avs_s0_readdatavalid_), //  output,   width = 1,                .readdatavalid
		.avs_s0_waitrequest   (_connected_to_avs_s0_waitrequest_),   //  output,   width = 1,                .waitrequest
		.avs_s0_byteenable    (_connected_to_avs_s0_byteenable_),    //   input,   width = 4,                .byteenable
		.avs_s0_burstcount    (_connected_to_avs_s0_burstcount_),    //   input,   width = 1,                .burstcount
		.avm_m0_address       (_connected_to_avm_m0_address_),       //  output,  width = 33, expanded_master.address
		.avm_m0_read          (_connected_to_avm_m0_read_),          //  output,   width = 1,                .read
		.avm_m0_waitrequest   (_connected_to_avm_m0_waitrequest_),   //   input,   width = 1,                .waitrequest
		.avm_m0_readdata      (_connected_to_avm_m0_readdata_),      //   input,  width = 32,                .readdata
		.avm_m0_write         (_connected_to_avm_m0_write_),         //  output,   width = 1,                .write
		.avm_m0_writedata     (_connected_to_avm_m0_writedata_),     //  output,  width = 32,                .writedata
		.avm_m0_readdatavalid (_connected_to_avm_m0_readdatavalid_), //   input,   width = 1,                .readdatavalid
		.avm_m0_byteenable    (_connected_to_avm_m0_byteenable_),    //  output,   width = 4,                .byteenable
		.avm_m0_burstcount    (_connected_to_avm_m0_burstcount_)     //  output,   width = 1,                .burstcount
	);

