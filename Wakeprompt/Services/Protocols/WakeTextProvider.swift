import Foundation

struct WakeTextContext: Sendable {
    static let defaultUserPrompt = "Generate my wake-up message."

    var voiceId: String
    var userPrompt: String?
}

protocol WakeTextProvider: Sendable {
    func generateWakeText(alarmTime: Date, context: WakeTextContext) async throws -> String
}
