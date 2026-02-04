import Foundation
import SwiftData

@MainActor
public class DataController: ObservableObject {
    public let container: ModelContainer
    
    public init(inMemory: Bool = false) {
        let schema = Schema([
            FocusSession.self,
            FocusCheck.self,
            AppSettings.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Initialize default settings if needed
            self.ensureDefaultSettings()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func ensureDefaultSettings() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let count = try context.fetchCount(descriptor)
            if count == 0 {
                let defaultSettings = AppSettings()
                context.insert(defaultSettings)
                try context.save()
                print("⚙️ [DataController] Initialized default settings")
            }
        } catch {
            print("❌ [DataController] Failed to check/create settings: \(error)")
        }
    }
    
    public func save() {
        let context = container.mainContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ [DataController] Save failed: \(error)")
            }
        }
    }
}
