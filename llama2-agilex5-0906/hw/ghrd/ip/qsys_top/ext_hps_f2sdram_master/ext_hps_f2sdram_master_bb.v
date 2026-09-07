module ext_hps_f2sdram_master #(
		parameter SYNC_RESET = 0
	) (
		input  wire        clk,                  //           clock.clk
		input  wire        reset,                //           reset.reset
		input  wire [29:0] avs_s0_address,       //  windowed_slave.address
		input  wire        avs_s0_read,          //                .read
		output wire [31:0] avs_s0_readdata,      //                .readdata
		input  wire        avs_s0_write,         //                .write
		input  wire [31:0] avs_s0_writedata,     //                .writedata
		output wire        avs_s0_readdatavalid, //                .readdatavalid
		output wire        avs_s0_waitrequest,   //                .waitrequest
		input  wire [3:0]  avs_s0_byteenable,    //                .byteenable
		input  wire [0:0]  avs_s0_burstcount,    //                .burstcount
		output wire [32:0] avm_m0_address,       // expanded_master.address
		output wire        avm_m0_read,          //                .read
		input  wire        avm_m0_waitrequest,   //                .waitrequest
		input  wire [31:0] avm_m0_readdata,      //                .readdata
		output wire        avm_m0_write,         //                .write
		output wire [31:0] avm_m0_writedata,     //                .writedata
		input  wire        avm_m0_readdatavalid, //                .readdatavalid
		output wire [3:0]  avm_m0_byteenable,    //                .byteenable
		output wire [0:0]  avm_m0_burstcount     //                .burstcount
	);
endmodule

