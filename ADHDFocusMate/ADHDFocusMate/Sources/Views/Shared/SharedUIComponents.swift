import SwiftUI

// MARK: - Shared UI Components for Settings and Onboarding

/// A custom toggle styled for the app's dark green theme
public struct SettingsToggle: View {
    public let title: String
    @Binding public var isOn: Bool

    public init(title: String, isOn: Binding<Bool>) {
        self.title = title
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .foregroundColor(AppTheme.textPrimary)
        }
        .toggleStyle(.switch)
        .tint(.white.opacity(0.8))
    }
}
