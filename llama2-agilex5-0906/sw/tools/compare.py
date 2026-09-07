#!/usr/bin/env python3
"""比对两个原始 fp32 文件: compare.py a.bin b.bin [rtol]  (调试时用 fwrite 把 logits/xb 落盘)"""
import sys, numpy as np
a = np.fromfile(sys.argv[1], np.float32); b = np.fromfile(sys.argv[2], np.float32)
rtol = float(sys.argv[3]) if len(sys.argv) > 3 else 1e-4
assert a.size == b.size, f"size {a.size} != {b.size}"
rel = np.abs(a - b) / (np.abs(b) + 1e-3)
bad = np.nonzero(rel > rtol)[0]
print(f"n={a.size} max_rel={rel.max():.3e} mismatches={bad.size} argmax a={a.argmax()} b={b.argmax()}")
for i in bad[:10]: print(f"  [{i}] {a[i]:.6f} vs {b[i]:.6f}")
sys.exit(1 if bad.size else 0)