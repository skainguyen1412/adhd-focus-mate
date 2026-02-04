import Foundation
import SwiftData

@Model
public class DailyFocusAggregate {
    /// The date of this aggregate (normalized to start of day)
    public var date: Date

    /// Total number of checks performed
    public var totalChecks: Int = 0

    /// Number of checks classified as work
    public var workChecks: Int = 0

    /// Number of checks classified as slack
    public var slackChecks: Int = 0

    /// Average confidence score of checks
    public var avgConfidence: Double = 0.0

    /// Longest consecutive work streak in minutes (approx, based on check interval)
    public var longestFocusStreak: Int = 0

    /// JSON encoded dictionary of [DistractionCategory.RawValue : Count]
    public var distractionCountsJSON: String = "{}"

    public init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
    }

    // MARK: - Helpers

    public var focusScore: Double {
        guard totalChecks > 0 else { return 0.0 }
        return Double(workChecks) / Double(totalChecks)
    }

    public var distractionCounts: [String: Int] {
        get {
            guard let data = distractionCountsJSON.data(using: .utf8),
                let dict = try? JSONDecoder().decode([String: Int].self, from: data)
            else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
                let string = String(data: data, encoding: .utf8)
            {
                distractionCountsJSON = string
            }
        }
    }

    public func incrementCategory(_ category: String) {
        var counts = distractionCounts
        counts[category, default: 0] += 1
        distractionCounts = counts
    }
}
