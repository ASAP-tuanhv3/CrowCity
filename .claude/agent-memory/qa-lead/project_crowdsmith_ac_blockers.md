---
name: Crowdsmith AC Design Blockers — Crowd State Manager + Collision Resolution
description: Design contradictions and AC blockers in Crowd State Manager and Crowd Collision Resolution GDDs
type: project
---

## Crowd State Manager GDD Blockers

Two design contradictions must be resolved before AC-10 and AC-15 can be written or tested.

**Contradiction C1 — Equal-count drain (blocks AC-10):**
F4 formula defines `overlapping_rival_count` as rivals with *higher* count only. At equal counts, value is 0 — no drain. The Detailed Design prose says "Equal counts: both drain at same rate." These are mutually exclusive. AC-10 claims both crowds go 50→48, which follows the prose, not the formula.

**Why:** Affects whether a stalemate between equal crowds is deadlocked (F4 result) or slowly destructive (prose result). This is a Pillar 5 design choice — deadlock vs. attrition.

**How to apply:** Do not write or accept AC-10 as testable until the game-designer confirms which source is authoritative and updates one of them.

**Contradiction C2 — Relic in GraceWindow (blocks AC-15):**
State table says GraceWindow is "up-only (Absorb)" for count mutation. Relic System section says "Handler validates state ∈ {Active, GraceWindow} before applying." AC-15's trace requires Relic to apply at count=1 (GraceWindow), producing count=6. If state table is authoritative, Relic is blocked there and the entire AC-15 trace is wrong.

**Why:** The state table and the Relic section were authored independently without cross-check.

**How to apply:** Block AC-15 from entering any test file until contradiction resolved. The resolution also affects what AC-11b's trace looks like after B enters GraceWindow.

## Crowd Collision Resolution GDD — No current design blockers

As of 2026-04-22, the Crowd Collision Resolution GDD is fully authored (all 8 sections except AC, which was blank and is now being proposed). No design contradictions found during AC authoring. Two items flagged as cross-system amendment requirements:
- `CrowdStateServer.getAllActive()` and `CrowdStateServer.setStillOverlapping()` are new API additions required from Crowd State Manager GDD — need amendment before implementation.
- Follower Entity GDD needs "arrival spawn suppressed on Eliminated rival" AC added (flagged in §E).

**How to apply:** When reviewing Collision Resolution stories for Done, confirm both new Crowd State APIs are implemented and that the Follower Entity Eliminated-arrival AC exists.
