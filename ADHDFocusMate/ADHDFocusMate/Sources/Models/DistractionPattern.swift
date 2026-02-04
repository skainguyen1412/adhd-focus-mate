import Foundation
import SwiftData

@Model
public class DistractionPattern {
    public var id: UUID

    /// Type of pattern detected (e.g., "time_trigger", "duration_trigger")
    public var patternType: String

    /// Human readable description of the pattern
    public var contextDescription: String

    /// Confidence in this pattern (0.0 - 1.0)
    public var confidence: Double

    /// When this pattern was detected
    public var detectedAt: Date

    /// Number of data points supporting this pattern
    public var dataPoints: Int

    public init(
        patternType: String,
        description: String,
        confidence: Double,
        dataPoints: Int
    ) {
        self.id = UUID()
        self.patternType = patternType
        self.contextDescription = description
        self.confidence = confidence
        self.detectedAt = Date()
        self.dataPoints = dataPoints
    }
}
