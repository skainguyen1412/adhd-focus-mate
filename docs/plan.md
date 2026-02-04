# ADHD-Focus-Mate (macOS) — Detailed Build Plan

## 1) Product concept (what we’re building)
An **ADHD-friendly focus timer** that runs quietly in the background (menu bar app). When the user starts a **Focus Session**, the app:

- Captures a **screenshot every 3 minutes** (or a user-configurable interval).
- Immediately classifies the screenshot as **Working** vs **Slacking** (plus confidence + short reason).
- Uses that classification to drive **gentle nudges**, **streaks**, and **session summaries**.

Core principle: **Support, not surveillance**. The user is always in control.

## 2) Goals / Non-goals

### Goals
- **Low friction**: one-click Start Focus / Pause / Stop from menu bar.
- **Low cost**: use **Gemini “cheap” tier** + minimal output; downscale images to reduce tokens.
- **Trustworthy**: strong privacy controls, clear explanations, easy pause/delete.
- **Personalizable (later)**: user-defined “this is work for me” overrides and per-app rules.

### Non-goals (for MVP)
- Cross-platform (start macOS only).
- Real-time 1 FPS recording or constant analysis.
- Employer-style monitoring features.

## 3) High-level architecture

### Processes / runtime style
- **Menu bar app** (NSStatusItem) + optional main window.
- “Soft-quit” behavior (optional): closing window keeps the app running in the menu bar.

### Core modules (suggested)
- `FocusSessionManager`: session state machine, timers, transitions.
- `CaptureService`: screenshot capture + downscaling.
- `ClassificationService`: Firebase Vertex AI call + response parsing.
- `Storage`: SwiftData models + retention/cleanup.
- `Insights`: aggregates session stats, generates summaries.
- `UI`: SwiftUI views for timer, history, settings, privacy.

### Data flow (per check)
1. Timer fires → capture screenshot.
2. Downscale/compress.
3. Send image to Gemini → parse structured JSON output.
4. Persist check result → update streak/timer UI → optional gentle nudge.

## 4) Project tooling (Tuist)

