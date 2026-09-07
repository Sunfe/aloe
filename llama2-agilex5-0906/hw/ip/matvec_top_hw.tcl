package require -exact qsys 25.1

set_module_property NAME         matvec_top
set_module_property DISPLAY_NAME "llama2 matvec accelerator"
set_module_property VERSION      1.0
set_module_property GROUP        "llama2"
set_module_property EDITABLE     false

# ---------------- 源文件 ----------------
set rtl_files {pkg/matvec_pkg.sv fp32_prims.sv csr.sv x_buf.sv y_buf.sv w_reader.sv pe_array.sv matvec_top.sv}
foreach fs {QUARTUS_SYNTH SIM_VERILOG} {
  add_fileset $fs $fs "" ""
  set_fileset_property $fs TOP_LEVEL matvec_top
  foreach f $rtl_files { add_fileset_file [file tail $f] SYSTEM_VERILOG PATH ../rtl/$f }
}
# fp32_mul_ip.ip / fp32_add_ip.ip 在 .qsf 里用 IP_FILE 加入工程, 此处不列

# ---------------- clock / reset ----------------
add_interface clock clock end
set_interface_property clock clockRate 0
add_interface_port clock clk clk Input 1

add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
add_interface_port reset rst_n reset_n Input 1

# ---------------- s_csr: AXI4-Lite ----------------
add_interface s_csr axi4lite end
set_interface_property s_csr associatedClock clock
set_interface_property s_csr associatedReset reset
set_interface_property s_csr readAcceptanceCapability 1
set_interface_property s_csr writeAcceptanceCapability 1
set_interface_property s_csr combinedAcceptanceCapability 1
set_interface_property s_csr readDataReorderingDepth 1
foreach {port role w dir} {
  s_awaddr awaddr 8 Input   s_awprot awprot 3 Input  s_awvalid awvalid 1 Input  s_awready awready 1 Output
  s_wdata  wdata 32 Input   s_wstrb  wstrb  4 Input  s_wvalid  wvalid  1 Input  s_wready  wready  1 Output
  s_bresp  bresp  2 Output  s_bvalid bvalid 1 Output s_bready  bready  1 Input
  s_araddr araddr 8 Input   s_arprot arprot 3 Input  s_arvalid arvalid 1 Input  s_arready arready 1 Output
  s_rdata  rdata 32 Output  s_rresp  rresp  2 Output s_rvalid  rvalid  1 Output s_rready  rready  1 Input
} { add_interface_port s_csr $port $role $dir $w }

# ---------------- s_mem: Avalon-MM ----------------
add_interface s_mem avalon end
set_interface_property s_mem associatedClock clock
set_interface_property s_mem associatedReset reset
set_interface_property s_mem addressUnits WORDS
set_interface_property s_mem readLatency 1
set_interface_property s_mem maximumPendingReadTransactions 0
add_interface_port s_mem av_address   address   Input  19
add_interface_port s_mem av_write     write     Input  1
add_interface_port s_mem av_read      read      Input  1
add_interface_port s_mem av_writedata writedata Input  32
add_interface_port s_mem av_readdata  readdata  Output 32

# ---------------- m_wr: AXI4 master ----------------
add_interface m_wr axi4 start
set_interface_property m_wr associatedClock clock
set_interface_property m_wr associatedReset reset
set_interface_property m_wr readIssuingCapability 8
set_interface_property m_wr writeIssuingCapability 1
set_interface_property m_wr combinedIssuingCapability 8
foreach {port role w dir} {
  m_awid awid 4 Output  m_awaddr awaddr 64 Output  m_awlen awlen 8 Output  m_awsize awsize 3 Output
  m_awburst awburst 2 Output  m_awlock awlock 1 Output  m_awcache awcache 4 Output  m_awprot awprot 3 Output
  m_awvalid awvalid 1 Output  m_awready awready 1 Input
  m_wdata wdata 256 Output  m_wstrb wstrb 32 Output  m_wlast wlast 1 Output  m_wvalid wvalid 1 Output  m_wready wready 1 Input
  m_bid bid 4 Input  m_bresp bresp 2 Input  m_bvalid bvalid 1 Input  m_bready bready 1 Output
  m_arid arid 4 Output  m_araddr araddr 64 Output  m_arlen arlen 8 Output  m_arsize arsize 3 Output
  m_arburst arburst 2 Output  m_arlock arlock 1 Output  m_arcache arcache 4 Output  m_arprot arprot 3 Output
  m_arvalid arvalid 1 Output  m_arready arready 1 Input
  m_rid rid 4 Input  m_rdata rdata 256 Input  m_rresp rresp 2 Input  m_rlast rlast 1 Input  m_rvalid rvalid 1 Input  m_rready rready 1 Output
} { add_interface_port m_wr $port $role $dir $w }

# ---------------- irq ----------------
add_interface irq interrupt end
set_interface_property irq associatedAddressablePoint s_csr
set_interface_property irq associatedClock clock
set_interface_property irq associatedReset reset
add_interface_port irq irq irq Output 1