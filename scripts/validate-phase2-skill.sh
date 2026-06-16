#!/bin/bash
set -euo pipefail

SKILL_FILE="skills/phase2-design/SKILL.md"
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

echo "=== Phase 2 SKILL.md Validation ==="
echo ""
cd "$(dirname "$0")/.."

if [ ! -f "$SKILL_FILE" ]; then
  echo "FAIL: $SKILL_FILE not found"
  exit 1
fi

echo "[1] Frontmatter completeness"
check "Frontmatter: name field" '^name:'
check "Frontmatter: description field" '^description:'
check "Frontmatter: argument-hint field" '^argument-hint:'

echo ""
echo "[2] Multi-project artifact paths (docs/vibespec/{project-slug}/)"
check "DESIGN path uses {project-slug}" 'docs/vibespec/{project-slug}/DESIGN.md'
check "Notes path uses {project-slug}" 'docs/vibespec/{project-slug}/phase2-design-notes.md'
check "Reads confirmed PRD by {project-slug}" 'docs/vibespec/{project-slug}/PRD.md'

echo ""
echo "[3] Phase 1 dependency gate"
check "Requires define confirmed" 'phases.define.status === "confirmed"'
check "Blocks when Phase 1 incomplete" 'Phase 1 (Define) 尚未完成'

echo ""
echo "[4] All 7 steps present"
check "Step 0 exists" '### Step 0:'
check "Step 1 exists" '### Step 1:'
check "Step 2 exists" '### Step 2:'
check "Step 3 exists" '### Step 3:'
check "Step 4 exists" '### Step 4:'
check "Step 5 exists" '### Step 5:'
check "Step 6 exists" '### Step 6:'

echo ""
echo "[5] Hard constraints (7 rules)"
check "Constraint: no style code" '不写样式代码'
check "Constraint: no component code" '不写组件代码'
check "Constraint: no skipping interaction states" '不跳过交互状态'
check "Constraint: no vague visual description" '不用模糊视觉描述'
check "Constraint: no DESIGN without routes/pages" '没有路由表不写入 DESIGN.md'
check "Constraint: no inventing requirements" '不发明 PRD 中不存在的功能需求'
check "Constraint: no tech selection" '不做技术选型'

echo ""
echo "[6] Step 1 research checkpoint gate"
check "Step 1 has blocking gate (no proceed without file)" '不得进入 Step 2'
check "Step 1 requires notes file created" '文件已创建并写入磁盘'
check "Step 1 three perspectives" 'PRD 解读、竞品 UI 模式、设计约束与风险'

echo ""
echo "[7] Step 3 coverage scan (14 dimensions)"
check "Coverage: information architecture" '| 信息架构 |'
check "Coverage: route completeness" '| 路由完整性 |'
check "Coverage: page coverage" '| 页面覆盖 |'
check "Coverage: component structure" '| 组件结构 |'
check "Coverage: user flows" '| 用户流程 |'
check "Coverage: loading state" '| Loading 状态 |'
check "Coverage: empty state" '| Empty 状态 |'
check "Coverage: error state" '| Error 状态 |'
check "Coverage: edge cases" '| 边界情况 |'
check "Coverage: data flow" '| 数据流向 |'
check "Coverage: visual direction" '| 视觉方向 |'
check "Coverage: responsive" '| 响应式 |'
check "Coverage: accessibility" '| 可访问性 |'
check "Coverage: PRD requirement tracing" '| PRD 需求追踪 |'

echo ""
echo "[8] Step 5 quality gate"
check "Step 5 requires visible self-check output" '展示自检结果表格'
check "Step 5 blocking gate" '不得跳过此步骤'
check "Step 5 requires Pass/Fail marking" '标记 Pass 或 Fail'

echo ""
echo "[9] Step 6 five-group confirmation"
check "Confirm group 1" '信息架构与路由表'
check "Confirm group 2" '页面清单与组件树'
check "Confirm group 3" '核心用户流程与交互状态'
check "Confirm group 4" '数据流向与视觉方向'
check "Confirm group 5" '响应式与可访问性'

echo ""
echo "[10] DESIGN.md template frontmatter"
check "DESIGN template: phase" 'phase: design'
check "DESIGN template: status" 'status: draft'
check "DESIGN template: prd link" 'prd: docs/vibespec/{project-slug}/PRD.md'
check "DESIGN template: created" 'created: YYYY-MM-DD'
check "DESIGN template: confirmed_at" 'confirmed_at:'

echo ""
echo "[10b] Low-fidelity wireframe requirement"
check "Wireframe section in template" '## 低保真线框图'
check "Wireframe required for P0 pages" 'P0 核心页面必须有一个 ASCII 低保真线框图'
check "Wireframe in Step 5 self-check" 'P0 核心页面都有 ASCII 低保真线框图'

echo ""
echo "[11] State.json update protocol"
check "state.json design artifact path" 'artifact.*docs/vibespec/{project-slug}/DESIGN.md'
check "state.json design confirmed status" '"status": "confirmed"'
check "Preserves Phase 1 define record" '原样保留'

echo ""
echo "[12] Timestamp guidance (no fabricated precision)"
check "confirmed_at fallback guidance" 'T00:00:00Z'

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
