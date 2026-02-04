import SwiftData
import SwiftUI
import UserNotifications

struct PreferencesStepView: View {
    @Query private var settings: [AppSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var isPermissionGranted = false
    @State private var showSkippedAlert = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Let me nudge you")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 24) {
                GlassCard {
                    VStack(spacing: 24) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)

                        Text(
                            "To help you stay on track, I need permission to send gentle notifications."
                        )
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)

                        Text("Without this, I can't let you know when you've drifted off.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)

                        if let appSettings = settings.first {
                            IntervalSlider(
                                intervalSeconds: Binding(
                                    get: { appSettings.intervalSeconds },
                                    set: { appSettings.intervalSeconds = $0 }
                                )
                            )
                            .padding(.top, 8)
                        }

                        if isPermissionGranted {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Permission Granted")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        } else {
                            NeonButton(title: "Enable Notifications", width: 220) {
                                requestPermission()
                            }
                            .padding(.top, 16)

                            Button("Maybe later") {
                                // Just proceeding without permission for now
                                // In a real flow this might trigger a 'Are you sure?' alert or just do nothing visually (the user can click Continue in parent)
                                showSkippedAlert = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(32)
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            checkPermissionStatus()
        }
        .alert("Are you sure?", isPresented: $showSkippedAlert) {
            Button("Enable", role: .none) {
                requestPermission()
            }
            Button("Skip", role: .cancel) {}
        } message: {
            Text("Nudges are the core feature of this app. Without them, it's just a timer.")
        }
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            DispatchQueue.main.async {
                self.isPermissionGranted = granted

                // Update settings if needed (though this is system level)
                if let appSettings = settings.first {
                    appSettings.slackNudgesEnabled = granted
                }
            }
        }
    }

    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isPermissionGranted = (settings.authorizationStatus == .authorized)
            }
        }
    }
}
