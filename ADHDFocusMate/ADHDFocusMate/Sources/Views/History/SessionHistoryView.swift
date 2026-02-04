import SwiftData
import SwiftUI

struct SessionHistoryView: View {
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if sessions.isEmpty {
                        GlassCard {
                            ContentUnavailableView(
                                "No Sessions Yet",
                                systemImage: "clock.arrow.circlepath",
                                description: Text("Start a focus session from the menu bar.")
                            )
                            .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding()
                    } else {
                        ForEach(sessions) { session in
                            NavigationLink(value: session) {
                                GlassCard {
                                    SessionRow(session: session)
                                        .padding(12)
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(session)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("History")
            .navigationDestination(for: FocusSession.self) { session in
                SessionDetailView(session: session)
            }
            .background(Color.clear)  // Let zenBackground show through
        }
    }
}

struct SessionRow: View {
    let session: FocusSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                statusBadge
            }

            if let goal = session.goalText, !goal.isEmpty {
                Text(goal)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Divider().background(Color.white.opacity(0.05))

            HStack {
                Label(durationString, systemImage: "hourglass")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                if session.checks.count > 0 {
                    Label("\(session.checks.count) checks", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    private var statusBadge: some View {
        Text(session.state.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.2))
                    .overlay(
                        Capsule().stroke(statusColor.opacity(0.4), lineWidth: 1)
                    )
            )
            .foregroundColor(statusColor)
    }

    private var statusColor: Color {
        switch session.state {
        case .active: return .green  // Keeping these for logic, but they will pop against dark
        case .paused: return .yellow
        case .completed: return .white  // Completed is neutral/good
        }
    }

    private var durationString: String {
        let end = session.endedAt ?? Date()
        let duration = end.timeIntervalSince(session.startedAt)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FocusSession.self, configurations: config)

    // Add sample data
    let session = FocusSession(goalText: "Sample Session", state: .completed)
    session.endedAt = Date().addingTimeInterval(3600)
    container.mainContext.insert(session)

    return SessionHistoryView()
        .modelContainer(container)
}
