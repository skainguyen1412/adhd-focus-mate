import SwiftData
import SwiftUI

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let session: FocusSession

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Session Info").font(.headline).foregroundColor(
                                AppTheme.textPrimary)

                            Divider().background(Color.white.opacity(0.1))

                            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                                GridRow {
                                    Text("Started").foregroundColor(AppTheme.textSecondary)
                                    Text(session.startedAt.formatted(date: .long, time: .standard))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                if let ended = session.endedAt {
                                    GridRow {
                                        Text("Ended").foregroundColor(AppTheme.textSecondary)
                                        Text(ended.formatted(date: .long, time: .standard))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    GridRow {
                                        Text("Duration").foregroundColor(AppTheme.textSecondary)
                                        Text(durationString).foregroundColor(AppTheme.textPrimary)
                                    }
                                }
                                GridRow {
                                    Text("Status").foregroundColor(AppTheme.textSecondary)
                                    Text(session.state.rawValue.capitalized).foregroundColor(
                                        AppTheme.textPrimary)
                                }
                                if let goal = session.goalText {
                                    GridRow {
                                        Text("Goal").foregroundColor(AppTheme.textSecondary)
                                        Text(goal).foregroundColor(AppTheme.textPrimary)
                                    }
                                }
                            }
                        }
                        .padding()
                    }

                    // MARK: - Session Flow
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Session Flow")
                            .font(.headline)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal)

                        SessionTimelineView(session: session)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .padding(.top, 40)  // Make room for back button
            }

            // Custom Back Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.leading, 20)
            .padding(.top, 20)
        }
        .navigationTitle("Session Details")
        .navigationBarBackButtonHidden(true)
        .background(Color.clear)  // Sub-navigation will need background handling if pushed
    }

    private var durationString: String {
        let end = session.endedAt ?? Date()
        let duration = end.timeIntervalSince(session.startedAt)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

#Preview {
    let session = FocusSession(goalText: "Coding", state: .completed)
    let check1 = FocusCheck(label: "work", confidence: 0.95, reason: "Writing Swift code in Xcode")
    let check2 = FocusCheck(
        label: "slack", confidence: 0.8, reason: "Browsing Reddit", slackPromptedAt: Date())
    session.checks = [check1, check2]

    return NavigationStack {
        SessionDetailView(session: session)
    }
}
