	peripheral_subsys u0 (
		.button_pio_external_connection_export (_connected_to_button_pio_external_connection_export_), //   input,   width = 4, button_pio_external_connection.export
		.button_pio_irq_irq                    (_connected_to_button_pio_irq_irq_),                    //  output,   width = 1,                 button_pio_irq.irq
		.dipsw_pio_external_connection_export  (_connected_to_dipsw_pio_external_connection_export_),  //   input,   width = 4,  dipsw_pio_external_connection.export
		.dipsw_pio_irq_irq                     (_connected_to_dipsw_pio_irq_irq_),                     //  output,   width = 1,                  dipsw_pio_irq.irq
		.led_pio_external_connection_in_port   (_connected_to_led_pio_external_connection_in_port_),   //   input,   width = 3,    led_pio_external_connection.in_port
		.led_pio_external_connection_out_port  (_connected_to_led_pio_external_connection_out_port_),  //  output,   width = 3,                               .out_port
		.pb_cpu_0_s0_waitrequest               (_connected_to_pb_cpu_0_s0_waitrequest_),               //  output,   width = 1,                    pb_cpu_0_s0.waitrequest
		.pb_cpu_0_s0_readdata                  (_connected_to_pb_cpu_0_s0_readdata_),                  //  output,  width = 32,                               .readdata
		.pb_cpu_0_s0_readdatavalid             (_connected_to_pb_cpu_0_s0_readdatavalid_),             //  output,   width = 1,                               .readdatavalid
		.pb_cpu_0_s0_burstcount                (_connected_to_pb_cpu_0_s0_burstcount_),                //   input,   width = 1,                               .burstcount
		.pb_cpu_0_s0_writedata                 (_connected_to_pb_cpu_0_s0_writedata_),                 //   input,  width = 32,                               .writedata
		.pb_cpu_0_s0_address                   (_connected_to_pb_cpu_0_s0_address_),                   //   input,  width = 17,                               .address
		.pb_cpu_0_s0_write                     (_connected_to_pb_cpu_0_s0_write_),                     //   input,   width = 1,                               .write
		.pb_cpu_0_s0_read                      (_connected_to_pb_cpu_0_s0_read_),                      //   input,   width = 1,                               .read
		.pb_cpu_0_s0_byteenable                (_connected_to_pb_cpu_0_s0_byteenable_),                //   input,   width = 4,                               .byteenable
		.pb_cpu_0_s0_debugaccess               (_connected_to_pb_cpu_0_s0_debugaccess_),               //   input,   width = 1,                               .debugaccess
		.clk_clk                               (_connected_to_clk_clk_),                               //   input,   width = 1,                            clk.clk
		.reset_reset_n                         (_connected_to_reset_reset_n_)                          //   input,   width = 1,                          reset.reset_n
	);

