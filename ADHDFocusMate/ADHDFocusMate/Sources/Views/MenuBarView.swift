import SwiftUI

struct MenuBarView: View {
    @ObservedObject var sessionManager: FocusSessionManager
    @Environment(\.openWindow) var openWindow
    @State private var goalText: String = ""
    @State private var isBreathing = false

    var body: some View {
        VStack(spacing: 20) {
            // Header / Status
            HStack {
                Text(statusText.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(2)
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                if sessionManager.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(AppTheme.neonGlow)
                        Text("\(sessionManager.currentStreak)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
            .padding(.horizontal, 4)

            // Timer Display & Input
            ZStack {
                // Background Glow
                Circle()
                    .fill(AppTheme.neonGlow.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .blur(radius: isBreathing ? 20 : 10)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isBreathing)

                // Ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 140, height: 140)

                // Progress Ring
                if sessionManager.state == .active || sessionManager.state == .paused {
                    Circle()
                        .trim(from: 0, to: CGFloat(min(sessionManager.elapsedTime / 3600, 1.0)))  // Visual progress
                        .stroke(
                            AppTheme.neonGlow, style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                }

                VStack(spacing: 8) {
                    if sessionManager.state == .active || sessionManager.state == .paused {
                        Text(formattedTime(sessionManager.elapsedTime))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())

                        if let goal = sessionManager.currentSession?.goalText, !goal.isEmpty {
                            Text(goal)
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(1)
                                .frame(maxWidth: 120)
                        }
                    } else {
                        // Input state
                        TextField("Focus Task", text: $goalText)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                            .padding(.vertical, 4)
                            .background(
                                VStack {
                                    Spacer()
                                    Rectangle().frame(height: 1).foregroundColor(
                                        AppTheme.primary.opacity(0.3))
                                }
                            )
                            .frame(maxWidth: 100)
                    }
                }
            }
            .padding(.vertical, 10)
            .onAppear { isBreathing = true }

            // Controls
            HStack(spacing: 16) {
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

            Divider()
                .overlay(AppTheme.primary.opacity(0.2))

            // Footer
            HStack {
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: {
                        $0.isVisible == false || $0.canBecomeMain
                    }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                    openWindow(id: "main")
                }) {
                    Text("Open App")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    AppDelegate.allowTermination = true
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 300)
        .background(AppTheme.backgroundDeep)
        .overlay {
            if sessionManager.showingPermissionAlert {
                ZStack {
                    Color.black.opacity(0.8)

                    VStack(spacing: 16) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.yellow)

                        Text("Permission Required")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Screen recording permission is needed to detect distractions.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            Button("Cancel") {
                                sessionManager.showingPermissionAlert = false
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.white.opacity(0.7))

                            Button("Settings") {
                                NSWorkspace.shared.open(
                                    URL(
                                        string:
                                            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
                                    )!)
                                sessionManager.showingPermissionAlert = false
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(AppTheme.primary)
                            .fontWeight(.bold)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.backgroundDeep)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(radius: 20)
                    )
                    .padding(20)
                }
                .transition(.opacity)
                .zIndex(100)
            }

            if sessionManager.showingApiKeyAlert {
                ZStack {
                    Color.black.opacity(0.8)

                    VStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.yellow)

                        Text("API Key Required")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(
                            "Please configure your Gemini API Key in Settings to start using the AI features."
                        )
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal)

                        HStack(spacing: 12) {
                            Button("Cancel") {
                                sessionManager.showingApiKeyAlert = false
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.white.opacity(0.7))

                            Button("Open Settings") {
                                NSApp.sendAction(
                                    #selector(AppDelegate.openSettings), to: nil, from: nil)
                                sessionManager.showingApiKeyAlert = false
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(AppTheme.primary)
                            .fontWeight(.bold)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.backgroundDeep)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(radius: 20)
                    )
                    .padding(20)
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }

    // MARK: - Helpers

    private var statusText: String {
        switch sessionManager.state {
        case .active: return "Focusing"
        case .paused: return "Paused"
        case .completed: return "Ready"
        }
    }

    private func formattedTime(_ totalSeconds: TimeInterval) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let seconds = Int(totalSeconds) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    MenuBarView(sessionManager: FocusSessionManager(dataController: DataController(inMemory: true)))
}
