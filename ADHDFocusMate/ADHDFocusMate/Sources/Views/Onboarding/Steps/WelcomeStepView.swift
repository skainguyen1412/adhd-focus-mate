import SwiftUI

struct WelcomeStepView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 40) {
            // Premium Breathing Brand Icon
            ZStack {
                // Outer Aura Pulse
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating ? 1.4 : 1.0)
                    .opacity(isAnimating ? 0 : 0.5)

                // Inner Soft Glow
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)

                // Floating Main Icon
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.3), radius: isAnimating ? 20 : 10)
                    .offset(y: isAnimating ? -10 : 10)
            }
            .animation(
                .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }

            VStack(spacing: 16) {
                Text("ADHD Focus Mate")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                Text(
                    "Your intelligent body-double.\nI monitor your screen to keep you in the zone, gently nudging you back when your ADHD brain drifts off."
                )
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 40)
                .lineSpacing(4)  // Better readability
            }
        }
    }
}
