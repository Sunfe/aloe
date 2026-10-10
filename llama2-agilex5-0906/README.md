# llama2.c on Agilex 5E

## 1. Board
DE25-Standard

## 2. TODO

- [x] All 6 layers Q/K/V integrated into FPGA
- [x] GEMV_MODE=verify|perf
- [x] GEMV_WEIGHTS=copy|resident
- [x] 18 Q/K/V weight matrices mounted to shared DDR
- [x] Resident weights reduce host copy overhead by ~167 ms/forward
- [x] Decouple cycle-level composition based on variable-class GEMV RTL
- [x] Implement intra-group aggregation and accumulation measurement
- [x] Add GVM2 VERSION and 128-bit BUILD_ID
- [x] On-board BUILD_ID verification against target image
- [x] On-board verification of OVERLAP_MUL_ADD=1, FP32_SETTLE_CYCLES=16
- [x] Current build verify+resident, 2-step short inference
- [x] Current build perf+resident, 32-step performance test
- [x] Two runs total 612 GEMV calls, 176,256 output elements iterate consistently
- [x] GEMV average cycles reduced from ~3.69M to ~2.56M
- [x] Cycle reduction ~30.61%, consistent with scheduling derivation
- [ ] Integrate BUILD_ID check into C driver and verify compilation and on-board execution
- [ ] Improve build input snapshot, dependency manifest, and SOF hash correspondence
- [ ] Save and verify current Quartus compilation, timing, and standalone GEMV regression records
- [ ] Confirm actual GEMV clock frequency
- [ ] Synchronize standalone CPU-only inference baseline build
- [ ] Future hardware efficiency optimization and larger matrix support
