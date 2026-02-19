import Foundation
import SwiftData

@Model
final class Alarm {
    @Attribute(.unique) var id: UUID
    var scheduledDate: Date
    var isEnabled: Bool

    var stateRaw: String
    var state: AlarmState {
        get { AlarmState(rawValue: stateRaw) ?? .draft }
        set { stateRaw = newValue.rawValue }
    }

    var voiceId: String
    var prompt: String?
    var repeatDays: [Int]?
    var generatedAudioFilename: String?
    var generatedText: String?
    var firedMode: String?
    var lastGeneratedAt: Date?
    var failureReason: String?
    var createdAt: Date

    init(
        scheduledDate: Date,
        voiceId: String = "coral",
        prompt: String? = nil,
        repeatDays: [Int]? = nil,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.scheduledDate = scheduledDate
        self.voiceId = voiceId
        self.prompt = prompt
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.stateRaw = AlarmState.draft.rawValue
        self.createdAt = Date()
    }

    var hour: Int {
        Calendar.current.component(.hour, from: scheduledDate)
    }

    var minute: Int {
        Calendar.current.component(.minute, from: scheduledDate)
    }

    var fireDate: Date {
        scheduledDate
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: scheduledDate)
    }

    var dateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(scheduledDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(scheduledDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d"
            return formatter.string(from: scheduledDate)
        }
    }
}
