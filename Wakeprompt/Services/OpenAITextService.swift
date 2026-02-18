import Foundation

struct OpenAITextService: WakeTextProvider {
    private let keychain = KeychainService.shared
    private let maxRetries = 3
    private let timeoutInterval: TimeInterval = 30

    func generateWakeText(alarmTime: Date, context: WakeTextContext) async throws -> String {
        guard let apiKey = keychain.loadAPIKey() else {
            throw OpenAIError.missingAPIKey
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        let timeString = formatter.string(from: alarmTime)

        let systemPrompt = """
            Generate a wake-up message for \(timeString). \
            Be encouraging and energizing. 3-4 sentences, \
            approximately 30 seconds when spoken aloud. \
            Do not include any stage directions or annotations.
            """

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Generate my wake-up message."]
            ],
            "max_tokens": 200,
            "temperature": 0.9
        ]

        let data = try await performRequest(
            url: "https://api.openai.com/v1/chat/completions",
            apiKey: apiKey,
            body: body
        )

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
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

enum OpenAIError: Error, LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case rateLimited
    case serverError(Int)
    case httpError(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "OpenAI API key not configured"
        case .invalidAPIKey: return "OpenAI API key is invalid"
        case .rateLimited: return "OpenAI rate limit exceeded"
        case .serverError(let code): return "OpenAI server error (\(code))"
        case .httpError(let code): return "OpenAI HTTP error (\(code))"
        case .invalidResponse: return "Invalid response from OpenAI"
        }
    }
}
