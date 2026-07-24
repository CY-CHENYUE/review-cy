---
name: review-cy
description: |-
  对 coding 过程中的 bug、测试失败、异常行为、性能退化、构建/集成故障、反复返工和“越修越坏”做工程根因诊断。用户说“排查/定位/找根因/debug”、“不要打补丁”、“为什么反复出现”、“这是框架、设计还是架构问题”、“帮我反思这次 coding 过程”时必须使用；当前 Agent 或前序 AI 已多次修复但原问题仍在、症状迁移或新问题不断出现时，也必须主动停止继续改动并使用。即使用户只说“帮我修这个 bug”，当原因不明确、涉及跨模块状态/并发/框架生命周期，或局部改动可能掩盖系统问题时，也应先使用。通过失败契约、系统模型、边界定位、可证伪假设和因果链，区分症状、触发条件、直接机制、根因、促成因素与缺失屏障，并把原因归到实现、契约、框架集成、组件设计、系统架构或运行环境层。默认诊断阶段只读，不直接改代码。不用于普通 PR/diff 审查、代码风格检查、无具体故障的泛化架构评审、纯功能实现，或根因已经被证实后的机械修复。
license: Apache-2.0
compatibility: Requires access to the relevant code, logs, tests, configuration, or an explicit problem report. Git and safe diagnostic commands are useful but not mandatory. No external model or vendor-specific CLI is required.
metadata:
  version: "3.0.0"
---

# review-cy · 工程根因诊断

这个 Skill 的任务不是尽快给出一段“看起来能好”的代码，而是建立一个经得起反证的解释：系统为什么会在这些条件下失败，问题最早从哪一层产生，为什么现有边界没有阻止它，以及怎样纠正才能避免同类问题复发。

核心原则：

- **先诊断，后修复。** 看到异常位置不等于找到异常来源。
- **先建系统模型，再解释证据。** 不理解正常路径、状态所有权和框架生命周期时，不猜根因。
- **主动寻找反证。** 相关性、最近改动和熟悉的旧故障只能形成候选假设。
- **输出因果栈，不强求单一根因。** 复杂故障可能同时存在触发、技术根因、促成因素和缺失屏障。
- **根因层级由证据决定。** 不把局部 bug 强行拔高成架构问题，也不把跨边界设计缺陷压缩成一行补丁。
- **默认只读。** 诊断允许执行安全、可逆、用于取证的检查；没有用户的修复授权，不改业务源码。

## 1. 先确定任务与授权

区分三种意图：

- **只诊断**：定位并解释根因，给纠正方向和验证计划；停在报告，不改源码。
- **诊断并修复**：先冻结诊断结论，再进入独立的实现阶段；不能边猜边叠加修改。
- **线上故障止血**：先保护用户和数据，再继续诊断。回滚、隔离、限流、关闭功能等只能标为 `CONTAINMENT`，不能冒充根因修复；尽量先保存日志、trace、配置、版本和失败样本。

若用户没有明确要求修改，按“只诊断”处理。

## 2. 多次 AI 修复无效时，冻结补丁循环

只要出现“修复后原问题仍在、症状移动、又需增加一个特判”这种重复模式，立即停止继续编辑。失败次数是升级诊断的信号，不是架构缺陷的证明。

先建立修复尝试账本：

```text
Attempt: <what changed>
Hypothesis: <why it was expected to work>
Prediction: <observable result if hypothesis was right>
Actual: <what really happened>
New evidence: <what this rules in/out>
Residual diff/workaround: <what remains in the workspace>
```

辨别失败模式：

- **症状完全不变**：改动可能不在真实执行路径，或原假设错误。
- **症状移动到下游/另一组件**：改动碰到了传播链，但首个错误状态仍在上游产生。
- **原问题缓解却出现新副作用**：可能存在隐藏共享状态、耦合或未建模的契约。
- **测试通过但真实环境失败**：测试 oracle、环境模型或代表性不足。
- **每次都需要新 guard/retry/fallback**：不变量没有在正确所有者处执行，需检查契约或设计。

读取当前 diff 和历史尝试，保留用户改动，不自动 reset、checkout 或回滚。若要恢复干净基线做实验，必须使用安全副本/worktree，或先取得用户确认。

## 3. 建立失败契约

