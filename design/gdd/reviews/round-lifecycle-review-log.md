# Review Log: Round Lifecycle

## Review — 2026-04-22 — Verdict: MAJOR REVISION NEEDED → Revised in session

Scope signal: M
Specialists: game-designer, systems-designer, qa-lead, creative-director
Blocking items: 5 resolved in session | Recommended: 6 (non-blocking)
Prior verdict resolved: No — first review

Summary: Three root-cause problems drove the majority of findings. (1) `_participants` conflated "intended to play" with "successfully active" — resolved by introducing the explicit "excluded participant" category (pcall-failed players absent from all placement logic; `setWinner` guard now checks `_crowds` not `_participants`). (2) Group 2 tiebreak changed from `peakTimestamp ascending` (rewarded brief early spikes) to `peakCount descending` (rewards sustained snowball play — better pillar alignment). (3) DC mid-round now freezes player state via `Players.PlayerRemoving` subscription — DC'd players appear in Group 3 with their count at disconnect, receiving placement and currency (Pillar 5). Additional fixes: T8 no-winner path removed (Match State always produces a non-nil winner when participants exist; T5 zero-participant path returns empty array); `Eliminated` handler made idempotent; F4 `getPeakTimestamp` formula added; 9 ACs rewritten for testability; 12-player cap misattribution corrected.
