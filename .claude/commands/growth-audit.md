# Growth Audit

Run the MuscleMap active simulator growth audit.

Use `/Users/og3939397/MuscleMap/.claude/skills/growth-audit/SKILL.md` as the source of truth.

Mandatory behavior:

1. Build, install, and launch MuscleMap on a dedicated simulator using the growth-audit helper script.
2. Read the Product Intent Oracle before judging screenshots: `/Users/og3939397/Documents/Obsidian Vault/zDOG/Projects/MuscleMap/Growth/MuscleMap_Product_Intent_Oracle.md`.
3. Use iOS Simulator MCP or computer-use to tap/swipe/type through the real app.
4. Use interaction trace mode: before screenshot -> action intent -> tap/swipe/type -> after screenshot -> compare.
5. Create sticky issues for every inconsistency, UI break, intentional insufficiency, weak feel, or improvement opportunity.
6. Label every sticky as bug / intentional / deprecated-intent / unknown-intent / discoverability-risk / sample-risk / taste before proposing fixes.
7. Capture a representative workout, not a one-set smoke test: at least 3 exercises and enough sets to make completion meaningful.
8. Audit the full trace with retention, flow, monetization, product-sense, trace-consistency, and intent-oracle critic lenses.
9. Cluster sticky issues into fix packages after the trace is complete. Do not jump from one screenshot to one implementation.
10. Block intentional, deprecated, unknown-intent, and sample-risk stickies from implementation unless zDOG explicitly overrides.
11. Write the report to `/Users/og3939397/Documents/Obsidian Vault/zDOG/Projects/MuscleMap/Growth/`.
12. Stop at the approval gate and ask zDOG before changing app code.

If the current Claude Code session does not expose a simulator MCP/computer-use tool, say that active UI operation is blocked and ask for it to be enabled. Do not pretend a code-only audit satisfies this command.
