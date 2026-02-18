import Foundation
import SwiftData

@Model
final class Alarm {
    @Attribute(.unique) var id: UUID
    var hour: Int
    var minute: Int
    var isEnabled: Bool

    var stateRaw: String
    var state: AlarmState {
        get { AlarmState(rawValue: stateRaw) ?? .draft }
        set { stateRaw = newValue.rawValue }
    }

    var voiceId: String
    var generatedAudioFilename: String?
    var generatedText: String?
    var firedMode: String?
    var lastGeneratedAt: Date?
    var failureReason: String?
    var createdAt: Date

    init(
        hour: Int,
        minute: Int,
        voiceId: String = "coral",
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.hour = hour
        self.minute = minute
        self.voiceId = voiceId
        self.isEnabled = isEnabled
        self.stateRaw = AlarmState.draft.rawValue
        self.createdAt = Date()
    }

    var fireDate: Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        guard let date = Calendar.current.date(from: components) else { return nil }
        // If the time has already passed today, schedule for tomorrow
        if date <= Date() {
            return Calendar.current.date(byAdding: .day, value: 1, to: date)
        }
        return date
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}
