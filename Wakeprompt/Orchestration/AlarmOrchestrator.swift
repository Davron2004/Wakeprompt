import Foundation
import SwiftData

@MainActor
final class AlarmOrchestrator {
    private let textProvider: any WakeTextProvider
    private let ttsProvider: any TTSProvider
    private let audioFileManager: AudioFileManager
    private let backbone: AlarmBackboneService
    private let telemetry: TelemetryService
    private let keychain: KeychainService

    init(
        textProvider: (any WakeTextProvider)? = nil,
        ttsProvider: (any TTSProvider)? = nil,
        audioFileManager: AudioFileManager? = nil,
        backbone: AlarmBackboneService? = nil,
        telemetry: TelemetryService? = nil,
        keychain: KeychainService? = nil
    ) {
        self.textProvider = textProvider ?? OpenAITextService()
        self.ttsProvider = ttsProvider ?? OpenAITTSService()
        self.audioFileManager = audioFileManager ?? .shared
        self.backbone = backbone ?? .shared
        self.telemetry = telemetry ?? .shared
        self.keychain = keychain ?? .shared
    }

    /// Creates and arms an alarm, falling back to system sound on any AI failure.
    /// Returns the alarm in `.armed` state, or `.errorBlocked` if even fallback fails.
    func saveAlarm(_ alarm: Alarm, context: ModelContext) async {
        let alarmId = alarm.id

        telemetry.log(.alarmCreated, alarmId: alarmId)

        // Step 1: Validate API key
        guard keychain.loadAPIKey() != nil else {
            alarm.state = .errorBlocked
            alarm.failureReason = "No API key configured"
            telemetry.log(.alarmCreateBlockedNoKey, alarmId: alarmId)
            trySave(context)
            return
        }

        // Step 2: Request AlarmKit authorization
        do {
            let authorized = try await backbone.requestAuthorization()
            guard authorized else {
                alarm.state = .errorBlocked
                alarm.failureReason = "Alarm permission denied"
                telemetry.log(.alarmkitPermissionDenied, alarmId: alarmId)
                trySave(context)
                return
            }
        } catch {
            alarm.state = .errorBlocked
            alarm.failureReason = "Alarm authorization failed: \(error.localizedDescription)"
            telemetry.log(.alarmkitPermissionDenied, alarmId: alarmId)
            trySave(context)
            return
        }

        // Step 3: Generate wake-up text
        alarm.state = .generatingText
        trySave(context)
        telemetry.log(.textGenStarted, alarmId: alarmId)

        let fireDate = alarm.fireDate

        let wakeText: String
        do {
            wakeText = try await textProvider.generateWakeText(
                alarmTime: fireDate,
                context: WakeTextContext(voiceId: alarm.voiceId, userPrompt: alarm.prompt)
            )
            alarm.generatedText = wakeText
            telemetry.log(.textGenCompleted, alarmId: alarmId)
            trySave(context)
        } catch {
            telemetry.log(.textGenFailed, alarmId: alarmId, extra: ["error": error.localizedDescription])
            await armFallback(alarm, context: context, reason: "Text generation failed: \(error.localizedDescription)")
            return
        }

        // Step 4: Generate audio via TTS
        alarm.state = .generatingAudio
        trySave(context)
        telemetry.log(.ttsStarted, alarmId: alarmId)

        let audioData: Data
        do {
            audioData = try await ttsProvider.synthesize(text: wakeText, voice: alarm.voiceId)
            telemetry.log(.ttsCompleted, alarmId: alarmId)
        } catch {
            telemetry.log(.ttsFailed, alarmId: alarmId, extra: ["error": error.localizedDescription])
            await armFallback(alarm, context: context, reason: "TTS failed: \(error.localizedDescription)")
            return
        }

        // Step 5: Save audio file and schedule primary alarm
        alarm.state = .armingPrimaryAlarm
        trySave(context)

        let filename = AudioFileManager.filename(for: alarmId)
        do {
            _ = try audioFileManager.saveAudio(data: audioData, filename: filename)
            alarm.generatedAudioFilename = filename
            alarm.lastGeneratedAt = Date()
            alarm.audioDurationSeconds = try? audioFileManager.audioDuration(filename: filename)

            try await backbone.scheduleAlarm(
                id: alarmId,
                fireDate: fireDate,
                soundFilename: filename,
                label: "AI Alarm",
                mode: "primary"
            )

            alarm.state = .armed
            alarm.firedMode = nil
            telemetry.log(.primaryArmed, alarmId: alarmId)
            trySave(context)
        } catch {
            // Clean up audio file if scheduling failed
            audioFileManager.deleteAudio(filename: filename)
            alarm.generatedAudioFilename = nil
            telemetry.log(.ttsFailed, alarmId: alarmId, extra: ["error": error.localizedDescription])
            await armFallback(alarm, context: context, reason: "Primary scheduling failed: \(error.localizedDescription)")
        }
    }

    /// Arms the fallback (system default sound). If even this fails, alarm is error-blocked.
    private func armFallback(_ alarm: Alarm, context: ModelContext, reason: String) async {
        alarm.state = .armingFallbackAlarm
        alarm.failureReason = reason
        trySave(context)

        do {
            try await backbone.scheduleAlarm(
                id: alarm.id,
                fireDate: alarm.fireDate,
                soundFilename: nil,
                label: "AI Alarm (Fallback)",
                mode: "fallback"
            )

            alarm.state = .armed
            telemetry.log(.fallbackArmed, alarmId: alarm.id, extra: ["reason": reason])
            trySave(context)
        } catch {
            alarm.state = .errorBlocked
            alarm.failureReason = "Fallback scheduling also failed: \(error.localizedDescription)"
            telemetry.log(.alarmkitPermissionDenied, alarmId: alarm.id, extra: ["error": error.localizedDescription])
            trySave(context)
        }
    }

    /// Re-runs the AI pipeline for an existing alarm.
    func regenerate(_ alarm: Alarm, context: ModelContext) async {
        // Cancel existing schedule
        backbone.cancelAlarm(id: alarm.id)

        // Clean up old audio
        if let oldFilename = alarm.generatedAudioFilename {
            audioFileManager.deleteAudio(filename: oldFilename)
        }

        alarm.state = .draft
        alarm.generatedText = nil
        alarm.generatedAudioFilename = nil
        alarm.audioDurationSeconds = nil
        alarm.failureReason = nil
        alarm.firedMode = nil
        trySave(context)

        await saveAlarm(alarm, context: context)
    }

    /// Cancels an alarm and cleans up resources.
    func cancel(_ alarm: Alarm, context: ModelContext) {
        backbone.cancelAlarm(id: alarm.id)

        if let filename = alarm.generatedAudioFilename {
            audioFileManager.deleteAudio(filename: filename)
        }

        alarm.state = .completed
        alarm.isEnabled = false
        telemetry.log(.alarmCancelled, alarmId: alarm.id)
        trySave(context)
    }

    func delete(_ alarm: Alarm, context: ModelContext) {
        backbone.cancelAlarm(id: alarm.id)

        if let filename = alarm.generatedAudioFilename {
            audioFileManager.deleteAudio(filename: filename)
        }

        context.delete(alarm)
        trySave(context)
    }

    private func trySave(_ context: ModelContext) {
        try? context.save()
    }
}
