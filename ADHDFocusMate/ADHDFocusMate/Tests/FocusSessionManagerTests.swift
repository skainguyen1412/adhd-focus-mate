import Combine
import CoreGraphics
import SwiftData
import Testing

@testable import ADHDFocusMate

@MainActor
struct FocusSessionManagerTests {
    let manager: FocusSessionManager
    let dataController: DataController
    let mockClassifier: MockClassificationService
    let captureLoop: ScreenshotCaptureLoop
    let notificationManager: NotificationManager

    init() {
        dataController = DataController(inMemory: true)
        mockClassifier = MockClassificationService()
        captureLoop = ScreenshotCaptureLoop()
        notificationManager = NotificationManager()

        manager = FocusSessionManager(
            dataController: dataController,
            captureLoop: captureLoop,
            classifier: mockClassifier,
            notificationManager: notificationManager
        )
        manager.skipPermissionCheck = true
        manager.skipApiKeyCheck = true
    }

    @Test
    func startSession() {
        manager.startSession(goal: "Test Goal")

        #expect(manager.state == .active)
        #expect(manager.currentSession != nil)
        #expect(manager.currentSession?.goalText == "Test Goal")
        #expect(captureLoop.isCapturing == true)

        // Verify persistence
        let descriptor = FetchDescriptor<FocusSession>()
        let sessions = try? dataController.container.mainContext.fetch(descriptor)
        #expect(sessions?.count == 1)
    }

    @Test
    func pauseSession() {
        manager.startSession()
        manager.pauseSession()

        #expect(manager.state == .paused)
        #expect(manager.currentSession?.state == .paused)
        #expect(captureLoop.isCapturing == false)
    }

    @Test
    func stopSession() {
        manager.startSession()
        manager.stopSession()

        #expect(manager.state == .completed)
        #expect(manager.currentSession == nil)
        #expect(captureLoop.isCapturing == false)

        // Verify session ended
        let descriptor = FetchDescriptor<FocusSession>()
        let sessions = try? dataController.container.mainContext.fetch(descriptor)
        #expect(sessions?.first?.endedAt != nil)
    }

    @Test
    func processingWorkScreenshot() async {
        manager.startSession()

        // Mock classification result
        mockClassifier.resultToReturn = ClassificationResult(
            label: .work,
            category: .coding,
            confidence: 0.9,
            reason: "Coding in Xcode"
        )

        // Simulate screenshot capture
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(
            data: nil, width: 100, height: 100, bitsPerComponent: 8, bytesPerRow: 400,
            space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        let image = context.makeImage()!

        captureLoop.latestScreenshot = image

        // Wait for async processing
        try? await Task.sleep(nanoseconds: 500_000_000)

        #expect(manager.currentStreak == 1)
        #expect(manager.lastCheck != nil)
        #expect(manager.lastCheck?.label == "work")
        #expect(manager.currentSession?.checks.count == 1)
    }

    @Test
    func processingSlackScreenshotTriggersNudge() async {
        manager.startSession()

        // Mock classification result
        mockClassifier.resultToReturn = ClassificationResult(
            label: .slack,
            category: .entertainment,
            confidence: 0.9,
            reason: "Watching YouTube"
        )

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(
            data: nil, width: 100, height: 100, bitsPerComponent: 8, bytesPerRow: 400,
            space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        let image = context.makeImage()!

        captureLoop.latestScreenshot = image

        try? await Task.sleep(nanoseconds: 500_000_000)

        #expect(manager.currentStreak == 0)
        #expect(manager.lastCheck?.label == "slack")
        #expect(manager.lastCheck?.slackPromptedAt != nil)
    }

    @Test
    func slackCooldownSkipsNextProcess() async {
        manager.startSession()

        // 1. First capture -> Slack
        mockClassifier.resultToReturn = ClassificationResult(
            label: .slack,
            category: .entertainment,
            confidence: 0.9,
            reason: "Slacking"
        )

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(
            data: nil, width: 100, height: 100, bitsPerComponent: 8, bytesPerRow: 400,
            space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        let image = context.makeImage()!

        captureLoop.latestScreenshot = image
        try? await Task.sleep(nanoseconds: 500_000_000)

        #expect(manager.currentSession?.checks.count == 1)
        #expect(manager.lastCheck?.label == "slack")

        // 2. Second capture immediately -> Should be skipped due to cooldown
        // Even if classifier has a different result queued, it shouldn't reach it
        mockClassifier.resultToReturn = ClassificationResult(
            label: .work,
            category: .coding,
            confidence: 1.0,
            reason: "Resumed Work"
        )

        captureLoop.latestScreenshot = image
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Still counts as 1 check because the second was skipped
        #expect(manager.currentSession?.checks.count == 1)
        #expect(manager.lastCheck?.label == "slack")  // Still the old one
    }
}
