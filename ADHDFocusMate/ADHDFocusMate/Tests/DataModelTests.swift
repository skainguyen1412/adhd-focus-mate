import SwiftData
import Testing

@testable import ADHDFocusMate

@MainActor
struct DataModelTests {
    let dataController: DataController

    init() {
        dataController = DataController(inMemory: true)
    }

    @Test
    func focusSessionCreation() throws {
        let session = FocusSession(goalText: "Test Goal", state: .active)
        dataController.container.mainContext.insert(session)

        try dataController.container.mainContext.save()

        let descriptor = FetchDescriptor<FocusSession>()
        let sessions = try dataController.container.mainContext.fetch(descriptor)

        #expect(sessions.count == 1)
        #expect(sessions.first?.goalText == "Test Goal")
        #expect(sessions.first?.state == .active)
    }

    @Test
    func focusCheckRelationship() throws {
        let session = FocusSession(goalText: "Work Session")
        dataController.container.mainContext.insert(session)

        let check = FocusCheck(label: "work", confidence: 0.9, reason: "Coding")
        session.checks.append(check)

        try dataController.container.mainContext.save()

        let descriptor = FetchDescriptor<FocusCheck>()
        let checks = try dataController.container.mainContext.fetch(descriptor)

        #expect(checks.count == 1)
        #expect(checks.first?.session?.id == session.id)
        #expect(session.checks.count == 1)
    }

    @Test
    func defaultSettingsInitialization() throws {
        // DataController init should create default settings
        let descriptor = FetchDescriptor<AppSettings>()
        let settings = try dataController.container.mainContext.fetch(descriptor)

        #expect(settings.count == 1)
        #expect(settings.first?.intervalSeconds == 60)
        #expect(settings.first?.slackNudgesEnabled == true)
    }
}
