import Foundation

public enum TimelineBlockType: String, Codable, Sendable {
    case work
    case distraction
    case gap
}

public struct TimelineBlock: Identifiable, Sendable {
    public let id: UUID
    public let type: TimelineBlockType
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    public let label: String
    public let category: String?
    public let reason: String?

    public init(
        id: UUID = UUID(),
        type: TimelineBlockType,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        label: String,
        category: String? = nil,
        reason: String? = nil
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.label = label
        self.category = category
        self.reason = reason
    }

    /// Coalesce a list of checks into logical blocks for the timeline
    public static func coalesce(checks: [FocusCheck]) -> [TimelineBlock] {
        guard !checks.isEmpty else { return [] }

        let sortedChecks = checks.sorted(by: { $0.capturedAt < $1.capturedAt })
        var blocks: [TimelineBlock] = []

        guard let first = sortedChecks.first else { return [] }

        var currentStartTime = first.capturedAt
        var currentEndTime = first.capturedAt
        var currentLabel = first.label
        var currentCategory = first.category
        var currentReason = first.reason
        var currentType: TimelineBlockType = first.label == "work" ? .work : .distraction

        for i in 1..<sortedChecks.count {
            let check = sortedChecks[i]
            let checkType: TimelineBlockType = check.label == "work" ? .work : .distraction

            // Criteria for continuing a block:
            // 1. Same type (work/distraction)
            // 2. Same category (if slack)
            // 3. Time gap < 3 minutes (otherwise consider it a gap)

            let timeGap = check.capturedAt.timeIntervalSince(currentEndTime)
            let isSameType = (checkType == currentType)
            let isSameCategory = (check.category == currentCategory)

            if isSameType && isSameCategory && timeGap < 180 {
                // Extend current block
                currentEndTime = check.capturedAt
            } else {
                // Finish current block
                blocks.append(
                    TimelineBlock(
                        type: currentType,
                        startTime: currentStartTime,
                        endTime: currentEndTime,
                        duration: currentEndTime.timeIntervalSince(currentStartTime),
                        label: currentLabel,
                        category: currentCategory,
                        reason: currentReason
                    ))

                // Check if there was a significant gap
                if timeGap >= 180 {
                    blocks.append(
                        TimelineBlock(
                            type: .gap,
                            startTime: currentEndTime,
                            endTime: check.capturedAt,
                            duration: timeGap,
                            label: "Inactive",
                            category: nil,
                            reason: "Long pause between checks"
                        ))
                }

                // Start new block
                currentStartTime = check.capturedAt
                currentEndTime = check.capturedAt
                currentLabel = check.label
                currentCategory = check.category
                currentReason = check.reason
                currentType = checkType
            }
        }

        // Append the last block
        blocks.append(
            TimelineBlock(
                type: currentType,
                startTime: currentStartTime,
                endTime: currentEndTime,
                duration: currentEndTime.timeIntervalSince(currentStartTime),
                label: currentLabel,
                category: currentCategory,
                reason: currentReason
            ))

        return blocks
    }
}
