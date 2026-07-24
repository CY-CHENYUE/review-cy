# review-cy v3 方法来源

> 调研截止：2026-07-15。这是维护者的设计与取舍记录，普通诊断时不必加载。六层分类是对多种方法的工程化综合，不是某一家机构发布的统一标准。

## Vibe coding 与 AI 修复失效

- [Vibe Coding in Practice: An Empirical Study of AI-Assisted Software Development](https://arxiv.org/abs/2512.22418)：观察到开发者会在缺少稳定系统模型时反复生成、运行和修改候选代码，形成带随机性的 debugging/refinement 循环；随着代码增长，人与生成代码之间的理解也可能分离。
- [Vibe Coding Through the Conversation](https://arxiv.org/abs/2506.23253)：把实践描述为对话驱动、混合式 debugging；人的关键工作从逐行编写转向提供上下文、评估结果和校准 Agent。
- [Understanding Automated Program Repair Agents through the Lens of Traceability](https://research.ibm.com/publications/understanding-automated-program-repair-agents-through-the-lens-of-traceability-an-empirical-study)：从可追踪性分析自动修复 Agent，指出逻辑缺陷、故障复现、相关回归测试和过拟合/冗长补丁仍是关键薄弱点。
- [FixedBench: Demystifying Agentic Coding through the Lens of Verifiability](https://www.sri.inf.ethz.ch/publications/gloaguen2026coding)：说明 coding agent 存在 action bias，即任务不需要代码修改时仍倾向采取修改动作；这使“先证明需要改什么”成为诊断协议的一部分。

借鉴：把每次 AI 修复视为一次可审计实验，必须记录假设、预测和实际结果；连续失败后冻结编辑，回到失败契约与系统模型；“采取了动作”和“测试偶然通过”都不能单独证明根因已经纠正。拒绝把 Vibe coding 本身、模型能力或“AI 写错了”当作技术根因。

## 系统化故障排查

### Google SRE

- [Effective Troubleshooting](https://sre.google/sre-book/effective-troubleshooting/)：把排查视为假设—演绎循环；从 problem report、系统理解和 telemetry 生成候选原因，用互斥实验排除；提醒相关性、旧故障记忆、观测副作用和混杂因素会误导。也明确线上先止血并不妨碍后续根因分析。
- [Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)：根因可能有多个；目标是理解促成原因并采取防复发动作，不把人当作可修复的系统组件；postmortem 成本需要明确触发条件。
- [Example Postmortem](https://sre.google/sre-book/example-postmortem/)：区分 impact、root cause、trigger、resolution、detection 和 action items，避免 knee-jerk action item。
- [Postmortem Analysis](https://sre.google/workbook/postmortem-analysis/)：真实事故类别不仅包括局部软件错误，还包括接口、部署、流程和复杂系统行为。

借鉴：失败契约、系统模型、边界二分、假设与反证、阴性结果、止血/纠正分离、多因素因果栈。

### 软件调试研究与工具

- [A Grounded Theory of Debugging in Professional Software Engineering Practice](https://arxiv.org/abs/2602.11435)：专业调试是通过导航与执行证据不断更新系统 mental model 的迭代诊断过程；形成足够确定性后才进入修复。
- [Delta Debugging](https://www.st.cs.uni-saarland.de/papers/tse2002/) 与 [Isolating Cause-Effect Chains](https://www.st.cs.uni-saarland.de/papers/fse2002/)：用失败/成功对照缩减必要差异，并沿状态传播定位因果来源。
- [Git bisect](https://git-scm.com/docs/git-bisect)：用可重复 failure oracle 二分引入故障的版本范围。

借鉴：失败/成功对照、最小复现、反向追踪、首个错误状态、一次一个变量。拒绝把最小复现当作唯一证据；生产故障可能只能得到概率性因果模型。

## 根因、因果因素与防复发

- [NASA Software Engineering Handbook SWE-204](https://swehb.nasa.gov/spaces/SWEHBVC/pages/50889445/SWE-204%2B-%2BProcess%2BAssessments)：区分 root cause、proximate cause 和 causal factor；强调准确诊断与长期纠正，不只处理结果。
- [NASA Mishap Root Cause Analysis](https://nodis3.gsfc.nasa.gov/displayAll.cfm?Internal_ID=N_PR_8621_0001_&page_name=ALL)：区分“发生了什么”和“为什么发生”，允许 localized/systemic root cause chains，并要求事实采集。
- [NIST Secure Software Development Framework](https://csrc.nist.gov/pubs/sp/800/218/final)：建议跨时间分析漏洞根因模式，并将检测同类根因的机制反馈到工具链与开发过程。

借鉴：根因是范围相关且可能复数；纠正要覆盖复发类别；技术根因、促成因素和缺失屏障分开。拒绝固定次数 Five Whys、把人或“AI 写错了”当最终根因。

## 设计与架构层判断

### Carnegie Mellon SEI

- [Early Analysis of Software Architecture](https://www.sei.cmu.edu/library/early-analysis-of-software-architecture/)：用质量属性需求与场景判断架构决策是否存在风险，并先确认架构信息是否足以支持分析。
- [Reasoning About Software Quality Attributes](https://www.sei.cmu.edu/library/reasoning-about-software-quality-attributes/)：性能、可靠性、安全、可修改性等架构判断应落到具体刺激、环境、响应和可测结果，而不是抽象形容词。
- [Architecture Tradeoff Analysis Method](https://www.sei.cmu.edu/library/architecture-tradeoff-analysis-method-collection/)：识别风险、敏感点和质量属性权衡。
- [Architectural Roots of Technical Debt](https://www.sei.cmu.edu/blog/a-case-study-in-locating-the-architectural-roots-of-technical-debt/)：bug 聚类、频繁变更和架构连接可以成为设计债线索，但仍需要因果分析。

借鉴：架构结论必须有跨边界路径、质量属性场景和权衡证据；“缺陷最早可预防的位置”比“最终发现/修改的位置”更接近纠正责任。

### 云架构官方方法

- [Azure Failure Mode Analysis](https://learn.microsoft.com/en-us/azure/well-architected/reliability/failure-mode-analysis)：沿关键流、依赖、故障点和 blast radius 分析系统性失败。
- [Azure Performance Antipatterns](https://learn.microsoft.com/en-us/azure/architecture/antipatterns/)：通过 telemetry、受控负载和实现上下文从症状识别重复性设计缺陷。
- [AWS Well-Architected: Loosely coupled dependencies](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel_prevent_interaction_failure_loosely_coupled_system.html)：组件边界、共享状态、故障隔离和 backpressure 影响故障传播与可诊断性。

借鉴：从关键流、状态所有权、耦合、失败域和可测响应判断设计/架构原因。拒绝看到某个 antipattern 名称就跳过当前系统证据。

## 公开 Agent Skills / Prompts

### 借鉴

- [Superpowers systematic-debugging](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/SKILL.md)：先复现、检查变化、跨边界取证、单一假设、最小实验、修复前建立失败证据。
- [Superpowers root-cause-tracing](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/root-cause-tracing.md)：从最终失败逐层追踪坏值和调用来源。
- [Trail of Bits audit-context-building](https://github.com/trailofbits/skills/blob/main/plugins/audit-context-building/skills/audit-context-building/SKILL.md)：先建立 actors、entrypoints、状态、invariants 和 trust boundaries，再分析候选缺陷。
- [OpenAI Codex review prompt](https://github.com/openai/codex/blob/main/codex-rs/core/review_prompt.md)：候选问题需要具体触发场景、受影响路径、置信度和可行动性；这部分只用于证据纪律，不保留 diff review 产品定位。

### 明确否决

- 不使用“修复失败三次就证明架构错误”之类的魔法次数；重复失败只触发冻结补丁循环和更深诊断。
- 不要求任何技术问题都执行同样重的完整流程；简单已确认实现错误可输出简版报告。
- 不引用无法审计的成功率、节省时间或“绝大多数无根因都是调查不完整”等数字。
- 不为每个函数、block 或组件规定固定数量的 Five Whys、假设、invariant 或 reviewer。
- 不默认并行调度多个模型，也不依赖指定 CLI、JSONL 或文本标签。
- 不把“每层都加校验”当防御纵深；不变量应优先由唯一所有者执行，必要边界再增加独立屏障。
- 不输出 PASS/FAIL、P0/P1 PR 门控或“只审本次 diff”；v3 是问题诊断，不是代码审查。
- 不为了显得深刻就建议重写架构；候选方案也必须解释质量属性收益、代价和验证方式。
