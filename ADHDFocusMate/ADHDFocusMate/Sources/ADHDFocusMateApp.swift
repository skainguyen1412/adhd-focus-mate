import SwiftData
import SwiftUI

// MARK: - App Delegate (System-level integration)

class AppDelegate: NSObject, NSApplicationDelegate {
    /// Set to true to allow actual termination (e.g., from "Quit Completely" or system shutdown)
    static var allowTermination = false

    func applicationDidFinishLaunching(_: Notification) {
        // Ensure we show as a regular app with Dock icon
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        if Self.allowTermination {
            return .terminateNow
        } else {
            // Soft quit: hide the app instead of quitting
            // The menu bar item stays visible for quick access
            NSApp.hide(nil)
            return .terminateCancel
        }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When clicking Dock icon, show the app
        if !flag {
            NSApp.activate(ignoringOtherApps: true)
            // Try to show main window
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }

    @objc func openSettings() {
        // Activate app
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            window.makeKeyAndOrderFront(nil)
        }
        // Post notification to switch tab
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }
}

extension Notification.Name {
    static let openSettings = Notification.Name("OpenSettings")
}

// MARK: - Main App

@main
struct ADHDFocusMateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var dataController: DataController
    @StateObject private var sessionManager: FocusSessionManager

    // Onboarding Persistence
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        let dc = DataController()
        _dataController = StateObject(wrappedValue: dc)
        _sessionManager = StateObject(wrappedValue: FocusSessionManager(dataController: dc))
    }

    var body: some Scene {
        // MARK: - Main Window (normal app window)

        // MARK: - Main Window (normal app window)

        Window("ADHD Focus Mate", id: "main") {
            ZStack {
                if hasCompletedOnboarding {
                    ContentView()
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                } else {
                    OnboardingContainerView()
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.8), value: hasCompletedOnboarding)
            .modelContainer(dataController.container)
            .environmentObject(sessionManager)
            .frame(
                minWidth: 900, maxWidth: .infinity,
                minHeight: 600, maxHeight: .infinity
            )
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // Remove "New Window" from File menu (single window app)
            CommandGroup(replacing: .newItem) {}

            CommandGroup(after: .appInfo) {
                Button("Reset Onboarding") {
                    hasCompletedOnboarding = false
                }

                Divider()

                Button("Quit Completely") {
                    AppDelegate.allowTermination = true
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command, .option])
            }
        }

        // MARK: - Menu Bar Status Item (companion)
        // ... keeping existing MenuBarExtra ...

        MenuBarExtra {
            MenuBarView(sessionManager: sessionManager)
                .modelContainer(dataController.container)
        } label: {
            // Dynamic Zen Pill
            renderMenuBarIcon(
                text: formattedTime(sessionManager.elapsedTime),
                state: sessionManager.state
            )
        }
        .menuBarExtraStyle(.window)
    }

    private func formattedTime(_ totalSeconds: TimeInterval) -> String {
        let minutes = (Int(totalSeconds) % 3600) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Menu Bar Zen/Pill Renderer
    private func renderMenuBarIcon(text: String, state: FocusSession.SessionState) -> Image {
        let isActive = state == .active
        let isPaused = state == .paused
        let showTimer = isActive || isPaused

        // Configuration
        let height: CGFloat = 22
        let fontSize: CGFloat = 12
        let iconSize: CGFloat = 15
        let paddingH: CGFloat = 8
        let innerSpacing: CGFloat = 4

        // Font Setup
        let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .semibold)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
        ]

        // Measure Text
        let textToDraw = showTimer ? text : "Ready"
        // If not showing timer and not paused, maybe just show icon?
        // User asked for "Zen Pill", so let's keep it minimal if idle.
        let shouldShowText = showTimer

        let textSize =
            shouldShowText ? (textToDraw as NSString).size(withAttributes: textAttributes) : .zero
        let totalTextWidth = shouldShowText ? textSize.width + innerSpacing : 0

        let totalWidth = paddingH + iconSize + totalTextWidth + paddingH

        let image = NSImage(
            size: NSSize(width: max(24, totalWidth), height: height), flipped: false
        ) { rect in
            // 1. Draw Glass Pill Background
            let pillPath = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)

            if isActive {
                NSColor(red: 0.29, green: 0.87, blue: 0.50, alpha: 0.2).setFill()  // Soft Green Glass
                pillPath.fill()
                NSColor(red: 0.29, green: 0.87, blue: 0.50, alpha: 0.3).setStroke()  // Green Border
                pillPath.lineWidth = 1
                pillPath.stroke()
            } else if isPaused {
                NSColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.15).setFill()  // Amber Glass
                pillPath.fill()
                NSColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.3).setStroke()
                pillPath.lineWidth = 1
                pillPath.stroke()
            } else {
                // Idle - "Jade Stone" (Subtle Mint Glass)
                NSColor(red: 0.29, green: 0.87, blue: 0.50, alpha: 0.05).setFill()
                pillPath.fill()
                // Very faint border to define edges
                NSColor(red: 0.29, green: 0.87, blue: 0.50, alpha: 0.1).setStroke()
                pillPath.lineWidth = 0.5
                pillPath.stroke()
            }

            // 2. Draw Icon
            // Always use filled leaf for idle to match active style
            let iconName = isActive ? "leaf.fill" : (isPaused ? "pause.circle.fill" : "leaf.fill")
            if let symbolImage = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
            {
                // Idle now uses Green tint too, just like Active
                let tintColor =
                    (isActive || !shouldShowText)
                    ? NSColor(red: 0.29, green: 0.87, blue: 0.50, alpha: 1.0) : NSColor.white

                // Create tinted configuration
                let iconRect = NSRect(
                    x: paddingH, y: (height - iconSize) / 2 - 0.5, width: iconSize, height: iconSize
                )

                // Manual tinting approach for NSImage (Symbol)
                var tintedImage = symbolImage
                let config = NSImage.SymbolConfiguration(paletteColors: [tintColor])
                tintedImage = symbolImage.withSymbolConfiguration(config) ?? symbolImage
                tintedImage.draw(in: iconRect)
            }

            // 3. Draw Text
            if shouldShowText {
                let textRect = NSRect(
                    x: paddingH + iconSize + innerSpacing,
                    y: (height - textSize.height) / 2 - 1,
                    width: textSize.width,
                    height: textSize.height
                )
                (textToDraw as NSString).draw(in: textRect, withAttributes: textAttributes)
            }

            return true
        }

        image.isTemplate = false  // Render exactly as we drew it (with colors)
        return Image(nsImage: image)
    }
}
