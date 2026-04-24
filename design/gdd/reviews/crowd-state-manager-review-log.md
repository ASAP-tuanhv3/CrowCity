# Review Log: Crowd State Manager

## Review — 2026-04-22 — Verdict: MAJOR REVISION NEEDED → Revised in session

Scope signal: M
Specialists: game-designer, systems-designer, network-programmer, qa-lead, creative-director
Blocking items: 4 resolved in session | Recommended: 8 (non-blocking)
Prior verdict resolved: No — first review

Summary: Four root-cause blockers resolved. (1) F4 equal-count drain contradiction fixed — operator changed from `>` to `>=`; AC-10 updated to reflect 1/tick drain at equal counts (BASE=15/15=1). (2) GraceWindow/Relic contradiction resolved — state table updated to "up-only (Absorb/Relic+)"; positive relics now explicitly apply in GraceWindow per Pillar 5. (3) `activeRelics` removed from 15 Hz broadcast payload (ADR-0001 bandwidth violation) — moved to reliable `CrowdRelicChanged` event on-change. (4) Eliminated state replication gap closed — reliable `CrowdEliminated` event added; AC-20 written. Additional improvements: F3 rewritten with collision-scale differentiation (`TRANSFER_RATE_effective = BASE + SCALE × count_delta`; large rivals now drain 4/tick vs 1/tick for equal-count standoffs); F4 updated with per-pair rates and explicit attacker_gain; GraceWindow entry condition fixed from "clamp triggered" to "count reaches floor" (covers exact-1 case); Implementation Note updated to Heartbeat accumulator; hue moved to one-time join event; 6 ACs rewritten for testability; AC-17/18 reclassified as Integration/Performance evidence.
