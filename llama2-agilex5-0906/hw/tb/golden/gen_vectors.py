# gen_vectors.py  用法: python gen_vectors.py 768 768
import sys, numpy as np, struct
n, d = int(sys.argv[1]), int(sys.argv[2])
rng = np.random.default_rng(0)
W = rng.standard_normal((n, d)).astype(np.float32) * 0.05
x = rng.standard_normal(d).astype(np.float32)
y = (W.astype(np.float64) @ x.astype(np.float64)).astype(np.float32)  # 高精度参考

def f2h(v): return "%08x" % struct.unpack("<I", struct.pack("<f", v))[0]
with open("w.hex", "w") as f:                 # 每行一拍: 8 个 fp32, lane7..lane0 拼成 256bit
    for r in range(n):
        for c in range(0, d, 8):
            f.write("".join(f2h(W[r, c+7-i]) for i in range(8)) + "\n")
with open("x.hex", "w") as f:
    for v in x: f.write(f2h(v) + "\n")
with open("y_ref.hex", "w") as f:
    for v in y: f.write(f2h(v) + "\n")
print(f"generated n={n} d={d}")
