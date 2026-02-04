# Distraction Pattern Analysis Feature

> **Status**: 📋 Planned  
> **Priority**: Future Enhancement  
> **Created**: 2026-01-29  

---

## Overview

A comprehensive analytics system that helps ADHD users understand their distraction patterns, peak focus times, and provides actionable insights to improve productivity.

---

## 📊 1. Core Analytics Dashboard

### Session Summary Stats
- **Focus Score** per session (% of checks labeled "work")
- **Longest Focus Streak** (consecutive work classifications)
- **Average Time Before First Distraction**
- **Most Common Distraction Types** (from the AI's `reason` field)

### Time-Based Insights

| Insight | How It Helps |
|---------|--------------|
| **Peak Focus Hours** | "You're most focused between 10am-12pm" |
| **Distraction-Prone Times** | "Afternoons (2-4pm) show 60% more slacking" |
| **Day of Week Patterns** | "Mondays start slow, Thursdays are your best" |
| **Session Duration Sweet Spot** | "Your ideal session length is 45 mins" |

---

## 🔍 2. Distraction Pattern Detection

### Trigger Analysis (what leads to slacking)
- **Time-based triggers**: "After 25 mins of work, distraction likelihood ↑ 40%"
- **Goal correlation**: Track which goals lead to more distractions (vague goals vs specific ones)
- **Recovery time**: How long does it take to get back to work after slacking?

### Distraction Categories (enhanced classification)

Instead of just "work/slack", parse the `reason` field to categorize:

```
📱 Social Media (Twitter, Reddit, Instagram)
🎬 Entertainment (YouTube, Netflix)
💬 Communication (Discord, iMessage)
🛒 Shopping (Amazon, etc.)
🎮 Gaming
🌐 Random Browsing
```

### Pattern Visualization
- **Focus Timeline**: A visual bar showing work/slack blocks per session
- **Heatmap**: Grid showing focus levels by hour × day of week
- **Transition Flow**: Sankey diagram showing what distractions follow what activities

---

## 🎯 3. Personalized Insights (AI-Powered)

Use Gemini to generate **weekly insight reports**:

> *"This week, you had 12 sessions totaling 8.5 hours of focus time. Your biggest distraction trigger was YouTube, appearing 23 times. Interestingly, your focus drops significantly after 35 minutes of continuous work. Consider taking short breaks around the 30-minute mark. Your best focus day was Tuesday—you completed 3 sessions with 85%+ focus scores."*

### Insight Types
- 📈 **Progress compared to last week**
- ⚠️ **Warning patterns** ("You've been distraction-prone after lunch 3 days in a row")
- 💡 **Actionable tips** ("Try the Pomodoro technique: your optimal focus length seems to be ~25 mins")
- 🎉 **Celebrations** ("New record! 2-hour uninterrupted focus session")

---

## 📱 4. Real-Time Awareness Features

### Live Focus Meter
A subtle indicator showing current session's focus percentage - not intrusive, but visible.

### Distraction Streak Warning
> "Hey! You've been off-track for 10 minutes. Need a break, or ready to refocus?"

### Gentle Nudges Based on Patterns
If the system knows you tend to slack at 3pm:
> "It's 2:55pm - your usual distraction time. Want to start a power focus session?"

---

## 📈 5. Progress Tracking

### Trend Analysis
- Week-over-week focus improvement
- Distraction frequency trending down?
- Best/worst days highlighted

### Goals & Streaks
- "Maintain 70% focus for 5 sessions" → Achievement unlocked!
- **Focus Streak Calendar** (like GitHub contribution graph)

---

## 🏗️ Technical Implementation

### New Models

```swift
// Analytics aggregate for efficient querying
@Model
public class DailyFocusAggregate {
    public var date: Date
    public var totalChecks: Int
    public var workChecks: Int
    public var slackChecks: Int
    public var avgConfidence: Double
    public var longestFocusStreak: Int
    public var distractionCategories: [String: Int] // category -> count
}

// Pattern record
@Model
public class DistractionPattern {
    public var id: UUID
    public var patternType: String  // "time_trigger", "duration_trigger", etc.
    public var description: String
    public var confidence: Double
    public var detectedAt: Date
    public var dataPoints: Int  // how many sessions this is based on
}
```

### Analytics Service

```swift
actor AnalyticsService {
    // Aggregate queries
    func computeFocusScore(for session: FocusSession) -> Double
    func findPeakFocusHours(days: Int) -> [Int]  // hours 0-23
    func findDistractionPatterns() -> [DistractionPattern]
    func generateWeeklyInsight() async -> String  // AI-powered
    
    // Category parsing
    func categorizeDistraction(reason: String) -> DistractionCategory
}
```

### Distraction Category Enum

```swift
enum DistractionCategory: String, Codable {
    case socialMedia = "Social Media"
    case entertainment = "Entertainment"
    case communication = "Communication"
    case shopping = "Shopping"
    case gaming = "Gaming"
    case randomBrowsing = "Random Browsing"
    case unknown = "Unknown"
}
```

---

## 🤔 Design Considerations

### Privacy
- Should analytics be 100% local, or optional cloud sync?
- Consider data minimization for sensitive screenshot data

### Data Retention
- How long to keep detailed checks vs aggregates?
- Suggested: Keep aggregates forever, detailed checks for 30 days

### UX for ADHD Users
- ADHD users can get overwhelmed by too much data
- Default view should be minimal and calming
- Progressive disclosure: simple → detailed

### Gamification
- Can be motivating but also stressful
- Make it opt-in or subtle
- Focus on personal progress, not competition

---

## 🚀 Recommended MVP

Start with these 3 features:

| Feature | Why First? | Complexity |
|---------|-----------|------------|
| **1. Session Focus Score** | Simple, immediately valuable feedback | Low |
| **2. Peak Hours Insight** | Actionable pattern, easy to compute | Medium |
| **3. Weekly AI Summary** | High-value, leverages existing Gemini setup | Medium |

### Phase 1: Foundation
- [ ] Add `DailyFocusAggregate` model
- [ ] Create `AnalyticsService` actor
- [ ] Implement basic focus score calculation
- [ ] Add session summary view

### Phase 2: Patterns
- [ ] Implement distraction categorization
- [ ] Build time-of-day analysis
- [ ] Create heatmap visualization
- [ ] Add pattern detection algorithms

### Phase 3: AI Insights
- [ ] Design weekly summary prompt
- [ ] Implement insight generation with Gemini
- [ ] Add notification for weekly reports
- [ ] Build insights history view

### Phase 4: Real-Time Features
- [ ] Live focus meter widget
- [ ] Predictive nudges based on patterns
- [ ] Recovery time tracking
- [ ] Streak and achievement system

---

## UI/UX Mockup Ideas

### Analytics Tab Layout
```
┌─────────────────────────────────────────┐
│  📊 Your Focus Patterns                 │
├─────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │  72%    │  │ 10-12am │  │  45min  │  │
│  │ Focus   │  │  Peak   │  │ Optimal │  │
│  │ Score   │  │  Hours  │  │ Session │  │
│  └─────────┘  └─────────┘  └─────────┘  │
├─────────────────────────────────────────┤
│  📅 Weekly Heatmap                      │
│  ┌─Mon─Tue─Wed─Thu─Fri─Sat─Sun─┐        │
│  │  🟢  🟡  🟢  🟢  🟡  ⚪  ⚪  │ 9am    │
│  │  🟢  🟢  🟢  🟢  🟢  ⚪  ⚪  │ 10am   │
│  │  🟢  🟢  🟡  🟢  🟢  ⚪  ⚪  │ 11am   │
│  │  🟡  🟡  🟡  🟡  🔴  ⚪  ⚪  │ 2pm    │
│  │  🔴  🟡  🔴  🟡  🔴  ⚪  ⚪  │ 3pm    │
│  └─────────────────────────────┘        │
├─────────────────────────────────────────┤
│  💡 This Week's Insight                 │
│  "Your focus dips after 2pm. Try a     │
│   short walk before afternoon work."   │
└─────────────────────────────────────────┘
```

---

## Related Files

- `Sources/Models/FocusCheck.swift` - Existing check model with label, confidence, reason
- `Sources/Models/FocusSession.swift` - Existing session model with checks relationship
- `Sources/ClassificationService.swift` - Existing AI classification (can reuse for insights)
