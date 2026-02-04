import SwiftUI

struct LogView: View {
    @ObservedObject var logService = LogService.shared
    @State private var selectedEntry: LogEntry?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Label("Activity Log", systemImage: "list.bullet.rectangle.portrait")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button(action: { logService.clear() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal)
            .padding(.top)

            if logService.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.neonGlow)
                        .opacity(0.5)
                    Text("No activities recorded yet.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zenGlass(cornerRadius: 32)
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(logService.entries) { entry in
                            LogEntryRow(entry: entry)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedEntry = entry
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)

                            if entry.id != logService.entries.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.05))
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .zenGlass(cornerRadius: 32)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .frame(minWidth: 500, minHeight: 450)
        .background(Color.clear)
        .sheet(item: $selectedEntry) { entry in
            LogDetailView(entry: entry)
        }
    }
}

struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Status Icon with Glow
            ZStack {
                Circle()
                    .fill(colorForLevel(entry.level).opacity(0.2))
                    .frame(width: 24, height: 24)

                Image(systemName: iconForLevel(entry.level))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(colorForLevel(entry.level))
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.source.rawValue.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colorForLevel(entry.level).opacity(0.1))
                        .foregroundColor(colorForLevel(entry.level))
                        .cornerRadius(4)

                    Spacer()

                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(AppTheme.textTertiary)
                }

                Text(entry.message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                if let details = entry.details, !details.isEmpty {
                    Text(details)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                        .opacity(0.6)
                }
            }
        }
    }

    private func colorForLevel(_ level: LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .debug: return .gray
        }
    }

    private func iconForLevel(_ level: LogLevel) -> String {
        switch level {
        case .info: return "info"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark"
        case .debug: return "ladybug"
        }
    }
}

struct LogDetailView: View {
    let entry: LogEntry
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AppTheme.zenBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Log Details")
                            .font(.title3.bold())
                            .foregroundColor(AppTheme.textPrimary)
                        Text(entry.timestamp.formatted(date: .long, time: .standard))
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Metadata Card
                        VStack(spacing: 12) {
                            LogDetailRow(
                                label: "Source", value: entry.source.rawValue, color: .primary)
                            Divider().background(Color.white.opacity(0.1))
                            LogDetailRow(
                                label: "Level", value: entry.level.rawValue, color: .primary)
                        }
                        .padding()
                        .zenGlass(cornerRadius: 16)

                        // Message Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MESSAGE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.textTertiary)

                            Text(entry.message)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                                .textSelection(.enabled)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .zenGlass(cornerRadius: 16)

                        // Details / Payload Card
                        if let details = entry.details {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("TECHNICAL DETAILS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textTertiary)

                                ScrollView(.horizontal, showsIndicators: true) {
                                    Text(details)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .padding(12)
                                        .textSelection(.enabled)
                                }
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(12)
                            }
                            .padding()
                            .zenGlass(cornerRadius: 16)
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 550, height: 500)
    }
}

struct LogDetailRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}
