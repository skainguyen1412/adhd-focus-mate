# FEATURE: Session Timeline Analysis "Flow & Friction"

## 1. The Core Concept
A visual "Session Retrospective" that tells the story of your focus session. Instead of just "80% Work", it answers: *"How did my focus evolve over time?"*

It helps users identify:
- **The "Ramp Up"**: How long it takes to get into deep work.
- **The "Micro-Gaps"**: Short 1-2 minute distractions vs. long breaks.
- **The "Crash"**: When fatigue sets in near the end.

## 2. Technical Implementation: "Event Coalescing"

Since the app checks every ~60 seconds, displaying raw data is too noisy (`Work`, `Work`, `Work`, `Slack`, `Work`).

We need a **Coalescing Algorithm** to group contiguous checks into **Blocks**:

**Input (Raw Checks):**
1. 10:00 [Work] "Coding"
2. 10:01 [Work] "Coding"
3. 10:02 [Work] "Coding"
4. 10:03 [Slack] "Twitter"
5. 10:04 [Slack] "Twitter"
6. 10:05 [Work] "Coding"

**Output (Timeline Blocks):**
- **10:00 - 10:03 (3m)**: 🟢 **Deep Work** (Coding)
- **10:03 - 10:05 (2m)**: 🔴 **Distraction** (Social Media)
- **10:05 - ...**: 🟢 **Recovery**

## 3. UI/UX Design: "Zen Timeline"

### Visualization Style
- **Vertical "River" Line**: A central line connecting time blocks.
- **Cards**:
    - **Work Blocks**: Clean, glass-morphic green/blue gradients.
    - **Distraction Blocks**: Subtle warning colors (orange/red/pink).
    - **Gap Indicators**: Small dashes for short durations.

### Interaction
- **Tooltip/Details**: Hovering over a block shows the AI's *reasoning* (e.g., "User appears to be scrolling a social media feed").
- **Edit Capability** (Optional MVP): Allow user to reclassify a block if the AI was wrong.

## 4. Implementation Steps

1.  **Logic Layer (`AnalyticsService`)**:
    - Implement `coalesceSessions(checks: [FocusCheck]) -> [TimelineBlock]`
2.  **UI Layer (`SessionTimelineView`)**:
    - Build a vertical scroll view with `VStack` and custom drawing for the connecting line.
    - Integrate into `AnalyticsDashboardView` (drill down from "Last Session").
