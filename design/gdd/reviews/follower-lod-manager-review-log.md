# Review Log: Follower LOD Manager GDD

## Review — 2026-04-22 — Verdict: MAJOR REVISION NEEDED → Revised in session

Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, performance-analyst, network-programmer, creative-director (senior)
Blocking items: 10 | Recommended: 12
Prior verdict resolved: N/A — first review

Summary: Five specialists converged on four crash-level bugs in F2 (Luau nil-arithmetic from 1-indexed boundary array used as 0-indexed, CULL constant never declared), a silent correctness failure where CrowdStateClient.get() returns non-nil for Eliminated crowds all round (LOD Manager's nil-check guard never fires), an ADR-0001 tier-2 discrepancy (billboard impostor vs 4 real follower rigs), and a Player Fantasy promise ("not a single follower pops") with no mechanical enforcement. Creative director issued binding MAJOR REVISION NEEDED. All 10 blockers revised in-session: F2 rewritten with explicit per-tier branches eliminating all nil-arithmetic paths; CULL=3 declared as typed integer; CrowdEliminated reliable event listener added with _eliminatedIds set; tier-2 cap changed to 1 billboard impostor per ADR intent; GDD self-flagged as blocked on ADR-0001 Accepted; Player Fantasy rewritten to match FadeIn mechanical reality; AC-LOD-05 test values corrected (d=19.5 → not below threshold); AC-LOD-02 rewritten to deferred-tick model; AC-LOD-15 reclassified into Logic + Performance/Integration split; cascade despawn throughput bound added (30 FadeOut/Heartbeat); 6 new ACs added (AC-LOD-16 through AC-LOD-21). User accepted revisions and marked Approved without re-review.
