# ddr_test_master_hw.tcl
# Platform Designer component definition for ddr_test_master

package require qsys

# ============================================
# 模块属性
# ============================================
set_module_property NAME ddr_test_master
set_module_property DISPLAY_NAME "DDR Test Master"
set_module_property VERSION 1.0
set_module_property GROUP "DSP"
set_module_property DESCRIPTION "AXI4 DDR Test Master with AXI4-Lite CSR Interface"
set_module_property AUTHOR "Your Name"
set_module_property ELABORATION_CALLBACK elaborate
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true

# ============================================
# 文件列表
# ============================================
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL ddr_test_master
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
add_fileset_file ddr_test_master.sv SYSTEM_VERILOG PATH ddr_test_master.sv TOP_LEVEL_FILE

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL ddr_test_master
add_fileset_file ddr_test_master.sv SYSTEM_VERILOG PATH ddr_test_master.sv

add_fileset SIM_VHDL SIM_VHDL "" ""
set_fileset_property SIM_VHDL TOP_LEVEL ddr_test_master
add_fileset_file ddr_test_master.sv SYSTEM_VERILOG PATH ddr_test_master.sv

# ============================================
# 参数定义
# ============================================
add_parameter AXI_ADDR_WIDTH INTEGER 64
set_parameter_property AXI_ADDR_WIDTH DISPLAY_NAME "AXI Address Width"
set_parameter_property AXI_ADDR_WIDTH ALLOWED_RANGES {32 64}
set_parameter_property AXI_ADDR_WIDTH HDL_PARAMETER true

add_parameter AXI_DATA_WIDTH INTEGER 128
set_parameter_property AXI_DATA_WIDTH DISPLAY_NAME "AXI Data Width"
set_parameter_property AXI_DATA_WIDTH ALLOWED_RANGES {64 128 256 512}
set_parameter_property AXI_DATA_WIDTH HDL_PARAMETER true

add_parameter AXI_ID_WIDTH INTEGER 4
set_parameter_property AXI_ID_WIDTH DISPLAY_NAME "AXI ID Width"
set_parameter_property AXI_ID_WIDTH ALLOWED_RANGES {1:16}
set_parameter_property AXI_ID_WIDTH HDL_PARAMETER true

# 派生参数
add_parameter AXI_STRB_WIDTH INTEGER 16
set_parameter_property AXI_STRB_WIDTH DERIVED true
set_parameter_property AXI_STRB_WIDTH HDL_PARAMETER false
set_parameter_property AXI_STRB_WIDTH VISIBLE false

# ============================================
# Elaboration 回调
# ============================================
proc elaborate {} {
    set data_width [get_parameter_value AXI_DATA_WIDTH]
    set strb_width [expr {$data_width / 8}]
    set_parameter_value AXI_STRB_WIDTH $strb_width
}

# ============================================
# CSR 时钟接口
# ============================================
add_interface csr_clk clock end
set_interface_property csr_clk clockRate 0

add_interface_port csr_clk csr_clk clk Input 1

# ============================================
# CSR 复位接口
# ============================================
add_interface csr_rst reset end
set_interface_property csr_rst associatedClock csr_clk
set_interface_property csr_rst synchronousEdges DEASSERT

add_interface_port csr_rst csr_rst reset Input 1

# ============================================
# AXI4-Lite CSR 从接口
# ============================================
add_interface csr_slave axi4lite end
set_interface_property csr_slave associatedClock csr_clk
set_interface_property csr_slave associatedReset csr_rst
set_interface_property csr_slave readAcceptanceCapability 1
set_interface_property csr_slave writeAcceptanceCapability 1
set_interface_property csr_slave combinedAcceptanceCapability 2
set_interface_property csr_slave bridgesToMaster ""

# 写地址通道
add_interface_port csr_slave csr_awaddr awaddr Input 32
add_interface_port csr_slave csr_awprot awprot Input 3
add_interface_port csr_slave csr_awvalid awvalid Input 1
add_interface_port csr_slave csr_awready awready Output 1

# 写数据通道
add_interface_port csr_slave csr_wdata wdata Input 32
add_interface_port csr_slave csr_wstrb wstrb Input 4
add_interface_port csr_slave csr_wvalid wvalid Input 1
add_interface_port csr_slave csr_wready wready Output 1

