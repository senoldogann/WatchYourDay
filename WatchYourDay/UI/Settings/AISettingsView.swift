import SwiftUI

struct AISettingsView: View {
    @ObservedObject var theme = ThemeManager.shared
    @AppStorage("aiProvider") private var aiProvider = "Local (Ollama)"
    @AppStorage("localModelName") private var localModelName = "llama3"
    @AppStorage("cloudModelName") private var cloudModelName = "gpt-4o-mini"
    
    @AppStorage("localBaseURL") private var localBaseURL = "http://localhost:11434"
    @AppStorage("cloudBaseURL") private var cloudBaseURL = "https://api.openai.com"
    
    private var isLocalProvider: Bool { aiProvider == "Local (Ollama)" }
    
    private var activeBaseURL: Binding<String> {
        isLocalProvider ? $localBaseURL : $cloudBaseURL
    }
    
    private var activeModelName: Binding<String> {
        isLocalProvider ? $localModelName : $cloudModelName
    }
    
    @State private var apiKeyInput: String = ""
    @State private var isKeySaved: Bool = false
    @State private var isTestingConnection: Bool = false
    @State private var showingTestResult: Bool = false
    @State private var testResultMessage: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(Color.claudeAccent)
                Text("INTELLIGENCE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            HStack(spacing: 0) {
                ForEach(["Local (Ollama)", "Cloud (OpenAI)"], id: \.self) { provider in
                    Button(action: { 
                        withAnimation { aiProvider = provider }
                    }) {
                        Text(provider)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(aiProvider == provider ? Color.claudeAccent : Color.clear)
                            .foregroundStyle(aiProvider == provider ? Color.white : Color.claudeTextPrimary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.claudeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            Group {
                LabeledContent("Base URL") {
                    TextField("URL", text: activeBaseURL)
                        .textFieldStyle(.roundedBorder)
                }
                
                LabeledContent("Model Name") {
                    TextField("Model", text: activeModelName)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            if !isLocalProvider {
                SecureField("API Key", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: apiKeyInput) { _, newValue in
                        if !newValue.isEmpty {
                            Task { @MainActor in
                                try? KeychainManager.saveString(key: "cloudAPIKey", value: newValue)
                                isKeySaved = true
                            }
                        }
                    }
                
                if isKeySaved {
                    Text("API Key Saved")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            Button(action: testConnection) {
                HStack {
                    if isTestingConnection {
                        ProgressView().controlSize(.small)
                    }
                    Text("Test Connection")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.claudeAccent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(isTestingConnection)
            
            if showingTestResult {
                Text(testResultMessage)
                    .font(.caption)
                    .foregroundStyle(testResultMessage.contains("✓") ? .green : .red)
            }
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { loadAPIKey() }
    }
    
    private func loadAPIKey() {
        Task { @MainActor in
            if let savedKey = KeychainManager.loadString(key: "cloudAPIKey") {
                apiKeyInput = savedKey
                isKeySaved = true
            }
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        showingTestResult = false
        
        // Capture current state to avoid race conditions
        let isLocal = isLocalProvider
        let baseURL = isLocal ? localBaseURL : cloudBaseURL
        let apiKey = apiKeyInput
        let modelName = isLocal ? localModelName : cloudModelName
        
        Task {
            do {
                // Basic validation
                guard !baseURL.isEmpty else { throw ConnectionError.invalidURL("URL cannot be empty") }
                if !isLocal && apiKey.isEmpty { throw ConnectionError.missingAPIKey }
                
                // Real connection test logic similar to original SettingsView
                let testURL = isLocal ? "\(baseURL)/api/generate" : "\(baseURL)/v1/chat/completions"
                guard let url = URL(string: testURL) else { throw ConnectionError.invalidURL("Malformed URL") }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if !isLocal {
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                }
                
                // Minimal payload
                let payload: [String: Any] = isLocal 
                    ? ["model": modelName, "prompt": "Hi", "stream": false]
                    : ["model": modelName, "messages": [["role": "user", "content": "Hi"]], "max_tokens": 1]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                request.timeoutInterval = 10
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw ConnectionError.invalidResponse
                }
                
                await MainActor.run {
                    testResultMessage = "✓ Connection Successful"
                    showingTestResult = true
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    testResultMessage = "✗ Connection Failed: \(error.localizedDescription)"
                    showingTestResult = true
                    isTestingConnection = false
                }
            }
        }
    }
}

// Helper for Connection Errors (Copied from SettingsView)
private enum ConnectionError: Error, LocalizedError {
    case invalidURL(String)
    case missingAPIKey
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let s): return "Invalid URL: \(s)"
        case .missingAPIKey: return "Missing API Key"
        case .invalidResponse: return "Invalid server response"
        }
    }
}
