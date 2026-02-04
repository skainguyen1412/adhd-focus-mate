import Combine
import CoreGraphics
import Foundation
import Testing

@testable import ADHDFocusMate

class MockScreenshotCapturer: ScreenshotCapturing {
    var imagesToReturn: [CGImage] = []
    var errorToThrow: Error?
    var captureCallCount = 0

    func capture() async throws -> CGImage {
        captureCallCount += 1
        if let error = errorToThrow {
            throw error
        }
        if !imagesToReturn.isEmpty {
            return imagesToReturn.removeFirst()
        }
        return createDummyCGImage()
    }

    private func createDummyCGImage() -> CGImage {
        let width = 10
        let height = 10
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        return context.makeImage()!
    }
}

@MainActor
struct ScreenshotCaptureLoopTests {

    @Test
    func startWaitsForIntervalBeforeCapture() async throws {
        let mockCapturer = MockScreenshotCapturer()
        var sleepCallCount = 0
        let loop = ScreenshotCaptureLoop(
            capturer: mockCapturer,
            sleepImpl: { _ in
                sleepCallCount += 1
                // Sleep short time
                try await Task.sleep(nanoseconds: 10_000_000)
            })

        loop.start()

        // Initially no capture
        #expect(mockCapturer.captureCallCount == 0)
        #expect(loop.latestScreenshot == nil)

        // Wait for first capture (requires one sleep)
        for await _ in loop.$latestScreenshot.values {
            if mockCapturer.captureCallCount >= 1 {
                break
            }
        }

        #expect(mockCapturer.captureCallCount >= 1)
        #expect(sleepCallCount >= 1)
        #expect(loop.isCapturing)

        loop.stop()
    }

    @Test
    func loopCapturesRepeatedly() async throws {
        let mockCapturer = MockScreenshotCapturer()

        let loop = ScreenshotCaptureLoop(
            capturer: mockCapturer,
            sleepImpl: { _ in
                // Sleep for a short but manageable time (e.g. 10ms)
                try await Task.sleep(nanoseconds: 10_000_000)
            })

        loop.start()

        // Wait enough time for at least 3 captures (initial + 2 loops) -> > 20ms
        // Let's wait 100ms to be safe, should get ~10 captures
        try? await Task.sleep(nanoseconds: 100_000_000)

        loop.stop()

        // Initial capture + subsequent sleeps
        // We expect at least 2 captures (1 initial + 1 after first sleep)
        #expect(mockCapturer.captureCallCount >= 2)
    }

    @Test
    func stopCancelsLoop() async throws {
        let mockCapturer = MockScreenshotCapturer()
        let loop = ScreenshotCaptureLoop(
            capturer: mockCapturer,
            sleepImpl: { _ in
                try await Task.sleep(nanoseconds: 100_000_000)
            })

        loop.start()
        #expect(loop.isCapturing)

        // Wait for a moment to ensure it started
        try? await Task.sleep(nanoseconds: 50_000_000)

        loop.stop()
        #expect(!loop.isCapturing)

        let countAfterStop = mockCapturer.captureCallCount

        // Wait longer than sleep interval
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Should not have incremented significantly
        #expect(mockCapturer.captureCallCount == countAfterStop)
    }
}
