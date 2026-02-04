import SwiftUI

struct PermissionStepView: View {
    @EnvironmentObject var state: OnboardingState

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                Text("Screen Permissions")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text(
                    "To know when you're distracted, we need permission to capture your screen occasionally."
                )
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 40)

                Text(
                    "**Privacy Note**: Screenshots are analyzed in-memory and never saved to disk or sent to our servers. Only the classification result (e.g. 'work') is stored."
                )
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 10)
                .padding(.horizontal, 60)
            }

            GlassCard {
                VStack(spacing: 20) {
                    HStack {
                        Image(
                            systemName: state.hasScreenRecordingPermission
                                ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .foregroundColor(state.hasScreenRecordingPermission ? .green : .orange)

                        Text(
                            state.hasScreenRecordingPermission
                                ? "Permission Granted" : "Permission Required"
                        )
                        .font(.headline)
                        .foregroundColor(.white)
                    }

                    if !state.hasScreenRecordingPermission {
                        Button(action: {
                            state.requestPermissions()
                        }) {
                            Text("Grant Access")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Text("After granting, you may need to restart the app.")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding()
            }
            .padding(.horizontal, 40)
        }
    }
}
