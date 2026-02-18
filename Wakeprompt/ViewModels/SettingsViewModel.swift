import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    var apiKey: String = ""
    var selectedVoice: String = "coral"
    var isSaving = false
    var statusMessage: String?

    static let availableVoices = ["alloy", "ash", "coral", "echo", "fable", "nova", "onyx", "sage", "shimmer"]

    private let keychain = KeychainService.shared

    init() {
        loadSettings()
    }

    func loadSettings() {
        apiKey = keychain.loadAPIKey() ?? ""
        selectedVoice = UserDefaults.standard.string(forKey: "selectedVoice") ?? "coral"
    }

    func saveSettings() {
        isSaving = true
        defer { isSaving = false }

        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedKey.isEmpty {
            try? keychain.deleteAPIKey()
            statusMessage = "API key removed"
        } else {
            do {
                try keychain.saveAPIKey(trimmedKey)
                statusMessage = "API key saved"
            } catch {
                statusMessage = "Failed to save API key"
            }
        }

        UserDefaults.standard.set(selectedVoice, forKey: "selectedVoice")
    }

    var hasAPIKey: Bool {
        keychain.loadAPIKey() != nil
    }
}
