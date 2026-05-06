# Story 009: UREvent NpcStateBroadcast + client mirror pool

> **Epic**: NPCSpawner (NPC Spawner)
> **Status**: Ready
> **Layer**: Feature + Presentation
> **Type**: Integration
> **Estimate**: 5h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/npc-spawner.md` §AC-19 + §F (UREvent channel)
**Requirement**: `TR-npc-spawner-015`, `TR-npc-spawner-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 NPC Spawner Authority §Replication Channel + ADR-0001 Crowd Replication Strategy
**ADR Decision Summary**: NPC positions replicate via `UnreliableRemoteEvent NpcStateBroadcast` at 15 Hz, 8 B/NPC delta, per-relevance-filter (only NPCs within `crowd.radius + 25 studs cushion` for any of the receiving player's crowds). Reliable `NpcPoolBootstrap` event sent on join with full pool snapshot. Client mirror pool: 300 Parts spawned on Bootstrap; subsequent UREvent deltas applied. NOT native Roblox Part replication (Workspace.StreamingEnabled=false on arena).

**Engine**: Roblox | **Risk**: HIGH (post-cutoff buffer + UREvent)
**Engine Notes**: Buffer encoding mandated for MVP per ADR-0001. UnreliableRemoteEvent stable post-cutoff; verify against `docs/engine-reference/roblox/replication-best-practices.md`.

**Control Manifest Rules (Foundation/Feature/Presentation):**
- Required: NPC replication via UREvent NpcStateBroadcast (ADR-0008)
- Required: Buffer encoding mandatory MVP (ADR-0001)
- Required: NPCSpawnerClient mirror pool: 300 Parts on Bootstrap; UREvent deltas applied (ADR-0008)
- Required: Per-relevance filter (crowd.radius + 25 studs cushion) (ADR-0008)
- Forbidden: Native Roblox Part replication for NPCs (ADR-0008 — bandwidth uncountable)
- Forbidden: UnreliableRemoteEvent for must-arrive events (ADR-0010 — Bootstrap is reliable)
- Guardrail: NpcStateBroadcast 3.0 KB/s budget (ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/npc-spawner.md` §AC-19 + AC-17b:*

- [ ] **AC-19 (UREvent replication)**: NPC position deltas reach client via `NpcStateBroadcast` UREvent at 15 Hz; transparency deltas included; client mirror pool (300 Parts) reflects server state within 1 tick + RTT.
- [ ] **AC-17b (Steady-state equilibrium soak)**: in 5-min synthetic soak with 12 crowds, server NpcStateBroadcast bandwidth measured ≤ 3.0 KB/s/client steady-state.
- [ ] **Bootstrap on join**: new player receives `NpcPoolBootstrap` reliable event with full active-NPC snapshot before first NpcStateBroadcast UREvent reaches them.
- [ ] **Per-relevance filter**: NPCs farther than `(any of receiver's crowd.radius + 25)` from EVERY one of the receiver's crowds are excluded from broadcast. (Lobby/spectator clients receive no NPC updates.)
- [ ] **Buffer encoding**: payload uses `buffer.create` not table serialization (verify via Wireshark-style packet inspection in test).

---

## Implementation Notes

*Derived from ADR-0008 §Replication Channel + ADR-0001 §Buffer Encoding:*

- Add to `RemoteName/UnreliableRemoteEventName.luau`: `NpcStateBroadcast = "NpcStateBroadcast"`. Add to `RemoteName/RemoteEventName.luau`: `NpcPoolBootstrap = "NpcPoolBootstrap"`.
- Server side (NPCSpawner module):
  - Per-tick (15 Hz): for each player, compute `relevant = filter(activeNPCs, npc → ∃ ownCrowd: dist(npc, ownCrowd) ≤ ownCrowd.radius + 25)`. Buffer-encode delta `{npcId u16 | x f32 | z f32 | transparency f32}` (8 B per NPC = `2 + 4 + 4 + 4 = 14 B` actually — re-examine: ADR-0008 says 8B; revisit at impl time vs. exact ADR encoding).
  - `Network.fireClient(player, UREventName.NpcStateBroadcast, buffer)`.
- On `PlayerAdded` (or RoundLifecycle.createAll for joiners mid-round-start): send `NpcPoolBootstrap` reliable event with full active snapshot (npcId + initial pos + transparency).
- Client side (`ReplicatedStorage/Source/NPCSpawnerClient/init.luau`):
  - On `NpcPoolBootstrap`: spawn 300 Parts in client-only folder; key by npcId.
  - On each `NpcStateBroadcast`: decode buffer; apply CFrame + Transparency deltas to client mirror Parts.
  - Janitor cleanup at MatchStateChanged → Intermission (clears local pool).
- Buffer encoding: helper in `Network/init.luau` (or `NetworkBuffer.luau` per existing pattern) — `pack` / `unpack` per ADR-0001 schema.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Stories 001-008: server-side pool / walk / respawn / density (all consumed here).
- Buffer codec module shared with CrowdStateBroadcast — already exists per network-layer-ext epic story 003 (Sprint 3 closed). Reuse.
- Mid-round-join late-join blocked MVP per ADR-0001 — this story handles Lobby join only.

---

## QA Test Cases

- **AC-19 (UREvent replication)** [Integration — TestEZ + RTT mock]:
  - Given: 1 server + 1 client mock; 5 active NPCs
  - When: 1 tick fires
  - Then: client mirror pool reflects 5 NPC positions; transparency match
  - Edge cases: dropped UREvent packet — next tick recovers; out-of-order packet — discarded silently (no ordering for UREvent).

- **AC-17b (Bandwidth soak)** [Integration — synthetic]:
  - Given: 12 crowds × 60 NPCs visible per client (post-relevance filter cap)
  - When: 5-min soak at 15 Hz
  - Then: bandwidth instrumentation reports ≤ 3.0 KB/s; no GC spikes
  - Edge cases: peak burst (all 60 NPCs moving) within 20 KB/s burst envelope per ADR-0003.

- **Bootstrap on join** [Integration]:
  - Given: new client joins mid-Lobby
  - When: server receives PlayerAdded
  - Then: `NpcPoolBootstrap` reliable received before first `NpcStateBroadcast` UREvent
  - Edge cases: join during T9 cleanup — receives empty bootstrap; Lobby join post-cleanup → bootstrap on next createAll.

- **Per-relevance filter**:
  - Given: receiver has 1 own crowd at `(0,0,0)` radius=10; NPCs at `(5,0,0)` (in radius+25=35) + `(50,0,0)` (out)
  - When: tick fires
  - Then: receiver's UREvent payload contains npc1 only; npc2 absent
  - Edge cases: spectator (no own crowds) → empty payload; multi-crowd own → union of relevance.

- **Buffer encoding**:
  - Given: payload constructed
  - When: `typeof(payload)` checked
  - Then: `"buffer"` (Roblox buffer datatype), not `"table"`
  - Edge cases: large pool (60 NPCs) → fits within 16 KB hard cap (ADR-0010).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/npc-spawner/urevent_replication_test.luau` — must exist and pass
- `production/qa/evidence/npc-bandwidth-soak-2026-XX-XX.md` — Studio bandwidth instrumentation export + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-008 (full server-side NPCSpawner); existing `Network` buffer codec from Sprint 3 (CrowdStateBroadcast epic).
- Unlocks: AbsorbSystem story-007 perf soak (NPCs visible to overlap test); end-to-end vertical slice playtest.
