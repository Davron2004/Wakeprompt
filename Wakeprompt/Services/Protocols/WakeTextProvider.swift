import Foundation

struct WakeTextContext: Sendable {
    var voiceId: String
}

protocol WakeTextProvider: Sendable {
    func generateWakeText(alarmTime: Date, context: WakeTextContext) async throws -> String
}
