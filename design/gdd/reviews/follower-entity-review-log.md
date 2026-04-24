# Review Log: Follower Entity GDD

## Review — 2026-04-22 — Verdict: MAJOR REVISION NEEDED → Revised in session

Scope signal: XL
Specialists: game-designer, systems-designer, qa-lead, gameplay-programmer, performance-analyst, audio-director, network-programmer, creative-director (senior)
Blocking items: 7 | Recommended: 8
Prior verdict resolved: N/A — first review

Summary: Seven specialists converged without disagreement on three crash-level bugs (NaN propagation in F2/F4 via zero-vector normalize, inactive WeldConstraint from wrong parent, rival-nil peel creating zombie pool slots), a pool math error (200 slots for 290+ demand), and a Player Fantasy/Rules coherence failure (synchronized bob, invisible conversion moment, insufficient pool for "rolling flood"). Creative director issued binding rejection. All 7 blockers were revised in-session: NaN guards added to F2 and F4, WeldConstraint fixed to parent under Body with Body.Anchored=true, rival-nil peel abort path defined in F7, pool raised to 460 (Body + Hat), per-follower d_init phase offset added to desynchronize bob, white-state frame added to SlideIn for conversion moment, F6 peel selection changed from farthest-from-own-center to closest-to-rival. 6 new ACs added (AC-21 through AC-26). Re-review required before any stories are written.
