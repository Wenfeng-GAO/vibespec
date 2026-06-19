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
echo "[2] All 7 steps present (Step 0-6)"
check "Step 0 exists" '### Step 0:'
check "Step 1 exists" '### Step 1:'
check "Step 2 exists" '### Step 2:'
check "Step 3 exists" '### Step 3:'
check "Step 4 exists" '### Step 4:'
check "Step 5 exists" '### Step 5:'
check "Step 6 exists" '### Step 6:'

echo ""
echo "[3] Hard constraints (7 rules)"
check "Hard constraint 1: no style code" '不写样式代码'
check "Hard constraint 2: no component code" '不写组件代码'
check "Hard constraint 3: no skip interaction states" '不跳过交互状态'
check "Hard constraint 4: no vague visual description" '不用模糊视觉描述'
check "Hard constraint 5: no route/page list = no write" '没有路由表不写入 DESIGN.md'
check "Hard constraint 6: no invent PRD features" '不发明 PRD 中不存在的功能需求'
check "Hard constraint 7: no tech selection" '不做技术选型'

echo ""
echo "[4] Step 0: Phase 1 state validation"
check "Step 0 reads state.json" '.vibespec/state.json'
check "Step 0 validates define confirmed" 'confirmed'
check "Step 0 blocks if Phase 1 incomplete" '尚未完成'
check "Step 0 extracts project-slug from artifact path" 'project-slug'

echo ""
echo "[5] Step 1: Design research (3 perspectives + completion criteria)"
check "Perspective 1: PRD interpretation" 'PRD 解读与设计需求提取'
check "Perspective 2: competitor UI" '竞品 UI 模式研究'
check "Perspective 3: design constraints" '设计约束与风险'
check "Step 1 completion: notes file created" '已创建'
check "Step 1 completion: notes file on disk" '写入磁盘'
check "Step 1 completion: 3 structured perspectives" '独立章节'
check "Step 1 completion: deferred design questions addressed" '初步设计方向'
check "Step 1 completion: block if file missing" '不得进入 Step 2'

echo ""
echo "[6] 14-dimension coverage scan"
check "Coverage 01: info architecture" '信息架构'
check "Coverage 02: route completeness" '路由完整性'
check "Coverage 03: page coverage" '页面覆盖'
check "Coverage 04: component structure" '组件结构'
check "Coverage 05: user flows" '用户流程'
check "Coverage 06: loading states" 'Loading 状态'
check "Coverage 07: empty states" 'Empty 状态'
check "Coverage 08: error states" 'Error 状态'
check "Coverage 09: edge cases" '边界情况'
check "Coverage 10: data flow" '数据流向'
check "Coverage 11: visual direction" '视觉方向'
check "Coverage 12: responsive" '响应式'
check "Coverage 13: accessibility" '可访问性'
check "Coverage 14: PRD traceability" 'PRD 需求追踪'

echo ""
echo "[7] DESIGN.md template sections"
check "Template: frontmatter phase=design" 'phase: design'
check "Template: frontmatter status=draft" 'status: draft'
check "Template: frontmatter prd field" 'prd:'
check "Template: frontmatter confirmed_at" 'confirmed_at:'
check "Template: info architecture section" '## 信息架构'
check "Template: route table section" '## 路由表'
check "Template: page inventory section" '## 页面清单'
check "Template: wireframe section" '## 低保真线框图'
check "Template: component tree section" '## 组件树'
check "Template: user flows section" '## 核心用户流程'
check "Template: interaction states section" '## 交互状态'
check "Template: data flow section" '## 数据流向'
check "Template: visual direction section" '## 视觉方向'
check "Template: responsive section" '## 响应式要求'
check "Template: accessibility section" '## 可访问性要求'
check "Template: design decision log section" '## 设计决策记录'
check "Template: defer to tech section" '## 延后到 Tech'
check "Template: confirmation records section" '## 确认记录'

echo ""
echo "[8] Step 5: Quality gate"
check "Quality gate: show Pass/Fail table" '展示自检结果表格'
check "Quality gate: block on skip" '不得跳过此步骤'
check "Quality gate: fix and recheck" '修正后重新自检'
check "Quality gate: wireframe completeness check" '低保真线框图'
check "Quality gate: route-page 1:1 check" '一一对应'

echo ""
echo "[9] 5-group confirmation"
check "Confirm group 1: IA + routes" '信息架构与路由表'
check "Confirm group 2: pages + components" '页面清单与组件树'
check "Confirm group 3: flows + states" '核心用户流程与交互状态'
check "Confirm group 4: data + visual" '数据流向与视觉方向'
check "Confirm group 5: responsive + a11y" '响应式与可访问性'

echo ""
echo "[10] Step 6: Completion protocol"
check "Completion: update frontmatter to confirmed" 'status: confirmed'
check "Completion: ISO 8601 timestamp" 'YYYY-MM-DDTHH:mm:ssZ'
check "Completion: state.json design entry" 'phases.design'
check "Completion: preserve existing define record" '原样保留'
check "Completion: artifact path in state.json" 'DESIGN.md'
check "Completion: do not auto-start Phase 3" '不要主动开始'

echo ""
echo "[11] {project-slug} path usage"
check "DESIGN.md path with project-slug" '{project-slug}/DESIGN.md'
check "Notes path with project-slug" '{project-slug}/phase2-design-notes.md'
check "PRD path reference with project-slug" '{project-slug}/PRD.md'

echo ""
echo "[12] DESIGN.md writing requirements"
check "Writing: routes cover all pages" '必须覆盖所有用户可达的页面'
check "Writing: pages 1:1 with routes" '一一对应'
check "Writing: states cover loading/empty/error" 'loading.*empty.*error'
check "Writing: quantified visual direction" '具体量化约束'
check "Writing: decisions have rationale" '记录选择和放弃理由'
check "Writing: P0 demand tracing" 'P0.*追踪'
check "Writing: wireframe per P0 page" 'P0 核心页面必须有一个 ASCII'

echo ""
echo "[13] Interaction rules"
check "Interaction: one question at a time" '一次只问一个'
check "Interaction: single-choice preferred" '单选问题'
check "Interaction: no bulk questions" '一次性抛给用户'
check "Interaction: design comparison format" '设计方案对比'

echo ""
echo "[14] Timestamp fallback rule"
check "Timestamp: ISO 8601 format" 'YYYY-MM-DDTHH:mm:ssZ'
check "Timestamp: date-only fallback logic" '当天日期'

echo ""
echo "[15] No code/tech leakage"
check "No tech selection in role" '不做技术选型'
check "No tech plan in role" '不进入 Tech Plan'
check "No framework recommendation" '不推荐框架'

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
