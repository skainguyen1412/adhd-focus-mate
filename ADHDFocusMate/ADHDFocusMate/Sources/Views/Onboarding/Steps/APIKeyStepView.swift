import SwiftData
import SwiftUI

struct APIKeyStepView: View {
    @EnvironmentObject var state: OnboardingState
    @Query private var settings: [AppSettings]

    @State private var connectionStatus: ConnectionStatus = .idle
    @State private var statusMessage: String = ""

    enum ConnectionStatus {
        case idle, testing, success, failure
    }

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "key.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                Text("Gemini API Key")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text(
                    "To power the AI-driven focus analysis, you need a Gemini API key. It's free to get started!"
                )
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 40)
            }

            GlassCard {
                VStack(spacing: 20) {
                    if let appSettings = settings.first {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Your API Key")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Link(
                                    destination: URL(
                                        string: "https://aistudio.google.com/app/apikey")!
                                ) {
                                    HStack(spacing: 4) {
                                        Text("Get Key")
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondary)
                                }
                                .buttonStyle(.plain)
                            }

                            SecureField(
                                "Paste your key here",
                                text: Binding(
                                    get: { appSettings.geminiApiKey ?? "" },
                                    set: { appSettings.geminiApiKey = $0 }
                                )
                            )
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Button(action: {
                                        testConnection(
                                            apiKey: appSettings.geminiApiKey ?? "",
                                            model: appSettings.geminiModel
                                        )
                                    }) {
                                        HStack {
                                            if connectionStatus == .testing {
                                                ProgressView()
                                                    .scaleEffect(0.5)
                                                    .frame(width: 16, height: 16)
                                            } else {
                                                Image(systemName: "network")
                                            }
                                            Text("Test Connection")
                                        }
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(
                                        connectionStatus == .testing
                                            || (appSettings.geminiApiKey ?? "").isEmpty)

                                    Spacer()
                                }

                                if connectionStatus != .idle {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(
                                            systemName: connectionStatus == .success
                                                ? "checkmark.circle.fill"
                                                : "exclamationmark.circle.fill"
                                        )
                                        .foregroundColor(
                                            connectionStatus == .success ? .green : .red)

                                        Text(statusMessage)
                                            .font(.caption)
                                            .foregroundColor(
                                                connectionStatus == .success ? .green : .red
                                            )
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .transition(.opacity)
                                }
                            }
                            .padding(.top, 4)
                        }
                    } else {
                        Text("Loading settings...")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()
            }
            .padding(.horizontal, 40)

            Text(
                "Your API key is stored only on this device and used to communicate directly with Google's Gemini API."
            )
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundColor(.white.opacity(0.5))
            .padding(.horizontal, 60)
        }
    }

    private func testConnection(apiKey: String, model: String) {
        guard !apiKey.isEmpty else { return }

        connectionStatus = .testing
        statusMessage = "Connecting..."

        Task {
            do {
                let service = GeminiService()
                let success = try await service.validateKey(apiKey, model: model)

                await MainActor.run {
                    if success {
                        connectionStatus = .success
                        statusMessage = "Connection successful!"
                    } else {
                        connectionStatus = .failure
                        statusMessage = "Verification failed"
                    }
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .failure
                    statusMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: AppSettings.self, configurations: config)
    container.mainContext.insert(AppSettings())

    return ZStack {
        AppTheme.zenBackground
        APIKeyStepView()
            .environmentObject(OnboardingState())
            .modelContainer(container)
    }
}
