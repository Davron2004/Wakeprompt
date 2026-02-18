import SwiftUI
import SwiftData

struct AlarmDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var alarm: Alarm
    let orchestrator: AlarmOrchestrator

    @State private var isRegenerating = false

    var body: some View {
        List {
            Section("Time") {
                HStack {
                    Text(alarm.timeString)
                        .font(.system(.largeTitle, design: .rounded, weight: .medium))
                    Spacer()
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

                if let lastGen = alarm.lastGeneratedAt {
                    LabeledContent("Generated") {
                        Text(lastGen, format: .dateTime.hour().minute())
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
    }

    private func regenerate() {
        isRegenerating = true
        Task {
            await orchestrator.regenerate(alarm, context: modelContext)
            isRegenerating = false
        }
    }
}
