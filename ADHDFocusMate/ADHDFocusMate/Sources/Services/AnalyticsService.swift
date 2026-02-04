import Foundation
import SwiftData
import SwiftUI

/// Service responsible for analyzing session data and generating insights
actor AnalyticsService {

    // MARK: - Core Metrics

    /// Calculate the focus score for a list of checks
    func computeFocusScore(checks: [FocusCheck]) -> Double {
        guard !checks.isEmpty else { return 0.0 }

        let workChecks = checks.filter { $0.label == "work" }.count
        return Double(workChecks) / Double(checks.count)
    }

    /// Calculate stats for a completed session
    func summarizeSession(_ session: FocusSession) -> (score: Double, duration: TimeInterval) {
        let score = computeFocusScore(checks: session.checks)
        let duration = session.endedAt?.timeIntervalSince(session.startedAt) ?? 0
        return (score, duration)
    }

    // MARK: - Pattern Analysis (Local)

    /// Identify peak focus hours based on historical checks
    /// Returns a dictionary of [Hour (0-23) : FocusScore (0.0-1.0)]
    func analyzePeakHours(sessions: [FocusSession]) -> [Int: Double] {
        var hourWork = [Int: Int]()
        var hourTotal = [Int: Int]()

        for session in sessions {
            for check in session.checks {
                let hour = Calendar.current.component(.hour, from: check.capturedAt)
                hourTotal[hour, default: 0] += 1
                if check.label == "work" {
                    hourWork[hour, default: 0] += 1
                }
            }
        }

        var hourlyScores = [Int: Double]()
        for (hour, total) in hourTotal {
            if total > 5 {  // Minimum data checks to be significant
                hourlyScores[hour] = Double(hourWork[hour, default: 0]) / Double(total)
            }
        }

        return hourlyScores
    }

    /// Get the most frequent distraction categories
    func getTopDistractions(sessions: [FocusSession], limit: Int = 3) -> [(
        category: String, count: Int
    )] {
        var counts = [String: Int]()

        for session in sessions {
            for check in session.checks where check.label == "slack" {
                let category = check.category ?? "Unknown"
                counts[category, default: 0] += 1
            }
        }

        return counts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (category: $0.key, count: $0.value) }
    }

    // MARK: - Advanced Pattern Detection

    /// Calculate average time (in seconds) to recover from a distraction
    /// Defined as: Duration of a continuous 'slack' block followed by 'work'
    func calculateAverageRecoveryTime(sessions: [FocusSession]) -> TimeInterval {
        var recoveryTimes: [TimeInterval] = []

        for session in sessions {
            let sortedChecks = session.checks.sorted(by: { $0.capturedAt < $1.capturedAt })
            guard !sortedChecks.isEmpty else { continue }

            var currentSlackStart: Date?

            for check in sortedChecks {
                if check.label == "slack" {
                    if currentSlackStart == nil {
                        currentSlackStart = check.capturedAt
                    }
                } else if check.label == "work" {
                    if let start = currentSlackStart {
                        let duration = check.capturedAt.timeIntervalSince(start)
                        // Filter out tiny glitches (< 30s) or massive breaks (> 1 hour)
                        if duration > 30 && duration < 3600 {
                            recoveryTimes.append(duration)
                        }
                        currentSlackStart = nil
                    }
                }
            }
        }

        guard !recoveryTimes.isEmpty else { return 0 }
        return recoveryTimes.reduce(0, +) / Double(recoveryTimes.count)
    }

    /// Analyze when focus drops off during a session
    /// Returns: [MinuteBucket (5-min intervals) : Count of first distractions]
    func analyzeDropOffTimes(sessions: [FocusSession]) -> [Int: Int] {
        var dropOffCounts = [Int: Int]()

        for session in sessions {
            let start = session.startedAt
            let sortedChecks = session.checks.sorted(by: { $0.capturedAt < $1.capturedAt })

            // Find first "work" block to establish baseline
            guard let firstWorkIndex = sortedChecks.firstIndex(where: { $0.label == "work" }) else {
                continue
            }

            // Find first "slack" AFTER the work started
            // This ignores "starting with slack" (procrastination) vs "dropping off" (fatigue)
            let workChecks = sortedChecks.suffix(from: firstWorkIndex)
            if let firstDistraction = workChecks.first(where: { $0.label == "slack" }) {
                let duration = firstDistraction.capturedAt.timeIntervalSince(start)
                let minute = Int(duration / 60)

                // Group into 5-minute buckets (0, 5, 10, 15...)
                let bucket = (minute / 5) * 5

                // Only count significant sessions (> 5 mins)
                if bucket >= 5 {
                    dropOffCounts[bucket, default: 0] += 1
                }
            }
        }

        return dropOffCounts
    }

    // MARK: - Aggregation

    /// Generate a DailyFocusAggregate from a day's sessions
    @MainActor
    func generateDailyAggregate(for date: Date, sessions: [FocusSession], context: ModelContext) {
        let startOfDay = Calendar.current.startOfDay(for: date)

        // Filter sessions that overlap with this day
        // For simplicity, we'll just look at checks that happened on this day
        let checksOnDay = sessions.flatMap { $0.checks }.filter {
            Calendar.current.isDate($0.capturedAt, inSameDayAs: date)
        }

        guard !checksOnDay.isEmpty else { return }

        // Check if aggregate exists
        let existingdescriptor = FetchDescriptor<DailyFocusAggregate>(
            predicate: #Predicate { $0.date == startOfDay }
        )

        let aggregate: DailyFocusAggregate
        if let existing = try? context.fetch(existingdescriptor).first {
            aggregate = existing
        } else {
            aggregate = DailyFocusAggregate(date: startOfDay)
            context.insert(aggregate)
        }

        // Update Stats
        aggregate.totalChecks = checksOnDay.count
        aggregate.workChecks = checksOnDay.filter { $0.label == "work" }.count
        aggregate.slackChecks = checksOnDay.filter { $0.label == "slack" }.count

        // Distraction Counts
        var distCounts = [String: Int]()
        for check in checksOnDay where check.label == "slack" {
            let cat = check.category ?? "Unknown"
            distCounts[cat, default: 0] += 1
        }
        aggregate.distractionCounts = distCounts

        try? context.save()
    }

    // MARK: - API Caching

    /// Shared singleton instance for persisting cache across view reloads
    static let shared = AnalyticsService()

    private var cachedInsight: String?
    private var lastInsightGenerationTime: Date?

    // MARK: - AI Insights

    /// Generate a personalized insight for the user based on recent activity
    /// Uses caching to avoid excessive API calls (max 1 call per app launch/day)
    func generateWeeklyInsight(apiKey: String, sessions: [FocusSession]) async throws -> String {
        // 1. Check Cache
        if let cached = cachedInsight, let lastTime = lastInsightGenerationTime {
            // Cache valid if within the same day (or simply just return cached during session)
            // The user requested "call... when app got start at first time", enabling session-based caching.
            // We can also add a time expiration (e.g. 6 hours).
            if Date().timeIntervalSince(lastTime) < 21600 {  // 6 hours
                return cached
            }
        }

        // 2. Prepare Data Summary
        let totalSessions = sessions.count
        let workChecks = sessions.flatMap { $0.checks }.filter { $0.label == "work" }.count
        let slackChecks = sessions.flatMap { $0.checks }.filter { $0.label == "slack" }.count
        let totalChecks = workChecks + slackChecks
        let score = totalChecks > 0 ? Double(workChecks) / Double(totalChecks) : 0.0

        let topDistractions = getTopDistractions(sessions: sessions, limit: 1)
        let primaryDistraction = topDistractions.first?.category ?? "general distractions"

        // Calculate Peak Hours
        let hourlyScores = analyzePeakHours(sessions: sessions)
        let sortedHours = hourlyScores.sorted { $0.value > $1.value }
        let peakHoursText: String
        if let bestHour = sortedHours.first?.key {
            peakHoursText = String(format: "%02d:00 - %02d:00", bestHour, bestHour + 1)
        } else {
            peakHoursText = "None"
        }

        let prompt = """
            Analyze this weekly productivity data for an ADHD user:
            - Total Sessions: \(totalSessions)
            - Focus Score: \(Int(score * 100))%
            - Primary Distraction: \(primaryDistraction)
            - Peak Focus Hours: \(peakHoursText)

            Write a SHORT (2 sentences max) insight.
            Sentence 1: Observation about their focus pattern or distraction.
            Sentence 2: A gentle, specific tip or encouragement.
            Tone: Empathetic, non-judgmental, encouraging.
            """

        let service = GeminiService()
        let result = try await service.generateContent(prompt: prompt, apiKey: apiKey)

        // 3. Update Cache
        self.cachedInsight = result
        self.lastInsightGenerationTime = Date()

        return result
    }
}
