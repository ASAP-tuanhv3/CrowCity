---
name: Crowdsmith Project Audio Context
description: Core audio facts about Crowdsmith — game pillars, concept audio needs, and current audio system status
type: project
---

Crowdsmith is a Roblox .io/crowd-city game: 5-min rounds, 8-12 players, 1-300 followers per player.

Audio-relevant pillars:
1. Snowball Dopamine — absorb + audio must feel intrinsically great
5. Comeback Always Possible — loss audio must be non-punishing (no loss sting)

Stated audio needs from game-concept.md:
- "crowd-size audio swell" listed as primary Sensation delivery mechanism
- "absorb SFX variants (small/medium/large crowd swell)" in Audio Needs row
- "audio chime" on moment-to-moment absorb description
- Chest UI SFX, round start/end stingers, ambient city

Audio Manager system (System #28) is Vertical Slice priority — NOT yet designed. No audio GDD exists.

Follower Entity GDD (designed 2026-04-22) contains the only audio spec in the project so far (§Visual/Audio Requirements). That spec has 6 confirmed issues — see adversarial review delivered 2026-04-22.

**Why:** Audio system is deferred to VS tier; only ad-hoc SFX specs exist inline in gameplay GDDs.
**How to apply:** When authoring Audio Manager GDD, cross-check every gameplay GDD for inline audio specs and reconcile them. The Follower Entity GDD's audio section will need a patch after the Audio Manager architecture is established.
