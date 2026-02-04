import AppKit
import Foundation

@testable import ADHDFocusMate

class MockClassificationService: ClassificationServiceProtocol, @unchecked Sendable {
    var resultToReturn: ClassificationResult?
    var errorToThrow: Error?

    func classify(imageData: Data, context: String?, apiKey: String?, model: String?) async throws
        -> ClassificationResult
    {
        if let error = errorToThrow {
            throw error
        }
        return resultToReturn
            ?? ClassificationResult(
                label: .work, category: .coding, confidence: 1.0, reason: "Mocked work")
    }
}
