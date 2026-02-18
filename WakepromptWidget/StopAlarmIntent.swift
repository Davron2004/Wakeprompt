import AppIntents
import AlarmKit

struct StopAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop Alarm"
    static let description = IntentDescription("Stops the AI Alarm")
    static let openAppWhenRun = false

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }

    init() {
        self.alarmID = ""
    }

    func perform() throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) {
            try AlarmManager.shared.cancel(id: id)
        }
        return .result()
    }
}
