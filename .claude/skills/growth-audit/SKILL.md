---
name: growth-audit
description: Run the MuscleMap Growth Harness. Use when auditing MuscleMap growth, retention, churn, paywall performance, App Store Connect or RevenueCat metrics, actively operating the iOS Simulator via MCP/computer-use, capturing simulator screenshots, reviewing user flows, or turning screenshots and metrics into prioritized product fixes.
argument-hint: "[focus or report title]"
allowed-tools: [Read, Write, Glob, Grep, Bash]
---

# MuscleMap Growth Harness v1

Run a repeatable, simulator-driven growth audit for MuscleMap. The goal is not to brainstorm broadly; it is to operate the app, capture the real flow after every important user action, turn screenshots into a traceable issue board, then stop for zDOG approval before changing product code.

## Defaults

- Product decision: keep growing MuscleMap; do not propose a separate new app in v1.
- Primary metric: retention and churn reduction before acquisition.
- Baseline as of 2026-05-15: first downloads 139, App Store CVR 8.58%, IAP count 3, active subscriptions 3, MRR $16.
- Treat "3 paid users, 1 cancelled" as a retention warning, not enough evidence for a pricing conclusion.
- During the audit, do not edit Swift, StoreKit, RevenueCat, App Store screenshot generator, or project files.
- After the audit, stop at the approval gate. Only implement after zDOG explicitly confirms the selected fix package.
- Do not jump from one screenshot to one fix. Complete the trace first, collect issue stickies, cluster them, then propose fix packages.
- One loop may produce multiple issue stickies. Implementation should be grouped into a small fix package only after the full trace is reviewed.
- A screenshot finding is invalid if the captured user state is unrealistic. A one-exercise / one-set / one-minute workout is a smoke test, not evidence for completion-screen retention quality.
- Never classify a finding as a bug until it has been checked against the Product Intent Oracle.

## Required Context

Read these first when available:

- `/Users/og3939397/Documents/Obsidian Vault/zDOG/Projects/MuscleMap/FINAL_VISION.md`
- `/Users/og3939397/Documents/Obsidian Vault/zDOG/Projects/MuscleMap/Growth/MuscleMap_Product_Intent_Oracle.md`
- `/Users/og3939397/Documents/Obsidian Vault/zDOG/Projects/MuscleMap/pricing_strategy.md`
- `/Users/og3939397/Documents/Obsidian Vault/zDOG/Projects/MuscleMap/Screens/01_HomeView.md`
- `/Users/og3939397/Documents/Obsidian Vault/zDOG/Projects/MuscleMap/Screens/09_PaywallView.md`
- `/Users/og3939397/Documents/Obsidian Vault/zDOG/Projects/MuscleMap/Screens/18_TodayRecommendationView.md`
- `/Users/og3939397/MuscleMap/docs/SCREEN_FLOWS.md`
- `/Users/og3939397/MuscleMap/docs/DESIGN_SYSTEM.md`

Use old audit files as clues, not current truth. Prefer fresh screenshots and current code when there is a conflict.
If old documents conflict with `MuscleMap_Product_Intent_Oracle.md`, the Oracle wins.

## Inputs

Collect or infer these, marking missing values as `unknown` instead of guessing:

- App Store Connect: first downloads, re-downloads, impressions, product page views, conversion rate, IAP count, D1 paid conversion, D7 paid conversion.
- RevenueCat: active subscriptions, MRR, revenue, new customers, active customers, cancellations or expirations, country split when known.
- Screenshot flow captured by operating the app: onboarding or first launch, Home, today recommendation, Workout start, active recording, completion, Paywall, History or Strength Map.

## Sample Validity Gate

Before writing findings, decide whether the captured flow is realistic enough to judge growth.

For the default retention audit, the session must include:

- at least 3 exercises from the recommended/routine flow;
- at least 2 sets for 2 or more exercises;
- at least 1 weighted exercise with weight > 0;
- at least 1 bodyweight exercise if the routine includes one;
- a completion screen after a session lasting more than 3 minutes in-app time or enough recorded volume to look like a real workout;
- both a Pro and Free state when auditing Paywall or locked value.

If these conditions are not met:

