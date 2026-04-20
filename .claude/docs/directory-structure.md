# Directory Structure

```text
/
├── CLAUDE.md                    # Master configuration
├── ANATOMY.md                   # Pattern reference (production game anatomy)
├── .claude/                     # Agent definitions, skills, hooks, rules, docs
├── src/                         # Game source code (Rojo project)
│   ├── ReplicatedStorage/       # Shared client + server code
│   │   ├── Source/              # ModuleScripts (network, UI, player data, etc.)
│   │   ├── Dependencies/        # ProfileStore, Freeze library
│   │   └── Instances/           # GUI prefabs, item containers
│   ├── ServerStorage/           # Server-only code
│   │   └── Source/              # Server ModuleScripts (data, spawning, etc.)
│   ├── ReplicatedFirst/         # Client entry point
│   │   └── Source/              # start.server.luau (RunContext: Client)
│   └── ServerScriptService/     # Server entry point
│       └── start.server.luau    # (RunContext: Server)
├── Packages/                    # Wally-managed dependencies (Promise, Janitor, TestEZ)
├── assets/                      # Game assets (art, audio, vfx, shaders, data)
├── design/                      # Game design documents (gdd, narrative, levels, balance)
├── docs/                        # Technical documentation (architecture, api, postmortems)
│   └── engine-reference/        # Curated engine API snapshots (version-pinned)
├── tests/                       # Test suites (unit, integration, performance, playtest)
├── tools/                       # Build and pipeline tools (ci, build, asset-pipeline)
├── prototypes/                  # Throwaway prototypes (isolated from src/)
└── production/                  # Production management (sprints, milestones, releases)
    ├── session-state/           # Ephemeral session state (active.md — gitignored)
    └── session-logs/            # Session audit trail (gitignored)
```
