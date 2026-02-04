import Foundation
import SwiftData

@Model
public class AppSettings {
    public var intervalSeconds: Int
    public var slackNudgesEnabled: Bool
    public var geminiModel: String
    public var geminiApiKey: String?
    public var apiProvider: String = "aiStudio"  // "aiStudio" or "vertexAI"
    public var isKeyValidated: Bool = false
    public var focusActivities: [String] = []  // e.g. ["Coding", "Writing"]
    public var distractionKeywords: [String] = []  // e.g. ["Youtube", "Social Media"]
    public var lastUpdated: Date

    public init(
        intervalSeconds: Int = 180,
        slackNudgesEnabled: Bool = true,
        geminiModel: String = "gemini-2.5-flash-lite",
        geminiApiKey: String? = nil,
        apiProvider: String = "aiStudio",
        isKeyValidated: Bool = false,
        focusActivities: [String] = [],
        distractionKeywords: [String] = [],
        lastUpdated: Date = Date()
    ) {
        self.intervalSeconds = intervalSeconds
        self.slackNudgesEnabled = slackNudgesEnabled
        self.geminiModel = geminiModel
        self.geminiApiKey = geminiApiKey
        self.apiProvider = apiProvider
        self.isKeyValidated = isKeyValidated
        self.focusActivities = focusActivities
        self.distractionKeywords = distractionKeywords
        self.lastUpdated = lastUpdated
    }
}
