import AppKit
import Foundation

// MARK: - Classification Result

/// Result of classifying a screenshot
public struct ClassificationResult: Codable, Sendable {
    /// Classification label
    public let label: Label
    /// Specific category of the activity
    public let category: DistractionCategory?
    /// Confidence score (0.0 - 1.0)
    public let confidence: Double
    /// Brief explanation for the classification
    public let reason: String

    /// Classification labels
    public enum Label: String, Codable, Sendable {
        case work
        case slack
    }
}

// MARK: - Distraction Categories

public enum DistractionCategory: String, Codable, Sendable, CaseIterable {
    case socialMedia = "Social Media"
    case entertainment = "Entertainment"
    case communication = "Communication"
    case shopping = "Shopping"
    case gaming = "Gaming"
    case randomBrowsing = "Random Browsing"
    case news = "News"
    case other = "Other"

    // For work, we can make it optional or have categories like:
    case coding = "Coding"
    case documentation = "Documentation"
    case design = "Design"
    case meeting = "Meeting"
    case email = "Email"
    case learning = "Learning"
}

// MARK: - Classification Error

/// Errors that can occur during classification
public enum ClassificationError: Error, LocalizedError {
    case imageProcessingFailed
    case invalidResponse
    case parsingFailed(String)
    case networkError(Error)
    case rateLimited
    case modelNotAvailable
    case apiKeyMissing

    public var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image for classification"
        case .invalidResponse:
            return "Received invalid response from AI model"
        case .parsingFailed(let details):
            return "Failed to parse response: \(details)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "Rate limited - please try again later"
        case .modelNotAvailable:
            return "AI model is not available"
        case .apiKeyMissing:
            return "Gemini API Key is missing. Please add it in Settings."
        }
    }
}

// MARK: - Classification Service Protocol

// MARK: - Classification Service Protocol

public protocol ClassificationServiceProtocol: Sendable {
    func classify(
        imageData: Data,
        context: String?,
        apiKey: String?,
        model: String?,
        apiProvider: String?,
        focusKeywords: [String],
        distractionKeywords: [String]
    ) async throws -> ClassificationResult
}

// MARK: - Classification Service

/// Service for classifying screenshots as work or slack using Gemini REST API
@available(macOS 12.0, *)
public actor ClassificationService: ClassificationServiceProtocol {

    // MARK: - Initialization

    /// Initialize the classification service
    public init() {}

    // MARK: - Prompt Generation

    private func makeSystemPrompt(focusKeywords: [String], distractionKeywords: [String]) -> String
    {
        let workList: String
        if !focusKeywords.isEmpty {
            workList = focusKeywords.map { "\"\($0)\"" }.joined(separator: ", ")
        } else {
            workList =
                "coding, writing, reading documentation, research, work emails, design tools, spreadsheets"
        }

        let slackList: String
        if !distractionKeywords.isEmpty {
            slackList = distractionKeywords.map { "\"\($0)\"" }.joined(separator: ", ")
        } else {
            slackList = "social media, videos, games, shopping, entertainment, personal browsing"
        }

        return """
            You are analyzing a screenshot to determine if the user is working or slacking off.

            Classify the screenshot as:
            - "work": productive activity (\(workList))
            - "slack": non-work activity (\(slackList))

            Also categorize the activity into one of these specific categories:
            - For Slack: "Social Media", "Entertainment", "Communication", "Shopping", "Gaming", "Random Browsing", "News", "Other"
            - For Work: "Coding", "Documentation", "Design", "Meeting", "Email", "Learning", "Other"

            If the activity is ambiguous (e.g., blank screen, loading), make your best guess based on context or default to "slack" if no work is visible.

            Respond with ONLY valid JSON in this exact format:
            {"label": "work|slack", "category": "CategoryName", "confidence": 0.0-1.0, "reason": "brief explanation under 120 chars"}
            """
    }

    // MARK: - Classification

    /// Classify a screenshot as work or slack
    public func classify(
        imageData: Data,
        context: String? = nil,
        apiKey: String? = nil,
        model: String? = nil,
        apiProvider: String? = nil,
        focusKeywords: [String] = [],
        distractionKeywords: [String] = []
    ) async throws -> ClassificationResult {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ClassificationError.apiKeyMissing
        }

        let service = GeminiService()

        // Use provided model or fallback
        let modelUnderTest = model ?? "gemini-2.5-flash-lite"
        let providerUnderTest = apiProvider ?? "aiStudio"

        var prompt = makeSystemPrompt(
            focusKeywords: focusKeywords, distractionKeywords: distractionKeywords)
        if let context = context, !context.isEmpty {
            prompt += "\nUser's current goal: \(context)"
        }

        do {
            let jsonString = try await service.classify(
                imageData: imageData, apiKey: apiKey, model: modelUnderTest,
                apiProvider: providerUnderTest, systemPrompt: prompt)
            return try parseResponse(jsonString)
        } catch {
            print("❌ [ClassificationService] REST Classification failed: \(error)")
            throw ClassificationError.networkError(error)
        }
    }

    // MARK: - Response Parsing

    /// Parse the JSON response from Gemini
    private func parseResponse(_ text: String) throws -> ClassificationResult {
        // Clean the response (remove markdown code blocks if present)
        var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown JSON code block if present
        if cleanedText.hasPrefix("```json") {
            cleanedText = String(cleanedText.dropFirst(7))
        } else if cleanedText.hasPrefix("```") {
            cleanedText = String(cleanedText.dropFirst(3))
        }

        if cleanedText.hasSuffix("```") {
            cleanedText = String(cleanedText.dropLast(3))
        }

        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse JSON
        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw ClassificationError.parsingFailed("Invalid UTF-8 in response")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ClassificationResult.self, from: jsonData)
        } catch {
            throw ClassificationError.parsingFailed(
                "JSON decode failed: \(error.localizedDescription). Raw: \(cleanedText)")
        }
    }
}

// MARK: - Convenience Extensions

extension ClassificationResult {
    /// Whether this classification indicates the user is slacking
    public var isSlacking: Bool {
        label == .slack
    }

    /// Whether this classification has high confidence
    public var isHighConfidence: Bool {
        confidence >= 0.75
    }

    /// Human-readable description
    public var description: String {
        let catText = category?.rawValue ?? "Unknown"
        return "\(label.rawValue.capitalized) | \(catText) (\(Int(confidence * 100))%): \(reason)"
    }
}
