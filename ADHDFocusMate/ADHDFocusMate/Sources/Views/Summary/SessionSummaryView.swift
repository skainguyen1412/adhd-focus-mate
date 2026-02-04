import SwiftUI

struct SessionSummaryView: View {
    let session: FocusSession
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Session Summary")
                .font(.title)
                .fontWeight(.bold)
            
            // Key Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                StatBox(title: "Duration", value: durationString, icon: "clock")
                StatBox(title: "Checks", value: "\(session.checks.count)", icon: "camera")
                StatBox(title: "Work", value: "\(workPercentage)%", icon: "briefcase", color: .green)
                StatBox(title: "Slack", value: "\(slackPercentage)%", icon: "gamecontroller", color: .red)
            }
            
            Divider()
            
            // Streak
            if longestStreak > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Longest Streak")
                            .font(.headline)
                        Text("\(longestStreak) checks in a row")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Message
            Text(encouragementMessage)
                .font(.body)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(30)
        .frame(width: 400, height: 500)
    }
    
    // MARK: - Computed Props
    
    private var durationString: String {
        let end = session.endedAt ?? Date()
        let duration = end.timeIntervalSince(session.startedAt)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
    
    private var workCount: Int {
        session.checks.filter { $0.label == "work" }.count
    }
    
    private var slackCount: Int {
        session.checks.filter { $0.label == "slack" }.count
    }
    
    private var workPercentage: Int {
        guard !session.checks.isEmpty else { return 0 }
        return Int((Double(workCount) / Double(session.checks.count)) * 100)
    }
    
    private var slackPercentage: Int {
        guard !session.checks.isEmpty else { return 0 }
        return 100 - workPercentage
    }
    
    private var longestStreak: Int {
        // Calculate longest sequence of "work"
        var maxStreak = 0
        var current = 0
        
        let sortedChecks = session.checks.sorted { $0.capturedAt < $1.capturedAt }
        
        for check in sortedChecks {
            if check.label == "work" {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 0
            }
        }
        
        return maxStreak
    }
    
    private var encouragementMessage: String {
        if workPercentage >= 80 {
            return "Incredible focus! You were in the zone."
        } else if workPercentage >= 50 {
            return "Good job! You kept trying to focus."
        } else {
            return "Every session counts. Try a shorter interval next time?"
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

#Preview {
    let session = FocusSession(goalText: "Coding", state: .completed)
    session.endedAt = Date().addingTimeInterval(3600)
    // Add dummy checks...
    return SessionSummaryView(session: session)
}
