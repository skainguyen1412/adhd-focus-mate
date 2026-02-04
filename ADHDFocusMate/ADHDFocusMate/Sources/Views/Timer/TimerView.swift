import SwiftUI

struct TimerView: View {
    @EnvironmentObject var sessionManager: FocusSessionManager
    @State private var goalText: String = ""

    // Animation state
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            // Content
            VStack(spacing: 40) {

                // MARK: - Header / Status
                // MARK: - Header / Status
                Text(statusText.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(4)
                    .foregroundColor(AppTheme.textSecondary)
                    .opacity(0.8)

                // MARK: - Main Timer Card
                GlassCard {
                    VStack(spacing: 40) {
                        // MARK: - Timer Ring
                        ZStack {
                            // Background Ring (Subtle)
                            Circle()
                                .stroke(Color.white.opacity(0.05), lineWidth: 8)
                                .frame(width: 320, height: 320)

                            // Active Ring (Neon Glow)
                            Circle()
                                .trim(
                                    from: 0,
                                    to: CGFloat(min(sessionManager.elapsedTime / 3600, 1.0))
                                )  // Just for visual, we use a different progress metric if needed
                                .stroke(
                                    AppTheme.neonGlow,
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 320, height: 320)
                                .rotationEffect(.degrees(-90))
                                .shadow(
                                    color: AppTheme.primary.opacity(0.5), radius: 10, x: 0, y: 0
                                )
                                .blur(radius: isBreathing ? 1 : 0)
                                .animation(
                                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                                    value: isBreathing)

                            // Time Text
                            Text(formattedTime(sessionManager.elapsedTime))
                                .font(.system(size: 70, weight: .thin, design: .default))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                                .minimumScaleFactor(0.5)
                        }
                        .onAppear { isBreathing = true }

                        // Goal Input
                        VStack(spacing: 12) {
                            if sessionManager.state == .active || sessionManager.state == .paused {
                                if let goal = sessionManager.currentSession?.goalText, !goal.isEmpty
                                {
                                    Text(goal)
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text("Focus Session")
                                        .font(.title3)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            } else {
                                TextField("What are you working on?", text: $goalText)
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(.plain)
                                    .padding(.vertical, 8)
                                    .background(
                                        VStack {
                                            Spacer()
                                            Rectangle()
                                                .frame(height: 1)
                                                .foregroundColor(AppTheme.primary.opacity(0.2))
                                        }
                                    )
                                    .frame(maxWidth: 300)
                            }
                        }
                    }
                    .padding(60)
                }

                // MARK: - Controls
                HStack(spacing: 32) {
                    if sessionManager.state == .active {
                        NeonIconButton(icon: "pause.fill") {
                            sessionManager.pauseSession()
                        }

                        NeonIconButton(icon: "stop.fill", isDestructive: true) {
                            sessionManager.stopSession()
                        }

                    } else if sessionManager.state == .paused {
                        NeonIconButton(icon: "play.fill") {
                            sessionManager.startSession()
                        }

                        NeonIconButton(icon: "stop.fill", isDestructive: true) {
                            sessionManager.stopSession()
                        }

                    } else {
                        NeonButton(title: "Start Focus", icon: "play.fill") {
                            sessionManager.startSession(goal: goalText)
                        }
                    }
                }

                // MARK: - Streak
                if sessionManager.currentStreak > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(AppTheme.neonGlow)
                        Text("\(sessionManager.currentStreak) clean checks")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .zenGlass(cornerRadius: 100, opacity: 0.1)
                }

                Spacer()
            }
            .padding(40)
        }
        .alert("Permission Required", isPresented: $sessionManager.showingPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "ADHD Timer AI needs screen recording permission to detect distractions. Please enable it in Settings."
            )
        }
        .alert("API Key Required", isPresented: $sessionManager.showingApiKeyAlert) {
            Button("Open Settings") {
                NSApp.sendAction(#selector(AppDelegate.openSettings), to: nil, from: nil)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please configure your Gemini API Key in Settings to start using the AI features.")
        }
    }

    private var statusText: String {
        switch sessionManager.state {
        case .active: return "Focusing"
        case .paused: return "Session Paused"
        case .completed: return "Ready to Focus"
        }
    }

    private func formattedTime(_ totalSeconds: TimeInterval) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
