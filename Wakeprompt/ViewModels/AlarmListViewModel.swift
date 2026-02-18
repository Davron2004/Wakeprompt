import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AlarmListViewModel {
    let orchestrator: AlarmOrchestrator

    var showingCreateSheet = false
    var showingSettings = false

    init(orchestrator: AlarmOrchestrator? = nil) {
        self.orchestrator = orchestrator ?? AlarmOrchestrator()
    }

    func deleteAlarm(_ alarm: Alarm, context: ModelContext) {
        orchestrator.delete(alarm, context: context)
    }
}
