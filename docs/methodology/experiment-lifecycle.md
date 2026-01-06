
# containerlab-labs 实验生命周期规范

## 1. 文档目的

本文档定义 **containerlab-labs** 中一次完整网络实验的**标准生命周期**，用于指导：

* FRR / SONiC 实验的统一流程
* 实验的可复现、可回溯
* 实验结果的长期沉淀与对比

该生命周期适用于：

* 协议原理验证（BGP / OSPF / EVPN）
* 行为对比实验（版本 / NOS / 参数）
* 架构实验（RR / 多 AS / 分层控制面）

---

## 2. 实验生命周期总览

一次完整实验必须经历以下阶段：

```text
规划 → 创建 → 部署 → 验证 → 观测 → 分析 → 归档 → 销毁
```

对应到仓库与工具：

| 阶段 | 主要产物            | 主要工具         |
| -- | --------------- | ------------ |
| 规划 | address-plan.md | 人工           |
| 创建 | 实验目录            | new_lab.py   |
| 部署 | 运行拓扑            | containerlab |
| 验证 | show 输出         | vtysh        |
| 观测 | pcap            | tcpdump      |
| 分析 | analysis.md     | Markdown     |
| 归档 | 完整实验目录          | Git          |
| 销毁 | 空运行环境           | containerlab |

---

## 3. Phase 0：实验规划（Design）

### 目标

在**不启动任何实验**之前，明确：

* 实验要验证什么
* 哪些变量是“固定的”
* 哪些变量是“实验因子”

### 必须完成的内容

* AS 规划
* Loopback / 链路 IP 规划
* 节点角色划分（RR / Client / ASBR）

📄 对应文件：

```text
topo/address-plan.md
```

> ⚠️ 禁止“边起实验边想拓扑”

---

## 4. Phase 1：实验创建（Scaffold）

### 目标

生成**标准化、可复用的实验目录骨架**

### 操作

```bash
python3 scripts/new_lab.py \
  --nos frr \
  --id 01 \
  --name egp_igp_rr
```

### 产物

```text
frr/labs/01_egp_igp_rr/
```

包含：

* README.md
* topo/
* configs/
* captures/
* diagrams/
* analysis/
* results/

> ⚠️ 禁止手工创建实验目录

---

## 5. Phase 2：实验部署（Deploy）

### 目标

将**抽象拓扑**转化为**真实运行的控制面**

### 操作

```bash
containerlab deploy -t topo/topo.yml
```

### 要求

* 明确指定镜像版本（如 FRR 10.5.0）
* 不使用 `latest` 作为长期实验基线
* 每次部署应是**可重复的**

---

## 6. Phase 3：基础验证（Verify）

### 目标

确认实验环境**正确启动**，但尚未进入分析阶段

### 验证点（示例）

```bash
vtysh -c "show ip ospf neighbor"
vtysh -c "show ip bgp summary"
```

### 输出归档

```text
results/show_outputs/
```

---

## 7. Phase 4：观测与抓包（Observe）

### 目标

采集**协议真实行为**，而非只看 CLI 结果

### 推荐抓包点

* eBGP 链路
* RR ↔ Client iBGP
* OSPF 邻接建立链路

### 示例

```bash
tcpdump -i eth1 tcp port 179 -w captures/bgp/r3_r4_update.pcap
```

> ⚠️ 抓包文件必须与实验一一对应，不允许复用

---

## 8. Phase 5：分析（Analyze）

### 目标

将“现象”转化为“解释”

### 必须回答的问题

* 路由是**如何传播**的？
* RR 在哪一步进行了反射？
* next-hop 是否被修改？为什么？
* 行为是否符合 RFC / 预期？

📄 对应文件：

```text
analysis/analysis.md
```

---

## 9. Phase 6：结果总结（Conclude）

### 目标

提炼**可复用结论**

### 示例内容

* 实验结论
* 关键配置点
* 常见误区
* 可扩展实验方向

📄 对应文件：

```text
results/summary.md
```

---

## 10. Phase 7：实验销毁（Destroy）

### 目标

释放资源，保持实验环境“干净”

### 操作

```bash
containerlab destroy -t topo/topo.yml
```

### 原则

* 实验结束后必须销毁
* 不保留长期运行实验

---

## 11. 禁止事项（Hard Rules）

* ❌ 在实验目录外存放抓包
* ❌ 混合多个实验结果
* ❌ 手工创建实验目录
* ❌ 使用 latest 作为长期对比基线
* ❌ 无分析文档的“跑通实验”

---

## 12. 生命周期与 CI / 自动化的关系

该生命周期天然适合：

* CI 批量运行实验
* 不同 FRR / SONiC 版本对比
* 参数矩阵测试

未来可扩展为：

```text
topo.yml + configs + analysis template
→ 自动 deploy
→ 自动 collect
→ 自动 diff
```

---

## 13. 总结

> **实验不是“跑通”，而是“可解释、可复现、可对比”。**

containerlab-labs 的生命周期规范，确保：

* 实验有开始、有结束
* 结果可长期复用
* 架构可持续演进

---

下一步：

1. 📄 写 **experiment-design.md**（如何设计一个“好实验”）
2. 🧪 给 `new_lab.py` 增加 `--with-topo`
3. 🧩 给 FRR / SONiC 做 **统一实验对照表**
4. 🖼️ 自动生成 PlantUML 模板
