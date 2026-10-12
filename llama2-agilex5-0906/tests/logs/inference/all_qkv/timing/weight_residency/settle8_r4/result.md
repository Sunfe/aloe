# Variable GEMV: FP32 settle budget 8

## Change Summary

- The variable GEMV reports FP32_SETTLE_CYCLES=8 instead of the
  previous verified value 16; OVERLAP_MUL_ADD remains enabled.
- The C driver expects settle=8 and passes its initialization checks.
- The original files were named settle4_*. The actual CSR readback
  in both runs is 8; these are not settle=4 results.
- The RTL BUILD_ID remains 1a67165bfaa445ed98c33b673a9b04db,
  which was also used for the settle=16 build. It therefore does
  not uniquely distinguish these two configurations. Do not use
  BUILD_ID alone to associate this run with a particular SOF.
- The logs do not establish which specific RTL, Tcl or Qsys files
  were edited; use the source diff for that change list.

## Results

| Metric                      | Settle 16 r3 |  Settle 8 r4 |
| --------------------------- | -----------: | -----------: |
| Mean cycles/GEMV, perf      | 2,561,929.72 | 1,738,626.37 |
| START_to_DONE, ms/forward   |      462.203 |      314.690 |
| Accelerator API, ms/forward |      468.572 |      321.078 |
| Forward mean, ms            |      546.612 |      377.987 |
| Achieved tok/s              |     1.843154 |     2.679112 |

Mean hardware cycles decreased by approximately 32.14%.
The verify n=2 and perf n=32 runs both exited with status 0:
612 GEMV calls and 176,256 output elements passed bit-exact
CPU/FPGA comparison in total. Resident upload readback passed.

End-to-end timing also includes CPU work; its improvement should
not be attributed entirely to the FPGA. GEMV_CLOCK_HZ was unset.
No file-level stdout comparison or current SOF hash is recorded here.