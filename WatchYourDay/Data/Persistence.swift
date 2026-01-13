import SwiftData
import Combine
import UserNotifications

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Snapshot.self,
                DailyReport.self,

            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}


