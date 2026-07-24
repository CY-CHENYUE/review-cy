# 证据强度与诊断报告

报告的目标是让下一位工程师能复核因果判断并决定纠正层级，而不是展示排查过程有多长。

## 证据层次

由强到弱大致为：

1. 可重复的失败/成功对照与单变量反事实实验。
2. 完整的数据流、控制流、状态转换和契约闭环。
3. 生产时间线、trace、遥测与自然版本/配置对照。
4. 官方规范、框架源码、release note 与最小受支持复现。
5. 相关日志、recent change、历史类似故障和经验模式。
6. 直觉、命名、代码气味或未经验证的工具告警。

弱证据可以产生假设，不能单独确认根因。多个来源若都依赖同一错误假设，不构成真正交叉验证。

## 状态定义

### CONFIRMED

- failure contract 清晰。
- 因果链解释关键事实与成功对照。
- 存在可重复反事实，或代码/状态/契约证据构成确定闭环。
- 主要竞争假设和混杂因素已检查。
- 能说明纠正为何覆盖同类故障。

### PROVISIONAL

- 当前模型最能解释证据，主要替代解释已检查。
- 关键反事实因安全、环境、数据或权限限制无法完成。
- 报告明确剩余假设和可能改变结论的证据。

不要把 `PROVISIONAL` 写成“基本确定”。

### INCONCLUSIVE

- 预期/实际、范围、时间线或 oracle 不清。
- 无法取得代表性失败证据。
- 多个候选原因仍产生相同预测。
- 关键代码、调用方、环境或外部系统不可见。

必须给下一项最有区分度的实验，不用猜测填满报告。

## 完整报告模板

```markdown
# 工程诊断

Status: CONFIRMED | PROVISIONAL | INCONCLUSIVE
One-line diagnosis: <cause and mechanism, or exactly what remains unknown>

## Problem contract

- Expected:
- Actual:
- Impact/scope:
- Trigger/reproduction:
- Timeline/recent changes:
- Oracle:

## Attempts already made

| Attempt | Hypothesis/prediction | Actual result | What it rules in/out |
|---|---|---|---|

## Causal map

- Symptom:
- Trigger:
- First invalid state:
- Failure mechanism:
- Proximate cause:
- Root/systemic cause(s):
- Contributing factors:
- Missing barrier / escape cause:

## Layer assessment

- Primary layer:
- Owner and violated invariant:
- Why this layer:
- Rejected alternative layers:
- Failure domain / blast radius: <known affected path, unknown scope, and evidence needed to bound it; required for architecture claims>
- Quality-attribute scenario (only for architecture claims):

## Evidence and hypothesis ledger

| Claim/hypothesis | Predicts | Evidence or experiment | State |
|---|---|---|---|

## Patch test

- Obvious local workaround:
- Why it is containment, a valid root correction, or a symptom patch:
- Equivalent paths checked:
- New coupling/state/trade-offs:

## Actions

### CONTAINMENT
<optional reversible stabilization, owner and removal condition>

### ROOT_CORRECTION
<direction tied to the confirmed/provisional causal model; no speculative code dump>

### PREVENTION
<model/contract/isolation/test/observability/release improvements>

## Verification

- Tests/experiments already run:
- Root-correction proof:
- Adjacent and regression scenarios:
- Containment removal criteria:

## Unknowns

- Unavailable evidence:
- Residual competing hypotheses:
- Next most discriminating experiment:
```

## 写作要求

- 结论在前，原始事实与推断分开。
- 每个根因声明都带系统层、责任所有者、不变量和证据。
- 对没有实际运行的测试写“未运行”，不要用建议命令冒充结果。
- 对没有代码、日志或运行环境的文本诊断，把“建议检查/下一项实验”与“已经检查所得证据”分开；验证计划不能冒充执行结果。
- 披露使用的代码范围、日志时间、环境和版本。
- 记录被拒绝的竞争假设，避免后来重复尝试。
- 不以“开发者/AI 写错了”作为根因；继续分析哪些契约、模型或屏障允许错误发生。
- 不输出 PR gate、PASS/FAIL、P0/P1 findings 或逐行 review 清单。

## 简版报告

简单、已确认的实现错误不必填满所有章节，但仍应保留：

```markdown
Status: CONFIRMED
Cause: <condition + violated invariant + mechanism + symptom>
Layer: IMPLEMENTATION
Evidence: <reproduction/counterfactual>
Why not a patch: <owner and equivalent paths>
Root correction: <direction>
Verification: <regression and adjacent cases>
```

简洁不能省略因果与证据；复杂不能成为堆砌术语的理由。
