import Combine
import CoreGraphics
import Foundation

@MainActor
class ScreenshotCaptureLoop: ObservableObject {
    @Published var latestScreenshot: CGImage?
    @Published var lastCapturedAt: Date?
    @Published var lastError: String?
    @Published var isCapturing: Bool = false

    @Published var interval: TimeInterval = 2.0

    private let capturer: ScreenshotCapturing
    private var captureTask: Task<Void, Never>?
    private let sleepImpl: (TimeInterval) async throws -> Void

    init(
        capturer: ScreenshotCapturing = CoreGraphicsScreenshotCapturer(),
        sleepImpl: @escaping (TimeInterval) async throws -> Void = {
            try await Task.sleep(nanoseconds: UInt64($0 * 1_000_000_000))
        }
    ) {
        self.capturer = capturer
        self.sleepImpl = sleepImpl
    }

    func start() {
        guard captureTask == nil else { return }

        isCapturing = true
        lastError = nil

        captureTask = Task {
            // Loop
            while !Task.isCancelled {
                do {
                    try await sleepImpl(interval)
                    if Task.isCancelled { break }
                    await performCapture()
                } catch {
                    break
                }
            }
        }
    }

    func stop() {
        captureTask?.cancel()
        captureTask = nil
        isCapturing = false
    }

    private func performCapture() async {
        do {
            let image = try await capturer.capture()
            self.latestScreenshot = image
            self.lastCapturedAt = Date()
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }
}
