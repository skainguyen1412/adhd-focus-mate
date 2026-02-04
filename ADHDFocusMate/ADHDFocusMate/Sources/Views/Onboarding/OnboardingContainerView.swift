import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var onboardingState = OnboardingState()

    private var isContinueDisabled: Bool {
        // Disable continue on Permission step (index 2) if permission not granted
        onboardingState.currentStep == 2 && !onboardingState.hasScreenRecordingPermission
    }

    var body: some View {
        ZStack {
            // Background
            AppTheme.zenBackground
                .ignoresSafeArea()

            VStack {
                // Header Area
                HStack {
                    if onboardingState.currentStep > 0
                        && onboardingState.currentStep < onboardingState.totalSteps - 1
                    {
                        Button(action: onboardingState.previousStep) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(.white.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    if onboardingState.currentStep < onboardingState.totalSteps - 1 {
                        Button("Skip") {
                            onboardingState.completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)

                Spacer()

                // Step Content
                ZStack {
                    switch onboardingState.currentStep {
                    case 0: WelcomeStepView()
                    case 1: HowItWorksStepView()
                    case 2: PermissionStepView()
                    case 3: APIKeyStepView()
                    case 4: FocusProfileStepView()
                    case 5: PreferencesStepView()
                    case 6: ReadyStepView()
                    default: EmptyView()
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
                .id(onboardingState.currentStep)

                Spacer()

                // Navigation / Progress
                VStack(spacing: 30) {
                    // Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingState.totalSteps, id: \.self) { index in
                            Circle()
                                .fill(
                                    .white.opacity(onboardingState.currentStep == index ? 0.9 : 0.2)
                                )
                                .frame(width: 8, height: 8)
                                .animation(.spring(), value: onboardingState.currentStep)
                        }
                    }

                    if onboardingState.currentStep < onboardingState.totalSteps - 1 {
                        NeonButton(title: "Continue", width: 240) {
                            onboardingState.nextStep()
                        }
                        .opacity(isContinueDisabled ? 0.5 : 1.0)
                        .disabled(isContinueDisabled)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .environmentObject(onboardingState)
    }
}

#Preview {
    OnboardingContainerView()
}
