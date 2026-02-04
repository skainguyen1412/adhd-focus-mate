import SwiftUI

public struct AppTheme {
    // MARK: - Colors (Deep Zen Theme)
    public static let primary = Color(hex: "4ADE80")  // Electric Leaf (Minty Green)
    public static let primaryDark = Color(hex: "064E3B")  // Deep Forest
    public static let secondary = Color(hex: "065F46")  // Mid Teal
    public static let accent = Color(hex: "10B981")  // Emerald

    // Backgrounds
    public static let backgroundDeep = Color(hex: "022C22")  // Nearly Black Green

    // Text
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.7)
    public static let textTertiary = Color.white.opacity(0.4)

    // MARK: - Gradients
    public static let zenBackground = RadialGradient(
        gradient: Gradient(colors: [
            Color(hex: "064E3B"),  // Center: Deep Forest
            Color(hex: "022C22"),  // Outer: Deepest Green
        ]),
        center: .center,
        startRadius: 0,
        endRadius: 1000
    )

    public static let neonGlow = LinearGradient(
        gradient: Gradient(colors: [Self.primary, Self.accent]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
