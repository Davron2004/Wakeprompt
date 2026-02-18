import Foundation

enum AudioFileError: Error, LocalizedError {
    case directoryCreationFailed
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed: return "Failed to create Library/Sounds directory"
        case .writeFailed(let error): return "Failed to write audio file: \(error.localizedDescription)"
        }
    }
}

final class AudioFileManager: Sendable {
    static let shared = AudioFileManager()

    private init() {}

    func librarySoundsURL() throws -> URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let soundsDir = library.appendingPathComponent("Sounds", isDirectory: true)

        if !FileManager.default.fileExists(atPath: soundsDir.path) {
            do {
                try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
            } catch {
                throw AudioFileError.directoryCreationFailed
            }
        }

        return soundsDir
    }

    func saveAudio(data: Data, filename: String) throws -> URL {
        let dir = try librarySoundsURL()
        let fileURL = dir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw AudioFileError.writeFailed(error)
        }

        return fileURL
    }

    func deleteAudio(filename: String) {
        guard let dir = try? librarySoundsURL() else { return }
        let fileURL = dir.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }

    func audioExists(filename: String) -> Bool {
        guard let dir = try? librarySoundsURL() else { return false }
        let fileURL = dir.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    static func filename(for alarmId: UUID) -> String {
        let prefix = alarmId.uuidString.prefix(8).lowercased()
        return "ai_alarm_\(prefix).wav"
    }
}
