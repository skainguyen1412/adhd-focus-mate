import Foundation
import SwiftData

@Model
public class FocusCheck {
    public var id: UUID
    public var capturedAt: Date
    public var label: String
    public var confidence: Double
    public var reason: String
    public var category: String?
    public var userConfirmedLabel: String?
    public var slackPromptedAt: Date?

    @Relationship(inverse: \FocusSession.checks)
    public var session: FocusSession?

    public init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        label: String,
        confidence: Double,
        reason: String,
        category: String? = nil,
        userConfirmedLabel: String? = nil,
        slackPromptedAt: Date? = nil
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.label = label
        self.confidence = confidence
        self.reason = reason
        self.category = category
        self.userConfirmedLabel = userConfirmedLabel
        self.slackPromptedAt = slackPromptedAt
    }
}
