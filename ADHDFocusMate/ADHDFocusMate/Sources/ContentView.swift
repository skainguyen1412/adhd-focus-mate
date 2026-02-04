import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: FocusSessionManager
    @State private var selectedTab: Tab = .timer

    enum Tab {
        case timer, history, analytics, settings, debug
    }

    public init() {}

    public var body: some View {
        ZStack {
            // Main Window Background
            AppTheme.zenBackground
                .ignoresSafeArea()

            HStack(spacing: 0) {
                // MARK: - Sidebar
                VStack(spacing: 20) {
                    // Logo/App Icon
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.neonGlow)
                        .padding(.top, 40)
                        .padding(.bottom, 20)

                    SidebarButton(icon: "timer", label: "Timer", isSelected: selectedTab == .timer)
                    {
                        selectedTab = .timer
                    }
                    SidebarButton(
                        icon: "clock.arrow.circlepath", label: "History",
                        isSelected: selectedTab == .history
                    ) {
                        selectedTab = .history
                    }
                    SidebarButton(
                        icon: "gear", label: "Settings", isSelected: selectedTab == .settings
                    ) {
                        selectedTab = .settings
                    }

                    SidebarButton(
                        icon: "chart.bar.fill", label: "Analytics",
                        isSelected: selectedTab == .analytics
                    ) {
                        selectedTab = .analytics
                    }

                    Spacer()

                    SidebarButton(
                        icon: "ant.fill", label: "Debug", isSelected: selectedTab == .debug
                    ) {
                        selectedTab = .debug
                    }
                }
                .frame(width: 100)
                .background(
                    Color.black.opacity(0.2)
                )
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1),
                    alignment: .trailing
                )

                // MARK: - Main Content Area
                ZStack {
                    switch selectedTab {
                    case .timer:
                        TimerView()
                    case .history:
                        SessionHistoryView()
                    case .analytics:
                        if #available(macOS 13.0, *) {
                            AnalyticsDashboardView()
                        } else {
                            VStack {
                                Text("Analytics Dashboard")
                                    .font(.title)
                                Text("Requires macOS 13.0+")
                                    .foregroundColor(.secondary)
                            }
                        }
                    case .settings:
                        SettingsView()
                    case .debug:
                        DebugView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            selectedTab = .settings
        }
    }
}

// MARK: - Sidebar Components

struct SidebarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? AppTheme.primary : .white.opacity(0.5))
            .frame(width: 80, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3), value: isSelected)
    }
}

// Retain the old ContentView as DebugView for testing
struct DebugView: View {
    @State private var selectedImage: NSImage?
    @State private var classificationResult: ClassificationResult?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var contextText = ""

    // Injectable service (create new instance for debug)
    let classifier = ClassificationService()

    // Screenshot Loop (create new instance for debug)
    @StateObject private var captureLoop = ScreenshotCaptureLoop()

    // Notification Manager (create new instance for debug)
    @StateObject private var notificationManager = NotificationManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Debug & Diagnostics")
                    .font(.title)
                    .padding()

                // MARK: - Notifications Testing Section
                VStack(spacing: 12) {
                    Text("Notification System")
                        .font(.title2)

                    HStack {
                        Button("Request Permissions") {
                            Task { await notificationManager.requestPermission() }
                        }
                        .disabled(notificationManager.isAuthorized)

                        Button("Send Nudge (1s)") {
                            Task { await notificationManager.sendSlackCheckNudge() }
                        }
                        .disabled(!notificationManager.isAuthorized)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)

                Divider()

                // MARK: - Classification Tester Section
                VStack(spacing: 12) {
                    Text("Classification Tester")
                        .font(.title2)

                    // Image Drop/Preview Area
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .frame(height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                            )

                        if let image = selectedImage {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 180)
                                .cornerRadius(8)
                        } else {
                            VStack {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 30))
                                Text("Drag & Drop Image")
                            }
                        }
                    }
                    .onTapGesture {
                        selectImage()
                    }
                    .onDrop(of: [.image], isTargeted: nil) { providers in
                        loadDroppedImage(from: providers)
                        return true
                    }

                    Button(action: analyzeImage) {
                        if isAnalyzing {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Classify Image")
                        }
                    }
                    .disabled(selectedImage == nil || isAnalyzing)

                    if let result = classificationResult {
                        Text(result.description)
                            .padding()
                    }
                }
                .padding()
            }
            .padding()
        }
    }

    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let image = NSImage(contentsOf: url) {
                    self.selectedImage = image
                    self.classificationResult = nil
                }
            }
        }
    }

    private func loadDroppedImage(from providers: [NSItemProvider]) {
        if let provider = providers.first(where: { $0.canLoadObject(ofClass: NSImage.self) }) {
            provider.loadObject(ofClass: NSImage.self) { image, error in
                DispatchQueue.main.async {
                    if let image = image as? NSImage {
                        self.selectedImage = image
                        self.classificationResult = nil
                    }
                }
            }
        }
    }

    private func analyzeImage() {
        guard let image = selectedImage,
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
        else { return }

        isAnalyzing = true
        Task {
            do {
                let result = try await classifier.classify(
                    imageData: data, context: nil, apiKey: nil, model: nil)
                await MainActor.run {
                    self.classificationResult = result
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isAnalyzing = false
                }
            }
        }
    }
}
