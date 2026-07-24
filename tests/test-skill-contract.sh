#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SKILL="$ROOT/SKILL.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

require_text() {
  grep -Fq -- "$2" "$1" || fail "missing text '$2' in $1"
}

reject_text() {
  if grep -Fiq -- "$2" "$1"; then
    fail "obsolete text '$2' found in $1"
  fi
}

require_file "$SKILL"
require_text "$SKILL" "name: review-cy"
require_text "$SKILL" "license: Apache-2.0"
require_text "$SKILL" 'version: "3.0.0"'
require_text "$SKILL" "默认只读"
require_text "$SKILL" "修复尝试账本"
require_text "$SKILL" "爆炸半径"

for token in CONFIRMED PROVISIONAL INCONCLUSIVE IMPLEMENTATION CONTRACT FRAMEWORK_INTEGRATION COMPONENT_DESIGN SYSTEM_ARCHITECTURE RUNTIME_ENVIRONMENT CONTAINMENT ROOT_CORRECTION PREVENTION; do
  require_text "$SKILL" "$token"
done

for ref in investigation-workflow.md causal-model.md diagnosis-layers.md anti-patch.md diagnostic-lenses.md method-selection.md evidence-and-report.md design-sources.md; do
  require_file "$ROOT/references/$ref"
  require_text "$SKILL" "references/$ref"
done

for obsolete in "codex review" "codex exec" "CODEX SAYS" "model_reasoning_effort" "web_search_cached" "codex-session-id" "NO_BLOCKERS_FOUND" "P0/P1 PR"; do
  reject_text "$SKILL" "$obsolete"
done

require_file "$ROOT/README.md"
require_file "$ROOT/LICENSE"
require_file "$ROOT/assets/wechat-qr.jpg"
require_text "$ROOT/README.md" "Vibe coding"
require_text "$ROOT/README.md" "assets/wechat-qr.jpg"
require_text "$ROOT/LICENSE" "Apache License"

python3 - "$ROOT/evals/evals.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

assert data["skill_name"] == "review-cy"
evals = data["evals"]
assert len(evals) >= 12
assert len({item["id"] for item in evals}) == len(evals)
for item in evals:
    assert item["prompt"].strip()
    assert item["expected_output"].strip()
    assert len(item.get("expectations", [])) >= 2

joined = "\n".join(item["expected_output"] for item in evals)
for token in ("IMPLEMENTATION", "INCONCLUSIVE", "CONTAINMENT"):
    assert token in joined

prompts = "\n".join(item["prompt"] for item in evals)
assert "AI" in prompts and ("修了四次" in prompts or "修复" in prompts)
assert any("已知与未知的爆炸半径" in exp for item in evals for exp in item.get("expectations", []))
PY

echo "PASS: review-cy v3 skill contract"
