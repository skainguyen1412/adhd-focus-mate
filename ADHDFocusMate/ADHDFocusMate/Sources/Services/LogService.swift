import Combine
import Foundation

/// Represents the level of severity for a log entry
public enum LogLevel: String, Codable, Sendable {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case debug = "DEBUG"
}

/// Represents the source of a log entry
public enum LogSource: String, Codable, Sendable {
    case gemini = "Gemini API"
    case session = "Focus Session"
    case system = "System"
}

/// A single entry in the application activity log
public struct LogEntry: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let source: LogSource
    public let message: String
    public let details: String?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        source: LogSource,
        message: String,
        details: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.source = source
        self.message = message
        self.details = details
    }
}

/// Service for centralized logging of application activities and errors
@MainActor
public class LogService: ObservableObject {
    public static let shared = LogService()

    @Published public private(set) var entries: [LogEntry] = []
    private let maxEntries = 100

    private init() {}

    /// Adds a new log entry
    public func log(
        level: LogLevel = .info,
        source: LogSource,
        message: String,
        details: String? = nil
    ) {
        let entry = LogEntry(
            level: level,
            source: source,
            message: message,
            details: details
        )

        // Print to console for real-time debugging as well
        let prefix = level == .error ? "❌" : (level == .warning ? "⚠️" : "ℹ️")
        print("\(prefix) [\(source.rawValue)] \(message)")
        if let details = details {
            print("   Details: \(details)")
        }

        entries.insert(entry, at: 0)

        // Keep memory usage in check
        if entries.count > maxEntries {
            entries.removeLast()
        }
    }

    /// Clears all log entries
    public func clear() {
        entries.removeAll()
    }
}
