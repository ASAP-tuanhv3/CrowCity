---
name: Design Process Feedback
description: Process rules inferred from project conventions and CLAUDE.md for this repository
type: feedback
---

Ask "May I write this section to [filepath]?" before any Write/Edit call. Show draft in conversation first and wait for explicit approval.

**Why:** CLAUDE.md §Collaboration Protocol: "Agents MUST ask 'May I write this to [filepath]?' before using Write/Edit tools."

**How to apply:** Every file write in this project is gated on user approval. Draft content in conversation text; only invoke Write tool after user confirms.

---

Upstream contracts from already-approved GDD sections are LOCKED. Never propose changes to them without flagging as an explicit escalation.

**Why:** User provided upstream contracts as locked in the session prompt; Crowd State Manager §C.3 drip model is the canonical example.

**How to apply:** When designing a new system, accept locked contracts as axioms and design around them, not through them.

---

Check `design/registry/entities.yaml` before defining any cross-system formula, constant, or entity.

**Why:** Registry is the single source of truth for cross-system facts. Diverging from registry values without a proposed registry update causes doc inconsistency.

**How to apply:** Read registry at start of any design session. Flag new cross-system facts for registry addition at end of session.
