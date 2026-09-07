module peripheral_subsys (
		input  wire [3:0]  button_pio_external_connection_export, // button_pio_external_connection.export
		output wire        button_pio_irq_irq,                    //                 button_pio_irq.irq
		input  wire [3:0]  dipsw_pio_external_connection_export,  //  dipsw_pio_external_connection.export
		output wire        dipsw_pio_irq_irq,                     //                  dipsw_pio_irq.irq
		input  wire [2:0]  led_pio_external_connection_in_port,   //    led_pio_external_connection.in_port
		output wire [2:0]  led_pio_external_connection_out_port,  //                               .out_port
		output wire        pb_cpu_0_s0_waitrequest,               //                    pb_cpu_0_s0.waitrequest
		output wire [31:0] pb_cpu_0_s0_readdata,                  //                               .readdata
		output wire        pb_cpu_0_s0_readdatavalid,             //                               .readdatavalid
		input  wire [0:0]  pb_cpu_0_s0_burstcount,                //                               .burstcount
		input  wire [31:0] pb_cpu_0_s0_writedata,                 //                               .writedata
		input  wire [16:0] pb_cpu_0_s0_address,                   //                               .address
		input  wire        pb_cpu_0_s0_write,                     //                               .write
		input  wire        pb_cpu_0_s0_read,                      //                               .read
		input  wire [3:0]  pb_cpu_0_s0_byteenable,                //                               .byteenable
		input  wire        pb_cpu_0_s0_debugaccess,               //                               .debugaccess
		input  wire        clk_clk,                               //                            clk.clk
		input  wire        reset_reset_n                          //                          reset.reset_n
	);
endmodule

