
# 01_egp_igp_rr 实验设计方案

## 1. 实验定位

**这是全仓库的“基线实验”**：建立一个贴近 Internet 架构的控制面分层模型：

* AS 内：**OSPF（IGP）**保障 loopback / next-hop 可达
* AS 内：**iBGP + Route Reflector（RR）**替代 iBGP full-mesh
* AS 间：**eBGP（EGP）**交换路由并体现 AS 级边界

该实验不引入 LocalPref/MED/community 等策略变量，确保后续所有 BGP 实验都有一致基线。

---

## 2. 实验目标与假设

### 2.1 实验目标

1. 构建 2-AS 分层网络，并形成稳定邻接关系：

* AS65001：r1/r2（clients）— r3（RR+ASBR）
* AS65002：r5/r6（clients）— r4（RR+ASBR）
* AS 间：r3 ↔ r4 eBGP

2. 验证 RR 的核心价值：

* **不做 iBGP full-mesh**，客户端仍能学习对端 AS 的路由。

3. 验证 IGP 与 iBGP 的分工：

* OSPF 仅负责 **AS 内可达性**（loopback/next-hop），不跨 AS 扩散业务路由。

### 2.2 实验假设（Hypothesis）

> 如果在 AS 内使用 **Route Reflector**（r3/r4）并由 OSPF 保证各节点 loopback 可达，
> 那么 AS 内的 RR Client（r1/r2、r5/r6）无需 iBGP full-mesh，也能学习到来自对端 AS 的前缀，
> 因为 RR 会对 iBGP UPDATE 执行反射转发，eBGP 只在 ASBR 间交换一次路由。

---

## 3. 拓扑与角色（最小但充分）

### 3.1 节点与角色

| 节点 |    AS | 角色            |
| -- | ----: | ------------- |
| r1 | 65001 | RR Client     |
| r2 | 65001 | RR Client     |
| r3 | 65001 | **RR + ASBR** |
| r4 | 65002 | **RR + ASBR** |
| r5 | 65002 | RR Client     |
| r6 | 65002 | RR Client     |

### 3.2 链路（与 topo.yml 一致）

* r1—r3（AS65001 内部）
* r2—r3（AS65001 内部）
* r3—r4（AS 间 eBGP）
* r4—r5（AS65002 内部）
* r4—r6（AS65002 内部）

### 3.3 地址规划（建议与你给的配置一致）

* loopback：1.1.1.1/32 … 6.6.6.6/32
* p2p：

  * r1—r3：10.0.13.0/30
  * r2—r3：10.0.23.0/30
  * r3—r4：172.16.34.0/30
  * r4—r5：20.0.45.0/30
  * r4—r6：20.0.46.0/30

---

## 4. 变量设计（确保因果）

### 4.1 固定变量（Control Variables）

* 拓扑、地址规划固定
* FRR 镜像固定：`quay.io/frrouting/frr:10.5.0`
* IGP 固定：**OSPF area 0，仅 AS 内链路+loopback**
* iBGP 建邻固定：**loopback 建邻 + update-source lo**

### 4.2 实验变量（Experiment Variable）

* **RR 是否开启**（route-reflector-client）

> 本实验只比较“启用 RR vs 关闭 RR”的差异，不引入其他 BGP policy。

---

## 5. 实验步骤设计（可复现闭环）

### Phase A：部署与基础连通

1. `containerlab deploy -t topo/topo.yml`
2. 给 r1~r6 下发接口 IP + loopback（或通过配置文件挂载）
3. 验证链路：

   * `ping` 直连口对端

### Phase B：构建 IGP（OSPF，仅 AS 内）

1. 在 AS65001（r1/r2/r3）启用 OSPF
2. 在 AS65002（r4/r5/r6）启用 OSPF
3. 验证：

   * `show ip ospf neighbor`
   * `show ip route ospf`（应能到达同 AS 的 loopback/32）

### Phase C：构建 BGP（RR + eBGP）

1. r3 作为 RR：r1/r2 作为 client
2. r4 作为 RR：r5/r6 作为 client
3. r3 ↔ r4 作为 eBGP（直连接口建邻）
4. 在每台路由器宣告 `network <lo>/32`
5. 验证：

   * `show ip bgp summary`
   * `show ip bgp`（应学习到对端 AS 的 /32）

### Phase D：对照实验（RR 开/关）

> 只动一个变量：RR client 配置

* **Control（无 RR）**：在 r3/r4 上移除 `route-reflector-client`

  * 预期：客户端学习不到“来自另一个 client 的 iBGP 学到的路由”（除非 full-mesh）
* **Experiment（有 RR）**：恢复 `route-reflector-client`

  * 预期：客户端恢复学习完整前缀集

---

## 6. 预期观测与判据（Pass/Fail）

### 6.1 邻接判据

* OSPF：

  * r1↔r3、r2↔r3 为 FULL
  * r4↔r5、r4↔r6 为 FULL
* BGP：

  * r1/r2 与 r3 iBGP Established
  * r5/r6 与 r4 iBGP Established
  * r3 与 r4 eBGP Established

### 6.2 RR 核心判据

* 在 **RR 启用**时：

  * r1 能看到 5.5.5.5/32、6.6.6.6/32（来自 AS65002）
  * r5 能看到 1.1.1.1/32、2.2.2.2/32（来自 AS65001）
* 在 **RR 禁用且无 full-mesh**时：

  * r1/r2、r5/r6 的路由学习将出现缺失（对照组）

---

## 7. 证据采集设计（必须有）

### 7.1 show 输出归档（results/show_outputs）

建议采集：

* `show ip ospf neighbor`
* `show ip route ospf`
* `show ip bgp summary`
* `show ip bgp`

### 7.2 抓包点（captures）

抓包最小集合：

1. r3—r4（eBGP 链路）

   * 观察 OPEN/KEEPALIVE/UPDATE
2. r1—r3（iBGP/RR 链路）

   * 观察 RR 是否向 client 发 UPDATE（反射行为）

命令示例：

```bash
tcpdump -i eth3 tcp port 179 -w captures/bgp/r3_r4.pcap
tcpdump -i eth1 tcp port 179 -w captures/bgp/r1_r3.pcap
```

---

## 8. 风险点与排错路径（提前写清）

### 常见失败原因

1. iBGP 用 loopback 建邻但 loopback 不可达
   → 先查 OSPF 是否学到对端 lo/32

2. eBGP 邻居没起
   → 检查 eth3/地址/直连、TCP 179、邻居 IP 是否正确

3. RR 启用但 client 仍学不到路由
   → 检查：

* client 是否真的指向 RR（neighbor）
* RR 是否配置 `route-reflector-client`
* `show ip bgp neighbors <ip> advertised-routes`

---

## 9. 产出物（归档要求）

实验结束后必须至少提交：

* `topo/topo.yml`
* `topo/address-plan.md`
* `configs/r1..r6/frr.conf`
* `analysis/analysis.md`（按模板）
* `results/summary.md`
* 必要 pcap（至少 1 个 eBGP + 1 个 iBGP）

---

## 10. 下一步实验的“基线复用点”

一旦 01 通过，后续实验可以在 **完全同一拓扑**上做单变量扩展：

* 02_local_pref（只改 local-pref）
* 03_as_path_prepend（只改 prepend）
* 04_med（只改 MED，多出口）

---

下一步可以把这份“设计方案”直接转成你实验目录里的两个文件：

* `frr/labs/01_egp_igp_rr/topo/address-plan.md`
* `frr/labs/01_egp_igp_rr/analysis/analysis.md`（已填入目标/假设/判据骨架）
