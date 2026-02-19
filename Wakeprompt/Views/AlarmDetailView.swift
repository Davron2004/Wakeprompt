import SwiftUI
import SwiftData

struct AlarmDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var alarm: Alarm
    let orchestrator: AlarmOrchestrator

    @State private var isRegenerating = false
    @State private var selectedVoice = ""
    @State private var promptText = ""

    var body: some View {
        List {
            Section("Time") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alarm.timeString)
                            .font(.system(.largeTitle, design: .rounded, weight: .medium))
                        Text(alarm.dateString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
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
                .disabled(isRegenerating)
                .onChange(of: selectedVoice) { oldValue, newValue in
                    guard oldValue != newValue, !oldValue.isEmpty else { return }
                    alarm.voiceId = newValue
                    if alarm.state == .armed {
                        regenerate()
                    }
                }
            }

            Section("Prompt") {
                TextField("E.g. \(WakeTextContext.defaultUserPrompt)", text: $promptText, axis: .vertical)
                    .lineLimit(2...4)
                    .disabled(isRegenerating)

                if promptHasChanged {
                    Button("Apply & Regenerate") {
                        applyPromptChange()
                    }
                    .disabled(isRegenerating)
                }
            }

            Section("Status") {
                LabeledContent("State", value: alarm.state.displayLabel)

                if alarm.failureReason != nil {
                    LabeledContent("Mode") {
                        Label("Fallback (System Sound)", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                } else if alarm.state == .armed {
                    LabeledContent("Mode") {
                        Label("Primary (AI Audio)", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                if let reason = alarm.failureReason {
                    LabeledContent("Fallback Reason", value: reason)
                }

                if let duration = alarm.audioDurationSeconds {
                    LabeledContent("Audio Duration") {
                        Text(formatDuration(duration))
                    }
                }
            }

            if let text = alarm.generatedText {
                Section("Generated Script") {
                    Text(text)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    regenerate()
                } label: {
                    HStack {
                        if isRegenerating {
                            ProgressView()
                                .padding(.trailing, 4)
                        }
                        Text("Regenerate AI Audio")
                    }
                }
                .disabled(isRegenerating || !alarm.state.isTerminal && alarm.state != .armed)

                Button("Cancel Alarm", role: .destructive) {
                    orchestrator.cancel(alarm, context: modelContext)
                    dismiss()
                }
            }
        }
        .navigationTitle("Alarm Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedVoice = alarm.voiceId
            promptText = alarm.prompt ?? ""
        }
    }

    private var promptHasChanged: Bool {
        let current = alarm.prompt ?? ""
        let edited = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        return current != edited && alarm.state == .armed
    }

    private func applyPromptChange() {
        let trimmed = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        alarm.prompt = trimmed.isEmpty ? nil : trimmed
        regenerate()
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let mins = total / 60
        let secs = total % 60
        return mins > 0 ? String(format: "%d:%02d", mins, secs) : "\(secs)s"
    }

    private func regenerate() {
        isRegenerating = true
        Task {
            await orchestrator.regenerate(alarm, context: modelContext)
            isRegenerating = false
        }
    }
}
