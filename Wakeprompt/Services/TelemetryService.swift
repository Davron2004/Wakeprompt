import Foundation
import os

enum TelemetryEvent: String, Sendable {
    case alarmCreated = "alarm_created"
    case textGenStarted = "text_gen_started"
    case textGenCompleted = "text_gen_completed"
    case textGenFailed = "text_gen_failed"
    case ttsStarted = "tts_started"
    case ttsCompleted = "tts_completed"
    case ttsFailed = "tts_failed"
    case primaryArmed = "primary_armed"
    case fallbackArmed = "fallback_armed"
    case alarmFiredPrimary = "alarm_fired_primary"
    case alarmFiredFallback = "alarm_fired_fallback"
    case alarmCancelled = "alarm_cancelled"
    case alarmCreateBlockedNoKey = "alarm_create_blocked_no_api_key"
    case alarmkitPermissionDenied = "alarmkit_permission_denied"
}

final class TelemetryService: Sendable {
    static let shared = TelemetryService()

    private let logger = Logger(subsystem: "com.aialarm.app", category: "telemetry")

    private init() {}

    func log(_ event: TelemetryEvent, alarmId: UUID? = nil, extra: [String: String] = [:]) {
        var message = "[\(event.rawValue)]"
        if let alarmId {
            message += " alarm=\(alarmId.uuidString.prefix(8))"
        }
        for (key, value) in extra {
            // Never log API keys
            if key.lowercased().contains("key") || key.lowercased().contains("token") {
                continue
            }
            message += " \(key)=\(value)"
        }

        switch event {
        case .textGenFailed, .ttsFailed, .alarmkitPermissionDenied, .alarmCreateBlockedNoKey:
            logger.error("\(message, privacy: .public)")
        default:
            logger.info("\(message, privacy: .public)")
        }

        #if DEBUG
        debugLog(message, extra: extra)
        #endif
    }

    #if DEBUG
    private func debugLog(_ message: String, extra: [String: String]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] \(message)")
    }
    #endif
}