# 写响应通道
add_interface_port csr_slave csr_bresp bresp Output 2
add_interface_port csr_slave csr_bvalid bvalid Output 1
add_interface_port csr_slave csr_bready bready Input 1

# 读地址通道
add_interface_port csr_slave csr_araddr araddr Input 32
add_interface_port csr_slave csr_arprot arprot Input 3
add_interface_port csr_slave csr_arvalid arvalid Input 1
add_interface_port csr_slave csr_arready arready Output 1

# 读数据通道
add_interface_port csr_slave csr_rdata rdata Output 32
add_interface_port csr_slave csr_rresp rresp Output 2
add_interface_port csr_slave csr_rvalid rvalid Output 1
add_interface_port csr_slave csr_rready rready Input 1

# ============================================
# AXI 时钟接口
# ============================================
add_interface axi_clk clock end
set_interface_property axi_clk clockRate 0

add_interface_port axi_clk axi_clk clk Input 1

# ============================================
# AXI 复位接口
# ============================================
add_interface axi_rst reset end
set_interface_property axi_rst associatedClock axi_clk
set_interface_property axi_rst synchronousEdges DEASSERT

add_interface_port axi_rst axi_rst reset Input 1

# ============================================
# AXI4 主接口
# ============================================
add_interface axi_master axi4 start
set_interface_property axi_master associatedClock axi_clk
set_interface_property axi_master associatedReset axi_rst
set_interface_property axi_master readIssuingCapability 8
set_interface_property axi_master writeIssuingCapability 8
set_interface_property axi_master combinedIssuingCapability 16

# 写地址通道
add_interface_port axi_master axi_awid awid Output AXI_ID_WIDTH
add_interface_port axi_master axi_awaddr awaddr Output AXI_ADDR_WIDTH
add_interface_port axi_master axi_awlen awlen Output 8
add_interface_port axi_master axi_awsize awsize Output 3
add_interface_port axi_master axi_awburst awburst Output 2
add_interface_port axi_master axi_awlock awlock Output 1
add_interface_port axi_master axi_awcache awcache Output 4
add_interface_port axi_master axi_awprot awprot Output 3
add_interface_port axi_master axi_awqos awqos Output 4
add_interface_port axi_master axi_awvalid awvalid Output 1
add_interface_port axi_master axi_awready awready Input 1

# 写数据通道
add_interface_port axi_master axi_wdata wdata Output AXI_DATA_WIDTH
add_interface_port axi_master axi_wstrb wstrb Output AXI_STRB_WIDTH
add_interface_port axi_master axi_wlast wlast Output 1
add_interface_port axi_master axi_wvalid wvalid Output 1
add_interface_port axi_master axi_wready wready Input 1

# 写响应通道
add_interface_port axi_master axi_bid bid Input AXI_ID_WIDTH
add_interface_port axi_master axi_bresp bresp Input 2
add_interface_port axi_master axi_bvalid bvalid Input 1
add_interface_port axi_master axi_bready bready Output 1

# 读地址通道
add_interface_port axi_master axi_arid arid Output AXI_ID_WIDTH
add_interface_port axi_master axi_araddr araddr Output AXI_ADDR_WIDTH
add_interface_port axi_master axi_arlen arlen Output 8
add_interface_port axi_master axi_arsize arsize Output 3
add_interface_port axi_master axi_arburst arburst Output 2
add_interface_port axi_master axi_arlock arlock Output 1
add_interface_port axi_master axi_arcache arcache Output 4
add_interface_port axi_master axi_arprot arprot Output 3
add_interface_port axi_master axi_arqos arqos Output 4
add_interface_port axi_master axi_arvalid arvalid Output 1
add_interface_port axi_master axi_arready arready Input 1

# 读数据通道
add_interface_port axi_master axi_rid rid Input AXI_ID_WIDTH
add_interface_port axi_master axi_rdata rdata Input AXI_DATA_WIDTH
add_interface_port axi_master axi_rresp rresp Input 2
add_interface_port axi_master axi_rlast rlast Input 1
add_interface_port axi_master axi_rvalid rvalid Input 1
add_interface_port axi_master axi_rready rready Output 1