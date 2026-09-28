#!/bin/bash

# 根目录
#ROOT="llama2-agilex5e"
ROOT=$PWD
mkdir -p "$ROOT"

# 1. 顶层文件
touch "$ROOT/README.md" "$ROOT/LICENSE" "$ROOT/.gitignore"

# 2. docs
mkdir -p "$ROOT"/docs/{architecture,interfaces,bringup,test}
touch "$ROOT"/docs/architecture/{system_overview.md,hw_sw_partition.md,performance_budget.md}
touch "$ROOT"/docs/interfaces/{csr_spec_v1.md,memory_layout_v1.md,host_api_v1.md,weight_format_v1.md}
touch "$ROOT"/docs/bringup/{board_setup.md,uio_enable.md,dma_coherency_notes.md}
touch "$ROOT"/docs/test/{test_plan.md,regression_matrix.md,acceptance_criteria.md}

# 3. software
mkdir -p "$ROOT"/software/{host/include,host/src,host/tests,host/third_party,driver/uapi,common/include,common/src}
touch "$ROOT"/software/host/include/{fpga_gemv.h,fpga_gemv_regs.h,dma_buf.h,matmul_backend.h,llm_runtime.h,log.h}
touch "$ROOT"/software/host/src/{fpga_gemv.c,dma_buf.c,matmul_backend_cpu.c,matmul_backend_fpga.c,llm_runtime.c,main.c}
touch "$ROOT"/software/host/tests/{test_fpga_gemv.c,test_dma_buf.c,test_matmul_compare.c,test_forward_smoke.c}
touch "$ROOT"/software/host/{CMakeLists.txt,Makefile}
mkdir -p "$ROOT"/software/host/third_party/llama2.c
touch "$ROOT"/software/driver/uapi/fpga_gemv_ioctl.h
touch "$ROOT"/software/driver/{fpga_gemv_drv.c,Kbuild,Makefile}
touch "$ROOT"/software/common/include/{project_config.h,types.h}
touch "$ROOT"/software/common/src/project_config.c

# 4. rtl
mkdir -p "$ROOT"/rtl/{gemv_core/{rtl,sim,constraints},csr_bridge/{rtl,sim},top/{rtl,qsys_pd,constraints}}
touch "$ROOT"/rtl/gemv_core/rtl/{gemv_core_top.sv,gemv_ctrl.sv,gemv_pe_array.sv,gemv_accum.sv,gemv_x_buffer.sv,gemv_w_reader.sv}
touch "$ROOT"/rtl/gemv_core/sim/{tb_gemv_core.sv,tb_data_gen.py,run_sim.sh}
touch "$ROOT"/rtl/gemv_core/constraints/gemv_core.sdc
touch "$ROOT"/rtl/csr_bridge/rtl/{gemv_csr.sv,axi_lite_slave.sv}
touch "$ROOT"/rtl/csr_bridge/sim/tb_gemv_csr.sv
touch "$ROOT"/rtl/top/rtl/{top_agilex5e.sv,reset_sync.sv}
touch "$ROOT"/rtl/top/constraints/{top.sdc,pins.qsf}

# 5. hls
mkdir -p "$ROOT"/hls/{gemv_hls/{src,include,scripts},}
touch "$ROOT"/hls/gemv_hls/src/gemv_kernel.cpp
touch "$ROOT"/hls/gemv_hls/include/gemv_kernel.hpp
touch "$ROOT"/hls/gemv_hls/scripts/{csim.tcl,synth.tcl,export.tcl}
touch "$ROOT"/hls/gemv_hls/README.md
touch "$ROOT"/hls/README.md

# 6. tools
mkdir -p "$ROOT"/tools/{weight_converter/{src,include,tests},golden_ref,perf}
touch "$ROOT"/tools/weight_converter/src/{convert_main.cpp,model_bin_parser.cpp,reorder_gemv.cpp,format_writer.cpp}
touch "$ROOT"/tools/weight_converter/include/{model_bin_parser.hpp,reorder_gemv.hpp,format_writer.hpp}
touch "$ROOT"/tools/weight_converter/tests/test_converter.cpp
touch "$ROOT"/tools/weight_converter/CMakeLists.txt
touch "$ROOT"/tools/golden_ref/{cpu_gemv_ref.py,compare_tensor.py,token_diff.py}
touch "$ROOT"/tools/perf/{parse_log.py,plot_tokens_per_sec.py,roofline_estimator.py}

# 7. scripts
mkdir -p "$ROOT"/scripts/{env,build,run,deploy,ci}
touch "$ROOT"/scripts/env/{setup_host_env.sh,setup_quartus_env.sh,setup_cross_compile.sh}
touch "$ROOT"/scripts/build/{build_host.sh,build_rtl.sh,build_hls.sh,build_all.sh}
touch "$ROOT"/scripts/run/{run_unit_tests.sh,run_fpga_smoke.sh,run_llama_generate.sh,run_regression.sh}
touch "$ROOT"/scripts/deploy/{copy_to_board.sh,load_bitstream.sh,set_uio_permissions.sh}
touch "$ROOT"/scripts/ci/{ci_host_build.sh,ci_unit_test.sh,ci_lint.sh}

# 8. configs
mkdir -p "$ROOT"/configs/{board,model,runtime}
touch "$ROOT"/configs/board/{agilex5e_devkit.json,memory_map.json}
touch "$ROOT"/configs/model/{llama2_7b.json,tokenizer.json}
touch "$ROOT"/configs/runtime/{backend_fpga.yaml,backend_cpu.yaml}

# 9. data
mkdir -p "$ROOT"/data/{models,tokenizer,test_vectors/{gemv,forward}}
touch "$ROOT"/data/models/{README.md,.gitkeep}
touch "$ROOT"/data/tokenizer/tokenizer.bin

# 10. build
mkdir -p "$ROOT"/build/{host,rtl,hls,reports}

# 11. ci
mkdir -p "$ROOT"/ci/{github/workflows,pre-commit}
touch "$ROOT"/ci/github/workflows/{host-build.yml,lint.yml}
touch "$ROOT"/ci/pre-commit/{clang-format.sh,checkpatch.sh}

echo "✅ 全部目录 + 文件已创建完成：$ROOT"
tree "$ROOT"
