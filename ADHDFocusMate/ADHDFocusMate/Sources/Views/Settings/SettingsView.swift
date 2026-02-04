import SwiftData
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var showingDeleteConfirmation = false
    @State private var isTestingConnection = false
    @State private var connectionError: String? = nil
    @State private var hasScreenRecordingPermission: Bool = false
    @State private var hasNotificationPermission: Bool = false
    @State private var selectedTab: Int = 0

    private func checkPermissions() {
        hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()

        Task {
            let status = await UNUserNotificationCenter.current().notificationSettings()
                .authorizationStatus
            await MainActor.run {
                hasNotificationPermission = (status == .authorized)
            }
        }
    }

    private func requestPermissions() {
        if !CGRequestScreenCaptureAccess() {
            // If CGRequestScreenCaptureAccess returns false, it means the system
            // couldn't automatically prompt for permission, or the user denied it.
            // In this case, we should direct them to System Settings.
            openSystemSettings()
        }
        // Give a short delay for the system to update permissions, then re-check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkPermissions()
        }
    }

    private func openSystemSettings() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        {
            NSWorkspace.shared.open(url)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - General Section
                    GlassCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Label("General", systemImage: "gearshape")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            Divider().background(Color.white.opacity(0.1))

                            if let appSettings = settings.first {
                                #if DEBUG
                                    SettingsToggle(
                                        title: "Test Mode (Capture every 10s)",
                                        isOn: Binding(
                                            get: { appSettings.intervalSeconds == 10 },
                                            set: { isEnabled in
                                                if isEnabled {
                                                    appSettings.intervalSeconds = 10
                                                } else {
                                                    appSettings.intervalSeconds = 60
                                                }
                                            }
                                        ))
                                #endif

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("API Provider").foregroundColor(AppTheme.textPrimary)
                                    Picker(
                                        "API Provider",
                                        selection: Binding(
                                            get: { appSettings.apiProvider },
                                            set: { appSettings.apiProvider = $0 }
                                        )
                                    ) {
                                        Text("Google AI Studio").tag("aiStudio")
                                        Text("Google Vertex AI").tag("vertexAI")
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                    .tint(AppTheme.textPrimary)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("AI Model").foregroundColor(AppTheme.textPrimary)
                                    Picker(
                                        "AI Model",
                                        selection: Binding(
                                            get: { appSettings.geminiModel },
                                            set: { appSettings.geminiModel = $0 }
                                        )
                                    ) {
                                        Text("Gemini 2.5 Flash Lite (Recommended)").tag(
                                            "gemini-2.5-flash-lite")
                                        Text("Gemini 2.5 Flash").tag(
                                            "gemini-2.5-flash")
                                        Text("Gemini 3.0 Flash Preview").tag(
                                            "gemini-3-flash-preview")
                                        Text("Gemini 3.0 Pro Preview").tag(
                                            "gemini-3-pro-preview")
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                    .tint(AppTheme.textPrimary)  // Attempt to style picker
                                }

                                IntervalSlider(
                                    intervalSeconds: Binding(
                                        get: { appSettings.intervalSeconds },
                                        set: { appSettings.intervalSeconds = $0 }
                                    )
                                )

                                Divider().background(Color.white.opacity(0.05))

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Gemini API Key").foregroundColor(AppTheme.textPrimary)
                                        Spacer()
                                        Link(
                                            destination: URL(
                                                string: "https://aistudio.google.com/app/apikey")!
                                        ) {
                                            HStack(spacing: 4) {
                                                Text("Get Key")
                                                Image(systemName: "arrow.up.right")
                                            }
                                            .font(.caption)
                                            .foregroundColor(AppTheme.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    SecureField(
                                        "Enter your API key",
                                        text: Binding(
                                            get: { appSettings.geminiApiKey ?? "" },
                                            set: {
                                                appSettings.geminiApiKey = $0
                                                appSettings.isKeyValidated = false
                                            }
                                        )
                                    )
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                    .foregroundColor(AppTheme.textPrimary)

                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Button(action: {
                                                testConnection(
                                                    apiKey: appSettings.geminiApiKey ?? "",
                                                    model: appSettings.geminiModel,
                                                    provider: appSettings.apiProvider,
                                                    settings: appSettings
                                                )
                                            }) {
                                                HStack {
                                                    if isTestingConnection {
                                                        ProgressView()
                                                            .scaleEffect(0.5)
                                                            .frame(width: 16, height: 16)
                                                    } else {
                                                        Image(systemName: "network")
                                                    }
                                                    Text("Test Connection")
                                                }
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(6)
                                            }
                                            .buttonStyle(.plain)
                                            .disabled(
                                                isTestingConnection
                                                    || (appSettings.geminiApiKey ?? "").isEmpty)

                                            Spacer()
                                        }

                                        if appSettings.isKeyValidated {
                                            HStack(spacing: 6) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                Text("Connected")
                                                    .font(.caption)
                                                    .foregroundColor(.green)
                                            }
                                        } else if let error = connectionError {
                                            HStack(alignment: .top, spacing: 6) {
                                                Image(systemName: "exclamationmark.circle.fill")
                                                    .foregroundColor(.red)
                                                Text(error)
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            }
                                        } else if !(appSettings.geminiApiKey?.isEmpty ?? true) {
                                            Text("Not verified")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }

                                Divider().background(Color.white.opacity(0.1))

                                // Screen Recording Permission
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Screen Recording").foregroundColor(
                                            AppTheme.textPrimary)
                                        Text(
                                            hasScreenRecordingPermission
                                                ? "Permission Granted" : "Permission Required"
                                        )
                                        .font(.caption)
                                        .foregroundColor(
                                            hasScreenRecordingPermission ? AppTheme.primary : .red)
                                    }

                                    Spacer()

                                    if !hasScreenRecordingPermission {
                                        Button("Grant Access") {
                                            requestPermissions()
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(6)
                                        .buttonStyle(.plain)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppTheme.primary)
                                    }
                                }

                                Divider().background(Color.white.opacity(0.05))

                                // Notification Permission
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Notifications").foregroundColor(AppTheme.textPrimary)
                                        Text(
                                            hasNotificationPermission
                                                ? "Permission Granted" : "Permission Required"
                                        )
                                        .font(.caption)
                                        .foregroundColor(
                                            hasNotificationPermission ? AppTheme.primary : .red)
                                    }

                                    Spacer()

                                    if !hasNotificationPermission {
                                        Button("Grant Access") {
                                            Task {
                                                let granted =
                                                    try? await UNUserNotificationCenter.current()
                                                    .requestAuthorization(options: [
                                                        .alert, .sound, .badge,
                                                    ])
                                                await MainActor.run {
                                                    hasNotificationPermission = granted ?? false
                                                    checkPermissions()
                                                }
                                            }
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(6)
                                        .buttonStyle(.plain)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppTheme.primary)
                                    }
                                }

                                Divider().background(Color.white.opacity(0.05))

                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        hasCompletedOnboarding = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "hand.wave")
                                        Text("Replay Onboarding")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .opacity(0.5)
                                    }
                                    .foregroundColor(AppTheme.textPrimary)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text("Loading settings...").foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .padding()
                    }

                    // MARK: - Focus Profile Section
                    if let appSettings = settings.first {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 20) {
                                Label("Focus Profile", systemImage: "person.text.rectangle")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)

                                Divider().background(Color.white.opacity(0.1))

                                TagCloudView(
                                    title: "Focus Zone",
                                    icon: "target",
                                    tags: [
                                        "Coding", "Writing", "Design", "Research", "Admin",
                                        "Learning",
                                    ],
                                    selectedTags: Binding(
                                        get: { appSettings.focusActivities },
                                        set: { appSettings.focusActivities = $0 }
                                    ),
                                    allowCustom: true,
                                    color: .teal
                                )

                                TagCloudView(
                                    title: "Weaknesses",
                                    icon: "exclamationmark.triangle",
                                    tags: [
                                        "Social Media", "YouTube", "Gaming", "News", "Messaging",
                                        "Shopping",
                                    ],
                                    selectedTags: Binding(
                                        get: { appSettings.distractionKeywords },
                                        set: { appSettings.distractionKeywords = $0 }
                                    ),
                                    allowCustom: true,
                                    color: .orange
                                )
                            }
                            .padding()
                        }
                    }

                    // MARK: - Privacy Section
                    GlassCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Label("Privacy", systemImage: "lock")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            Divider().background(Color.white.opacity(0.05))

                            Text(
                                "We only store classification results (e.g., 'work', 'slack'). Screenshots are analyzed in memory and discarded immediately."
                            )
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)

                            Button(action: { showingDeleteConfirmation = true }) {
                                Text("Delete All History")
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                    }

                    // MARK: - About Section
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("About", systemImage: "info.circle")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            Divider().background(Color.white.opacity(0.1))

                            HStack {
                                Text("ADHD Timer AI v1.0")
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Link(
                                    "View Source Code",
                                    destination: URL(
                                        string: "https://github.com/tuist/ADHDTimerAI")!
                                )
                                .foregroundColor(AppTheme.secondary)
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            .tag(0)

            LogView()
                .tabItem {
                    Label("Activity Log", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(1)
        }
        .onAppear {
            checkPermissions()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            checkPermissions()
        }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This will permanently delete all session history and logs. This action cannot be undone."
            )
        }
        .background(Color.clear)
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: FocusSession.self)
            try modelContext.delete(model: FocusCheck.self)
            // Keep AppSettings
        } catch {
            print("Failed to delete data: \(error)")
        }
    }

    private func testConnection(
        apiKey: String, model: String, provider: String = "aiStudio", settings: AppSettings
    ) {
        guard !apiKey.isEmpty else { return }

        isTestingConnection = true
        connectionError = nil

        Task {
            do {
                let service = GeminiService()
                let success = try await service.validateKey(
                    apiKey, model: model, apiProvider: provider)

                await MainActor.run {
                    isTestingConnection = false
                    if success {
                        settings.isKeyValidated = true
                        connectionError = nil
                    } else {
                        settings.isKeyValidated = false
                        connectionError = "Validation failed"
                    }
                }
            } catch {
                await MainActor.run {
                    isTestingConnection = false
                    settings.isKeyValidated = false
                    connectionError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: AppSettings.self, configurations: config)
    container.mainContext.insert(AppSettings())
    return SettingsView()
        .modelContainer(container)
}