把模糊的“有问题”改写为可观察的失败：

- Expected：正常情况下应发生什么。
- Actual：实际发生什么，原始错误和完整调用栈是什么。
- Trigger：输入、状态、时序、负载、版本和环境条件。
- Scope：受影响与不受影响的用户、路径、组件和版本。
- Timeline：最后正常、首次异常、近期代码/配置/依赖/数据变化。
- Oracle：用什么证据判断原故障复现或消失。

缺少关键项时先取证。不能复现不代表没有问题；可以用生产证据重建，但必须降低结论强度。

## 4. 建立最小系统模型

读取相关项目规则、需求、架构/设计说明、完整函数和直接上下文。画出与故障有关的最小模型：

```text
入口/触发 → 数据与控制流 → 状态所有者 → 组件边界 → 副作用/输出
                  ↘ 契约与不变量 ↙
```

至少回答：

1. 谁创建、拥有、改变和销毁关键状态？
2. 哪个契约或不变量本应始终成立？
3. 框架、运行时或依赖在何时调用什么，线程/进程/事务边界在哪里？
4. 哪个组件有能力预防无效状态，哪个组件只能观察后果？

不要只读报错行。需要具体取证方法时读取 [investigation-workflow.md](references/investigation-workflow.md)。

## 5. 复现、对照与边界定位

优先取得一个失败样本和一个尽可能接近的成功对照，再缩减差异：

1. 保留原始错误、输入、版本、配置和时间顺序。
2. 比较 working/broken case，不一次改变多个变量。
3. 从可见失败向后追踪到“正确状态第一次变坏”的位置。
4. 多组件系统在边界记录输入、输出、状态和配置传播；必要时用二分缩小故障域。
5. 检查近期变更，但同时寻找能否反驳“最近改动导致”的证据。
6. 记录阴性结果；排除一个假设也是有效进展。

主动实验必须安全、可逆，并考虑日志、重试、缓存、并发和观察工具本身造成的干扰。

## 6. 维护可证伪的假设账本

每个候选原因写成：

```text
Hypothesis: <specific causal claim>
Because: <current supporting evidence>
Predicts: <observation that should exist if true>
Discriminator: <test that separates it from competing hypotheses>
Result: <observed outcome and confounders>
State: OPEN | REJECTED | SUPPORTED | CONFIRMED
```

优先执行信息增益最高、风险最低的区分实验。实验不符合预测时，更新模型或新建假设，不在旧假设上继续叠补丁。

## 7. 构造因果栈

按 [causal-model.md](references/causal-model.md) 区分：

```text
Trigger → first invalid state → failure mechanism → visible symptom
                    ↑
        root/systemic cause(s)
        contributing factors
        missing barrier / escape cause
```

根因必须在明确范围内解释关键事实，并满足以下门槛：

- 能预测失败与相近成功条件的差异。
- 能说明违反了哪个契约、规范、不变量或质量属性。
- 有反事实或闭环证据：控制该因素后故障按预测消失，或静态数据/控制流足以证明传播链。
- 已检查主要竞争假设、混杂因素和独立原因。
- 纠正位置在首个错误转换或其可控上游，而不只是最终报错处。
- 纠正能覆盖同类故障，不只覆盖当前样本。

复杂系统里根因可以不止一个。证据不够时输出 `PROVISIONAL` 或 `INCONCLUSIVE`，并给出下一项最有区分力的实验。

## 8. 判定问题所在层

使用 [diagnosis-layers.md](references/diagnosis-layers.md)，为每个因果节点同时标注“因果角色”和“系统层”。可选主层：

- `IMPLEMENTATION`：既有契约和设计成立，局部实现违反它。
- `CONTRACT`：生产者、消费者或状态转换对不变量的理解不一致或未定义。
- `FRAMEWORK_INTEGRATION`：错误使用框架生命周期、调度、资源所有权、配置或扩展点；真正的框架缺陷需要最小受支持复现。
- `COMPONENT_DESIGN`：组件内部的状态模型、抽象、API、算法或职责分配使错误成为结构性结果。
- `SYSTEM_ARCHITECTURE`：问题来自跨组件拓扑、共享状态、耦合、一致性、信任/故障边界或质量属性取舍。
- `RUNTIME_ENVIRONMENT`：配置、权限、资源、版本、工具链、部署或外部系统差异是必要条件。

