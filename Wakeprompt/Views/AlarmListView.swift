import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Alarm.createdAt, order: .reverse) private var alarms: [Alarm]
    @State private var viewModel = AlarmListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if alarms.isEmpty {
                    ContentUnavailableView(
                        "No Alarms",
                        systemImage: "alarm",
                        description: Text("Tap + to create your first AI alarm")
                    )
                } else {
                    List {
                        ForEach(alarms) { alarm in
                            NavigationLink(value: alarm) {
                                AlarmRowView(alarm: alarm)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.deleteAlarm(alarms[index], context: modelContext)
                            }
                        }
                    }
                }
            }
            .navigationTitle("AI Alarm")
            .navigationDestination(for: Alarm.self) { alarm in
                AlarmDetailView(alarm: alarm, orchestrator: viewModel.orchestrator)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateSheet) {
                AlarmCreateView(orchestrator: viewModel.orchestrator)
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Row View

private struct AlarmRowView: View {
    let alarm: Alarm

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(.system(.title, design: .rounded, weight: .medium))

                HStack(spacing: 6) {
                    stateIndicator
                    Text(alarm.dateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(alarm.state.displayLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if alarm.state == .armed {
                if alarm.failureReason != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var stateIndicator: some View {
        switch alarm.state {
        case .armed where alarm.failureReason == nil:
            Circle().fill(.green).frame(width: 8, height: 8)
        case .armed:
            Circle().fill(.orange).frame(width: 8, height: 8)
        case .generatingText, .generatingAudio, .armingPrimaryAlarm, .armingFallbackAlarm:
            ProgressView().scaleEffect(0.5)
        case .errorBlocked:
            Circle().fill(.red).frame(width: 8, height: 8)
        default:
            Circle().fill(.gray).frame(width: 8, height: 8)
        }
    }
}
