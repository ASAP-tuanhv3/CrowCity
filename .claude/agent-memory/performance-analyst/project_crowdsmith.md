---
name: Crowdsmith Project Context
description: Core performance facts, budgets, and constraints for Crowdsmith — Roblox crowd simulation game
type: project
---

Crowdsmith is a Roblox Crowd City clone. Engine: Roblox, Language: Luau strict mode.

**Target platforms:** PC (primary, 60 FPS), Mobile/iPhone SE (secondary, 45 FPS), Console (Xbox)
**Frame budget:** 16.67ms @ 60 FPS desktop; ~33ms acceptable on mobile

**Architecture:** Server holds per-crowd aggregate state only (position, hitboxRadius, count, hue). Followers are purely client-side boids-flocked Parts. 15 Hz UnreliableRemoteEvent broadcast. ADR-0001 is the foundational architecture decision.

**Key render caps (LOD):**
- LOD 0 (0-20m): own 80, rival 30
- LOD 1 (20-40m): 15 each
- LOD 2 (40-100m): 4 each (billboard impostor)
- Cull > 100m

**Worst-case client part count:** 80 own + 30×7 rivals = 290 followers × 2 Parts = 580 Parts at LOD 0 simultaneously (8 crowds, all within 20m)

**Pool prealloc stated in GDD:** 200 LOD-0 Body + 200 Hat (shortfall vs 290 needed)

**Key perf AC:** AC-17 — FollowerEntityClient update loop ≤ 2.5ms p99 at 60 FPS on desktop (80 LOD-0 followers, 124 Parts max per the AC text — note AC says 124 but worst-case math gives 580)

**Prototype validation:** Desktop 60 FPS confirmed at 8 crowds × 300 followers. Mobile and multi-client bandwidth NOT yet tested (deferred to MVP integration).

**Why:** Knowing these budgets shapes every optimization recommendation and regression threshold.
**How to apply:** Use these numbers when evaluating whether a proposed system fits within budget, and when flagging spec inconsistencies between the GDD and actual worst-case math.
