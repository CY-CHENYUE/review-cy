# 成熟工程方法路由

不要把所有疑难故障都塞进同一个 checklist。先判断当前最缺的是复现、定位、因果结构、潜在失效模式、架构权衡，还是组织学习，再选择最轻的成熟方法。

## 方法选择表

| 当前问题 | 优先方法 | 主要产物 | 不适合替代什么 |
|---|---|---|---|
| 原因不明、候选很多 | 假设—演绎 troubleshooting | 可证伪假设与区分实验 | 不能靠经验直觉直接下结论 |
| 输入/配置/版本空间很大 | Delta Debugging / bisection | 最小失败差异、必要条件 | 不能证明缩减后条件就是根因 |
| 跨组件、不清楚在哪里坏 | 边界观测 + 系统二分 | 首个异常边界、传播路径 | 不能把最后失败组件当源头 |
| 多次 AI 修复失败 | Attempt ledger + causal tracing | 假设/预测/结果历史、症状迁移模式 | 失败次数不能证明架构问题 |
| 多个条件共同造成高影响事件 | Fault Tree Analysis (FTA) | top event 的 AND/OR 原因组合 | 不适合把相关性自动画成因果 |
| 想系统枚举组件可能怎样失效 | FMEA/FMECA | failure mode、effect、detection/control | 更偏前瞻预防，不替代当前故障 RCA |
| 设计/架构质量属性冲突 | 轻量 QAW/ATAM | 场景、敏感点、风险、权衡点 | 不因一次 bug 就启动完整正式评估 |
| 事故或同类问题反复出现 | RCA + CAPA / blameless postmortem | 因果因素、纠正/预防动作、责任与验证 | 不应以写文档代替技术证据 |
| 失效如何越过保护层 | Barrier analysis | 缺失、失效或被绕过的控制 | 不能把“多加校验”当唯一答案 |

## 假设—演绎 troubleshooting

默认方法。基于系统正常模型和观察生成候选原因，为每个假设写出预测，用能区分竞争假设的实验更新模型。

适用于大多数 bug、测试失败、构建、性能和集成问题。重点是：

- 明确 expected/actual 和 failure oracle。
- 一次实验改变一个关键变量。
- 主动寻找反证和混杂因素。
- 记录阴性结果。

## Delta Debugging 与 bisection

当失败由大量输入、配置、commit、feature flag 或组件组合构成时，系统性缩小产生失败与成功差异的最小集合。

使用前提：

- failure oracle 稳定。
- 每个候选子集都能安全运行。
- 缩减过程没有破坏原 failure mechanism。

结果表示“这些差异对当前复现必要或相关”，还需因果与 incorrectness 证明。

## Fault Tree Analysis · 故障树

从一个高影响 top event 反向展开可能导致它的必要/充分组合，用 AND/OR 表达多故障关系。适合：

- 安全、数据损坏、重复扣款、全局不可用等高后果事件。
- 单一原因解释不了，多个条件需要共同出现。
- 需要检查共同原因、冗余失效和最小 cut sets。

只把有机制与证据支持的节点放入正式树；头脑风暴候选要标为未验证。

## FMEA/FMECA · 失效模式与影响分析

从组件/功能向前枚举“它可能怎样失效、影响什么、现有检测/控制是什么”。适合 root correction 后做同类预防，也适合新设计的高风险路径。

最小字段：

```text
Function/component
Failure mode
Local effect
End effect
Cause/mechanism
Existing detection/control
Recommended prevention
Verification
```

FMEA 是前瞻性覆盖工具；若当前故障尚未定位，先做 causal investigation，不要用风险表格替代证据。

## 轻量 QAW/ATAM · 架构场景与权衡

只有证据指向组件关系或质量属性时使用。把模糊的“架构不好”转成：

```text
Stimulus source → Stimulus → Environment → Artifact
→ Expected response → Measurable response
```

再识别：

- 当前架构做了什么决策。
- 哪个参数变化会显著改变结果（敏感点）。
- 一个质量属性的改善会牺牲什么（权衡点）。
- 哪些风险直接威胁业务/工程目标。

不照搬正式 ATAM 的多日组织流程；本 Skill 使用其场景化和权衡核心。

## RCA + CAPA / blameless postmortem

用于事故、重复故障或影响较大的近失事件。报告应连接：

```text
事实时间线
→ causal/root factors
→ containment
→ corrective action
→ preventive action
→ objective effectiveness evidence
```

避免归罪个人。若“AI 生成了错误代码”，继续问：什么系统模型、契约、验证或权限边界让错误被接受并持续叠加？

## Barrier analysis · 屏障分析

沿 failure mechanism 检查哪些预防、检测、隔离和恢复屏障本应介入：

- 屏障不存在。
- 屏障设计覆盖不足。
- 屏障存在但未执行/结果被忽略。
- 屏障与真实责任边界不一致。
- 屏障只检测症状，无法阻止错误状态。

优先让不变量由唯一所有者执行。跨信任边界、灾难性影响或独立失效需求存在时，再增加互相独立的防御层。

## Vibe coding 的使用方式

把每次 AI 修复视为一个工程实验，而不是一次新的答案采样：

1. 修改前写假设与预测。
2. 保留失败样本和基线。
3. 一次只验证一个关键因果主张。
4. 实际结果不符合预测时，停止叠加代码并更新 mental model。
5. 连续尝试出现症状迁移或补丁堆叠时，切换到 causal tracing / FTA / 架构场景，而不是换个 prompt 继续抽样。
6. 成功标准是解释和关闭故障类别，不只是当前测试变绿。
