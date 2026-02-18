import WidgetKit
import SwiftUI
import AlarmKit
import AppIntents

struct WakepromptLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<AIAlarmMetadata>.self) { context in
            // Lock Screen / Banner presentation
            lockScreenView(context: context)
                .padding()
                .activityBackgroundTint(.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.attributes.presentation.alert.title)
                            .font(.headline)
                            .foregroundStyle(.white)

                        alarmModeLabel(context: context)
                    }
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(tintColor(context: context))
            } compactTrailing: {
                Text(context.attributes.presentation.alert.title)
                    .font(.caption2)
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(tintColor(context: context))
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<AlarmAttributes<AIAlarmMetadata>>) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(tintColor(context: context))
                Text(context.attributes.presentation.alert.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            alarmModeLabel(context: context)

            HStack(spacing: 16) {
                Button(intent: StopAlarmIntent(alarmID: context.state.alarmID)) {
                    Label("Stop", systemImage: "xmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.red, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private func alarmModeLabel(context: ActivityViewContext<AlarmAttributes<AIAlarmMetadata>>) -> some View {
        let mode = context.attributes.metadata?.mode ?? "fallback"
        HStack(spacing: 4) {
            Circle()
                .fill(mode == "primary" ? .green : .orange)
                .frame(width: 6, height: 6)
            Text(mode == "primary" ? "AI Audio" : "Fallback")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func tintColor(context: ActivityViewContext<AlarmAttributes<AIAlarmMetadata>>) -> Color {
        (context.attributes.metadata?.mode ?? "fallback") == "primary" ? .blue : .orange
    }
}
