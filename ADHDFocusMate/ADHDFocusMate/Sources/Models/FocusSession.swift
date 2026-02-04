import Foundation
import SwiftData

@Model
public class FocusSession {
    public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var goalText: String?
    public var stateRawValue: String
    
    @Relationship(deleteRule: .cascade)
    public var checks: [FocusCheck] = []
    
    public var state: SessionState {
        get { SessionState(rawValue: stateRawValue) ?? .completed }
        set { stateRawValue = newValue.rawValue }
    }
    
    public enum SessionState: String, Codable {
        case active
        case paused
        case completed
    }
    
    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        goalText: String? = nil,
        state: SessionState = .active
    ) {
        self.id = id
        self.startedAt = startedAt
        self.goalText = goalText
        self.stateRawValue = state.rawValue
    }
}
