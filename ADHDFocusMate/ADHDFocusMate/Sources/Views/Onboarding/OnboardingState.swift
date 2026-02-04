import AppKit
import Foundation
import ScreenCaptureKit
import SwiftUI

public class OnboardingState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") public var hasCompletedOnboarding = false
    @Published public var currentStep = 0
    @Published public var hasScreenRecordingPermission = false

    // Total steps (0-6)
    public let totalSteps = 7

    public init() {
        checkPermissions()
    }

    public func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        }
    }

    public func previousStep() {
        if currentStep > 0 {
            withAnimation {
                currentStep -= 1
            }
        }
    }

    public func checkPermissions() {
        // CGPreflightScreenCaptureAccess checks if we have permission without requesting
        hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
    }

    public func requestPermissions() {
        // This triggers the system prompt if not already enabled
        // Note: In modern macOS, this often returns false even if granted until re-checked
        _ = CGRequestScreenCaptureAccess()

        // Re-check after a brief delay or provide a button to manually re-check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkPermissions()
        }
    }

    public func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.8)) {
            hasCompletedOnboarding = true
        }
    }
}
