#!/usr/bin/env python3
"""runq.c (version 2, Q8_0) .bin -> FPGA 行交织布局 + manifest.json
用法: export_weights.py in_q80.bin out_fpga.bin
"""
import sys, json, struct, numpy as np

def main(src, dst):
    raw = open(src, "rb").read()
    magic, ver = struct.unpack_from("<Ii", raw, 0)
    assert magic == 0x616b3432 and ver == 2, "需要 export.py --version 2 生成的文件"
    dim, hidden, n_layers, n_heads, n_kv_heads, vocab, seq_len = struct.unpack_from("<7i", raw, 8)
    shared = raw[36]
    GS = struct.unpack_from("<i", raw, 37)[0]
    head = raw[:256]
    kv_dim = dim * n_kv_heads // n_heads
    off = 256

    def take_f32(n):
        nonlocal off
        a = np.frombuffer(raw, np.float32, n, off); off += 4 * n; return a

    def take_q8(n):                      # runq.c: 先 int8 q[n], 再 fp32 s[n/GS]
        nonlocal off
        q = np.frombuffer(raw, np.int8, n, off); off += n
        s = np.frombuffer(raw, np.float32, n // GS, off); off += 4 * (n // GS)
        return q, s

    out = bytearray(head)
    manifest = {"dim": dim, "hidden_dim": hidden, "n_layers": n_layers, "vocab": vocab,
                "group_size": GS, "shared_classifier": int(shared), "fp32": {}, "q8": {}}

    for name, n in [("rms_att", n_layers * dim), ("rms_ffn", n_layers * dim), ("rms_final", dim)]:
        manifest["fp32"][name] = {"offset": len(out), "count": n}
        out += take_f32(n).tobytes()

    def emit(name, count, rows, cols):
        assert cols % GS == 0 and cols % 32 == 0, f"{name}: cols={cols} 必须是 GS 和 32 的倍数"
        spad = ((cols // GS) * 4 + 31) // 32 * 32          # scale 区补齐到 32B
        entries = []
        for i in range(count):
            q, s = take_q8(rows * cols)
            q = q.reshape(rows, cols); s = s.reshape(rows, cols // GS)
            start = len(out)
            for r in range(rows):
                sb = s[r].tobytes(); out.extend(sb + b"\0" * (spad - len(sb)))
                out.extend(q[r].tobytes())
            entries.append({"offset": start, "rows": rows, "cols": cols, "row_bytes": spad + cols})
        manifest["q8"][name] = entries

    emit("token_embedding", 1, vocab, dim)
    emit("wq", n_layers, dim, dim);     emit("wk", n_layers, kv_dim, dim); emit("wv", n_layers, kv_dim, dim)
    emit("wo", n_layers, dim, dim)
    emit("w1", n_layers, hidden, dim);  emit("w2", n_layers, dim, hidden); emit("w3", n_layers, hidden, dim)
    if not shared: emit("wcls", 1, vocab, dim)
    assert off == len(raw), f"输入未消费完: {off} != {len(raw)}"

    open(dst, "wb").write(out)
    json.dump(manifest, open(dst + ".manifest.json", "w"), indent=1)
    print(f"ok: {len(out)>>20} MB, GS={GS}")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])