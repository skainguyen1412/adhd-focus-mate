import SwiftUI

struct IntervalSlider: View {
    @Binding var intervalSeconds: Int

    private let steps = [60, 180, 300]

    private var sliderValue: Binding<Double> {
        Binding(
            get: {
                Double(steps.firstIndex(of: intervalSeconds) ?? 1)
            },
            set: { newValue in
                let index = Int(newValue.rounded())
                if index >= 0 && index < steps.count {
                    intervalSeconds = steps[index]
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Check-in Interval")
                    .foregroundColor(AppTheme.textPrimary)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(currentLabel)
                    .foregroundColor(AppTheme.primary)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.primary.opacity(0.1))
                    .cornerRadius(4)
            }

            Slider(value: sliderValue, in: 0...Double(steps.count - 1), step: 1)
                .accentColor(AppTheme.primary)

            HStack {
                Text("Super ADHD")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text("ADHD")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text("Focus")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, 4)
        }
    }

    private var currentLabel: String {
        switch intervalSeconds {
        case 60: return "1 min"
        case 180: return "3 mins"
        case 300: return "5 mins"
        default: return "\(intervalSeconds / 60) mins"
        }
    }
}

#Preview {
    ZStack {
        AppTheme.zenBackground
        VStack {
            IntervalSlider(intervalSeconds: .constant(180))
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding()
        }
    }
}
