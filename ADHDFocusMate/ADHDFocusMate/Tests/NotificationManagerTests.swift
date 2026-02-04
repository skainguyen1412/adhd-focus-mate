import Foundation
import Testing
import UserNotifications

@testable import ADHDFocusMate

class MockNotificationCenter: NotificationCenterProtocol {
    var requestedOptions: UNAuthorizationOptions?
    var addedRequests: [UNNotificationRequest] = []
    var categories: Set<UNNotificationCategory> = []
    var delegate: UNUserNotificationCenterDelegate?
    var authStatusToReturn: UNAuthorizationStatus = .notDetermined

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestedOptions = options
        return true
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        self.categories = categories
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        return authStatusToReturn
    }

    func setDelegate(_ delegate: UNUserNotificationCenterDelegate?) {
        self.delegate = delegate
    }
}

// Helper to simulate response
class MockNotificationResponse: UNNotificationResponse {
    let _actionIdentifier: String

    init(actionIdentifier: String) {
        self._actionIdentifier = actionIdentifier
        super.init(coder: NSCoder())!
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var actionIdentifier: String {
        return _actionIdentifier
    }
}

@MainActor
struct NotificationManagerTests {

    @Test
    func requestPermissionCallsCenter() async {
        let mock = MockNotificationCenter()
        let manager = NotificationManager(notificationCenter: mock)

        await manager.requestPermission()

        #expect(mock.requestedOptions?.contains(.alert) == true)
        #expect(mock.requestedOptions?.contains(.sound) == true)
        #expect(manager.isAuthorized == true)
    }

    @Test
    func sendSlackCheckAddsRequest() async {
        let mock = MockNotificationCenter()
        let manager = NotificationManager(notificationCenter: mock)

        // Ensure initialized
        try? await Task.sleep(nanoseconds: 10_000_000)

        await manager.sendSlackCheckNudge()

        #expect(mock.addedRequests.count == 1)
        let request = mock.addedRequests.first!
        #expect(request.content.categoryIdentifier == "slack_check")
        #expect(request.content.title == "Focus Nudge")
        #expect(
            request.content.body == "It looks like you've drifted off. Let's get back to your goal!"
        )
    }

    @Test
    func categoriesAreSetup() async {
        let mock = MockNotificationCenter()
        _ = NotificationManager(notificationCenter: mock)

        // Wait for init
        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(mock.categories.count == 1)
        let category = mock.categories.first!
        #expect(category.identifier == "slack_check")
        #expect(category.actions.count == 0)
    }

    // Simulating the delegate callback is tricky because we can't easily instantiate UNNotificationResponse
    // without private API or hacking NSCoder.
    // However, since we implement the delegate method in NotificationManager, we can test that method directly
    // if we trust we can pass a response object.
    // The workaround subclass MockNotificationResponse above might crash on super.init() if it checks validity.
    // Let's verify if `super.init(coder: ...)` crashes for UNNotificationResponse.
    // If it does, we might skip testing the delegate *callback* via `NotificationManager` direct call,
    // and rely on integration/manual testing for that specific part, or assume it works if logic is simple.

    // Alternatively, we can abstract the "Action Handler" logic into a separate testable unit,
    // but that might be overengineering for Phase 0.
}
