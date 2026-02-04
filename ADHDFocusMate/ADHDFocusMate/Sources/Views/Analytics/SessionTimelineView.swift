import SwiftUI

struct SessionTimelineView: View {
    let session: FocusSession
    @State private var blocks: [TimelineBlock] = []
    @State private var visibleBlockIds: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            if blocks.isEmpty {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Analyzing session flow...")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                        TimelineBlockRow(
                            block: block,
                            isLast: index == blocks.count - 1
                        )
                        .opacity(visibleBlockIds.contains(block.id) ? 1 : 0)
                        .offset(y: visibleBlockIds.contains(block.id) ? 0 : 20)
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .onAppear {
            loadTimeline()
        }
    }

    private func loadTimeline() {
        let coal = TimelineBlock.coalesce(checks: session.checks)
        withAnimation(.smooth) {
            self.blocks = coal
        }
        animateBlocksSequentially()
    }

    private func animateBlocksSequentially() {
        for (index, block) in blocks.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    _ = visibleBlockIds.insert(block.id)
                }
            }
        }
    }
}

struct TimelineBlockRow: View {
    let block: TimelineBlock
    let isLast: Bool

    @State private var rowHeight: CGFloat = 0

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Time Column
            VStack(alignment: .trailing, spacing: 4) {
                Text(block.startTime, style: .time)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)

                Text(formatDuration(block.duration))
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.8))
            }
            .frame(width: 80)

            // Indicator Column
            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [indicatorColor, .gray.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                        .frame(height: rowHeight > 0 ? rowHeight + 24 : 0)  // Stretch slightly past for gap coverage if needed, but rowHeight should be enough
                        .offset(y: 6)  // Start from center of circle (r=6)
                }

                Circle()
                    .fill(indicatorColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .frame(width: 12)

            // Content Column
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(titleText)
                        .font(.headline)
                        .foregroundColor(.white)

                    if let cat = block.category {
                        Text(cat)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(indicatorColor.opacity(0.2))
                            .foregroundColor(indicatorColor)
                            .cornerRadius(4)
                    }
                }

                if let reason = block.reason {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.bottom, 24)  // Added spacing between blocks
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { rowHeight = geo.size.height }
                        .onChange(of: geo.size.height) { h in rowHeight = h }
                }
            )

            Spacer()
        }
    }

    private var indicatorColor: Color {
        switch block.type {
        case .work: return .green
        case .distraction: return .red
        case .gap: return .gray.opacity(0.5)
        }
    }

    private var titleText: String {
        switch block.type {
        case .work: return "Deep Work"
        case .distraction: return "Distraction"
        case .gap: return "Inactive"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        if mins == 0 { return "<1m" }
        return "\(mins)m"
    }
}
