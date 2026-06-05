# Research Notes

These notes summarize the initial exploration for VibeSpec.

## Core Insight

Medium-sized app and web projects need more than a fast coding agent. They need a workflow that forces product clarity, staged review, and explicit verification before implementation drifts too far.

The product opportunity is not to replace tools like Lovable, Bolt, Replit Agent, v0, Cursor, Claude Code, Codex, or Gemini CLI. It is to orchestrate the work around them.

## User Pain Points

1. **Unclear product definition**
   - The user often starts with a rough idea instead of a PRD.
   - Feature behavior, page structure, user journeys, and acceptance criteria are implicit.
   - The agent fills in gaps freely, so the final result may feel wrong even when it "works".

2. **Weak validation standards**
   - The agent may optimize for task completion instead of product quality.
   - Visual quality, UX states, edge cases, accessibility, performance, and maintainability are often under-specified.
   - Without a rubric, the agent can lower expectations without saying so.

3. **Late feedback**
   - Many vibe-coding sessions behave like a long blind run.
   - The user sees the real product too late.
   - Rework becomes expensive because foundational decisions have already leaked into code.

## Product Thesis

VibeSpec should be a **workflow layer** for vibe coding:

- upstream of implementation,
- independent of any single coding agent,
- artifact-driven,
- checkpoint-driven,
- and verification-driven.

It should make the agent ask better questions, produce better plans, stop at useful review points, and prove quality with concrete evidence.

## Reference Tools

### GitHub Spec Kit

Reference: <https://github.com/github/spec-kit>

What to borrow:

- Spec-driven development flow.
- Constitution for durable project principles.
- Clarification before planning.
- Checklists before implementation.
- Commands such as specify, plan, tasks, implement, clarify, analyze, and checklist.

Gap for VibeSpec:

- Spec Kit is strong for engineering workflow but less focused on visual exploration, user-facing product review, and non-expert checkpoint UX.

### Kiro Specs

Reference: <https://kiro.dev/docs/specs/>

What to borrow:

- The split between requirements, design, and tasks.
- Task status and guided execution UI.
- Explicit distinction between quick vibe work and spec work.
- Better long-running feature continuity.

Gap for VibeSpec:

- It is still centered around an IDE agent experience. VibeSpec can be more tool-neutral and product/design-first.

### BMad Method

Reference: <https://github.com/bmad-code-org/BMAD-METHOD>

What to borrow:

- Multi-agent roles: analyst, PM, architect, UX, developer, QA.
- Planning artifacts before implementation.
- Agentic agile framing.
- Brainstorming and research stages before build.

Gap for VibeSpec:

- It is powerful but can feel method-heavy. VibeSpec should compress the workflow for solo creators and small teams.

### GSD Core

Reference: <https://github.com/open-gsd/gsd-core>

What to borrow:

- Phase loop: discuss, plan, execute, verify, ship.
- Planning artifacts such as project, requirements, roadmap, context, validation, plan, summary, verification, and UAT.
- UI spec contract.
- Plan checker and verification workflows.
- Conversational UAT.

What it cannot fully solve:

- Product discovery and product strategy.
- Deep PRD structure for user journeys, page inventory, analytics, permissions, and release decisions.
- Visual ideation and high-fidelity design review.
- Non-technical dashboard experience.
- Template packs for common app/web categories.

### OpenSpec, SpecDD, and Colign

References:

- <https://github.com/Fission-AI/OpenSpec>
- <https://specdd.ai/>
- <https://www.colign.co/>

What to borrow:

- Repo-local specs.
- AI-readable product context.
- Vendor-neutral assistant support.
- Lightweight spec files that can travel with the codebase.

Gap for VibeSpec:

- These are closer to infrastructure or protocol layers. VibeSpec can own the product workflow and UX on top.

### Task Master AI

Reference: <https://docs.task-master.dev/getting-started/quick-start/prd-quick>

What to borrow:

- PRD to tasks and subtasks.
- Dependency-aware task graph.
- Execution-friendly task breakdown.

Gap for VibeSpec:

- It is stronger in task management than product/design validation.

### AI App Builders

References:

- Lovable: <https://docs.lovable.dev/>
- Bolt: <https://bolt.new/>
- Replit Agent: <https://docs.replit.com/references/agent/overview>
- v0: <https://v0.app/docs>
- Firebase Studio: <https://firebase.google.com/docs/studio/get-started-ai>
- Figma Make: <https://developers.figma.com/docs/code/intro-to-figma-make/>

What to borrow:

- Fast generation loop.
- Live preview.
- Point-and-edit feedback.
- One-click deploy or share.
- Design-system-aware generation.
- Visual-first prototyping.

Gap for VibeSpec:

- These tools generate quickly, but medium-sized products still need stronger PRD discipline, staged approvals, requirement coverage, and quality gates.

### Agent Skills

References:

- <https://agentskills.io/>
- <https://code.claude.com/docs/en/skills>

What to borrow:

- Skills as reusable workflow packages.
- File-based instructions, scripts, references, and assets.
- Marketplace or shareable packs.

Gap for VibeSpec:

- Skills provide capabilities, but users still need an opinionated workflow that decides when each skill should run.

## Local Skill References

Useful local skills observed during exploration:

- `product-design:get-context`, `product-design:ideate`, `product-design:image-to-code`, `product-design:audit`, `product-design:design-qa`
- `ce:brainstorm`, `ce:plan`, `ce:work`, `ce:review`
- `document-review`, `product-lens-reviewer`, `design-lens-reviewer`, `scope-guardian-reviewer`, `security-lens-reviewer`, `feasibility-reviewer`
- `frontend-design`, `design-shotgun`, `plan-design-review`, `design-review`, `design-iterator`
- `qa`, `qa-only`, `test-browser`, `verification-before-completion`
- `agent-native-architecture`, `agent-native-reviewer`

These skills suggest that VibeSpec could start as a curated workflow and skill pack before becoming a full product UI.

## Recommended MVP Shape

### 1. Spec Builder

Convert idea to:

- product brief,
- PRD,
- user personas,
- user journeys,
- page inventory,
- feature specs,
- acceptance criteria,
- non-goals,
- risks,
- open decisions.

### 2. Checkpoint Workspace

Create explicit stop points:

- product brief approval,
- PRD review,
- design direction review,
- implementation plan review,
- phase implementation review,
- browser QA review,
- UAT approval.

### 3. Quality Gates

Each stage needs pass/fail evidence:

- requirement coverage,
- UX flow coverage,
- visual quality,
- responsive behavior,
- accessibility,
- browser interaction,
- engineering tests,
- deployment readiness.

## Product Differentiation

VibeSpec should combine:

- Spec Kit and Kiro's spec discipline,
- BMad's role-based product thinking,
- GSD Core's phase loop and verification,
- Lovable/v0/Figma Make's visual feedback loop,
- Agent Skills' reusable capability packaging.

The wedge is:

> Help solo creators and small teams vibe code medium-sized products without losing control of product intent, design quality, and delivery confidence.

## Possible Next Artifacts

- `docs/product-brief.md`
- `docs/prd.md`
- `docs/mvp-plan.md`
- `docs/workflow.md`
- `docs/artifact-model.md`
- `docs/quality-gates.md`
- `docs/competitive-map.md`
- `skills/`
- `templates/`
