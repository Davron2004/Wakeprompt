import Foundation
@preconcurrency import AlarmKit
import ActivityKit
import AppIntents
import SwiftUI

enum AlarmBackboneError: Error, LocalizedError {
    case notAuthorized
    case schedulingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Alarm permission not granted"
        case .schedulingFailed(let error): return "Failed to schedule alarm: \(error.localizedDescription)"
        }
    }
}

final class AlarmBackboneService: Sendable {
    static let shared = AlarmBackboneService()

    private let manager = AlarmManager.shared

    private init() {}

    func requestAuthorization() async throws -> Bool {
        switch manager.authorizationState {
        case .authorized:
            return true
        case .notDetermined:
            let state = try await manager.requestAuthorization()
            return state == .authorized
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    var isAuthorized: Bool {
        manager.authorizationState == .authorized
    }

    func scheduleAlarm(
        id: UUID,
        hour: Int,
        minute: Int,
        soundFilename: String?,
        label: String,
        mode: String
    ) async throws {
        guard isAuthorized else {
            throw AlarmBackboneError.notAuthorized
        }

        let time = AlarmKit.Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        let relative = AlarmKit.Alarm.Schedule.Relative(time: time, repeats: .never)
        let schedule = AlarmKit.Alarm.Schedule.relative(relative)

        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: label)
        )

        let presentation = AlarmPresentation(alert: alert)

        let metadata = AIAlarmMetadata(alarmLabel: label, mode: mode)

        let attributes = AlarmAttributes<AIAlarmMetadata>(
            presentation: presentation,
            metadata: metadata,
            tintColor: mode == "primary" ? .blue : .orange
        )

        let sound: AlertConfiguration.AlertSound
        if let filename = soundFilename {
            sound = .named(filename)
        } else {
            sound = .default
        }

        let configuration = AlarmManager.AlarmConfiguration<AIAlarmMetadata>.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopAlarmIntent(alarmID: id),
            secondaryIntent: nil,
            sound: sound
        )

        do {
            _ = try await manager.schedule(id: id, configuration: configuration)
        } catch {
            throw AlarmBackboneError.schedulingFailed(error)
        }
    }

    func cancelAlarm(id: UUID) {
        try? manager.cancel(id: id)
    }
}
