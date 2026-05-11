# ADR-0008-A1: NPCSpawner Caller Authority — Boot Wiring Bridge Amendment

**Status**: Accepted (2026-05-11)
**Amends**: ADR-0008 §Caller Authority Matrix
**Story**: Sprint 7 7-6

## Context

ADR-0008 §Caller Authority Matrix names **RoundLifecycle** as sole caller
of `NPCSpawner.createAll(participants)` and `NPCSpawner.destroyAll()`:

| API | Authorised callers (sole set) | Forbidden |
|---|---|---|
| `createAll(participants)` | RoundLifecycle (T4 transition only) | All other systems |
| `destroyAll()` | RoundLifecycle (T9 transition + PlayerRemoving handler) | All other systems |

This conflicts with ADR-0006 §Layer Hierarchy:

- **RoundLifecycle** is Core-layer (per ADR-0005 §MSM/RoundLifecycle Split).
- **NPCSpawner** is Feature-layer (per ADR-0008 §Layer Placement).
- Core → Feature direct import is **forbidden** by ADR-0006.

A direct call from RoundLifecycle (Core) to NPCSpawner.createAll (Feature)
would violate the layer hierarchy. Sprint 6 task 6-2 surfaced this conflict
when wiring the production MSM Lobby→Active driver — discovered that the
RoundLifecycle → NPCSpawner.createAll path could not be built without
breaking ADR-0006.

## Decision

Introduce a **Boot Wiring Bridge** as the architectural solution. The bridge
lives in `src/ServerScriptService/start.server.luau` (Boot layer — above
Core and Feature) and mediates between layers via the
`MatchStateChangedServer` BindableEvent signal:

```
RoundLifecycle (Core) ─┐
                        ├─ both create/destroy crowd records on T4/T9
MatchStateServer (Core)─┴─ fires MatchStateChangedServer signal
                                    │
                                    ▼
                          start.server.luau (Boot)
                                    │
                                    ▼
                          NPCSpawner.createAll / destroyAll (Feature)
```

Boot layer is permitted to import both Core and Feature (per ADR-0006
§Layer Hierarchy). Bridge subscribes to MSM signal, calls NPCSpawner APIs
on state transition. RoundLifecycle never imports NPCSpawner directly.

### Updated Caller Authority Matrix

| API | Authorised callers (sole set) | Forbidden |
|---|---|---|
| `createAll(participants)` | **Boot wiring bridge in start.server.luau** (subscribes to MatchStateChangedServer; fires on `newState == "Active"`) | All other systems |
| `destroyAll()` | **Boot wiring bridge in start.server.luau** (fires on `newState == "Intermission"`) | All other systems |
| `getAllActiveNPCs()` | AbsorbSystem (Phase 3 only); other server systems may read but MUST NOT mutate returned references | Mutation of returned table (unchanged) |
| `reclaim(npcId)` | AbsorbSystem (Phase 3 only) (unchanged) | All other systems |

### Participant list resolution

Bridge resolves participants via MSM's read API (`getParticipation`)
instead of receiving them from RoundLifecycle directly:

```lua
local participants: { Player } = {}
for _, plr in ipairs(Players:GetPlayers()) do
    if MatchStateServer.getParticipation(plr) then
        table.insert(participants, plr)
    end
end
NPCSpawner.createAll(participants)
```

This keeps both RoundLifecycle.createAll and NPCSpawner.createAll firing
with the same participant set (semantically equivalent, derived from the
same MSM `_participation` map).

## Consequences

**Positive**:
- ADR-0006 §Layer Hierarchy preserved (no Core → Feature import).
- RoundLifecycle and NPCSpawner remain independently testable (different
  layers, no cross-mock requirement).
- Bridge is a single, documented choke point — easy to audit.

**Negative**:
- Boot layer is now a de-facto coordinator for cross-system lifecycle.
  Risk: if more such bridges accumulate, start.server.luau becomes a
  "god script". Mitigation: re-evaluate when bridge count > 3.
- Bridge dispatch is async (Roblox BindableEvent contract). NPCSpawner.createAll
  may fire 1 frame after RoundLifecycle.createAll. Acceptable per Sprint 6
  Studio playtest verification — broadcast lag absorbs the gap.
- Maintenance coupling: bridge's participant resolution must stay
  semantically equivalent to MSM's internal `_participatingPlayers()`.
  Both filter via `Players:GetPlayerByUserId`; today's behavior matches.
  Documented as a maintenance note in the bridge code.

## ADR Dependencies

- **ADR-0005 MSM/RoundLifecycle Split** — places RoundLifecycle in Core.
- **ADR-0006 Module Placement Rules** — Layer Hierarchy forbids Core → Feature import.
- **ADR-0008 NPC Spawner Authority** — original §Caller Authority Matrix this amends.

## Engine Compatibility

No new engine APIs introduced. Uses existing `BindableEvent`. Compatible
with current Roblox runtime (verified Sprint 6 + 7 Studio Local Server playtests).

## GDD Requirements Addressed

| GDD Requirement | Resolution |
|---|---|
| `design/gdd/npc-spawner.md` §C.1 — createAll/destroyAll lifecycle | Bridge ensures same lifecycle triggers; no GDD change |
| `design/gdd/match-state-machine.md` §Active state transition | Bridge fires NPCSpawner.createAll on Active entry; aligns with MSM T4 |

## Verification Required

- [x] Studio Local Server playtest 2-player Sprint 7 7-1: bridge fires
  NPCSpawner.createAll on Active state; NPCs spawn in arena
  (verified 2026-05-10 by tuanhv3)
- [x] Bridge fires NPCSpawner.destroyAll on Intermission state; NPCs
  cleared between rounds (verified Sprint 7 7-3 — no orphan NPCs)
- [ ] Smoke check critical-paths refresh (Sprint 7 7-7) lists bridge as
  Sprint 6 mechanic.
