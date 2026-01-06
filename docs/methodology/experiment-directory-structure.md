
# containerlab-labs 实验目录结构与自动化规范

## 1. 文档目的

本文档用于说明 **containerlab-labs** 仓库的目录结构设计原则、自动化脚本使用方式以及实验归档规范。

目标是构建一个：

* 可长期维护
* 可复现
* 可对比
* 可扩展（FRR / SONiC / 其他 NOS）

的网络协议实验仓库。

---

## 2. 总体设计原则

### 2.1 以 NOS 为第一层隔离维度

实验目录以 **Network Operating System（NOS）** 为第一层拆分，而不是以协议（BGP / OSPF）拆分：

* FRR ≠ SONiC（即使 SONiC 也使用 FRR）
* 配置方式、调试路径、控制面模型不同
* 对比实验必须在 NOS 维度下进行

因此目录顶层明确区分：

* `frr/`
* `sonic/`

---

### 2.2 一个实验 = 一个自包含目录

每个实验目录必须是 **自包含的闭环**，包含：

* 拓扑
* 配置
* 抓包
* 图（PlantUML）
* 分析文档
* 结果总结

实验目录本身即实验文档。

---

### 2.3 自动化优先于手工维护

* 目录结构由脚本生成
* 实验规范通过模板固化
* 人只关注：

  * 拓扑
  * 协议行为
  * 分析结论

---

## 3. 仓库顶层目录结构说明

```text
containerlab-labs/
├── README.md                  # 仓库总览说明
│
├── docs/                      # 通用文档（与具体实验无关）
│   ├── setup/                 # 环境与工具安装
│   ├── templates/             # README / analysis 模板
│   └── methodology/           # 实验方法论与规范
│
├── scripts/                   # 公共自动化脚本（不存实验内容）
│   ├── init_repo.py
│   └── new_lab.py
│
├── frr/                       # FRR 相关实验
│   ├── base/                  # FRR 公共说明
│   └── labs/                  # FRR 实验实例
│
├── sonic/                     # SONiC 相关实验
│   ├── base/                  # SONiC 公共说明
│   └── labs/                  # SONiC 实验实例
│
└── images/                    # 跨实验共享图片资源
    ├── topology/
    ├── sequence/
    └── icons/
```

---

## 4. 单个实验目录结构规范

以 FRR 的 EGP / IGP + Route Reflector 实验为例：

```text
01_egp_igp_rr/
├── README.md                  # 实验入口说明
│
├── topo/
│   ├── topo.yml               # containerlab 拓扑定义
│   └── address-plan.md        # IP / AS / 角色规划
│
├── configs/
│   ├── r1/
│   │   └── frr.conf
│   ├── r2/
│   └── ...
│
├── captures/
│   ├── bgp/
│   │   └── r3_r4_update.pcap
│   └── ospf/
│       └── r1_r3_hello.pcap
│
├── diagrams/
│   ├── topology/              # 拓扑图（PlantUML）
│   ├── sequence/              # 协议时序图
│   └── control-plane/         # 控制面逻辑图
│
├── analysis/
│   ├── analysis.md            # 核心分析
│   └── notes.md               # 过程记录
│
└── results/
    ├── summary.md             # 实验结论
    └── show_outputs/          # show 命令输出
```

### 设计收益

* 实验可独立归档
* 实验可整体迁移
* 实验结果可复盘
* 支持版本 / NOS 对比

---

## 5. 自动化脚本说明

### 5.1 init_repo.py —— 仓库初始化脚本

#### 用途

* 在 **containerlab-labs 根目录** 中初始化标准子目录结构
* 不创建嵌套目录
* 幂等、可重复执行

#### 正确使用方式

```bash
mkdir containerlab-labs
cd containerlab-labs
python3 scripts/init_repo.py
```

#### 重要约束

* `init_repo.py` **必须在 containerlab-labs 目录内执行**
* 若在其他目录执行，脚本会直接退出并提示错误

---

### 5.2 new_lab.py —— 单实验目录生成脚本

#### 用途

* 创建一个新的实验目录
* 自动生成 README 与标准子目录
* 保证实验结构一致性

#### 使用示例

```bash
python3 scripts/new_lab.py \
  --nos frr \
  --id 01 \
  --name egp_igp_rr
```

生成：

```text
frr/labs/01_egp_igp_rr/
```

---

## 6. 文档归档规范

### 6.1 方法论类文档

放置位置：

```text
docs/methodology/
```

例如：

* experiment-directory-structure.md
* experiment-lifecycle.md
* nos-comparison-frr-sonic.md

---

### 6.2 实验分析文档

* **只放在对应实验目录中**
* 不放入全局 docs

例如：

```text
frr/labs/01_egp_igp_rr/analysis/analysis.md
```

---

## 7. 推荐实验生命周期（摘要）

1. 使用 `new_lab.py` 创建实验目录
2. 编写 topo.yml 与配置
3. 使用 containerlab deploy
4. 抓包、验证、记录
5. 完成 analysis / results
6. destroy 实验
7. 实验目录归档

---

## 8. 总结

> containerlab-labs 不是一次性实验目录，而是一个 **长期演进的网络协议实验平台**。

通过：

* 严格的目录规范
* 自动化脚本
* NOS 维度隔离

可以支持：

* FRR / SONiC 深度实验
* 协议行为对比
* CI / 自动化测试
* 长期知识沉淀

---
