import SwiftUI

struct HowItWorksStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("How it works")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                // Top Row: 2 items
                HStack(spacing: 12) {
                    BentoCard(
                        icon: "timer",
                        title: "Calm Timer",
                        description: "Minimalist design to reduce visual noise."
                    )
                    BentoCard(
                        icon: "brain.head.profile",
                        title: "Context Aware",
                        description: "Intelligently distinguishes work vs. distraction."
                    )
                }

                // Middle Row: 2 items
                HStack(spacing: 12) {
                    BentoCard(
                        icon: "bell.badge",
                        title: "Gentle Nudge",
                        description: "Soft, shame-free reminders to guide you back."
                    )
                    BentoCard(
                        icon: "list.bullet.clipboard",
                        title: "Session Flow",
                        description: "See your session timeline without judgment."
                    )
                }

                // Bottom Row: 1 full-width item
                BentoCard(
                    icon: "chart.xyaxis.line",
                    title: "Deep Analysis Pattern",
                    description: "Unlock insights into your peak hours and Kryptonites over time.",
                    isFullWidth: true
                )
            }
            .padding(.horizontal, 40)
        }
    }
}

struct BentoCard: View {
    let icon: String
    let title: String
    let description: String
    var isFullWidth: Bool = false

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    if isFullWidth {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05))  // Subtle inner highlight
        }
        // Force equal height for non-full-width cards in the same row?
        // Simpler approach: fixed height or rely on text content being similar length.
        .frame(height: isFullWidth ? 70 : 80)
    }
}
