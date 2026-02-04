import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
class FocusSessionManager: ObservableObject {
    // MARK: - Published State
    @Published var currentSession: FocusSession?
    @Published var state: FocusSession.SessionState = .completed
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentStreak: Int = 0
    @Published var lastCheck: FocusCheck?
    @Published var isProcessing: Bool = false
    @Published var showingPermissionAlert: Bool = false
    @Published var showingApiKeyAlert: Bool = false

    // For testing purposes
    public var skipPermissionCheck: Bool = false
    public var skipApiKeyCheck: Bool = false

    var hasScreenRecordingPermission: Bool {
        if skipPermissionCheck { return true }
        return CGPreflightScreenCaptureAccess()
    }

    // MARK: - Dependencies
    private let dataController: DataController
    private let captureLoop: ScreenshotCaptureLoop
    private let classifier: ClassificationServiceProtocol
    private let notificationManager: NotificationManager

    private var nextCheckEarliestDate: Date?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        dataController: DataController,
        captureLoop: ScreenshotCaptureLoop? = nil,
        classifier: ClassificationServiceProtocol? = nil,
        notificationManager: NotificationManager? = nil
    ) {
        self.dataController = dataController
        self.captureLoop = captureLoop ?? ScreenshotCaptureLoop()
        self.classifier = classifier ?? ClassificationService()
        self.notificationManager = notificationManager ?? NotificationManager()

        setupCaptureObservation()
    }

    private func setupCaptureObservation() {
        captureLoop.$latestScreenshot
            .dropFirst()  // Skip initial nil or existing value if any
            .compactMap { $0 }
            .sink { [weak self] cgImage in
                guard let self = self, self.state == .active else { return }

                // 1. Calculate Resized Size (Max 1024px for API efficiency)
                let originalSize = NSSize(width: cgImage.width, height: cgImage.height)
                let maxDimension: CGFloat = 768  // Reduced further for safety
                var targetSize = originalSize

                if originalSize.width > maxDimension || originalSize.height > maxDimension {
                    let ratio = min(
                        maxDimension / originalSize.width, maxDimension / originalSize.height)
                    targetSize = NSSize(
                        width: originalSize.width * ratio, height: originalSize.height * ratio)
                }

                // 2. Convert to NSImage and Resize using NSBitmapImageRep
                let nsImage = NSImage(cgImage: cgImage, size: originalSize)
                guard
                    let bitmapRep = NSBitmapImageRep(
                        bitmapDataPlanes: nil,
                        pixelsWide: Int(targetSize.width),
                        pixelsHigh: Int(targetSize.height),
                        bitsPerSample: 8,
                        samplesPerPixel: 4,
                        hasAlpha: true,
                        isPlanar: false,
                        colorSpaceName: .deviceRGB,
                        bytesPerRow: 0,
                        bitsPerPixel: 0
                    )
                else { return }

                bitmapRep.size = targetSize

                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
                nsImage.draw(
                    in: NSRect(origin: .zero, size: targetSize), from: .zero, operation: .copy,
                    fraction: 1.0)
                NSGraphicsContext.restoreGraphicsState()

                // 3. Convert to Data with compression
                guard
                    let data = bitmapRep.representation(
                        using: .jpeg, properties: [.compressionFactor: 0.8])  // Lower quality, smaller size
                else { return }

                Task {
                    await self.processScreenshot(data)
                }
            }
            .store(in: &cancellables)
    }

    private func processScreenshot(_ imageData: Data) async {
        guard let session = currentSession, state == .active else { return }

        // Skip if in cooldown (cost reduction)
        if let earliest = nextCheckEarliestDate, Date() < earliest {
            print("⏳ [FocusSessionManager] Skipping check cycle (slack cooldown in effect)")
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            // Fetch API Key and Model
            // Fetch API Key and Model
            var apiKey: String?
            var model: String?
            var apiProvider: String?
            var focusKeywords: [String] = []
            var distractionKeywords: [String] = []

            let descriptor = FetchDescriptor<AppSettings>()
            if let settings = try? dataController.container.mainContext.fetch(descriptor).first {
                apiKey = settings.geminiApiKey
                model = settings.geminiModel
                apiProvider = settings.apiProvider
                focusKeywords = settings.focusActivities
                distractionKeywords = settings.distractionKeywords
            }

            // 1. Classify
            let result = try await classifier.classify(
                imageData: imageData,
                context: session.goalText,
                apiKey: apiKey,
                model: model,
                apiProvider: apiProvider,
                focusKeywords: focusKeywords,
                distractionKeywords: distractionKeywords
            )

            // 2. Create Check Record
            let check = FocusCheck(
                label: result.label.rawValue,
                confidence: result.confidence,
                reason: result.reason,
                category: result.category?.rawValue
            )

            // 3. Update Session
            session.checks.append(check)
            lastCheck = check

            // 4. Update Streak & Nudge Logic
            if result.label == .work {
                currentStreak += 1
            } else {
                currentStreak = 0
                // Nudge if slack
                if result.label == .slack {
                    await handleSlackDetection(check: check)
                }
            }

            // 5. Save
            saveContext()

        } catch {
            LogService.shared.log(
                level: .error,
                source: .session,
                message: "Activity Classification Failed",
                details: error.localizedDescription
            )

            // Send notification for persistent or critical errors
            let errorMsg = error.localizedDescription
            if errorMsg.contains("401") || errorMsg.contains("403") {
                await notificationManager.sendErrorNotification(
                    title: "API Key Error",
                    body: "Your Gemini API Key seems invalid. Please check your settings.",
                    errorKey: "api_key_invalid"
                )
            } else if errorMsg.contains("offline") || errorMsg.contains("network") {
                await notificationManager.sendErrorNotification(
                    title: "Connection Lost",
                    body: "Focus Mate is having trouble reaching the AI. Check your internet.",
                    errorKey: "network_offline"
                )
            }
        }
    }

    private func handleSlackDetection(check: FocusCheck) async {
        // Send notification
        await notificationManager.sendSlackCheckNudge()
        check.slackPromptedAt = Date()

        // Cost saving: skip the next check cycle
        // Using captureLoop.interval + buffer to ensure we skip at least one capture
        let cooldownDuration = captureLoop.interval + 5.0
        nextCheckEarliestDate = Date().addingTimeInterval(cooldownDuration)
        print(
            "🤫 [FocusSessionManager] Slack detected. Silencing next check for \(Int(cooldownDuration))s"
        )
    }

    // MARK: - Session Control

    func startSession(goal: String? = nil) {
        guard state != .active else { return }

        // Safety Check: Screen Recording Permission
        guard hasScreenRecordingPermission else {
            print(
                "⚠️ [FocusSessionManager] Attempted to start session without Screen Recording permission."
            )
            showingPermissionAlert = true
            showingPermissionAlert = true
            return
        }

        // Safety Check: API Key
        guard hasValidApiKey else {
            print("⚠️ [FocusSessionManager] Attempted to start session without API Key.")
            showingApiKeyAlert = true
            return
        }

        // Apply Settings
        applySettings()

        if state == .paused, let session = currentSession {
            // Resume
            session.state = .active
            state = .active
        } else {
            // New Session
            let session = FocusSession(goalText: goal, state: .active)
            dataController.container.mainContext.insert(session)
            currentSession = session
            state = .active
            elapsedTime = 0
            currentStreak = 0
            lastCheck = nil
            nextCheckEarliestDate = nil
        }

        saveContext()
        startTimer()
        captureLoop.start()
    }

    func pauseSession() {
        guard state == .active, let session = currentSession else { return }

        session.state = .paused
        state = .paused

        saveContext()
        stopTimer()
        captureLoop.stop()
    }

    func stopSession() {
        guard let session = currentSession else { return }

        session.state = .completed
        session.endedAt = Date()
        state = .completed

        saveContext()
        stopTimer()
        captureLoop.stop()

        // Generate summary here in future
        currentSession = nil
    }

    // MARK: - Helpers

    private func applySettings() {
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? dataController.container.mainContext.fetch(descriptor).first {
            captureLoop.interval = TimeInterval(settings.intervalSeconds)
            print("⚙️ [FocusSessionManager] Applied capture interval: \(settings.intervalSeconds)s")
        }
    }

    private func saveContext() {
        dataController.save()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.state == .active else { return }
                self.elapsedTime += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private var hasValidApiKey: Bool {
        if skipApiKeyCheck { return true }
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? dataController.container.mainContext.fetch(descriptor).first {
            // Check if key exists and is not empty
            return settings.geminiApiKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                == false
        }
        return false
    }
}
