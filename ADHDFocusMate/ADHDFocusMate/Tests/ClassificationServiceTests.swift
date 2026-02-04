import AppKit
import Testing

@testable import ADHDFocusMate

// MARK: - ClassificationResult Tests

struct ClassificationResultTests {

    // MARK: - JSON Parsing Tests

    @Test func decode_validWorkJSON_succeeds() throws {
        let json = """
            {"label": "work", "confidence": 0.85, "reason": "User is coding in VS Code"}
            """

        let result = try JSONDecoder().decode(
            ClassificationResult.self, from: json.data(using: .utf8)!)

        #expect(result.label == .work)
        #expect(result.confidence == 0.85)
        #expect(result.reason == "User is coding in VS Code")
    }

    @Test func decode_validSlackJSON_succeeds() throws {
        let json = """
            {"label": "slack", "confidence": 0.92, "reason": "YouTube video playing"}
            """

        let result = try JSONDecoder().decode(
            ClassificationResult.self, from: json.data(using: .utf8)!)

        #expect(result.label == .slack)
        #expect(result.confidence == 0.92)
        #expect(result.reason == "YouTube video playing")
    }

    @Test func decode_invalidLabel_throws() {
        let json = """
            {"label": "invalid", "confidence": 0.5, "reason": "test"}
            """

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ClassificationResult.self, from: json.data(using: .utf8)!)
        }
    }

    @Test func decode_missingField_throws() {
        let json = """
            {"label": "work", "confidence": 0.5}
            """

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ClassificationResult.self, from: json.data(using: .utf8)!)
        }
    }

    // MARK: - Convenience Property Tests

    @Test func isSlacking_slackLabel_returnsTrue() {
        let result = ClassificationResult(
            label: .slack, category: .socialMedia, confidence: 0.8, reason: "test")
        #expect(result.isSlacking == true)
    }

    @Test func isSlacking_workLabel_returnsFalse() {
        let result = ClassificationResult(
            label: .work, category: .coding, confidence: 0.8, reason: "test")
        #expect(result.isSlacking == false)
    }

    @Test func isHighConfidence_above75_returnsTrue() {
        let result = ClassificationResult(
            label: .work, category: .coding, confidence: 0.75, reason: "test")
        #expect(result.isHighConfidence == true)

        let result2 = ClassificationResult(
            label: .work, category: .coding, confidence: 0.90, reason: "test")
        #expect(result2.isHighConfidence == true)
    }

    @Test func isHighConfidence_below75_returnsFalse() {
        let result = ClassificationResult(
            label: .work, category: .coding, confidence: 0.74, reason: "test")
        #expect(result.isHighConfidence == false)

        let result2 = ClassificationResult(
            label: .work, category: .coding, confidence: 0.50, reason: "test")
        #expect(result2.isHighConfidence == false)
    }

    @Test func description_formatsCorrectly() {
        let result = ClassificationResult(
            label: .work, category: .coding, confidence: 0.85, reason: "Coding in Xcode")
        #expect(result.description == "Work | Coding (85%): Coding in Xcode")
    }
}

// MARK: - ClassificationError Tests

struct ClassificationErrorTests {

    @Test func errorDescription_imageProcessingFailed() {
        let error = ClassificationError.imageProcessingFailed
        #expect(error.errorDescription?.contains("Failed to process image") == true)
    }

    @Test func errorDescription_invalidResponse() {
        let error = ClassificationError.invalidResponse
        #expect(error.errorDescription?.contains("invalid response") == true)
    }

    @Test func errorDescription_parsingFailed() {
        let error = ClassificationError.parsingFailed("missing field")
        #expect(error.errorDescription?.contains("missing field") == true)
    }

    @Test func errorDescription_rateLimited() {
        let error = ClassificationError.rateLimited
        #expect(error.errorDescription?.contains("Rate limited") == true)
    }
}

// MARK: - ClassificationService Unit Tests

struct ClassificationServiceTests {

    @Test func labelRawValues() {
        #expect(ClassificationResult.Label.work.rawValue == "work")
        #expect(ClassificationResult.Label.slack.rawValue == "slack")
    }

    @Test func parseResponse_jsonWithCodeBlock_parsesCorrectly() throws {
        let responseWithCodeBlock = """
            ```json
            {"label": "work", "confidence": 0.85, "reason": "User is coding"}
            ```
            """

        var cleaned = responseWithCodeBlock.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        let result = try JSONDecoder().decode(
            ClassificationResult.self, from: cleaned.data(using: .utf8)!)

        #expect(result.label == .work)
        #expect(result.confidence == 0.85)
    }
}
