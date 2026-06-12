#!/bin/bash
set -euo pipefail

SKILL_FILE="skills/phase1-define/SKILL.md"
PASS=0
FAIL=0
FAILURES=""

check() {
  local label="$1"
  local pattern="$2"
  if grep -q "$pattern" "$SKILL_FILE"; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label"
    FAIL=$((FAIL + 1))
    FAILURES="${FAILURES}\n  - ${label}"
  fi
}

check_count() {
  local label="$1"
  local pattern="$2"
  local expected="$3"
  local count
  count=$(grep -c "$pattern" "$SKILL_FILE" || true)
  if [ "$count" -ge "$expected" ]; then
    echo "  PASS: $label (found $count, need >= $expected)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label (found $count, need >= $expected)"
    FAIL=$((FAIL + 1))
    FAILURES="${FAILURES}\n  - ${label} (found $count, need >= $expected)"
  fi
}

echo "=== Phase 1 SKILL.md Validation ==="
echo ""
cd "$(dirname "$0")/.."

if [ ! -f "$SKILL_FILE" ]; then
  echo "FAIL: $SKILL_FILE not found"
  exit 1
fi

echo "[1] Multi-project artifact paths"
check "PRD path uses {project-slug}" '{project-slug}/PRD.md'
check "Notes path uses {project-slug}" '{project-slug}/phase1-define-notes.md'

echo ""
echo "[2] Step 1 completion criteria"
check "Step 1 has blocking gate (no proceed without file)" '不得进入 Step 2'
check "Step 1 requires file creation" '文件已创建'
check "Step 1 requires 4 perspectives" '用户与场景、产品边界、风险与假设、对标模式'

echo ""
echo "[3] Step 1 four-perspective table"
check "Perspective table: user & scenario" '用户与场景'
check "Perspective table: product boundary" '产品边界'
check "Perspective table: risk & assumptions" '风险与假设'
check "Perspective table: benchmark patterns" '对标模式'

echo ""
echo "[4] Step 6 completion criteria"
check "Step 6 requires visible output" '展示自检结果'
check "Step 6 blocking gate" '不得跳过此步骤'
check "Step 6 requires Pass/Fail marking" 'Pass.*Fail'

echo ""
echo "[5] State.json artifact path"
check "state.json uses {project-slug}" 'artifact.*{project-slug}/PRD.md'

echo ""
echo "[6] Frontmatter completeness"
check "Frontmatter: name field" '^name:'
check "Frontmatter: description field" '^description:'
check "Frontmatter: argument-hint field" '^argument-hint:'

echo ""
echo "[7] All 8 steps present"
check "Step 0 exists" '### Step 0:'
check "Step 1 exists" '### Step 1:'
check "Step 2 exists" '### Step 2:'
check "Step 3 exists" '### Step 3:'
check "Step 4 exists" '### Step 4:'
check "Step 5 exists" '### Step 5:'
check "Step 6 exists" '### Step 6:'
check "Step 7 exists" '### Step 7:'
check "Step 8 exists" '### Step 8:'

echo ""
echo "[8] Hard constraints (7 rules)"
check_count "7 hard constraints present" '^\d\+\.' 7

echo ""
echo "[9] Coverage scan table (12 dimensions)"
check "Coverage scan: goals" '目标与问题'
check "Coverage scan: user profile" '用户画像'
check "Coverage scan: core scenarios" '核心场景'
check "Coverage scan: user journey" '用户旅程'
check "Coverage scan: feature scope" '功能范围'
check "Coverage scan: anti-features" 'Anti-Features'
check "Coverage scan: success criteria" '成功标准'
check "Coverage scan: constraints" '约束与依赖'
check "Coverage scan: risks" '风险与假设'
check "Coverage scan: terminology" '术语一致性'
check "Coverage scan: completion signal" '完成信号'
check "Coverage scan: placeholder detection" '占位符检测'

echo ""
echo "[10] 5-group confirmation list"
check "Confirm group 1" '产品目标与目标用户'
check "Confirm group 2" '核心场景与用户旅程'
check "Confirm group 3" '功能需求与.*P0/P1/P2'
check "Confirm group 4" '成功标准与不做什么'
check "Confirm group 5" '风险、假设与未决问题'

echo ""
echo "[11] PRD template frontmatter"
check "PRD template: phase" 'phase: define'
check "PRD template: status" 'status: draft'
check "PRD template: created" 'created: YYYY-MM-DD'
check "PRD template: updated" 'updated: YYYY-MM-DD'
check "PRD template: confirmed_at" 'confirmed_at:'

echo ""
echo "=== Results ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failed checks:"
  echo -e "$FAILURES"
  exit 1
else
  echo ""
  echo "ALL CHECKS PASSED"
  exit 0
fi
