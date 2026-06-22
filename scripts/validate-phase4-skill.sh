#!/bin/bash
set -euo pipefail

SKILL_FILE="skills/phase4-implement/SKILL.md"
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

echo "=== Phase 4 SKILL.md Validation ==="
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
echo "[2] Multi-session execution loop (not linear Step 0-N)"
check "Execution loop documented" '执行循环'
check "Step 0: validate upstream" 'Step 0: 验证上游'
check "Step 0a: task splitting" 'Step 0a: Task 拆分'
check "Step 1: read current task" 'Step 1: 读取当前'
check "Step 2: implement" 'Step 2: 实现'
check "Step 3: self-check" 'Step 3: 自检'
check "Step 4: record result" 'Step 4: 记录结果'

echo ""
echo "[3] Invocation modes"
check "No task-id: find next pending" '无 task-id'
check "Explicit task-id: execute specified" 'T{N}.*明确'
check "Continue: execute next pending" 'continue.*执行下一个'
check "Retry: re-execute last failed" 'retry.*重新执行'
check "Status: report progress" 'status.*报告'

echo ""
echo "[4] Hard constraints (8 rules)"
check "HC 1: scope limit per task" '不一次改动过大范围'
check "HC 2: no TODO/FIXME placeholders" '占位符注释'
check "HC 3: no cross-task jumping" '不跨 task 随意跳转'
check "HC 4: no skipping verification" '不忽略验证命令'
check "HC 5: 3-failure ceiling" '连续失败超过.*2.*次'
check "HC 6: no modifying out-of-scope files" '允许修改范围外'
check "HC 7: no unrelated code" '与 task 无关的代码'
check "HC 8: no skipping self-check recording" '不跳过自检'

echo ""
echo "[5] Step 0: Phase 3 state validation"
check "Step 0 validates tech confirmed" 'tech.*confirmed'
check "Step 0 blocks if Phase 3 incomplete" '尚未完成'
check "Step 0 extracts project-slug from tech artifact" 'phases.tech.artifact'
check "Step 0 reads PRD + DESIGN + TECH" 'PRD.*DESIGN.*TECH'
check "Step 0 detects missing TASKS.md" 'TASKS.md.*不存在'

echo ""
echo "[6] Step 0a: Task splitting rules"
check "Dependency ordering" '依赖排序'
check "Layer ordering: infra first" '基础设施先于业务逻辑'
check "Max 3-5 files per task" '3-5.*文件'
check "Stable task IDs (T1, T2...)" '稳定 ID'
check "P0 coverage required" 'P0.*覆盖'
check "P1/P2 annotation" '\[P1\].*\[P2\]'
check "TASKS.md template: task goal" 'task 目标'
check "TASKS.md template: input context (前置依赖)" '前置依赖'
check "TASKS.md template: modification scope" '允许修改范围'
check "TASKS.md template: expected output" '预期产出'
check "TASKS.md template: verification method" '验证方式'
check "TASKS.md template: completion summary" '完成总结'

echo ""
echo "[7] Step 3: Self-check items"
check "Self-check: typecheck" 'typecheck'
check "Self-check: lint" 'lint'
check "Self-check: no TODO/FIXME" 'TODO.*FIXME'
check "Self-check: files in scope" '允许修改范围'
check "Self-check: expected output files exist" '预期产出'
check "Self-check: fallback for uninitialized project" '尚未初始化'

echo ""
echo "[8] Step 4: Result recording"
check "On success: task -> completed" 'task.*completed'
check "On success: consecutiveFailures -> 0" 'consecutiveFailures.*0'
check "On failure: task -> failed" 'failed.*reason'
check "On failure: consecutiveFailures++" 'consecutiveFailures.*N'
check "TASKS.md completion summary appended" '完成总结'

echo ""
echo "[9] Failure escalation (3 consecutive failures)"
check "3 failures triggers human intervention" 'human-intervention-needed'
check "Explicit stop message on 3 failures" '连续 3.*task.*失败'
check "Suggestions to user on failure" '检查 TASKS.md'

echo ""
echo "[10] Completion protocol"
check "All tasks done: status -> completed" 'status.*completed'
check "All tasks done: do NOT auto-start Phase 5" '不自动进入 Phase 5'
check "All tasks done: prompt user for Phase 5" 'Phase 5.*集成验证'
check "More tasks pending: prompt next invocation" '再次调用继续'

echo ""
echo "[11] state.json format"
check "implement phase entry" 'phases.implement'
check "implement status enum" 'in-progress.*completed.*human-intervention-needed'
check "tasks sub-object with status per task" 'T1.*status'
check "consecutiveFailures counter" 'consecutiveFailures'
check "currentTask tracker" 'currentTask'
check "startedAt timestamp" 'startedAt'
check "completedAt timestamp" 'completedAt'
check "Preserves define + design + tech records" '原样保留'

echo ""
echo "[12] Task status enum"
check "Task status: pending" 'pending'
check "Task status: in-progress (Step 2 start)" 'in-progress'
check "Task status: completed" 'completed'
check "Task status: failed" 'failed'
check "Task attempt counter" 'attempt'

echo ""
echo "[13] {project-slug} path usage"
check "PRD path with project-slug" '{project-slug}/PRD.md'
check "DESIGN path with project-slug" '{project-slug}/DESIGN.md'
check "TECH path with project-slug" '{project-slug}/TECH.md'
check "TASKS.md path with project-slug" '{project-slug}/TASKS.md'

echo ""
echo "[14] Interaction rules"
check "One task per invocation declared" '每次调用只执行一个'
check "Announce task before executing" '执行前宣布'
check "On failure: record, don't diagnose" '不做诊断对话'
check "Status mode: progress only" '只输出当前进度'

echo ""
echo "[15] Role and scope"
check "Role: implementing engineer" '执行工程师'
check "Multi-session vs single-session comparison" 'Phase 1-3.*单 session'
check "Phase 4 writes code (first phase)" '产出代码文件'
check "Phase 4 NO human confirmation to exit" '不需要人工确认来退出'

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
