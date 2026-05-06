# Story 003: Hook dispatch — Phase 2 onTick + onAcquire/onExpire ordering

> **Epic**: RelicSystem (Relic System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/relic-system.md` §C + §F
**Requirement**: `TR-relic-007`, `TR-relic-008`, `TR-relic-021`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 §Phase 2
**ADR Decision Summary**: RelicSystem registers Phase 2 callback (after Collision Phase 1, before Absorb Phase 3). For each Active relic with `onTick=true`, dispatch handler. `onAcquire` fires synchronously inside `grant()` (Story 002). `onExpire` fires inside `clearAll()`/`removeActiveRelic()` (Story 008). Absent hook = no-op no error.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: Phase 2 RelicSystem (after Collision Phase 1) (ADR-0002)
- Required: Tick-mutated count visible to Absorb Phase 3 same tick (ADR-0002)
- Forbidden: Yield inside Phase 2 callback (ADR-0002)
- Guardrail: Phase 2 budget 0.2 ms/tick (ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/relic-system.md`, scoped to this story:*

- [ ] **AC-6 (Absent hook = no-op)**: spec with `hookSet.onTick = false` → Phase 2 dispatch does NOT invoke any tick callback for that slot; raises no error.
- [ ] **AC-7 (Hook fires correct phase position)**: spec with `hookSet.onTick = true` Active → onTick fires in Phase 2 (after Collision Phase 1, before Absorb Phase 3). Verified by mock call-order log.
- [ ] **Hook handlers in `RelicHooks` table**: `RelicHooks.onAcquire(spec, crowdId, slot)`, `.onExpire(spec, crowdId, slot)`, `.onTick(spec, crowdId, slot, tick)`, `.onChestOpen(spec, crowdId, slot, tier, baseToll) -> number?` — table dispatches by `spec.specId` to per-relic handler functions.
- [ ] **`onAcquire` + `onExpire` always fire when declared (TR-021)**: handler-guaranteed; `onTick` + others optional and skipped if declared false.

---

## Implementation Notes

*Derived from GDD §C Hook Dispatch + ADR-0002 §Phase 2:*

- `RelicHooks` module at `src/ServerStorage/Source/RelicSystem/RelicHooks.luau`:
  ```luau
  local RelicHooks = {}
  local handlers = {}  -- handlers[specId] = { onAcquire?, onExpire?, onTick?, onChestOpen? }

  function RelicHooks.register(specId: string, fns)
      handlers[specId] = fns
  end

  function RelicHooks.onAcquire(spec, crowdId, slot)
      local h = handlers[spec.specId]
      if h and h.onAcquire then h.onAcquire(crowdId, slot) end
  end

  function RelicHooks.onExpire(spec, crowdId, slot)
      local h = handlers[spec.specId]
      if h and h.onExpire then h.onExpire(crowdId, slot) end
  end

  function RelicHooks.onTick(spec, crowdId, slot, tick)
      local h = handlers[spec.specId]
      if h and h.onTick then h.onTick(crowdId, slot, tick) end
  end

  function RelicHooks.onChestOpen(spec, crowdId, slot, tier, baseToll)
      local h = handlers[spec.specId]
      if h and h.onChestOpen then return h.onChestOpen(crowdId, slot, tier, baseToll) end
      return nil
  end
  ```
- Per-relic handler files: `RelicSystem/handlers/TollBreakerHandler.luau`, `SurgeHandler.luau`, `WingspanHandler.luau` — each registers via `RelicHooks.register("TollBreaker", { onAcquire = ..., onExpire = ..., onChestOpen = ... })` at module require.
- Phase 2 callback `RelicSystem.tickPhase2(tickCount)`:
  ```luau
  local active = csm.getAllActive()
  for _, crowd in active do
      for _, slot in crowd.activeRelics do
          local spec = RelicRegistry.getById(slot.specId)
          if spec.hookSet.onTick then
              RelicHooks.onTick(spec, crowd.crowdId, slot, tickCount)
          end
      end
  end
  ```
- Phase 2 wiring at `start.server.luau` post-require: `TickOrchestrator.registerPhase(2, RelicSystem.tickPhase2)`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: grant calls onAcquire (this story exposes the dispatch table).
- Stories 004-006: per-relic handler implementations (TollBreaker/Surge/Wingspan).
- Story 008: clearAll calls onExpire.

---

## QA Test Cases

- **AC-6 (Absent hook no-op)**:
  - Given: spec with onTick=false (e.g., TollBreaker)
  - When: Phase 2 fires
  - Then: spy on `handlers["TollBreaker"].onTick` shows 0 invocations; no error
  - Edge cases: handlers["TollBreaker"] has onTick defined but spec.hookSet.onTick=false → still skipped (spec.hookSet is authoritative).

- **AC-7 (Hook fires Phase 2)** [Integration]:
  - Given: synthetic test spec "TickyRelic" with onTick=true Active on crowd
  - When: 1 tick fires
  - Then: phase ordering log shows: Phase1 → Phase2 (TickyRelic.onTick) → Phase3 (Absorb)
  - Edge cases: count mutation in onTick visible to Phase 3 csm.get reads same tick.

- **TR-021 (Always-fire contract)**:
  - Given: spec with onAcquire=true onExpire=true
  - When: grant + clearAll
  - Then: onAcquire fires inside grant; onExpire fires inside clearAll
  - Edge cases: handler raises pcall — TickOrchestrator phase pcall catches; next phase still fires.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/relic/hook_dispatch.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (registry); Story 002 (grant invokes onAcquire); TickOrchestrator (Sprint 3).
- Unlocks: Stories 004 (Surge handler), 005 (Wingspan), 006 (TollBreaker), 008 (clearAll onExpire).
