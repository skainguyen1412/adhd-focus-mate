import Combine
import Foundation
import UserNotifications

// MARK: - Protocol

/// Abstract protocol for UNUserNotificationCenter to enable unit testing
protocol NotificationCenterProtocol: AnyObject {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>)

    // Abstracting settings to return just the status or a wrapper
    func getAuthorizationStatus() async -> UNAuthorizationStatus

    // We can't abstract the delegate property easily because it's weak and typed to UNUserNotificationCenterDelegate
    // Instead, we'll have the manager hold the delegate and assign it to the concrete implementation
    func setDelegate(_ delegate: UNUserNotificationCenterDelegate?)
}

// MARK: - System Wrapper

/// Concrete implementation wrapping the system UNUserNotificationCenter
class SystemNotificationCenter: NotificationCenterProtocol {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return try await center.requestAuthorization(options: options)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        center.setNotificationCategories(categories)
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func setDelegate(_ delegate: UNUserNotificationCenterDelegate?) {
        center.delegate = delegate
    }
}

// MARK: - Manager

@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    // MARK: - Properties

    @Published var isAuthorized: Bool = false

    private let notificationCenter: NotificationCenterProtocol
    private let categoryIdentifier = "slack_check"
    private let errorCategoryIdentifier = "error_alert"

    private var lastErrorTimes: [String: Date] = [:]
    private let notificationCooldown: TimeInterval = 600  // 10 minutes

    // MARK: - Init

    init(notificationCenter: NotificationCenterProtocol = SystemNotificationCenter()) {
        self.notificationCenter = notificationCenter
        super.init()
        self.notificationCenter.setDelegate(self)
        self.setupCategories()
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Setup

    private func setupCategories() {
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let errorCategory = UNNotificationCategory(
            identifier: errorCategoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        notificationCenter.setNotificationCategories([category, errorCategory])
    }

    func checkAuthorizationStatus() async {
        let status = await notificationCenter.getAuthorizationStatus()
        self.isAuthorized = (status == .authorized)
    }

    // MARK: - Public API

    func requestPermission() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [
                .alert, .sound, .badge,
            ])
            self.isAuthorized = granted
            print("🔔 Notification permission granted: \(granted)")
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            self.isAuthorized = false
        }
    }

    func sendSlackCheckNudge() async {
        let content = UNMutableNotificationContent()
        content.title = "Focus Nudge"
        content.body = "It looks like you've drifted off. Let's get back to your goal!"
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("✅ Slack check notification scheduled")
        } catch {
            print("❌ Failed to schedule notification: \(error)")
        }
    }

    func sendErrorNotification(title: String, body: String, errorKey: String) async {
        // Prevent spam: only send if we haven't sent this error recently
        if let lastTime = lastErrorTimes[errorKey],
            Date().timeIntervalSince(lastTime) < notificationCooldown
        {
            print("🤫 Skipping error notification due to cooldown: \(errorKey)")
            return
        }

        lastErrorTimes[errorKey] = Date()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = errorCategoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("✅ Error notification scheduled: \(title)")
        } catch {
            print("❌ Failed to schedule error notification: \(error)")
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle foreground presentation
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        // Show banner and sound even if app is in foreground
        completionHandler([.banner, .sound])
    }

    // Handle actions
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Passive notification - no specific actions to handle anymore
        completionHandler()
    }
}
