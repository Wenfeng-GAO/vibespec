#!/bin/bash
set -euo pipefail

SKILL_FILE="skills/phase3-tech/SKILL.md"
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

echo "=== Phase 3 SKILL.md Validation ==="
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
echo "[2] All 6 steps present (Step 0-5)"
check "Step 0 exists" '### Step 0:'
check "Step 1 exists" '### Step 1:'
check "Step 2 exists" '### Step 2:'
check "Step 3 exists" '### Step 3:'
check "Step 4 exists" '### Step 4:'
check "Step 5 exists" '### Step 5:'

echo ""
echo "[3] Hard constraints (7 rules)"
check "Hard constraint 1: no implementation code" '不写完整实现代码'
check "Hard constraint 2: no unverified dependencies" '不引入未经验证的外部依赖'
check "Hard constraint 3: no skipping data model" '不跳过数据模型'
check "Hard constraint 4: no skipping API contract" '不跳过 API 契约'
check "Hard constraint 5: dir structure matches DESIGN" '目录结构必须对应 DESIGN'
check "Hard constraint 6: verifiable commands" '验证命令必须可执行'
check "Hard constraint 7: no unilateral tech decisions" '不擅自决定关键技术选型'

echo ""
echo "[4] Step 0: Phase 2 state validation"
check "Step 0 reads state.json" '.vibespec/state.json'
check "Step 0 validates design confirmed" 'design.*confirmed'
check "Step 0 blocks if Phase 2 incomplete" '尚未完成'
check "Step 0 extracts project-slug from design artifact" 'phases.design.artifact'
check "Step 0 gathers deferred-to-tech items" '延后到 Tech'

echo ""
echo "[5] Step 1: Tech research (4 sub-steps)"
check "Sub-step 1.1: PRD/DESIGN tech requirements" 'PRD/DESIGN 技术需求提取'
check "Sub-step 1.2: existing codebase assessment" '现有代码库评估'
check "Sub-step 1.3: external dependency research" '外部依赖与生态研究'
check "Sub-step 1.4: tech constraints" '技术约束与风险预判'
check "Step 1 completion: notes file created" 'phase3-tech-notes.md'
check "Step 1 completion: notes file on disk" '已创建并写入磁盘'
check "Step 1 completion: 4 structured perspectives" '独立章节'
check "Step 1 completion: deferred items addressed" '初步技术方向'
check "Step 1 completion: block if file missing" '不得进入 Step 2'

echo ""
echo "[6] 14-dimension coverage scan"
check "Coverage 01: tech stack completeness" '技术栈完整性'
check "Coverage 02: dir structure vs DESIGN" '目录结构与 DESIGN 对应性'
check "Coverage 03: data model coverage" '数据模型覆盖'
check "Coverage 04: API contract coverage" 'API 契约覆盖'
check "Coverage 05: state management" '状态管理方案'
check "Coverage 06: external dependency assessment" '外部依赖评估'
check "Coverage 07: security boundary" '安全与权限边界'
check "Coverage 08: test strategy coverage" '测试策略覆盖'
check "Coverage 09: verification command executability" '验证命令可执行性'
check "Coverage 10: implementation risk identification" '实现风险识别'
check "Coverage 11: tech decision traceability" '技术决策可追溯'
check "Coverage 12: deferred item resolution" '延后项处理'
check "Coverage 13: PRD/DESIGN demand tracing" 'PRD/DESIGN 需求追踪'
check "Coverage 14: placeholder detection" '占位符检测'

echo ""
echo "[7] TECH.md template sections"
check "Template: frontmatter phase=tech" 'phase: tech'
check "Template: frontmatter status=draft" 'status: draft'
check "Template: frontmatter prd link" 'prd:'
check "Template: frontmatter design link" 'design:'
check "Template: frontmatter confirmed_at" 'confirmed_at:'
check "Template: tech stack section" '## 技术栈'
check "Template: directory structure section" '## 目录结构'
check "Template: data model section" '## 数据模型'
check "Template: API contract section" '## API 契约'
check "Template: state management section" '## 状态管理'
check "Template: external dependencies section" '## 外部依赖'
check "Template: security section" '## 安全和权限边界'
check "Template: test strategy section" '## 测试策略'
check "Template: verification commands section" '## 验证命令'
check "Template: implementation risks section" '## 实现风险'
check "Template: tech decision log section" '## 技术决策记录'
check "Template: deferred to implementation section" '## 延后到实现'
check "Template: confirmation records section" '## 确认记录'

