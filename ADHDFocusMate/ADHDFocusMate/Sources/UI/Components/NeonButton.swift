import SwiftUI

public struct NeonButton: View {
    let title: String
    let icon: String?
    let width: CGFloat?
    let action: () -> Void

    public init(
        title: String, icon: String? = nil, width: CGFloat? = nil, action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.width = width
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(AppTheme.primaryDark)
            .frame(width: width)  // Apply width if specified
            .padding(.horizontal, width == nil ? 32 : 0)  // Only add horizontal padding if width is not fixed
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(AppTheme.neonGlow)
                    .shadow(color: AppTheme.primary.opacity(0.5), radius: 10, x: 0, y: 0)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// For cases where we want a circular icon neon button
public struct NeonIconButton: View {
    let icon: String
    let isDestructive: Bool
    let action: () -> Void

    public init(icon: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(isDestructive ? .white : AppTheme.primaryDark)
                .padding(16)
                .background(
                    Circle()
                        .fill(
                            isDestructive
                                ? AnyShapeStyle(Color.red.opacity(0.8))
                                : AnyShapeStyle(AppTheme.neonGlow)
                        )
                        .shadow(
                            color: (isDestructive ? Color.red : AppTheme.primary).opacity(0.5),
                            radius: 10, x: 0, y: 0)
                )

                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
