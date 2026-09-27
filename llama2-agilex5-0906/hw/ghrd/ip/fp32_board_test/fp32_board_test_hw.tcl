package require qsys

set_module_property NAME fp32_board_test
set_module_property DISPLAY_NAME "FP32 Board Test"
set_module_property VERSION 1.0
set_module_property GROUP "Custom"
set_module_property DESCRIPTION \
    "HPS-controlled FP32 multiply/add hardware test"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true

# Synthesis files.
# fp32_serial.sv contains:
#   fp32_binary_serial
#   fp32_mul
#   fp32_add
#
# The two vendor .ip files are added to the Quartus project separately.

add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL fp32_board_test

add_fileset_file fp32_board_test.sv SYSTEM_VERILOG \
    PATH fp32_board_test.sv TOP_LEVEL_FILE

add_fileset_file fp32_serial.sv SYSTEM_VERILOG \
    PATH fp32_serial.sv

# Clock.

add_interface clk clock end
set_interface_property clk clockRate 0
add_interface_port clk clk clk Input 1

# Active-high reset, synchronous deassertion.

add_interface reset reset end
set_interface_property reset associatedClock clk
set_interface_property reset synchronousEdges DEASSERT
add_interface_port reset reset reset Input 1

# Avalon-MM CSR: 16 words x 4 bytes = 64-byte aperture.

add_interface csr_slave avalon end

set_interface_property csr_slave associatedClock clk
set_interface_property csr_slave associatedReset reset
set_interface_property csr_slave addressUnits WORDS
set_interface_property csr_slave bitsPerSymbol 8

set_interface_property csr_slave readLatency 0
set_interface_property csr_slave readWaitTime 0
set_interface_property csr_slave writeWaitTime 0
set_interface_property csr_slave setupTime 0
set_interface_property csr_slave holdTime 0
set_interface_property csr_slave timingUnits Cycles

set_interface_property csr_slave maximumPendingReadTransactions 0

add_interface_port csr_slave avs_address     address     Input  4
add_interface_port csr_slave avs_read        read        Input  1
add_interface_port csr_slave avs_write       write       Input  1
add_interface_port csr_slave avs_writedata   writedata   Input  32
add_interface_port csr_slave avs_byteenable  byteenable  Input  4
add_interface_port csr_slave avs_readdata    readdata    Output 32
add_interface_port csr_slave avs_waitrequest waitrequest Output 1