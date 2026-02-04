import SwiftUI

// MARK: - Reusable Tag Cloud Component
public struct TagCloudView: View {
    public let title: String
    public let icon: String
    public let tags: [String]
    @Binding public var selectedTags: [String]
    public var allowCustom: Bool = false
    public var color: Color = .blue

    @State private var showCustomInput = false
    @State private var newTagText = ""

    public init(
        title: String,
        icon: String,
        tags: [String],
        selectedTags: Binding<[String]>,
        allowCustom: Bool = false,
        color: Color = .blue
    ) {
        self.title = title
        self.icon = icon
        self.tags = tags
        self._selectedTags = selectedTags
        self.allowCustom = allowCustom
        self.color = color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            // Flow Layout for tags
            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagCapsule(
                        text: tag,
                        isSelected: selectedTags.contains(tag),
                        color: color
                    ) {
                        toggleTag(tag)
                    }
                }

                // Custom Tags
                ForEach(selectedTags.filter { !tags.contains($0) }, id: \.self) { tag in
                    TagCapsule(
                        text: tag,
                        isSelected: true,
                        color: color
                    ) {
                        toggleTag(tag)
                    }
                }

                if allowCustom {
                    Button(action: { showCustomInput.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showCustomInput) {
                        VStack(spacing: 12) {
                            TextField("New Tag", text: $newTagText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)

                            Button("Add") {
                                if !newTagText.isEmpty {
                                    if !selectedTags.contains(newTagText) {
                                        selectedTags.append(newTagText)
                                    }
                                    newTagText = ""
                                    showCustomInput = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func toggleTag(_ tag: String) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

public struct TagCapsule: View {
    public let text: String
    public let isSelected: Bool
    public let color: Color
    public let action: () -> Void

    public init(text: String, isSelected: Bool, color: Color, action: @escaping () -> Void) {
        self.text = text
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? color.opacity(0.3) : Color.white.opacity(0.05)
                )
                .foregroundColor(
                    isSelected ? .white : .white.opacity(0.7)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? color.opacity(0.6) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
                .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// Simple FlowLayout Helper
public struct FlowLayout: Layout {
    public var spacing: CGFloat

    public init(spacing: CGFloat) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ())
        -> CGSize
    {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return rows.reduce(CGSize.zero) { size, row in
            CGSize(
                width: max(size.width, row.width),
                height: size.height + row.height + spacing
            )
        }
    }

    public func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for (item, size) in row.items {
                item.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    struct Row {
        var items: [(LayoutSubview, CGSize)]
        var width: CGFloat
        var height: CGFloat
    }

    func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow: [(LayoutSubview, CGSize)] = []
        var currentX: CGFloat = 0
        var currentHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && !currentRow.isEmpty {
                rows.append(
                    Row(items: currentRow, width: currentX - spacing, height: currentHeight))
                currentRow = []
                currentX = 0
                currentHeight = 0
            }

            currentRow.append((subview, size))
            currentX += size.width + spacing
            currentHeight = max(currentHeight, size.height)
        }

        if !currentRow.isEmpty {
            rows.append(Row(items: currentRow, width: currentX - spacing, height: currentHeight))
        }

        return rows
    }
}
