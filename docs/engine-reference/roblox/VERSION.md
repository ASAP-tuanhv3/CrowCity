# Roblox — Engine Reference

*Last verified: 2026-04-20*

| Field | Value |
|-------|-------|
| **Engine** | Roblox (continuously-updated live service — no version number) |
| **Language** | Luau (`--!strict` enforced) |
| **Project Pinned** | 2026-04-20 |
| **LLM Knowledge Cutoff** | May 2025 |
| **Risk Level** | MEDIUM — Roblox ships API changes monthly; Luau type solver shipped post-cutoff |

## Toolchain Pins

Pinned via `aftman.toml` at repo root:

| Tool | Version | Purpose |
|------|---------|---------|
| Rojo | 7.5.1-uplift.syncback.rc.21 | Studio ↔ filesystem sync (UpliftGames fork with syncback support) |
| Selene | 0.26.1 | Linter — run via `selene src/` |
| Wally | 0.3.2 | Package manager — installs to `Packages/` |

Pinned via `wally.toml`:

| Package | Version | Purpose |
|---------|---------|---------|
| testez | 0.4.1 | Unit test framework |
| janitor | 1.18.3 | Connection / instance cleanup |
| promise | 4.0.0 | Async control flow |

Vendored (not via Wally):

- **ProfileStore** — `src/ReplicatedStorage/Dependencies/ProfileStore.luau` (session-locked DataStore wrapper)
- **Freeze** — `src/ReplicatedStorage/Dependencies/Freeze/` (immutable Dictionary + List operations)

## Knowledge Gap Policy

Roblox and Luau evolve continuously. The LLM's training data (cutoff May 2025) is missing approximately 12 months of API changes as of this doc's "last verified" date.

**Before proposing code that uses a specific Roblox service API, Luau language feature, or deprecation-sensitive endpoint**, agents MUST:

1. Read this directory's module docs (`luau-type-system.md`, `replication-best-practices.md`, `profilestore-reference.md`)
2. For APIs not covered here, WebSearch `create.roblox.com/docs [api name]` or `devforum.roblox.com [api name] [current year]`
3. When suggesting Luau syntax newer than May 2025 (type functions, `read` table properties, byte-buffer types, vector library), cite the RFC or devforum announcement
4. Never guess at API shape — if uncertain, ask the user or search

## Post-Cutoff Highlights (May 2025 → April 2026)

**Luau type system (Nov 2025):**
- New Type Solver moved out of Studio Beta
- "Non-Strict by Default" migration announced
- Type functions (user-defined compile-time type logic) generally available
- `read` keyword marks table properties read-only
- See `luau-type-system.md` for detail

**Luau VM (Dec 2025 recap):**
- Load-store propagation extended to upvalues, buffers, userdata
- Integer CPU instructions for buffer + bit32 ops
- Native SIMD vector ops matured

**API deprecations / breaking changes:**

| Date | Change | Impact |
|------|--------|--------|
| 2025-07-01 | Develop API asset endpoints deprecated | Web API only — minimal in-game script impact |
| 2025-07-01 | Developer Products + Game Passes endpoint changes | Verify any Open Cloud / HTTP usage |
| 2025-12-05 | Avatar API `v1/avatar-fetch` removed | Use `v2/avatar-fetch` |
| 2026-01-27 | `Player:PlayerOwnsAsset` / `PlayerOwnsAssetAsync` enforces inventory privacy | Returns may be `false` for private inventories — do not gate gameplay on asset ownership without fallback |
| 2026-03-23 | `BadgeService` methods + badges web APIs respect privacy | Same privacy-respecting pattern applied |
| Ongoing 2025 | Multiple methods replaced by `Async` versions (`AnimationClipProvider`, `AvatarEditorService`, `Players`) | Prefer `Async` variants in new code |

## Project-Relevant Notes

Crowdsmith is the current game concept (see `design/gdd/game-concept.md`). Key engine considerations flagged for future architecture work:

- **Crowd replication** — Large follower counts per player (100-300) × 8-12 players. Prototype with `UnreliableRemoteEvent` for non-critical movement updates; authoritative crowd-count + radius via `RemoteEvent`. See `replication-best-practices.md`.
- **ProfileStore** — Already vendored. Session-locked, handles `BindToClose`. See `profilestore-reference.md`.
- **No custom shaders** — Roblox does not expose GLSL/HLSL. Use built-in `SurfaceAppearance`, `ParticleEmitter`, and `PostEffect` instances.
- **Parallel Luau** — If crowd flocking becomes CPU-bound, `Actor` + `task.desynchronize()` is the only parallelism primitive. Not yet needed.

## Sources

- [Luau Type System Guide 2026](https://www.oflight.co.jp/en/columns/luau-type-system-strict-mode-guide-2026)
- [Luau New Type Solver general release](https://devforum.roblox.com/t/general-release-luau%E2%80%99s-new-type-solver/4084991)
- [Luau Recap: Runtime 2025](https://luau.org/news/2025-12-19-luau-recap-runtime-2025/)
- [Roblox Creator Docs type-checking](https://create.roblox.com/docs/luau/type-checking)
- [Official List of Deprecated Web Endpoints](https://devforum.roblox.com/t/official-list-of-deprecated-web-endpoints/62889)
- [PlayerOwnsAsset breaking change](https://devforum.roblox.com/t/upcoming-breaking-change-to-playerownsasset-and-inventory-web-apis/4226591)
- [BadgeService breaking change](https://devforum.roblox.com/t/upcoming-breaking-change-to-checkuserbadgesasync-userhasbadgeasync-and-badges-web-apis/4438920)
- [Luau buffer RFC](https://rfcs.luau.org/type-byte-buffer.html)
- [Luau vector library RFC](https://rfcs.luau.org/vector-library.html)

Run `/setup-engine refresh` to re-verify against latest Roblox announcements.
