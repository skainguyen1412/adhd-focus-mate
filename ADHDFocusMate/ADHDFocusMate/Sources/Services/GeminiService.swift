import AppKit
import Foundation

/// Service for interacting with Google's Gemini API directly via REST
public actor GeminiService {

    public init() {}

    // MARK: - Validation

    /// Validates the API key by making a minimal request
    public func validateKey(
        _ apiKey: String, model: String = "gemini-2.5-flash-lite", apiProvider: String = "aiStudio"
    ) async throws
        -> Bool
    {
        guard let url = makeURL(model: model, apiKey: apiKey, provider: apiProvider) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any]
        if apiProvider == "vertexAI" {
            // Vertex AI via API Key seems to prefer/accept this simplified object structure
            body = [
                "contents": [
                    "role": "user",
                    "parts": [
                        "text": "Test"
                    ],
                ],
                "generationConfig": [
                    "maxOutputTokens": 1
                ],
            ]
        } else {
            // Standard AI Studio Structure
            body = [
                "contents": [
                    [
                        "parts": [
                            ["text": "Test"]
                        ]
                    ]
                ],
                "generationConfig": [
                    "maxOutputTokens": 1
                ],
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            await LogService.shared.log(
                level: .error,
                source: .gemini,
                message: "Network request failed during validation",
                details:
                    "Error: \(error.localizedDescription)\n\nRequest: \(getRequestBodyString(request: request))"
            )
            throw error
        }

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                return true
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                await LogService.shared.log(
                    level: .error,
                    source: .gemini,
                    message: "Key Validation Failed (Status \(httpResponse.statusCode))",
                    details:
                        "Error: \(errorText)\n\nRequest: \(getRequestBodyString(request: request))"
                )
                throw NSError(
                    domain: "GeminiAPIError", code: httpResponse.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "API Error (\(httpResponse.statusCode)): \(errorText)"
                    ])
            }
        }

        return false
    }

    // MARK: - Classification

    /// Classifies an image data using the Gemini API
    public func classify(
        imageData: Data, apiKey: String, model: String = "gemini-2.5-flash-lite",
        apiProvider: String = "aiStudio", systemPrompt: String
    ) async throws
        -> String
    {
        // Note: You can make model dynamic later if needed

        guard let url = makeURL(model: model, apiKey: apiKey, provider: apiProvider) else {
            throw URLError(.badURL)
        }

        let base64Image = imageData.base64EncodedString()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any]

        if apiProvider == "vertexAI" {
            body = [
                "systemInstruction": [
                    "parts": [
                        "text": systemPrompt
                    ]
                ],
                "contents": [
                    "role": "user",
                    "parts": [
                        [
                            "inlineData": [
                                "mimeType": "image/jpeg",
                                "data": base64Image,
                            ]
                        ],
                        ["text": "Classify this screenshot. Respond with JSON only."],
                    ],
                ],
                "generationConfig": [
                    "temperature": 0.1,
                    "responseMimeType": "application/json",
                ],
            ]
        } else {
            body = [
                "systemInstruction": [
                    "parts": [
                        ["text": systemPrompt]
                    ]
                ],
                "contents": [
                    [
                        "role": "user",
                        "parts": [
                            [
                                "inlineData": [
                                    "mimeType": "image/jpeg",
                                    "data": base64Image,
                                ]
                            ],
                            ["text": "Classify this screenshot. Respond with JSON only."],
                        ],
                    ]
                ],
                "generationConfig": [
                    "temperature": 0.1,
                    "responseMimeType": "application/json",
                ],
            ]
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)

        print("🤖 [GeminiService] Sending REST request via upload task...")
        let (data, response): (Data, URLResponse)
        do {
            // Use upload task instead of data task to stream the body properly
            (data, response) = try await URLSession.shared.upload(for: request, from: bodyData)
        } catch {
            await LogService.shared.log(
                level: .error,
                source: .gemini,
                message: "Network request failed during classification",
                details:
                    "Error: \(error.localizedDescription)\n\nBody Size: \(bodyData.count) bytes\n\nRequest Body (truncated):\n\(getBodyString(from: bodyData))"
            )
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            await LogService.shared.log(
                level: .error,
                source: .gemini,
                message: "API Error (Status \(httpResponse.statusCode))",
                details: "Error: \(errorText)\n\nRequest: \(getRequestBodyString(request: request))"
            )
            throw NSError(
                domain: "GeminiAPIError", code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorText)"])
        }

        // Parse Response
        guard let jsonStart = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = jsonStart["candidates"] as? [[String: Any]],
            let firstCandidate = candidates.first,
            let content = firstCandidate["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let firstPart = parts.first,
            let text = firstPart["text"] as? String
        else {
            let rawResponse = String(data: data, encoding: .utf8) ?? "nil"
            await LogService.shared.log(
                level: .error,
                source: .gemini,
                message: "Invalid Response Format",
                details: "Raw: \(rawResponse)\n\nRequest: \(getRequestBodyString(request: request))"
            )
            throw NSError(
                domain: "ParsingError", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response"])
        }

        return text
    }

    // MARK: - Generate Content

    /// Generates content from a text prompt using the Gemini API
    public func generateContent(
        prompt: String, apiKey: String, model: String = "gemini-2.5-flash-lite",
        apiProvider: String = "aiStudio",
        systemPrompt: String? = nil
    ) async throws -> String {
        guard let url = makeURL(model: model, apiKey: apiKey, provider: apiProvider) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any]

        if apiProvider == "vertexAI" {
            body = [
                "contents": [
                    "role": "user",
                    "parts": [
                        "text": prompt
                    ],
                ],
                "generationConfig": [
                    "temperature": 0.7
                ],
            ]
            if let systemPrompt = systemPrompt {
                body["systemInstruction"] = [
                    "parts": [
                        "text": systemPrompt
                    ]
                ]
            }
        } else {
            body = [
                "contents": [
                    [
                        "role": "user",
                        "parts": [["text": prompt]],
                    ]
                ],
                "generationConfig": [
                    "temperature": 0.7
                ],
            ]
            if let systemPrompt = systemPrompt {
                body["systemInstruction"] = [
                    "parts": [
                        ["text": systemPrompt]
                    ]
                ]
            }
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🤖 [GeminiService] Sending Text Generation request...")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            await LogService.shared.log(
                level: .error,
                source: .gemini,
                message: "Network request failed during generation",
                details:
                    "Error: \(error.localizedDescription)\n\nRequest: \(getRequestBodyString(request: request))"
            )
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            await LogService.shared.log(
                level: .error,
                source: .gemini,
                message: "API Error (Status \(httpResponse.statusCode))",
                details: "Error: \(errorText)\n\nRequest: \(getRequestBodyString(request: request))"
            )
            throw NSError(
                domain: "GeminiAPIError", code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorText)"])
        }

        // Parse Response
        guard let jsonStart = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = jsonStart["candidates"] as? [[String: Any]],
            let firstCandidate = candidates.first,
            let content = firstCandidate["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let firstPart = parts.first,
            let text = firstPart["text"] as? String
        else {
            let rawResponse = String(data: data, encoding: .utf8) ?? "nil"
            await LogService.shared.log(
                level: .error,
                source: .gemini,
                message: "Invalid Response Format",
                details: "Raw: \(rawResponse)\n\nRequest: \(getRequestBodyString(request: request))"
            )
            throw NSError(
                domain: "ParsingError", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response"])
        }

        return text
    }

    // MARK: - Private Helpers

    private func makeURL(model: String, apiKey: String, provider: String) -> URL? {
        if provider == "vertexAI" {
            // Vertex AI Endpoint
            let urlString =
                "https://aiplatform.googleapis.com/v1/publishers/google/models/\(model):generateContent?key=\(apiKey)"
            return URL(string: urlString)
        } else {
            // AI Studio Endpoint (Default)
            let urlString =
                "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
            return URL(string: urlString)
        }
    }

    private func getRequestBodyString(request: URLRequest) -> String {
        guard let body = request.httpBody else { return "No body captured" }
        return getBodyString(from: body)
    }

    private func getBodyString(from data: Data) -> String {
        let fullString = String(data: data, encoding: .utf8) ?? "Binary content"

        // Truncate if it's too long (base64 images make strings massive)
        if fullString.count > 2000 {
            return String(fullString.prefix(1000))
                + "\n\n... [TRUNCATED \(fullString.count - 1500) chars] ...\n\n"
                + String(fullString.suffix(500))
        }
        return fullString
    }
}
