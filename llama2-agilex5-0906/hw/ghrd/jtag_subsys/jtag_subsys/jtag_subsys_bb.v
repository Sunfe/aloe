module jtag_subsys (
		output wire [31:0] fpga_m_master_address,            //      fpga_m_master.address
		input  wire [31:0] fpga_m_master_readdata,           //                   .readdata
		output wire        fpga_m_master_read,               //                   .read
		output wire        fpga_m_master_write,              //                   .write
		output wire [31:0] fpga_m_master_writedata,          //                   .writedata
		input  wire        fpga_m_master_waitrequest,        //                   .waitrequest
		input  wire        fpga_m_master_readdatavalid,      //                   .readdatavalid
		output wire [3:0]  fpga_m_master_byteenable,         //                   .byteenable
		output wire [31:0] hps_f2sdram_master_address,       // hps_f2sdram_master.address
		input  wire [31:0] hps_f2sdram_master_readdata,      //                   .readdata
		output wire        hps_f2sdram_master_read,          //                   .read
		output wire        hps_f2sdram_master_write,         //                   .write
		output wire [31:0] hps_f2sdram_master_writedata,     //                   .writedata
		input  wire        hps_f2sdram_master_waitrequest,   //                   .waitrequest
		input  wire        hps_f2sdram_master_readdatavalid, //                   .readdatavalid
		output wire [3:0]  hps_f2sdram_master_byteenable,    //                   .byteenable
		output wire [31:0] hps_m_master_address,             //       hps_m_master.address
		input  wire [31:0] hps_m_master_readdata,            //                   .readdata
		output wire        hps_m_master_read,                //                   .read
		output wire        hps_m_master_write,               //                   .write
		output wire [31:0] hps_m_master_writedata,           //                   .writedata
		input  wire        hps_m_master_waitrequest,         //                   .waitrequest
		input  wire        hps_m_master_readdatavalid,       //                   .readdatavalid
		output wire [3:0]  hps_m_master_byteenable,          //                   .byteenable
		input  wire        clk_clk,                          //                clk.clk
		input  wire        reset_reset_n                     //              reset.reset_n
	);
endmodule

