### tiny_llm:

##### 说明：
大模型推理的完整骨架， 覆盖“最小 Transformer + 注意力 + 张量推理”，大模型 99% 的核心逻辑：
- 最小微模型（结构同 Llama）
-  完整 GGUF 张量结构
-  可在 STM32 / FPGA 跑的 C 代码
-  从 读取张量 → 推理 → 输出 全流程

##### 属性：
词表大小：**32**（最简单）
向量维度：**64**
层数：**1 层 Transformer**
注意力头数：**1**
FFN 中间维度：**128**

##### 运行方法：
```
gcc tiny_llm.c -o tiny_llm -lm
./tiny_llm

输出：
输入token: 1
输出下一个token: 10
```

