import SwiftUI

struct GenerationStatusBanner: View {
    let state: AlarmState
    let errorMessage: String?

    var body: some View {
        if state != .draft || errorMessage != nil {
            VStack(spacing: 8) {
                if state.isGenerating || state == .armingPrimaryAlarm || state == .armingFallbackAlarm {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(state.displayLabel)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }

                if let error = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }

                if state == .armed && errorMessage != nil {
                    Text("Alarm armed with system sound as fallback")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if state == .errorBlocked {
                    Label("Alarm could not be scheduled", systemImage: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
}
