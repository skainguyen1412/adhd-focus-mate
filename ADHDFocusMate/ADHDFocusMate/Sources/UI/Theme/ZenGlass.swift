import SwiftUI

struct ZenGlass: ViewModifier {
    var cornerRadius: CGFloat = 24
    var opacity: Double = 0.05

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(opacity))
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .white.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func zenGlass(cornerRadius: CGFloat = 24, opacity: Double = 0.05) -> some View {
        self.modifier(ZenGlass(cornerRadius: cornerRadius, opacity: opacity))
    }
}
