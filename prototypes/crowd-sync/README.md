# Crowd-Sync Prototype

**Question**: Can Roblox handle 800-3000 follower entities across 8-12 players at 60 FPS on mobile?

**Architecture under test**: Server hitbox-only + decoupled gameplay/render count + client boids flocking + LOD swap (concept doc §Technical Risks, art bible §5 + §8.5).

---

## Architecture

```
SERVER (authoritative)                        CLIENT (decorative)
─────────────────────                         ────────────────────
per-crowd state:                              receives crowd state @ 15Hz
  { position, radius,         ──UnreliableRE──▶ (UnreliableRemoteEvent)
    followerCount, hue }                      renders N local followers per
                                                crowd where N = render cap
hit detection @ 15Hz                            (function of camera distance)
  (circle overlap test)                       flocks followers via boids
  cost: O(players²)                             LOD swap every 0.1s
broadcast state @ 15Hz                        caps:
  cost: ~40 bytes/crowd                         own close 80, rival close 30,
                                                medium 15, far 4, cull >100m
```

Server NEVER knows individual follower positions. Clients can see different individual follower layouts — gameplay doesn't care.

## Files

```
prototypes/crowd-sync/
├── default.project.json        Rojo project mapping
├── README.md                   this file
├── REPORT.md                   filled after user runs the prototype
└── src/
    ├── shared/
    │   ├── CrowdConfig.luau    all tuning knobs (edit values here, hit Play)
    │   ├── BoidsFlock.luau     flocking math
    │   └── Remotes.luau        UnreliableRemoteEvent wrapper
    ├── server/
    │   └── CrowdServer.server.luau
    └── client/
        └── CrowdClient.client.luau
```

## How to Run

### 1. Build and open in Studio

From this directory:

```bash
rojo build -o crowd-sync-proto.rbxlx
```

Open `crowd-sync-proto.rbxlx` in Roblox Studio.

(Alternatively: `rojo serve` and sync into a blank Studio place via the Rojo plugin.)

### 2. Configure test scenario

Edit `src/shared/CrowdConfig.luau` before each test run:

```lua
CrowdConfig.BOT_CROWD_COUNT = 8               -- sweep: 1, 4, 8, 12
CrowdConfig.STARTING_FOLLOWERS_PER_CROWD = 100
CrowdConfig.MAX_FOLLOWERS_PER_CROWD = 300     -- sweep: 100, 200, 300
CrowdConfig.FOLLOWER_GROWTH_RATE = 10
```

### 3. Start test

- `Play` (F5) — client runs in Studio. Camera sits at origin. Bot crowds wander randomly around the baseplate.
- Or `Test > Start` with 4 players emulated for multi-client stress test.

### 4. Read metrics

Every 2 seconds, output window logs:

**Server**:
```
[CrowdServer] crowds=8 totalFollowers=1600 hitOverlaps=3 memMB=512.4
```

**Client**:
```
[CrowdClient] FPS=58.3 avgFrameMs=17.14 renderedParts=120 bandwidth=1.34kbps crowds=8
```

### 5. Cross-check MicroProfiler

Open `Ctrl+F6` (Studio) or `Alt+F5` (in-game). Watch:
- `Render/Prepared` — should stay <4ms
- `Heartbeat` — client boids + LOD should stay <1ms combined
- `Physics/Stepped` — should stay ~0ms (anchored Parts)
- Memory > GraphicsTexture — should stay flat (no texture churn)

### 6. Device emulator sweep

After desktop pass, `Test > Device` → iPhone SE (720×1280, min-spec mobile). Re-run same scenarios.

## Test Matrix — run all, record into REPORT.md

| Scenario | BOT_CROWD_COUNT | MAX_FOLLOWERS | Devices | Success criteria |
|----------|-----------------|---------------|---------|------------------|
| Baseline | 1 | 100 | Desktop | 60 FPS. Render cap ≤ 80. |
| Nominal | 4 | 200 | Desktop | ≥ 55 FPS. Render total ≤ 400. |
| Target MVP | 8 | 300 | Desktop | ≥ 55 FPS. Render total ≤ 700. |
| Full vision | 12 | 300 | Desktop | ≥ 50 FPS. Render total ≤ 1000. |
| Mobile MVP | 8 | 300 | iPhone SE emu | ≥ 45 FPS. Bandwidth ≤ 10kbps. |
| Mobile stretch | 12 | 300 | iPhone SE emu | ≥ 40 FPS. |

## Success / Fail Criteria (maps to concept doc §Technical Risks)

| Verdict | Criteria |
|---------|----------|
| **PROCEED** | Mobile MVP scenario hits 45 FPS, bandwidth < 10kbps, Heartbeat < 8ms. Visual crowd-feel "reads as a mob" despite render cap. |
| **PROCEED-CONCERNS** | Desktop hits spec, mobile falls 5-10 FPS short. Add Parallel Luau actor optimization path to architecture plan. |
| **PIVOT** | Mobile < 30 FPS or bandwidth > 50kbps. Re-architect: reduce render caps further or switch to pure billboard crowds at cost of visual identity. |
| **KILL** | Even with caps to 20 visible followers per crowd, frame rate cannot hold 45 FPS at 8-player × 300-follower load. → Abandon "crowd" mechanic, pivot genre. |

## Known Prototype Gaps

Deliberately skipped per skill guidance — NOT production-quality:

- No player-controlled crowd (bots only — throughput test, not input test)
- No absorb mechanic (measured hit overlaps only; no state mutation on hit)
- No elimination / crowd-merge logic
- No chests, relics, skins, UI
- Single-material flat-color Parts (no art bible asset standard compliance)
- O(n²) within-crowd boids (fine at n ≤ 80; production needs spatial hash)
- No server-side actor for bot crowd (runs on main server thread — acceptable for 15Hz)
- Render-cap swap rebuilds Parts each tier change (production should pool)
- No pooling of any kind

If the prototype proceeds, production implementation is written **from scratch** — no copy-paste from here per prototype skill guardrails.