- mark the report confidence as `low`;
- do not rank completion-screen whitespace or "missing emotional reward" as a Top 1 fix unless the same issue appears in a representative session;
- rerun the flow if MCP control is available;
- distinguish "thin test data artifact" from "real product issue."

## Product Intent Oracle Gate

Before recording any sticky as `bug`, read and apply:

`/Users/og3939397/Documents/Obsidian Vault/zDOG/Projects/MuscleMap/Growth/MuscleMap_Product_Intent_Oracle.md`

For every suspicious finding, classify it as one of:

- `bug`: implementation contradicts current intent or visibly breaks.
- `intentional`: current behavior is intended; do not propose implementation.
- `deprecated-intent`: old concept or doc exists, but current product intentionally moved away.
- `unknown-intent`: cannot determine from Oracle; ask zDOG.
- `discoverability-risk`: behavior is intended but users may not find/understand it.
- `sample-risk`: finding may be caused by test state, debug state, or thin sample.
- `taste`: subjective product feel; can be discussed but not treated as a defect.

Known examples:

- Missing Strength Map is not automatically a bug. Current Oracle says it has been removed from the main path because the value is weak. Classify as `intentional` or `deprecated-intent`, unless the real issue is Pro value discoverability.
- `0.25` controls must be tested with long press before any bug claim. If long press works, classify as `intentional`; if users cannot discover it, classify as `discoverability-risk`.

If a finding is `unknown-intent`, add it to `Oracle Questions` and do not include it in the implementation package.

## Active Simulator Audit

Use active app operation as the default. Manual screenshots are fallback only.

### 1. Prepare a dedicated simulator

Use the bundled helper script:

```bash
cd /Users/og3939397/MuscleMap
.claude/skills/growth-audit/scripts/sim_capture.sh init
```

The script prints and writes:

- `RUN_DIR`: `/tmp/musclemap-growth-audit/<run-id>`
- `UDID`: dedicated iPhone 16 Pro Max simulator
- `APP_BUNDLE_ID`: `com.buildinpublic.MuscleMap`

Use that exact UDID. Do not use `booted` when a dedicated UDID is available.

### 2. Operate the app with MCP/computer-use

Use the available iOS Simulator MCP or computer-use tool for UI actions:

- tap;
- swipe;
- type text;
- dismiss sheets;
- navigate tab bar;
- wait for animations to finish.

If no MCP/computer-use tool is available in the current Claude Code session, report that active operation is blocked and ask zDOG to enable it or manually perform the next tap while screenshots are still captured by the script. Do not silently downgrade to a purely code-only audit.

### 3. Capture every checkpoint

After each meaningful screen transition:

```bash
cd /Users/og3939397/MuscleMap
source /tmp/musclemap-growth-audit/<run-id>/env.sh
.claude/skills/growth-audit/scripts/sim_capture.sh shot home
```

Use descriptive labels:

- `00_launch`
- `01_onboarding`
- `02_home_top`
- `03_today_recommendation`
- `04_workout_start`
- `05_active_recording`
- `06_completion`
- `07_paywall`
- `08_history_or_strength`

For all screenshots, inspect only the resized `*_small.png` file.

### 4. Flow to inspect by default

Follow this path unless the user gives a narrower target:

1. Launch app.
2. Complete onboarding if needed, choosing mainstream inputs: hypertrophy, gym, intermediate, 4 days/week.
3. Land on Home.
4. Decide whether "what should I train today?" is clear in 1 second.
5. Open today's recommendation or recommended workout preview.
6. Start workout from the recommendation.
7. Complete a representative workout: at least 3 exercises, 2 sets each where practical, with realistic reps/weights.
8. Finish workout.
9. Inspect completion screen for "come back tomorrow" motivation.
10. Trigger Paywall from the most natural locked value.
11. Inspect History or Strength Map for proof of progress.

For simulator screenshots, always resize before asking a model to inspect them:

```bash
xcrun simctl io "$MM_GROWTH_UDID" screenshot /tmp/musclemap_growth_check.png
sips -Z 800 /tmp/musclemap_growth_check.png --out /tmp/musclemap_growth_check_small.png
```

If capturing a full flow, save temporary originals and resized copies under `/tmp/musclemap-growth-audit/<run-id>/screenshots/`.

## Interaction Trace Mode

