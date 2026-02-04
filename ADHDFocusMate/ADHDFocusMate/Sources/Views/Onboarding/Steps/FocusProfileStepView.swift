import SwiftData
import SwiftUI

struct FocusProfileStepView: View {
    @Query private var settings: [AppSettings]
    @Environment(\.modelContext) private var modelContext

    @State private var focusActivities: [String] = []  // e.g., Coding, Writing
    @State private var distractions: [String] = []  // e.g., YouTube, Social Media

    // Pre-defined options
    let suggestedFocus = ["Coding", "Writing", "Design", "Research", "Admin", "Learning"]
    let suggestedDistractions = [
        "Social Media", "YouTube", "Gaming", "News", "Messaging", "Shopping",
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("Calibrate Your Mate")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Help me understand what you do, so I can know when you're drifting.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 40)

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 24) {
                        // Focus Zone Section
                        TagCloudView(
                            title: "My Focus Zone",
                            icon: "target",
                            tags: suggestedFocus,
                            selectedTags: $focusActivities,
                            allowCustom: true,
                            color: .teal
                        )

                        // Weaknesses Section
                        TagCloudView(
                            title: "My Weaknesses",
                            icon: "exclamationmark.triangle",
                            tags: suggestedDistractions,
                            selectedTags: $distractions,
                            allowCustom: true,
                            color: .orange  // Use orange/pink for distractions
                        )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            if let appSettings = settings.first {
                focusActivities = appSettings.focusActivities
                distractions = appSettings.distractionKeywords
            }
        }
        .onDisappear {
            saveSettings()
        }
    }

    private func saveSettings() {
        if let appSettings = settings.first {
            appSettings.focusActivities = focusActivities
            appSettings.distractionKeywords = distractions
            // SwiftData auto-saves context changes usually, but good to be explicit if needed in larger flows
        } else {
            // Should exist from init but safety check
            let newSettings = AppSettings(
                focusActivities: focusActivities,
                distractionKeywords: distractions
            )
            modelContext.insert(newSettings)
        }
    }
}