测试、监控、发布和流程通常作为 `MISSING_BARRIER` 或促成因素记录，而不是用“人操作错了”终止分析。

架构结论需要跨边界因果证据和明确的质量属性场景；还要分别披露已知故障域/爆炸半径、尚未知的范围，以及哪项观测能收窄它。改动大、修过多次或代码难看都不是架构缺陷的充分证据。

## 9. 拒绝症状补丁

在提出纠正方向前执行 [anti-patch.md](references/anti-patch.md) 检查。以下情况说明还没完成诊断：

- 在报错点加默认值、空值保护、catch、retry、sleep、超时或特判，却没有解释坏状态从哪里产生。
- 只能证明“测试绿了”，不能说明哪条不变量恢复了。
- 修复让症状移动到另一个组件，或需要各调用方重复补偿。
- 新增隐藏状态、双写、重复校验或 feature flag，却没有唯一所有者和退出条件。
- 同类错误在多个位置重复出现，局部修复仍允许无效状态进入系统。

纠正建议必须分层：

- `CONTAINMENT`：可逆止血；说明风险、所有者和移除条件。
- `ROOT_CORRECTION`：消除已证实的错误转换、错误契约或结构性条件。
- `PREVENTION`：让同类问题更难再次产生或更早暴露，例如模型约束、隔离、契约测试、监控或发布门禁。

## 10. 选择专项镜头

只加载与证据有关的 [diagnostic-lenses.md](references/diagnostic-lenses.md) 部分：

- 状态、所有权与生命周期
- 并发、异步与分布式交互
- 数据、schema 与一致性
- 性能、资源与退化
- 框架、依赖、构建与运行环境
- API、协议与跨消费者契约

专项 checklist 用于发现候选原因，不能替代因果证明。

遇到输入/版本空间巨大、多因素 top event、系统性失效模式、架构质量属性冲突或事故复盘时，再读取 [method-selection.md](references/method-selection.md)，按需选择 Delta Debugging、故障树、FMEA、轻量 QAW/ATAM、RCA/CAPA 或屏障分析；不要把所有方法机械执行一遍。

## 11. 输出诊断报告

严格使用 [evidence-and-report.md](references/evidence-and-report.md) 的结构。状态只有：

- `CONFIRMED`：存在可复现反事实，或证据闭环足以确认根因。
- `PROVISIONAL`：当前因果模型最能解释证据并已排除主要竞争假设，但关键反事实无法安全完成。
- `INCONCLUSIVE`：证据不足、失败契约不清或多个假设尚不能区分。

报告先给根因结论，再给证据和建议；不要用长篇排查流水账掩盖结论。若没有确认根因，明确说不知道什么，以及下一项实验如何改变判断。

## 12. 修复阶段的边界

只有用户明确要求修复时才进入实现：

1. 先保存诊断报告、失败样本和验证 oracle。
2. 为根因或系统不变量建立能先失败的回归证据。
3. 实施最小的根因纠正，不捆绑无关重构。
4. 验证原故障、相近边界、竞争路径和全套相关检查。
5. 复查 containment 是否可以移除，预防动作是否真的覆盖故障类别。

若实现结果违背原预测，停止继续修改，回到假设账本。一次意外通过不能把错误模型变成正确模型。

## 按需参考

- 复现、对照、追踪、边界取证和实验：[investigation-workflow.md](references/investigation-workflow.md)
- 症状、机制、根因、促成因素和缺失屏障：[causal-model.md](references/causal-model.md)
- 实现、契约、框架、设计、架构和环境分层：[diagnosis-layers.md](references/diagnosis-layers.md)
- 识别 workaround、症状补丁与真正纠正：[anti-patch.md](references/anti-patch.md)
- 并发、数据、性能、框架与 API 专项镜头：[diagnostic-lenses.md](references/diagnostic-lenses.md)
- Delta Debugging、FTA、FMEA、ATAM、RCA/CAPA 与屏障分析路由：[method-selection.md](references/method-selection.md)
- 证据强度、状态和最终报告模板：[evidence-and-report.md](references/evidence-and-report.md)
- 方法来源与明确否决的设计：[design-sources.md](references/design-sources.md)
