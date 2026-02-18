import Foundation

protocol TTSProvider: Sendable {
    func synthesize(text: String, voice: String) async throws -> Data
}