We will use **[Tuist](https://tuist.io)** for project generation and modularization.

### Why Tuist?
- **Clean modular architecture**: easily split the app into frameworks (Core, Capture, Classification, UI, etc.)
- **Unified dependencies**: centralized dependency management (SPM, local frameworks)
- **Consistent builds**: generated `.xcodeproj` ensures no merge conflicts in project files
- **Scalability**: as the app grows, Tuist makes it trivial to add new modules or features

### Project structure (suggested)
```
ADHDTimerAI/
├── Project.swift              # Tuist manifest
├── Tuist/
│   └── Config.swift
├── App/                       # Main menu bar app target
├── Modules/
│   ├── Core/                  # FocusSessionManager, models
│   ├── Capture/               # CaptureService
│   ├── Classification/        # ClassificationService (Gemini)
│   ├── Storage/               # SwiftData persistence
│   ├── Insights/              # Session summaries, analytics
│   └── UI/                    # SwiftUI views
└── Tests/
    ├── CoreTests/
    ├── CaptureTests/
    └── ...
```

### Workflow
1. Define targets and dependencies in `Project.swift`
2. Run `tuist generate` to create the `.xcodeproj`
3. Build and run as normal in Xcode

### Benefits for this project
- **Faster iteration**: clean separation between capture, AI, and UI logic
- **Easier testing**: each module can be tested independently
- **Code organization**: enforces clean architecture from day one

## 5) Permissions & privacy model (must-have)

### Permissions
- **Screen recording permission** (macOS privacy prompt) to capture screenshots.
- **Notifications** permission for nudges (interactive “slack check”).

### Privacy controls (MVP requirements)
- **Pause** and “Stop session” always visible.
- **Local storage by default**: store *classification results*; keep screenshots optional.
- **Rolling buffer** option (e.g., keep last 30–120 minutes of screenshots only).
- **Export & delete**: user can delete a session and all associated artifacts.

### Privacy controls (future)
- **Per-app allow/deny list** (e.g., never capture Password Managers).
- **Sensitive app auto-block list** (seed defaults).

### Recommended storage policy
Default: **do not keep screenshots long-term**.
- Keep only:
  - timestamp
  - label (work/slack)
  - confidence
  - reason (short)
  - active app bundle id (if available)
  - optional “domain” (if you can safely infer without capturing content)
- Optional toggle: “Keep screenshots for review” with retention window.

## 5) Cost design (Gemini)

### Your cadence
Every 3 minutes = **20 checks/hour**.
If focus = **6 hours/day**:
- 120 checks/day
- 3,600 checks/month (30-day month)

### Token minimization strategy
Gemini bills images as tokens; keep cost low by:
- **Downscaling** images to **≤384px** (often ~258 tokens/image in Gemini 2.x token rules).
- **JPEG compression** (quality ~0.6–0.8).
- **Tiny output** (strict JSON with 1–2 short strings).
- Keep prompt short and stable (you can also measure precisely with `countTokens`).

### Cost measurement in development (recommended)
Add a dev-only “Cost Meter” tool that:
- calls Gemini `countTokens` on the exact payload you would send
- logs tokens/check and tokens/day so you can tune downscaling/prompt.

## 6) AI classification design

### A) MVP: direct Gemini classification (every check)
Input:
- compressed screenshot image
- minimal context:
  - (optional) current focus goal (short)
Output (force JSON):

```json
{
  "label": "work" | "slack" | "uncertain",
  "confidence": 0.0,
  "reason": "short string (<= 120 chars)"
}
```

### B) Future: local gate + personalization
- Add a **local heuristic gate** (foreground app, idle detection, etc.) to reduce AI calls.
- Add user correction loop (“Always treat X as Work?”) and learn per-app rules.

## 7) Data model (SwiftData)
Use **SwiftData** for local persistence (simple, Apple-native).

Suggested entities:
- `FocusSession`
  - `id`, `startedAt`, `endedAt`, `goalText`, `mode`, `createdAt`
- `FocusCheck`
  - `id`, `sessionId`
  - `capturedAt`
  - `label`, `confidence`, `reason`
  - `userConfirmedLabel?` (nullable; set by notification response)
  - `slackPromptedAt?` (nullable; when we asked “Are you slacking off?”)
  - `screenshotPath?` (optional, if you store screenshots)
- `Settings`
  - `intervalSeconds` (default 180)
  - `screenshotRetentionMinutes` (default 0)
  - `geminiModel`, `maxTokensOut`
  - `slackNudgesEnabled` (default true)
  - `slackNudgeConfidenceThreshold` (e.g., 0.75)
  - `slackNudgeConsecutiveCount` (e.g., 2)
  - `slackNudgeCooldownMinutes` (e.g., 15)

Use **Firebase SDK** (GoogleService-Info.plist), so no manual API key handling needed.

## 8) Capture design (implementation approach)

### Capture quality targets
For classification you rarely need full resolution.
- Start with **max dimension 384–512px**.
- Consider cropping to the “center region” if you want to reduce tokens further (but be careful—slack cues may be in the browser chrome/tab bar).

### Redaction strategy (future)
- Per-app blocking and auto sensitive-app blocking.
- Optional blur/redaction (hard to do reliably).

## 9) UX plan (MVP screens)

### Menu bar
- Start Focus
- Pause
- Stop + Save Session
- Open App (main window)

### Main window tabs
- **Timer**: big start/pause/stop, goal text, last check result, streak.
- **Session History**: sessions list + detail view (timeline of checks).
- **Privacy**: retention settings, “delete all data”.
- **Settings**: interval, notifications, provider/model.

### Nudges (gentle)
#### Slack-check notification (MVP)
When the model says “slack”, the app can ask the user to confirm with an **interactive notification**:

- **Title**: “Are you slacking off?”
- **Actions**:
  - **“Yes, I’m sorry!”** → record confirmation, optionally suggest “Pause session?” or “Take a 2‑min reset”.
  - **“No, I didn’t.”** → record denial (useful signal for future personalization + model tuning).

#### When to send it
- Only nudge if:
  - **confidence is high** AND
  - **consecutive slack checks ≥ N** (e.g., 2) AND
  - user hasn’t been prompted recently (**cooldown**).

#### Implementation notes (macOS)
- Register a notification category, e.g. `slack_check`, with two actions:
  - `slack_yes` (“Yes, I’m sorry!”)
  - `slack_no` (“No, I didn’t.”)
- Implement `UNUserNotificationCenterDelegate` to handle action taps.
- Map the notification back to a specific `FocusCheck` via an identifier in `userInfo` (e.g., `checkId`).
  - On `slack_yes`: set `userConfirmedLabel = "slack"`
  - On `slack_no`: set `userConfirmedLabel = "work"` (or `"not_slack"` if you prefer a third state)
  - Always store `slackPromptedAt` when the notification is created.

## 10) Phased implementation plan

### Phase 0 — Spike (1–2 days)
- Create a menu bar app skeleton.
- Implement screenshot capture on a timer (no storage).
- Show last captured thumbnail in a debug window.

Exit criteria: stable capture + permission onboarding.

### Phase 1 — Session engine + SwiftData (2–4 days)
- Implement `FocusSessionManager` state machine.
- Persist sessions + checks in SwiftData.
- Implement retention cleanup job.

Exit criteria: start/pause/stop works; history view shows checks.

### Phase 2 — Gemini integration (2–5 days)
- Integrate **Firebase iOS SDK** (Vertex AI for Firebase).
- Add `GoogleService-Info.plist` to project Resources.
- Implement `ClassificationService` using Firebase's `GenerativeModel` with structured JSON output.
- Add token counting where possible (or rely on Firebase quotas).

Exit criteria: each check produces label/confidence/reason reliably; errors are handled.

### Phase 3 — Nudges + summaries (2–5 days)
- Notification permission + **interactive slack-check** (“Are you slacking off?” → Yes/No).
- End-of-session summary (work % vs slack %, streak highlights).

Exit criteria: usable MVP for a single user daily.

### Phase 4 — Hardening (ongoing)
- Crash safety, retry policies, offline behavior.
- Export (CSV/JSON), delete flows, UI polish.
- Packaging, signing, Sparkle updates (optional).

### Future (post-MVP) — Rules + heuristics gate
- Foreground app detection.
- Per-app allow/deny and always-work/always-slack rules.
- Sensitive app auto-block list (seed defaults).
- Idle detection (no keyboard/mouse input) to tag “Idle”.
- Goal/context personalization and correction loop.

## 11) Reliability & error handling rules
- If capture fails: record a check with `label=uncertain`, do not spam AI.
- If Gemini fails: exponential backoff; mark check as `uncertain`.
- Always keep UI responsive (AI calls off main thread).
- Add a “Provider health” indicator in settings.

## 12) Testing plan
- **Unit tests**
  - session state transitions
  - retention cleanup
- **Integration tests**
  - capture loop runs for N cycles without leaks
  - mock Gemini responses and parsing
- **Manual test checklist**
  - permission denied flow
  - offline mode
  - long focus sessions

## 13) Next decisions I need from you (to lock the spec)
- Do you want **Work/Slack only**, or **Work/Slack/Idle/Uncertain**?
- Do you want to store **any screenshots** by default, or **never** (results-only)?
- Do you want **nudges** (notifications) in MVP, or later?
- Do you want per-session **goal text** (“finish X”) to be sent to Gemini (privacy tradeoff)?

