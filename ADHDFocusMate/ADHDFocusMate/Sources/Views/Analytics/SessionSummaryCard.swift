import SwiftUI

struct SessionSummaryCard: View {
    let score: Double
    let duration: TimeInterval
    let streak: Int

    var body: some View {
        GlassCard {
            HStack(spacing: 20) {
                // Score Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: score)
                        .stroke(
                            scoreColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 60, height: 60)

                    Text("\(Int(score * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Session Focus")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    HStack {
                        Label {
                            Text(formatDuration(duration))
                        } icon: {
                            Image(systemName: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)

                        if streak > 0 {
                            Label {
                                Text("\(streak) check streak")
                            } icon: {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
        }
    }

    private var scoreColor: Color {
        if score >= 0.8 { return .green }
        if score >= 0.5 { return .yellow }
        return .red
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        return "\(minutes)m"
    }
}
