# Story 001: Spawn — ChestComponent + ProximityPrompt + T1/T2/T3 tier handling

> **Epic**: ChestSystem (Chest System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/chest-system.md`
**Requirement**: `TR-chest-011`, `TR-chest-021`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 Module Placement + ADR-0003 Performance Budget (9 ProximityPrompt cap)
**ADR Decision Summary**: ChestSystem at `ServerStorage/Source/ChestSystem/init.luau`. ChestComponent attached via ComponentCreator + `ChestTag` CollectionService tag (ANATOMY §9). MVP scope: T1 + T2 spawned at createAll (T3 silently skipped — registry framework supports). 9-prompt instance cap (6 T1 + 3 T2 MVP).

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: ProximityPrompt + CollectionService stable pre-cutoff.

**Control Manifest Rules:**
- Required: Server module under `ServerStorage/Source/ChestSystem/init.luau` (ADR-0006)
- Required: ComponentCreator pattern from ANATOMY §9 (CLAUDE.md)
- Required: CollectionService tag via `SharedConstants/CollectionServiceTag/ChestTag.luau` (ADR-0006)
- Required: ChestTier attribute name from `SharedConstants/Attribute.luau`
- Forbidden: Magic strings for tag/attribute (ADR-0006)
- Guardrail: ≤9 ProximityPrompts (6 T1 + 3 T2 MVP) (ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/chest-system.md`, scoped to this story:*

- [ ] **AC-1 (Spawn T1/T2/T3 attachment)**: GIVEN Workspace contains Parts tagged `ChestTag` with `ChestTierAttribute` values 1, 2, and 3, WHEN `ChestSystem.createAll()` is called at MSM T4 (Active entry), THEN `ChestComponent` attached to each T1+T2 Part; T3 Parts silently skipped (remain inert geometry); each component state is `Available`.
- [ ] **AC-2 (Missing attribute)**: Part with `ChestTag` but no `ChestTierAttribute` → skipped + error logged + no ChestComponent created.
- [ ] **AC-3 (Prompt distance + hold)**: ChestComponent in Available state has `ProximityPrompt.MaxActivationDistance == CHEST_PROMPT_DISTANCE = 20`; `ProximityPrompt.HoldDuration == CHEST_PROMPT_HOLD_SEC = 0.8`.

---

## Implementation Notes

*Derived from GDD §C + ANATOMY §9:*

- Add to `SharedConstants/CollectionServiceTag/ChestTag.luau`: `ChestTag = "Chest"`. Add to `SharedConstants/Attribute.luau`: `ChestTier = "ChestTier"`.
- `ChestComponent` class in `ServerStorage/Source/ChestSystem/ChestComponent.luau`:
  - `.new(instance: Part, tier: number, sysContext) -> ClassType`
  - Internal: `_state = "Available"`, `_prompt: ProximityPrompt`, `_billboard: BillboardGui`, `_connections: Connections`.
  - `:destroy()` cleans connections, removes prompt, removes billboard.
- `ChestSystem.createAll()`: iterate `CollectionService:GetTagged(ChestTag)`. For each: read `ChestTier` attribute. If missing → log + skip. If tier ∈ {1, 2} → instantiate ChestComponent. If tier == 3 → silent skip (MVP). Track all components in `_chests` dict keyed by chest UUID.
- ProximityPrompt setup inside ChestComponent:
  - `MaxActivationDistance = CHEST_PROMPT_DISTANCE` (20)
  - `HoldDuration = CHEST_PROMPT_HOLD_SEC` (0.8)
  - `ActionText = "Open Chest"`
  - Trigger handler defers to Story 002 guard pipeline.
- Constants in `SharedConstants/ChestSystemConstants.luau`: `CHEST_PROMPT_DISTANCE = 20`, `CHEST_PROMPT_HOLD_SEC = 0.8`, `T1_CHEST_COUNT = 6`, `T2_CHEST_COUNT = 3`, `T3_CHEST_COUNT = 0` (MVP).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Guard pipeline 6-stage.
- Story 003: Open exclusivity tiebreak.
- Story 008: Draft remotes + timeout.
- Story 009: destroyAll cleanup.
- Story 011: Respawn + materialize tween.

---

## QA Test Cases

- **AC-1 (T1/T2/T3 spawn)**:
  - Given: Workspace mock with 6 T1 + 3 T2 + 1 T3 tagged Parts
  - When: `createAll()`
  - Then: 9 ChestComponents attached (T1+T2); 1 T3 inert; all state==Available
  - Edge cases: 0 tagged Parts → no error.

- **AC-2 (Missing attribute)**:
  - Given: 1 Part with ChestTag but no ChestTier attribute
  - When: createAll
  - Then: log spy shows error; ChestComponent count == 0 for this Part
  - Edge cases: malformed attribute (string instead of number) → also rejected.

- **AC-3 (Prompt config)**:
  - Given: ChestComponent post-create
  - When: prompt inspected
  - Then: MaxActivationDistance == 20; HoldDuration == 0.8
  - Edge cases: future tier-specific tuning — knobs in ChestSpec table (Story 005).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/chest/spawn_component_prompt.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: ComponentCreator (template provided); RoundLifecycle.createAll caller hook.
- Unlocks: Stories 002+ (guards consume ChestComponent state).
