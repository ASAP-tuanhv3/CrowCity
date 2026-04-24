# Review Log: Match State Machine

## Review — 2026-04-21 — Verdict: MAJOR REVISION NEEDED → Revised in-session
Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, network-programmer, creative-director
Blocking items: 7 | Recommended: 7
Summary: Structurally sound state machine (correct state list, comprehensive edge cases, 19 ACs) but written outside-in from engineering concerns rather than Player Fantasy. Seven blockers resolved in-session: ROUND_DURATION_SEC safe range corrected to [285,315] to enforce Pillar 3; SOLO_WAIT (T8) redesigned to instant-win; F7 rejoin-cancel mechanic removed (architecturally incoherent on Roblox); F6 timer formula corrected for RTT bias; per-player participation signal fully specified; tiebreak step 3 replaced with ROUND_SEED hash (fairness fix); grantMatchRewards moved to Result entry for coin-tick animation alignment. Four ACs rewritten (AC-7, AC-10, AC-12, AC-13, AC-14); AC-20 added.
Prior verdict resolved: N/A — first review
