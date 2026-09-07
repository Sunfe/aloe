#****************************************************************************
#
# SPDX-License-Identifier: MIT-0
# Copyright(c) 2019-2021 Intel Corporation.
#
#****************************************************************************
#
# Sample SDC for Agilex GHRD.
#
#****************************************************************************

set_time_format -unit ns -decimal_places 3

# 50MHz board input clock, 150MHz for EMIF refclk
create_clock -name MAIN_CLOCK -period 20 [get_ports CLOCK2_50]
create_clock -name EMIF_REF_CLOCK -period "150MHz" [get_ports DDR4_REFCLK_p]

set_false_path -from [get_ports {CPU_RESET_n}]

# sourcing JTAG related SDC
source ./jtag.sdc

# FPGA IO port constraints
set_false_path -from [get_ports {KEY[*]}] -to *
set_false_path -from [get_ports {SW[*]}] -to *
set_false_path -from [get_ports {LEDR[*]}] -to *
set_false_path -from * -to [get_ports {LEDR[*]}]

# False Path between debounced and reset synchronizer
set_false_path -from fpga_reset_n_debounced -to {soc_inst|rst_controller_*|altera_reset_synchronizer_int_chain[1]}

