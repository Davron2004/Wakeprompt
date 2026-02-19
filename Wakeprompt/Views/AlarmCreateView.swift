import SwiftUI
import SwiftData

struct AlarmCreateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let orchestrator: AlarmOrchestrator

    @State private var selectedTime = Date()
    @State private var selectedVoice = UserDefaults.standard.string(forKey: "selectedVoice") ?? "coral"
    @State private var promptText = ""
    @State private var isArming = false
    @State private var armingState: AlarmState = .draft
    @State private var errorMessage: String?
    @State private var armedAlarm: Alarm?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Alarm Time",
                        selection: $selectedTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowInsets(EdgeInsets())
                }

                Section("Voice") {
                    let defaultVoice = UserDefaults.standard.string(forKey: "selectedVoice") ?? "coral"
                    Picker("Voice", selection: $selectedVoice) {
                        ForEach(SettingsViewModel.availableVoices, id: \.self) { voice in
                            if voice == defaultVoice {
                                Text("\(voice.capitalized) (default)").tag(voice)
                            } else {
                                Text(voice.capitalized).tag(voice)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Prompt") {
                    TextField("E.g. \(WakeTextContext.defaultUserPrompt)", text: $promptText, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    GenerationStatusBanner(state: armingState, errorMessage: errorMessage)

                    Button(action: createAlarm) {
                        Group {
                            if isArming {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.white)
                                    Text(armingState.displayLabel)
                                }
                            } else {
                                Text("Set Alarm")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isArming ? Color.gray : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isArming)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if let alarm = armedAlarm, alarm.state != .armed {
                            orchestrator.delete(alarm, context: modelContext)
                        }
                        dismiss()
                    }
                    .disabled(isArming)
                }
            }
            .interactiveDismissDisabled(isArming)
        }
    }

    private func createAlarm() {
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        let alarm = Alarm(
            scheduledDate: selectedTime,
            voiceId: selectedVoice,
            prompt: trimmedPrompt.isEmpty ? nil : trimmedPrompt
        )

        modelContext.insert(alarm)
        armedAlarm = alarm
        isArming = true
        errorMessage = nil

        Task {
            await orchestrator.saveAlarm(alarm, context: modelContext)

            armingState = alarm.state
            isArming = false

            if alarm.state == .armed {
                if alarm.failureReason != nil {
                    errorMessage = alarm.failureReason
                    // Still armed (fallback) — allow dismiss after brief delay
                    try? await Task.sleep(for: .seconds(1.5))
                }
                dismiss()
            } else if alarm.state == .errorBlocked {
                errorMessage = alarm.failureReason ?? "Failed to schedule alarm"
                orchestrator.delete(alarm, context: modelContext)
                armedAlarm = nil
            }
        }
    }
}