This is the default review mode. Treat every meaningful tap, swipe, sheet dismissal, input, or tab change as an event.

For each event:

1. Capture a `before` screenshot.
2. State the user's intent in one sentence.
3. Perform the action with MCP/computer-use.
4. Wait for the UI to settle.
5. Capture an `after` screenshot.
6. Compare before/after and record what changed.
7. Check consistency with the previous screen and the product promise.
8. Create issue stickies for anything suspicious.

Use labels like:

- `04_before_today_recommendation`
- `05_after_tap_start_recommended_workout`
- `06_before_add_set`
- `07_after_add_set`

### Per-event review questions

Ask these after each action:

- Did the result match the user's intent?
- Does the Product Intent Oracle say this behavior is intentional or deprecated?
- Did the UI keep the context from the previous screen, or did it feel like a jump?
- Is the next action obvious without reading instructions?
- Is any text cropped, too small, duplicated, stale, or misleading?
- Is any empty space intentional, or does it look unfinished?
- Is any locked/Pro value introduced at a psychologically reasonable moment?
- Does this screen feel like MuscleMap, or like a generic/debug screen?
- Is the issue caused by bad test data, a real UI bug, weak copy, or weak product logic?

### Sticky issue format

Every issue must be written as a sticky. Do not bury issues in paragraphs.

```markdown
| ID | Severity | Category | Oracle Label | Screen/Event | Evidence | Why It Matters | Suggested Fix | Confidence |
|---|---|---|---|---|---|---|---|---|
| STK-001 | P1 | consistency | bug | today recommendation -> workout start | `05_after...png` | User expected Day 2 workout but landed in generic state | Preserve recommended workout context in active session header | high |
```

Categories:

- `ui-break`: layout, clipping, unreadable text, broken spacing, visual state bug.
- `consistency`: previous screen promise does not match next screen.
- `intent-gap`: user tapped for one reason but the result does not answer it.
- `feel`: screen works but feels flat, generic, unrewarding, or not premium.
- `friction`: too many taps, unclear path, hard gym usage.
- `monetization`: Pro value, paywall timing, price/value mismatch.
- `sample-risk`: finding may be caused by unrealistic test state.
- `intentional`: current behavior matches Product Intent Oracle.
- `deprecated-intent`: old/removed product idea is being mistaken for a missing feature.
- `unknown-intent`: needs zDOG answer before any implementation.
- `discoverability-risk`: intended behavior exists but may be hard to discover.

Severity:

- `P0`: blocks core flow or creates false/misleading state.
- `P1`: materially hurts activation, retention, monetization, or trust.
- `P2`: polish issue worth batching.
- `P3`: note only.

### Trace completion rule

Do not generate the implementation prompt until:

- the planned flow is completed;
- the issue stickies are clustered by root cause;
- low-confidence stickies are separated;
- `intentional`, `deprecated-intent`, `unknown-intent`, and `sample-risk` stickies are blocked from implementation unless zDOG explicitly overrides;
- the highest-leverage fix package is chosen from the full board, not from the first obvious screenshot.

## Critic Passes

Use these six critic lenses. If project subagents are available, run `retention-critic`, `flow-critic`, `monetization-critic`, `product-sense-critic`, `trace-consistency-critic`, and `intent-oracle-critic` with the same input packet. If not, run the six passes inline.

Critics are advisory only. They must not approve, reject, or force a rewrite.

### retention-critic

Looks for the reason a new user returns tomorrow and a paid user stays next month. Focus on daily open reason, 90-day challenge strength, workout completion emotion, habit loop, and cancellation risk.

### flow-critic

Looks for friction in the actual path. Focus on tap count, confusing transitions, gym usability, one-handed use, "today's recommendation -> recording" continuity, empty states, and screenshot-visible design issues.

### monetization-critic

Looks for whether Pro is sold as an outcome. Focus on value clarity, paywall entrypoint context, price justification, before/after proof, locked feature timing, and cancellation objections.

### product-sense-critic

Looks for the human "feel" that screenshots and metrics miss. Focus on whether a real lifter feels rewarded, proud, clear, curious, and pulled back tomorrow. This critic must separate taste judgments from bugs and must call out low-confidence samples.

### trace-consistency-critic

