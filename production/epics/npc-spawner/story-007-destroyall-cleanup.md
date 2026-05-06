# Story 007: destroyAll() cleanup — cancel pending timers + tweens

> **Epic**: NPCSpawner (NPC Spawner)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/npc-spawner.md` §AC-14
**Requirement**: covered by `TR-npc-spawner-001` (lifecycle `destroyAll` is the inverse of `createAll`).
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 MSM/RoundLifecycle Split + ADR-0008 NPC Spawner Authority
**ADR Decision Summary**: `RoundLifecycle.destroyAll()` (T9) is sole caller of `NPCSpawner.destroyAll()`. The latter cancels all pending respawn `task.delay` timers (Story 005), cancels all in-flight fade tweens (Story 006), parks all NPC Parts, and clears `_pool`/active-list. Idempotent — second call no-op.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: `task.cancel(thread)` available; TweenService `:Cancel` stable.

**Control Manifest Rules (Feature layer + Core layer):**
- Required: T9 ordering invariant — `RoundLifecycle.destroyAll() → RelicSystem.clearAll() → MatchStateChanged("Intermission") broadcast` (ADR-0005)
- Required: NPCSpawner.destroyAll cancels respawn timers + tweens (ADR-0008)
- Forbidden: Cancelling MSM/RL methods externally — RL.destroyAll is the only invoker (ADR-0005)

---

## Acceptance Criteria

*From GDD `design/gdd/npc-spawner.md` §AC-14:*

- [ ] **AC-14 (destroyAll cancels pending timers, injected scheduler)**: GIVEN 5 NPCs in pending-respawn state, WHEN `destroyAll()` runs, THEN every `_respawnTimer` cancelled (no respawn fires after destroyAll); every `_fadeTween:Cancel()` called.
- [ ] **Pool cleared**: post-destroyAll, `_pool` empty; `getAllActiveNPCs()` returns empty frozen table (AC-13 from Story 003).
- [ ] **Idempotent**: calling `destroyAll()` twice does not error; second call is no-op.
- [ ] **Heartbeat disconnected**: own Heartbeat connection (Story 001) disconnected on destroy.

---

## Implementation Notes

*Derived from ADR-0008 §Lifecycle + ADR-0005 §T9 ordering:*

- `destroyAll()` body (idempotent guard at top: `if self._destroyed then return end`):
  1. Disconnect Heartbeat connection.
  2. For each NPC in `_pool`: cancel `_respawnTimer` if active (`task.cancel`); cancel `_fadeTween` if alive (`:Cancel()`); destroy Part instance.
  3. Clear `_pool = {}`, `_activeList = {}`, `_cachedSnapshot = {}` (frozen empty), `_destroyed = true`.
- `_respawnTimer` storage: each NPC record carries a `thread?` reference to the result of `task.delay`. Cancel via `task.cancel(thread)` if not nil.
- `_fadeTween`: stored in Story 006; cancel via `:Cancel()`.
- Re-`createAll` after `destroyAll`: reset `_destroyed = false` at top of `createAll`. (This requires Story 001 to set/check `_destroyed`.)

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: createAll bootstrap (this is its inverse).
- Story 002: reclaim invalidation.
- Stories 005, 006: respawn pipeline + fade-in (cancel handles consumed here).

---

## QA Test Cases

- **AC-14 (Cancel pending timers + tweens)**:
  - Given: 5 NPCs scheduled for respawn at varying delays (DI scheduler)
  - When: `destroyAll()` called
  - Then: spy on `task.cancel` shows 5 cancellations; spy on `tween:Cancel` shows N cancellations (N == in-flight tween count); zero respawns fire post-destroyAll
  - Edge cases: timer already fired pre-destroyAll — `task.cancel` no-op safe; tween already complete — Cancel safe.

- **Pool cleared**:
  - Given: post-destroyAll
  - When: state inspection
  - Then: `_pool` empty; `getAllActiveNPCs()` returns empty frozen
  - Edge cases: pre-destroyAll had 300 NPCs all active — all cleared; Part instances destroyed (`Part.Parent == nil` post-destroy).

- **Idempotent**:
  - Given: destroyAll called once
  - When: destroyAll called again
  - Then: no error; no double-destroy of Parts
  - Edge cases: second call without `createAll` between — no-op.

- **Heartbeat disconnect**:
  - Given: NPCSpawner Heartbeat counted == 1
  - When: destroyAll
  - Then: NPCSpawner Heartbeat counted == 0
  - Edge cases: re-createAll → reconnects to 1.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/npc-spawner/destroyall_cleanup.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (Heartbeat handle), Story 005 (respawn timer handles), Story 006 (fade tween handles).
- Unlocks: T9 round lifecycle integration test (RoundLifecycle epic).
