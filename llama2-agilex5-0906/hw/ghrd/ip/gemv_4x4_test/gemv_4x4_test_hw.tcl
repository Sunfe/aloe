package require qsys

set_module_property NAME gemv_4x4_test
set_module_property DISPLAY_NAME "4x4 FP32 GEMV Test"
set_module_property VERSION 1.0
set_module_property GROUP "Custom"
set_module_property DESCRIPTION \
    "Fixed 4x4 FP32 GEMV with AXI4-Lite CSR and AXI4 DDR master"
set_module_property AUTHOR "Custom"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property ELABORATION_CALLBACK elaborate

# ============================================================
# Filesets
# ============================================================

add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL gemv_4x4_test
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false

add_fileset_file gemv_4x4_test.sv SYSTEM_VERILOG \
    PATH gemv_4x4_test.sv TOP_LEVEL_FILE

#
# fp32_serial.sv is shared with fp32_board_test.
# The path is relative to this hw.tcl file:
#
# gemv_4x4_test/../fp32_board_test/fp32_serial.sv
#
add_fileset_file fp32_serial.sv SYSTEM_VERILOG \
    PATH ../fp32_board_test/fp32_serial.sv

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL gemv_4x4_test

add_fileset_file gemv_4x4_test.sv SYSTEM_VERILOG \
    PATH gemv_4x4_test.sv

add_fileset_file fp32_serial.sv SYSTEM_VERILOG \
    PATH ../fp32_board_test/fp32_serial.sv

# ============================================================
# Parameters
# ============================================================

foreach spec {
    {AXI_ADDR_WIDTH      64  {32 64}}
    {AXI_DATA_WIDTH      128 {128}}
    {AXI_ID_WIDTH        4   {1:16}}
    {AXI_PROT_VALUE      2   {0:7}}
    {FP32_SETTLE_CYCLES  16  {16 32 64}}
} {
    lassign $spec pname pdefault prange

    add_parameter $pname INTEGER $pdefault
    set_parameter_property $pname DISPLAY_NAME $pname
    set_parameter_property $pname ALLOWED_RANGES $prange
    set_parameter_property $pname HDL_PARAMETER true
}

add_parameter AXI_STRB_WIDTH INTEGER 16
set_parameter_property AXI_STRB_WIDTH DERIVED true
set_parameter_property AXI_STRB_WIDTH HDL_PARAMETER false
set_parameter_property AXI_STRB_WIDTH VISIBLE false

proc elaborate {} {
    set data_width [get_parameter_value AXI_DATA_WIDTH]
    set_parameter_value AXI_STRB_WIDTH [expr {$data_width / 8}]
}

# ============================================================
# Clock
# ============================================================

add_interface clk clock end
set_interface_property clk clockRate 0
add_interface_port clk clk clk Input 1

# ============================================================
# Reset
# ============================================================

add_interface reset reset end
set_interface_property reset associatedClock clk
set_interface_property reset synchronousEdges DEASSERT
add_interface_port reset reset reset Input 1

# ============================================================
# AXI4-Lite CSR subordinate
# 4 KiB address aperture
# ============================================================

add_interface csr_slave axi4lite end

set_interface_property csr_slave associatedClock clk
set_interface_property csr_slave associatedReset reset
set_interface_property csr_slave readAcceptanceCapability 1
set_interface_property csr_slave writeAcceptanceCapability 1
set_interface_property csr_slave combinedAcceptanceCapability 2

foreach port_spec {
    {csr_awaddr   awaddr   Input  12}
    {csr_awprot   awprot   Input  3}
    {csr_awvalid  awvalid  Input  1}
    {csr_awready  awready  Output 1}

    {csr_wdata    wdata    Input  32}
    {csr_wstrb    wstrb    Input  4}
    {csr_wvalid   wvalid   Input  1}
    {csr_wready   wready   Output 1}

    {csr_bresp    bresp    Output 2}
    {csr_bvalid   bvalid   Output 1}
    {csr_bready   bready   Input  1}

    {csr_araddr   araddr   Input  12}
    {csr_arprot   arprot   Input  3}
    {csr_arvalid  arvalid  Input  1}
    {csr_arready  arready  Output 1}

    {csr_rdata    rdata    Output 32}
    {csr_rresp    rresp    Output 2}
    {csr_rvalid   rvalid   Output 1}
    {csr_rready   rready   Input  1}
} {
    add_interface_port csr_slave {*}$port_spec
}

# ============================================================
# AXI4 DDR memory manager
# Single-beat transactions
# One outstanding transaction
# ============================================================

add_interface axi_master axi4 start

set_interface_property axi_master associatedClock clk
set_interface_property axi_master associatedReset reset
set_interface_property axi_master readIssuingCapability 1
set_interface_property axi_master writeIssuingCapability 1
set_interface_property axi_master combinedIssuingCapability 1

foreach port_spec {
    {axi_awid     awid     Output AXI_ID_WIDTH}
    {axi_awaddr   awaddr   Output AXI_ADDR_WIDTH}
    {axi_awlen    awlen    Output 8}
    {axi_awsize   awsize   Output 3}
    {axi_awburst  awburst  Output 2}
    {axi_awlock   awlock   Output 1}
    {axi_awcache  awcache  Output 4}
    {axi_awprot   awprot   Output 3}
    {axi_awqos    awqos    Output 4}
    {axi_awvalid  awvalid  Output 1}
    {axi_awready  awready  Input  1}

    {axi_wdata    wdata    Output AXI_DATA_WIDTH}
    {axi_wstrb    wstrb    Output AXI_STRB_WIDTH}
    {axi_wlast    wlast    Output 1}
    {axi_wvalid   wvalid   Output 1}
    {axi_wready   wready   Input  1}

    {axi_bid      bid      Input  AXI_ID_WIDTH}
    {axi_bresp    bresp    Input  2}
    {axi_bvalid   bvalid   Input  1}
    {axi_bready   bready   Output 1}

    {axi_arid     arid     Output AXI_ID_WIDTH}
    {axi_araddr   araddr   Output AXI_ADDR_WIDTH}
    {axi_arlen    arlen    Output 8}
    {axi_arsize   arsize   Output 3}
    {axi_arburst  arburst  Output 2}
    {axi_arlock   arlock   Output 1}
    {axi_arcache  arcache  Output 4}
    {axi_arprot   arprot   Output 3}
    {axi_arqos    arqos    Output 4}
    {axi_arvalid  arvalid  Output 1}
    {axi_arready  arready  Input  1}

    {axi_rid      rid      Input  AXI_ID_WIDTH}
    {axi_rdata    rdata    Input  AXI_DATA_WIDTH}
    {axi_rresp    rresp    Input  2}
    {axi_rlast    rlast    Input  1}
    {axi_rvalid   rvalid   Input  1}
    {axi_rready   rready   Output 1}
} {
    add_interface_port axi_master {*}$port_spec
}