Looks across the entire before/after trace. Focus on whether each tap honored the promise of the previous screen, whether state and copy stayed coherent, and whether issue stickies are properly clustered before any implementation recommendation.

### intent-oracle-critic

Checks every sticky against the Product Intent Oracle. Focus on false positives: intentional behavior, deprecated ideas, unknown intent, hidden gestures, and sample-risk findings being mislabeled as bugs.

## Bottleneck Ranking

Rank these four every run:

1. activation: user understands value and completes first meaningful action.
2. retention: user has a reason to return and record again.
3. monetization: user sees Pro as worth paying for and staying on.
4. acquisition: store traffic and conversion into install.

For v1, acquisition cannot be rank 1 unless retention and monetization are clearly healthy.

## Report Output

Write reports to:

`/Users/og3939397/Documents/Obsidian Vault/zDOG/Projects/MuscleMap/Growth/`

Filename:

`YYYY-MM-DD_growth_audit_<short-focus>.md`

The Obsidian template lives at:

`/Users/og3939397/Documents/Obsidian Vault/zDOG/Projects/MuscleMap/Growth/_REPORT_TEMPLATE.md`

Use this exact report structure:

```markdown
# MuscleMap Growth Audit — YYYY-MM-DD

## 1. Current Metrics
| Source | Metric | Value | Note |
|---|---:|---:|---|

## 2. Current State in One Paragraph

## 2.5 Sample Validity
| Check | Result | Why |
|---|---|---|

## 2.6 Product Intent Oracle
| Item | Status | Notes |
|---|---|---|

## 3. Flow Reviewed
| Step | Screen | Screenshot | User Question | Verdict |
|---|---|---|---|---|

## 3.5 Active Capture Log
| Label | Path | What Changed | Notes |
|---|---|---|---|

## 3.6 Interaction Trace
| Event | Before | Action / Intent | After | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|

## 3.7 Sticky Issue Board
| ID | Severity | Category | Oracle Label | Screen/Event | Evidence | Why It Matters | Suggested Fix | Confidence |
|---|---|---|---|---|---|---|---|---|

## 3.8 Oracle Questions
| ID | Screen/Event | Question | Why It Matters | Suggested Label |
|---|---|---|---|---|

## 4. Bottleneck Ranking
| Rank | Area | Why |
|---:|---|---|

## 5. Critic Findings
### retention-critic
### flow-critic
### monetization-critic
### product-sense-critic
### trace-consistency-critic
### intent-oracle-critic

## 5.5 Human Review
| Moment | Feeling | Score 1-5 | Why |
|---|---|---:|---|

## 6. Fix Packages
| Package | Stickies Included | Expected Impact | Risk | Why This Batch |
|---|---|---|---|---|

## 6.5 Top 3 Fix Packages
| Priority | Package | Expected Impact | Risk | Evidence |
|---:|---|---|---|---|

## 7. Recommended Fix Package

## 8. Claude Code Implementation Prompt

## 9. Approval Gate
Stop here. Ask zDOG whether to implement the selected fix. Do not change app code until confirmed.

## 10. Before / After Screenshot Checklist

## 11. Metrics to Recheck
### 48 hours
### 7 days

## 12. Decision Log
```

## Selection Rules

Choose the selected fix using this order:

1. It improves daily return or cancellation risk.
2. It is visible in screenshots.
3. It fits the "筋トレのStrava - 体の変化を可視化して、コンテンツにする" vision.
4. It can be verified with `/build-verify` and screenshot comparison.
5. It avoids broad rewrites and unrelated polish.

## Implementation Prompt Requirements

The generated prompt must be ready to paste into Claude Code and must include:

- the selected fix package;
- included sticky IDs;
- exact user flow being improved;
- files likely involved, if known;
- what not to touch;
- required screenshot checks;
- required build command or `/build-verify`;
- expected metrics to observe after release.

Do not write a generic "improve retention" prompt. Make it concrete enough for an implementation agent to start immediately.
Do not generate an implementation prompt from a single event unless the issue is P0.

## Approval Gate Wording

End every audit with a short confirmation question:

```text
この1案で実装に進める？進めるなら、このあとコード変更に入る。
```

Do not include more than one selected implementation package at the gate.