echo ""
echo "[8] Step 5: Quality gate (11 items)"
check "Quality gate: placeholder check" '是否仍有占位符'
check "Quality gate: implementation code leakage" '完整实现代码泄漏'
check "Quality gate: P0 demand mapping" 'P0.*需求.*数据模型或 API 契约'
check "Quality gate: data model covers DESIGN entities" 'DESIGN.md 中所有数据实体'
check "Quality gate: API covers CRUD operations" 'CRUD 操作'
check "Quality gate: external dependency assessment" '外部依赖.*评估依据'
check "Quality gate: dir structure annotated" 'DESIGN.md 路由和组件'
check "Quality gate: tech decisions with rationale" '选择理由和放弃的替代方案'
check "Quality gate: deferred items resolved" '解决或明确延后到实现'
check "Quality gate: verification commands executability" '可执行或有明确的不可执行原因'
check "Quality gate: TECH.md still draft" 'TECH.md.*draft'
check "Quality gate: show Pass/Fail table" '展示自检结果表格'
check "Quality gate: block on skip" '不得跳过此步骤'
check "Quality gate: fix and recheck" '修正后重新自检'

echo ""
echo "[9] 5-group confirmation"
check "Confirm group 1: tech stack + dir structure" '技术栈与目录结构'
check "Confirm group 2: data model + API contract" '数据模型与 API 契约'
check "Confirm group 3: state mgmt + external deps" '状态管理与外部依赖'
check "Confirm group 4: security + testing" '安全边界与测试策略'
check "Confirm group 5: risks + tech decisions" '实现风险与技术决策'

echo ""
echo "[10] Step 5: Completion protocol"
check "Completion: update frontmatter to confirmed" 'status: confirmed'
check "Completion: ISO 8601 timestamp" 'YYYY-MM-DDTHH:mm:ssZ'
check "Completion: state.json tech entry" 'phases.tech'
check "Completion: preserve define + design records" '原样保留'
check "Completion: artifact path in state.json" 'TECH.md'
check "Completion: do not auto-start Phase 4" '不要主动开始'

echo ""
echo "[11] {project-slug} path usage"
check "TECH.md path with project-slug" '{project-slug}/TECH.md'
check "Notes path with project-slug" '{project-slug}/phase3-tech-notes.md'
check "PRD path reference with project-slug" '{project-slug}/PRD.md'
check "DESIGN path reference with project-slug" '{project-slug}/DESIGN.md'

echo ""
echo "[12] Code boundary rules"
check "Allow: type definitions for API contract" '接口/类型定义'
check "Allow: interface signatures" 'interface'
check "Forbid: method body implementations" '方法体实现'
check "Forbid: business logic" '业务逻辑'
check "Forbid: complete algorithm" '完整算法'

echo ""
echo "[13] TECH.md writing requirements"
check "Writing: version constraints required" '版本约束'
check "Writing: dir structure maps to DESIGN routes" '路由表和组件树'
check "Writing: data model covers DESIGN entities" 'DESIGN.md 中"数据实体"'
check "Writing: API covers CRUD" 'CRUD 操'
check "Writing: code examples = types only" '接口/类型定义和伪代码'
check "Writing: dependency assessment required" '评估依据'
check "Writing: verification commands runnable" '可直接复制'
check "Writing: tech decisions log alternatives" '放弃方案.*原因'
check "Writing: P0 demand tracing" 'P0.*追踪'
check "Writing: defer unresolved to implementation" '延后到实现'

echo ""
echo "[14] Interaction rules"
check "Interaction: one question at a time" '一次只问一个'
check "Interaction: single-choice preferred" '单选问题'
check "Interaction: no bulk questions" '一次性抛给用户'
check "Interaction: tech comparison format" '技术方案对比'

echo ""
echo "[15] Timestamp fallback rule"
check "Timestamp: ISO 8601 format" 'YYYY-MM-DDTHH:mm:ssZ'
check "Timestamp: date-only fallback logic" '当天日期'

echo ""
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