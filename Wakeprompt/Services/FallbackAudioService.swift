import Foundation

final class FallbackAudioService: Sendable {
    static let shared = FallbackAudioService()

    private init() {}

    /// Returns nil to indicate that AlarmKit should use `.default` system alarm sound.
    /// This is the most reliable fallback — no file dependencies.
    var fallbackSoundFilename: String? { nil }
}
