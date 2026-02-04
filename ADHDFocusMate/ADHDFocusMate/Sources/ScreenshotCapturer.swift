import CoreGraphics
import ScreenCaptureKit
import AppKit

enum ScreenshotCaptureError: Error, LocalizedError {
    case captureFailed
    case missingPermission
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .captureFailed:
            return "Failed to capture the screen."
        case .missingPermission:
            return "Missing screen recording permission. Please verify System Settings."
        case .invalidImage:
            return "Captured image data was invalid."
        }
    }
}

protocol ScreenshotCapturing {
    func capture() async throws -> CGImage
}

struct CoreGraphicsScreenshotCapturer: ScreenshotCapturing {
    func capture() async throws -> CGImage {
        do {
            let content = try await SCShareableContent.current
            
            // Just grab the first display for now (usually main)
            guard let display = content.displays.first else {
                throw ScreenshotCaptureError.captureFailed
            }
            
            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            let config = SCStreamConfiguration()
            
            // Set capture resolution to display resolution
            config.width = display.width
            config.height = display.height
            config.showsCursor = true
            
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        } catch {
            // Map SC errors to our custom error type where appropriate
            if error is SCStreamError {
                // In a real app we might inspect the error code (e.g. .userDeclined)
                throw ScreenshotCaptureError.missingPermission
            }
            throw error
        }
    }
}
