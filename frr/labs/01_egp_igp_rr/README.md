## 实验目标

本实验旨在在 **containerlab + FRRouting（datacenter profile）** 环境中，验证以下控制平面行为：

1. **IGP（OSPF）作为 underlay**
   - 所有节点 Loopback 地址在 IGP 中可达
   - 为 iBGP 建立提供稳定的传输基础

2. **iBGP Route Reflector（RR）机制**
   - r3 作为 RR
   - r1、r2 作为 RR Client
   - 验证 RR 能正确执行 *client → client* 路由反射
   - 验证未启用 RR 时 iBGP 的 full-mesh 限制

3. **eBGP 与 iBGP 的协同**
   - r3 ↔ r4 运行 eBGP
   - eBGP 学到的前缀经 RR 正确反射给 iBGP Client
   - 确认 AS_PATH、NEXT_HOP 等关键属性符合预期

4. **datacenter profile 下的 FRR 行为**
   - 使用 `frr defaults datacenter`
   - 验证 daemon 启动模型、vtysh 集成模式对实验结果无负面影响
   - 为后续 iBGP + EVPN 实验奠定统一基线

---

## 实验拓扑

### 控制面设计

- **拓扑结构**
  - 见：`diagrams/topology/topology.puml`
  - 物理连接用于表达 IGP / eBGP 邻接关系

- **控制面分层**
  - 见：`diagrams/control-plane/control-plane.puml`
  - 明确区分：
    - Underlay：OSPF
    - Overlay（控制面）：iBGP / eBGP
    - RR 逻辑位置

- **RR 行为时序**
  - 见：`diagrams/sequence/sequence.puml`
  - 描述：
    - eBGP UPDATE → RR
    - RR → iBGP Client 反射
    - Keepalive / UPDATE 交互顺序

---

## 实验假设

本实验基于以下可验证假设设计：

1. **IGP 假设**
   - 若 OSPF 正常收敛，则所有节点 Loopback 可达
   - 若 Loopback 不可达，则 iBGP 会话无法建立

2. **iBGP / RR 假设**
   - 在未配置 RR 的情况下，iBGP Client 之间不会互相学习路由
   - 启用 `route-reflector-client` 后：
     - RR 可将来自一个 Client 的路由反射给另一个 Client
     - RR 自身不会破坏 iBGP 的 AS_PATH 规则

3. **eBGP → iBGP 传播假设**
   - eBGP 学到的前缀可进入 RR 的 BGP RIB
   - 该前缀可被 RR 反射给所有 iBGP Client
   - 抓包中应观察到对应的 BGP UPDATE 报文

4. **datacenter profile 假设**
   - `frr defaults datacenter` 不改变 BGP / OSPF 协议语义
   - daemon 启动行为与传统模式存在差异，但不影响控制面正确性

---

## 结论摘要

通过 **show 命令 + 抓包双重验证**，本实验得到以下结论：

1. **OSPF underlay 正常**
   - 所有节点 Loopback 在 IGP 中可达
   - iBGP 邻居均基于 Loopback 成功建立

2. **Route Reflector 行为符合预期**
   - r3 成功作为 RR
   - r1 / r2 作为 RR Client，可学习彼此及 eBGP 域路由
   - 未出现 iBGP full-mesh 要求

3. **eBGP 路由成功被反射**
   - r3 从 r4 学到 eBGP 前缀
   - 抓包确认：
     - RR 接收 eBGP UPDATE
     - RR 向 iBGP Client 发送反射 UPDATE
   - BGP UPDATE 报文在 r3 的多个接口可观测

4. **datacenter profile 可作为后续实验基线**
   - 所有相关 daemon（bgpd / ospfd / staticd）稳定运行
   - `service integrated-vtysh-config` 简化配置加载流程
   - 为下一步 iBGP + EVPN 实验提供一致运行环境

> 结论：  
> 在 containerlab + FRR datacenter profile 环境中，iBGP Route Reflector 的控制平面行为符合 RFC 4456 预期，可作为后续 EVPN / VXLAN 控制平面的可靠基础。

