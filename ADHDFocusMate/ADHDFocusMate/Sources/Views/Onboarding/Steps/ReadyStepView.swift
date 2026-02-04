import SwiftUI

struct ReadyStepView: View {
    @EnvironmentObject var state: OnboardingState
    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 120, height: 120)

                if showCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                    showCheckmark = true
                }
            }

            VStack(spacing: 16) {
                Text("You're all set!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                Text("Your customized focus sanctuary is ready.")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }

            Button(action: {
                state.completeOnboarding()
            }) {
                Text("Start Focus Session")
                    .font(.headline)
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 260)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
        }
    }
}
