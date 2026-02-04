import Charts
import SwiftData
import SwiftUI

@available(macOS 13.0, *)
struct AnalyticsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var sessionManager: FocusSessionManager

    // We can use a query to get recent sessions
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]

    // Local state for analysis
    @State private var weeklyScore: Double = 0.0
    @State private var peakHours: [Int: Double] = [:]
    @State private var topDistractions: [(String, Int)] = []

    // Service
    private let analyticsService = AnalyticsService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Analytics")
                        .font(.largeTitle)
                        .fontWeight(.light)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)

                // Current/Last Session Card
                if let current = sessionManager.currentSession {
                    VStack(alignment: .leading) {
                        Text("Current Session")
                            .font(.headline)
                            .foregroundColor(AppTheme.textSecondary)

                        let stats =
                            sessionManager.state == .active
                            ? (score: computeScore(current), duration: sessionManager.elapsedTime)
                            : (score: 0.0, duration: 0)

                        SessionSummaryCard(
                            score: stats.score,
                            duration: stats.duration,
                            streak: sessionManager.currentStreak
                        )
                    }
                    .padding(.horizontal)
                } else if let last = sessions.first {
                    VStack(alignment: .leading) {
                        Text("Last Session")
                            .font(.headline)
                            .foregroundColor(AppTheme.textSecondary)

                        // We need to calculate this, for now mock or simple calc
                        let score =
                            Double(last.checks.filter { $0.label == "work" }.count)
                            / Double(max(1, last.checks.count))
                        let duration =
                            last.endedAt?.timeIntervalSince(last.startedAt ?? Date()) ?? 0

                        SessionSummaryCard(
                            score: score,
                            duration: duration,
                            streak: 0  // We don't store streak in session yet, would need to calc
                        )

                    }
                    .padding(.horizontal)
                }

                // Analytics Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    // Weekly Score
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weekly Focus")
                                .font(.headline)
                                .foregroundColor(AppTheme.textSecondary)

                            HStack(alignment: .firstTextBaseline) {
                                Text("\(Int(weeklyScore * 100))%")
                                    .font(.system(size: 48, weight: .thin))
                                    .foregroundColor(.white)
                                Text("avg")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Peak Hour
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Peak Focus Time")
                                .font(.headline)
                                .foregroundColor(AppTheme.textSecondary)

                            if let peak = peakHours.max(by: { $0.value < $1.value }) {
                                Text(formatHour(peak.key))
                                    .font(.system(size: 36, weight: .thin))
                                    .foregroundColor(.white)
                                Text("\(Int(peak.value * 100))% efficiency")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("--:--")
                                    .font(.system(size: 36, weight: .thin))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal)

                // Distraction Breakdown
                VStack(alignment: .leading) {
                    Text("Top Distractions")
                        .font(.headline)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal)

                    GlassCard {
                        VStack(spacing: 16) {
                            if topDistractions.isEmpty {
                                Text("No distractions detected yet")
                                    .foregroundColor(AppTheme.textSecondary)
                                    .padding()
                            } else {
                                ForEach(topDistractions, id: \.0) { item in
                                    HStack {
                                        Text(item.0)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(item.1)x")
                                            .foregroundColor(AppTheme.textSecondary)

                                        // Simple bar
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.white.opacity(0.1))
                                                    .frame(height: 8)

                                                Capsule()
                                                    .fill(Color.red.opacity(0.6))
                                                    .frame(
                                                        width: geo.size.width
                                                            * (Double(item.1)
                                                                / Double(
                                                                    max(
                                                                        1,
                                                                        topDistractions.first?.1
                                                                            ?? 1))),
                                                        height: 8)
                                            }
                                        }
                                        .frame(width: 100, height: 8)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                    .padding(.horizontal)
                }

                // MARK: - Advanced Patterns
                VStack(alignment: .leading, spacing: 16) {
                    Text("Focus Patterns")
                        .font(.headline)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        // Recovery Time Card
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Bounce Back", systemImage: "arrow.uturn.forward")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)

                                Text(formatDuration(avgRecoveryTime))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Text("Avg recovery time")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Drop-off Card
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Danger Zone", systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)

                                Text(mostCommonDropOff)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Text("Most frequent drop-off")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                }

                // AI Insight Card
                if !insightText.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("Weekly Insight")
                                .font(.headline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.horizontal)

                        GlassCard {
                            Text(insightText)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.clear)
        .onAppear {
            loadAnalytics()
        }
        .onChange(of: sessions) { _ in
            loadAnalytics()
        }
    }

    // State for insight
    @State private var insightText: String = ""
    @State private var avgRecoveryTime: TimeInterval = 0
    @State private var mostCommonDropOff: String = "-"
    @Query private var settings: [AppSettings]

    private func computeScore(_ session: FocusSession) -> Double {
        guard !session.checks.isEmpty else { return 0.0 }
        let work = session.checks.filter { $0.label == "work" }.count
        return Double(work) / Double(session.checks.count)
    }

    private func formatHour(_ hour: Int) -> String {
        let date =
            Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }

    private func loadAnalytics() {
        Task {
            // Calculate Weekly Score
            // This logic ideally moves to actor, but for MVP doing it here or calling actor methods

            // Peak Hours
            let peaks = await analyticsService.analyzePeakHours(sessions: sessions)

            // Top Distractions
            let distractions = await analyticsService.getTopDistractions(sessions: sessions)

            // Pattern Analysis
            let recovery = await analyticsService.calculateAverageRecoveryTime(sessions: sessions)
            let dropOffs = await analyticsService.analyzeDropOffTimes(sessions: sessions)

            // Determine most common drop-off bucket
            var dropOffText = "-"
            if let maxDropOff = dropOffs.max(by: { $0.value < $1.value }) {
                dropOffText = "\(maxDropOff.key)-\(maxDropOff.key + 5)m"
            }

            // Weekly Score (simple average of all loaded sessions for now, ideally filter by week)
            let totalScore = sessions.reduce(0.0) { acc, session in
                acc
                    + (Double(session.checks.filter { $0.label == "work" }.count)
                        / Double(max(1, session.checks.count)))
            }
            let avg = sessions.isEmpty ? 0.0 : totalScore / Double(sessions.count)

            // Load Insight if API Key present
            var newInsight = ""
            if let apiKey = settings.first?.geminiApiKey, !apiKey.isEmpty, !sessions.isEmpty {
                // Simple caching strategy: check if we generated one today in UserDefaults?
                // For now, let's just generate on load (beware quotas!)
                // Better: Add a "Generate Insight" button.
                generateInsight()
            }

            await MainActor.run {
                self.peakHours = peaks
                self.topDistractions = distractions
                self.weeklyScore = avg
                self.avgRecoveryTime = recovery
                self.mostCommonDropOff = dropOffText
            }
        }
    }

    private func generateInsight() {
        guard let apiKey = settings.first?.geminiApiKey, !apiKey.isEmpty else { return }
        Task {
            do {
                let insight = try await analyticsService.generateWeeklyInsight(
                    apiKey: apiKey, sessions: sessions)
                await MainActor.run {
                    self.insightText = insight
                }
            } catch {
                print("Error generating insight: \(error)")
            }
        }
    }
}
