# review-cy

一个面向 Vibe coding / AI 编码过程的工程根因诊断 Skill。

它解决的不是“再审一遍 diff”，而是这种常见困境：AI 已经修改了好几轮，原问题仍然存在；每次修复只是换一个报错、增加一个 guard/retry/fallback，代码越来越复杂，却没有人真正解释问题为什么发生。

`review-cy` 会暂停继续打补丁，用复现、系统模型、边界取证、可证伪假设和因果链，判断问题真正位于：

- 局部实现
- 契约与不变量
- 框架集成与生命周期
- 组件状态/抽象设计
- 系统架构与跨组件边界
- 配置、依赖和运行环境

目录名暂时保留 `review-cy`，兼容已有安装和公开仓库；v3 的产品定位已经从 code review 重置为 root-cause engineering diagnosis。

## 什么时候使用

典型触发：

```text
这个 bug AI 已经修了三轮，还是没解决。先别改代码，找真正根因。
```

```text
不要再加 null check 了，沿数据流查清这个坏状态从哪里产生。
```

```text
测试通过但生产仍失败，这是环境差异、框架生命周期，还是设计问题？
```

```text
每修一个地方，另一个模块就出问题。帮我判断是不是状态所有权或架构边界有缺陷。
```

也适用于原因不明确的测试失败、构建/CI 故障、性能退化、并发问题、集成异常和反复返工。

不用于：

- 普通 PR/diff 审查或 merge 门控
- 代码风格、命名和格式检查
- 没有具体故障场景的泛泛架构讨论
- 纯功能实现
- 已经证明根因后的机械修复
- 每次编辑、测试或提交后的例行检查

## 核心流程

```text
冻结补丁循环
  → 建立失败契约
  → 建立最小系统模型
  → 复现与成功对照
  → 沿边界定位首个错误状态
  → 用区分实验验证假设
  → 构造因果栈
  → 判定问题层级
  → 审判候选补丁
  → 给出止血 / 根因纠正 / 预防方案
```

## 多次 AI 修复失败时会做什么

Skill 会先记录每次尝试的：

- 原假设
- 具体改动
- 预期结果
- 实际结果
- 新增证据
- 工作区遗留的 workaround

然后区分：

- 症状未变：原假设或执行路径判断错误。
- 症状移动：补丁碰到了传播链，但上游仍产生无效状态。
- 新副作用出现：存在隐藏耦合、共享状态或遗漏契约。
- 测试绿、生产失败：测试 oracle 或环境模型不代表真实系统。
- guard/retry/fallback 越来越多：不变量没有在正确所有者处执行。

“修过很多次”只会触发深度诊断，不会被当作“架构一定有问题”的证据。

## 因果栈，而不是一个万能根因

报告会明确区分：

- `Symptom`：用户或测试看到的失败。
- `Trigger`：让潜伏问题暴露的条件。
- `Failure mechanism`：错误状态怎样传播。
- `Proximate cause`：直接导致失败的条件。
- `Root/systemic cause`：纠正后能阻止同类故障复发的可控因素。
- `Contributing factor`：放大概率或影响的条件。
- `Missing barrier`：本应预防或更早发现问题的控制。

每个节点还会标注所在系统层。一个流量峰值可能只是运行环境触发器，而真正根因可能是多层重试形成的架构反馈回路；不能把两者压成一句“流量太大”。

## 如何判断是不是架构问题

架构不是“改动很多”或“修了很久”的同义词。只有出现跨组件证据时才上升：

- 不变量没有明确所有者。
- 多个调用方重复同一种 guard、授权、转换或重试。
- 局部修复持续把故障推给另一个组件。
- 正确修复要求改变公共契约、状态所有权、依赖方向或故障边界。
- 只有在并发、负载、部分失败或真实生产拓扑下才出现。
- 修一个质量属性会破坏安全、性能、可靠性或可修改性中的另一个。

架构结论必须包含具体质量属性场景、端到端关键流、当前敏感点和候选方向的可测权衡。

## 什么叫“不是打补丁”

小改动也可以是根因修复，大重构也可能只是掩盖症状。

真正的纠正应当：

1. 恢复一条明确契约或系统不变量。
2. 位于最早拥有该不变量的责任边界。
3. 阻断已证实的 failure mechanism。
4. 覆盖等价输入和同源路径。
5. 有旧实现失败、新实现通过的验证证据。

线上回滚、限流、扩容和 feature flag 可以先止血，但必须标为 `CONTAINMENT`，写清移除条件，不能冒充最终修复。

## 输出

```text
Status: CONFIRMED | PROVISIONAL | INCONCLUSIVE

Problem contract
Attempts already made
Causal map
Layer assessment
Evidence and hypothesis ledger
Patch test
CONTAINMENT / ROOT_CORRECTION / PREVENTION
Verification
Unknowns and next discriminating experiment
```

默认只诊断，不修改业务源码。用户明确要求“诊断并修复”时，也会先冻结诊断报告和失败证据，再进入独立实现阶段。

## 安装

### Claude Code

```bash
git clone https://github.com/CY-CHENYUE/review-cy.git ~/.claude/skills/review-cy
```

### Codex

```bash
git clone https://github.com/CY-CHENYUE/review-cy.git ~/.codex/skills/review-cy
```

如果已经 clone `cc-skills`，建议用软链接指向其中的 canonical `review-cy/`，不要维护第二份手改副本。

## 文件结构

```text
review-cy/
├── SKILL.md
├── README.md
├── LICENSE
├── references/
│   ├── investigation-workflow.md
│   ├── causal-model.md
│   ├── diagnosis-layers.md
│   ├── anti-patch.md
│   ├── diagnostic-lenses.md
│   ├── method-selection.md
│   ├── evidence-and-report.md
│   └── design-sources.md
├── evals/evals.json
├── tests/test-skill-contract.sh
└── assets/wechat-qr.jpg
```

## 设计依据

主要参考：[Google SRE Effective Troubleshooting](https://sre.google/sre-book/effective-troubleshooting/)、[Google SRE Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)、[NASA 软件根因分析](https://swehb.nasa.gov/spaces/SWEHBVC/pages/50889445/SWE-204%2B-%2BProcess%2BAssessments)、[CMU SEI 架构质量属性分析](https://www.sei.cmu.edu/library/reasoning-about-software-quality-attributes/)、[Delta Debugging](https://www.st.cs.uni-saarland.de/papers/tse2002/)、[IBM 自动修复 Agent 可追踪性研究](https://research.ibm.com/publications/understanding-automated-program-repair-agents-through-the-lens-of-traceability-an-empirical-study)、[FixedBench](https://www.sri.inf.ethz.ch/publications/gloaguen2026coding) 和公开的 [Superpowers systematic-debugging](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/SKILL.md)。

完整的借鉴与否决记录见 [references/design-sources.md](references/design-sources.md)。

## 同步来源

本独立仓库由 [CY-CHENYUE/cc-skills](https://github.com/CY-CHENYUE/cc-skills) 中的 `review-cy/` 目录同步发布。`cc-skills` 是唯一编辑源，独立仓库是发布镜像。

## 许可

Apache-2.0，见 [LICENSE](LICENSE)。

## 交流

<div align="center">
  <p>扫码关注公众号，获取更新与交流反馈</p>
  <img src="assets/wechat-qr.jpg" alt="WeChat Official Account QR Code" width="200">
</div>
