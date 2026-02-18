import Foundation

struct OpenAITTSService: TTSProvider {
    private let keychain = KeychainService.shared
    private let maxRetries = 3
    private let timeoutInterval: TimeInterval = 30

    func synthesize(text: String, voice: String) async throws -> Data {
        guard let apiKey = keychain.loadAPIKey() else {
            throw OpenAIError.missingAPIKey
        }

        let body: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voice,
            "response_format": "wav"
        ]

        return try await performRequest(
            url: "https://api.openai.com/v1/audio/speech",
            apiKey: apiKey,
            body: body
        )
    }

    private func performRequest(url: String, apiKey: String, body: [String: Any]) async throws -> Data {
        var lastError: Error = OpenAIError.invalidResponse

        for attempt in 0..<maxRetries {
            do {
                var request = URLRequest(url: URL(string: url)!)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = timeoutInterval
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw OpenAIError.invalidResponse
                }

                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw OpenAIError.invalidAPIKey
                case 429:
                    if attempt < maxRetries - 1 {
                        try await Task.sleep(for: .seconds(Double(attempt + 1) * 2))
                        continue
                    }
                    throw OpenAIError.rateLimited
                case 500...599:
                    if attempt < maxRetries - 1 {
                        try await Task.sleep(for: .seconds(Double(attempt + 1) * 2))
                        continue
                    }
                    throw OpenAIError.serverError(httpResponse.statusCode)
                default:
                    throw OpenAIError.httpError(httpResponse.statusCode)
                }
            } catch let error as OpenAIError {
                throw error
            } catch {
                lastError = error
                if attempt < maxRetries - 1 {
                    try await Task.sleep(for: .seconds(Double(attempt + 1)))
                    continue
                }
            }
        }

        throw lastError
    }
}
