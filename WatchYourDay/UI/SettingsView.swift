import SwiftUI
import SwiftData
import AppKit
import Charts

struct SettingsView: View {
    // General AI Settings
    @AppStorage("aiProvider") private var aiProvider = "Local (Ollama)"
    @AppStorage("localModelName") private var localModelName = "llama3"
    @AppStorage("cloudModelName") private var cloudModelName = "gpt-4o-mini"
    
    // Separate URL Storage
    @AppStorage("localBaseURL") private var localBaseURL = "http://localhost:11434"
    @AppStorage("cloudBaseURL") private var cloudBaseURL = "https://api.openai.com"
    
    // Computed properties for active settings
    private var isLocalProvider: Bool { aiProvider == "Local (Ollama)" }
    private var activeBaseURL: Binding<String> {
        isLocalProvider ? $localBaseURL : $cloudBaseURL
    }
    private var activeModelName: Binding<String> {
        isLocalProvider ? $localModelName : $cloudModelName
    }
    
    // Cloud Settings
    @State private var apiKeyInput: String = ""
    @State private var isKeySaved: Bool = false
    @State private var showingTestResult = false
    @State private var testResultMessage = ""
    @State private var isTestingConnection = false
    
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var launchManager = LaunchManager.shared
    @ObservedObject var blacklistManager = BlacklistManager.shared
    @State private var newBlacklistApp: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // System Settings
                systemCard
                
                // Privacy / Blacklist (New)
                privacyCard
                
                // AI Provider Card
                // ...
                aiProviderCard
                
                // Configuration Card
                configurationCard
                
                // Export Section
                exportCard

                // Storage Card
                storageCard
                
                // About Card
                aboutCard
            }
            .padding()
        }
        .background(Color.claudeBackground)
        .onAppear { loadAPIKey() }
    }
    
    // MARK: - System Card
    private var systemCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "macwindow")
                    .foregroundStyle(Color.claudeAccent)
                Text("SYSTEM")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            Toggle(isOn: Binding(
                get: { launchManager.isEnabled },
                set: { try? launchManager.configureLaunchAtLogin(enabled: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Launch at Login")
                        .font(.subheadline)
                        .foregroundStyle(Color.claudeTextPrimary)
                    Text("Automatically start WatchYourDay when you log in.")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
            }
            .toggleStyle(.switch)
            .tint(Color.claudeAccent)
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // ... [Header omitted] ...
    
    // MARK: - Export Card
    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(Color.claudeAccent)
                Text("DATA EXPORT")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            Text("Generate reports of your activity.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button(action: exportCSV) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Export CSV")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.claudeAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                
                Button(action: exportPDF) {
                    HStack {
                        Image(systemName: "doc.richtext")
                        Text("Export PDF")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.claudeAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                
                Button(action: exportMarkdown) {
                    HStack {
                        Image(systemName: "doc.plaintext")
                        Text("Export MD")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.claudeAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
            }
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Storage Card
    // ... [Storage Card omitted] ...

    // ... [Rest of file] ...


    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.claudeAccent, Color.claudeSecondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Settings")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.claudeTextPrimary)
            
            Text("Configure your WatchYourDay experience")
                .font(.subheadline)
                .foregroundStyle(Color.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // MARK: - Privacy Card
    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(Color.claudeAccent)
                Text("PRIVACY & BLACKLIST")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            Text("Apps listed here will NOT be recorded.")
                .font(.caption)
                .foregroundStyle(Color.gray)
            
            // Input
            HStack {
                TextField("App Name (e.g. Safari)", text: $newBlacklistApp)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color.claudeTextPrimary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit {
                        withAnimation {
                            blacklistManager.addApp(newBlacklistApp)
                            newBlacklistApp = ""
                        }
                    }
                
                Button(action: {
                    withAnimation {
                        blacklistManager.addApp(newBlacklistApp)
                        newBlacklistApp = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.claudeAccent)
                }
                .buttonStyle(.plain)
                .disabled(newBlacklistApp.isEmpty)
            }
            
            // List
            if !blacklistManager.blockedApps.isEmpty {
                VStack(spacing: 8) {
                    ForEach(blacklistManager.blockedApps, id: \.self) { app in
                        HStack {
                            Text(app)
                                .font(.subheadline)
                                .foregroundStyle(Color.claudeTextPrimary)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    blacklistManager.removeApp(app)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            } else {
                Text("No apps blacklisted.")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(Color.gray.opacity(0.5))
            }
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - AI Provider Card
    private var aiProviderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundStyle(Color.claudeAccent)
                Text("AI PROVIDER")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            HStack(spacing: 12) {
                ProviderButton(
                    title: "Local",
                    subtitle: "Ollama",
                    icon: "desktopcomputer",
                    isSelected: aiProvider == "Local (Ollama)",
                    onTap: { aiProvider = "Local (Ollama)" }
                )
                
                ProviderButton(
                    title: "Cloud",
                    subtitle: "OpenAI / Custom",
                    icon: "cloud.fill",
                    isSelected: aiProvider == "Cloud (OpenAI, Ollama)",
                    onTap: { aiProvider = "Cloud (OpenAI, Ollama)" }
                )
            }
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Configuration Card
    private var configurationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Color.claudeAccent)
                Text(aiProvider == "Local (Ollama)" ? "LOCAL CONFIGURATION" : "CLOUD CONFIGURATION")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            // Model Name
            SettingsTextField(
                label: "Model Name",
                placeholder: isLocalProvider ? "e.g. llama3, mistral" : "e.g. gpt-4o-mini, claude-3",
                text: activeModelName,
                icon: "brain.head.profile"
            )
            
            // Base URL
            SettingsTextField(
                label: "Base URL",
                placeholder: isLocalProvider ? "http://localhost:11434" : "https://api.openai.com",
                text: activeBaseURL,
                icon: "link"
            )
            
            // API Key (Cloud only)
            if aiProvider != "Local (Ollama)" {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(Color.claudeAccent)
                            .frame(width: 20)
                        Text("API Key")
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                    }
                    
                    HStack {
                        SecureField("sk-...", text: $apiKeyInput)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.claudeTextPrimary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onChange(of: apiKeyInput) { _, newValue in
                                if !newValue.isEmpty {
                                    Task { @MainActor in
                                        try? KeychainManager.saveString(key: "cloudAPIKey", value: newValue)
                                        isKeySaved = true
                                    }
                                }
                            }
                        
                        if isKeySaved {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            
            // Test Connection Button
            Button(action: testConnection) {
                HStack {
                    if isTestingConnection {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                    Text("Test Connection")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.claudeAccent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(isTestingConnection)
            .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
            
            if showingTestResult {
                HStack {
                    Image(systemName: testResultMessage.contains("✓") ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(testResultMessage.contains("✓") ? .green : .red)
                    Text(testResultMessage)
                        .font(.caption)
                        .foregroundStyle(testResultMessage.contains("✓") ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Storage Card
    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundStyle(Color.claudeAccent)
                Text("STORAGE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Snapshot Storage")
                        .font(.subheadline)
                        .foregroundStyle(Color.claudeTextPrimary)
                    Text("Screenshots are stored locally in Application Support")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
                
                Spacer()
                
                Button(action: openStorageFolder) {
                    Image(systemName: "folder.fill")
                        .font(.title3)
                        .foregroundStyle(Color.claudeAccent)
                }
                .buttonStyle(.plain)
                .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
            }
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - About Card
    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.claudeAccent)
                Text("ABOUT")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WatchYourDay")
                        .font(.headline)
                        .foregroundStyle(Color.claudeTextPrimary)
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
                
                Spacer()
                
                Image(systemName: "eye.fill")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.claudeAccent, Color.claudeSecondaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("AI-powered screen time tracking with smart categorization and productivity insights.")
                .font(.caption)
                .foregroundStyle(Color.gray)
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Actions
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
        
        WDLogger.debug("Provider: \(isLocal ? "Local" : "Cloud"), URL: \(baseURL), Model: \(modelName)", category: .ai)
        
        Task {
            do {
                // Validate URL format
                guard !baseURL.isEmpty else {
                    throw ConnectionError.invalidURL("URL cannot be empty")
                }
                
                // For cloud, require API key with minimum length
                if !isLocal {
                    guard !apiKey.isEmpty else {
                        throw ConnectionError.missingAPIKey
                    }
                    guard apiKey.count >= 20 else {
                        throw ConnectionError.invalidURL("API key is too short. Please enter a valid API key.")
                    }
                }
                
                // Build test request based on provider
                let testURL: String
                var request: URLRequest
                
                if isLocal {
                    // Ollama: Use /api/generate to validate model exists
                    testURL = "\(baseURL)/api/generate"
                    guard let url = URL(string: testURL) else {
                        throw ConnectionError.invalidURL("Malformed URL: \(testURL)")
                    }
                    request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Minimal test payload with actual model name
                    let testPayload: [String: Any] = [
                        "model": modelName,
                        "prompt": "Hi",
                        "stream": false
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: testPayload)
                } else {
                    // Cloud: Make a real chat completion request to validate API key
                    testURL = "\(baseURL)/v1/chat/completions"
                    guard let url = URL(string: testURL) else {
                        throw ConnectionError.invalidURL("Malformed URL: \(testURL)")
                    }
                    request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Minimal test payload
                    let testPayload: [String: Any] = [
                        "model": modelName,
                        "messages": [["role": "user", "content": "Hi"]],
                        "max_tokens": 1
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: testPayload)
                }
                
                request.timeoutInterval = 30
                WDLogger.debug("Testing: \(testURL) with model: \(modelName)", category: .ai)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ConnectionError.invalidResponse
                }
                
                // Check Content-Type header
                let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
                WDLogger.debug("Status: \(httpResponse.statusCode), Content-Type: \(contentType)", category: .ai)
                
                // Must be application/json for valid API
                guard contentType.contains("application/json") else {
                    throw ConnectionError.invalidURL("Not a valid API endpoint (received HTML instead of JSON)")
                }
                
                // Handle specific status codes
                switch httpResponse.statusCode {
                case 200:
                    // Validate JSON structure
                    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        throw ConnectionError.invalidResponse
                    }
                    
                    if isLocal {
                        // Ollama generate returns {"response": "..."}
                        if json["response"] != nil {
                            showSuccess("Ollama connected! Model '\(modelName)' is available.")
                        } else if let errorMsg = json["error"] as? String {
                            throw ConnectionError.invalidURL(errorMsg)
                        } else {
                            throw ConnectionError.invalidResponse
                        }
                    } else {
                        // OpenAI-compatible returns {"id": "...", "choices": [...]}
                        if json["id"] != nil || json["choices"] != nil {
                            showSuccess("API key is valid! Connection successful.")
                        } else if let error = json["error"] as? [String: Any] {
                            let message = error["message"] as? String ?? "Unknown API error"
                            throw ConnectionError.invalidURL(message)
                        } else {
                            showSuccess("Connection successful!")
                        }
                    }
                case 401:
                    throw ConnectionError.unauthorized
                case 403:
                    throw ConnectionError.forbidden
                case 404:
                    throw ConnectionError.notFound(isLocal ? "Ollama API not found. Is Ollama running?" : "API endpoint not found. Check your Base URL.")
                case 429:
                    throw ConnectionError.rateLimited
                case 500...599:
                    throw ConnectionError.serverError(httpResponse.statusCode)
                default:
                    // Try to parse error from response
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw ConnectionError.invalidURL(message)
                    }
                    throw ConnectionError.httpError(httpResponse.statusCode)
                }
                
            } catch let error as ConnectionError {
                WDLogger.error("ConnectionError: \(error.message)", category: .ai)
                showError(error.message)
            } catch let urlError as URLError {
                WDLogger.error("URLError: \(urlError.code) - \(urlError.localizedDescription)", category: .ai)
                switch urlError.code {
                case .notConnectedToInternet:
                    showError("No internet connection")
                case .timedOut:
                    showError("Connection timed out. Is the server running?")
                case .cannotConnectToHost:
                    showError("Cannot connect to host. Check if \(isLocal ? "Ollama" : "the API server") is running.")
                default:
                    showError("Network error: \(urlError.localizedDescription)")
                }
            } catch {
                WDLogger.error("Unexpected: \(error)", category: .ai)
                showError("Unexpected error: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    private func showSuccess(_ message: String) {
        testResultMessage = "✓ \(message)"
        showingTestResult = true
        isTestingConnection = false
    }
    
    @MainActor
    private func showError(_ message: String) {
        testResultMessage = "✗ \(message)"
        showingTestResult = true
        isTestingConnection = false
    }
    
    private func openStorageFolder() {
        let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("WatchYourDay/Snapshots")
        NSWorkspace.shared.open(path)
    }
    
    // MARK: - Export Actions
    private func exportCSV() {
        // Simple export of ALL snapshots for now, or today's. 
        // For MVP, let's export TODAY's data for CSV or report content.
        // Actually, CSV usually implies raw data.
        Task {
            // Fetch snapshots via PersistenceController (MainActor)
            // Fetch snapshots via PersistenceController (MainActor)
            let context = PersistenceController.shared.container.mainContext
            
            // Limit to last 30 days to avoid Out Of Memory crashes
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
            let predicate = #Predicate<Snapshot> { $0.timestamp > cutoff }
            
            let descriptor = FetchDescriptor<Snapshot>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            if let snapshots = try? context.fetch(descriptor) {
                if let url = try? await ExportService.shared.generateCSV(for: snapshots) {
                     NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    private func exportPDF() {
        Task {
            // Generate report for TODAY
            let today = Date()
            if let report = await ReportManager.shared.generatePeriodicReport(force: true) {
                 if let url = await ExportService.shared.generatePDF(from: report) {
                     NSWorkspace.shared.open(url)
                 }
            } else {
                 // Try to fetch existing report?
                 // For now, if no report generation possible (e.g. no data), do nothing or log.
                 WDLogger.info("No report to export", category: .general)
            }
        }
    }

    
    private func exportMarkdown() {
        Task {
            // Generate report for TODAY
            if let report = await ReportManager.shared.generatePeriodicReport(force: true) {
                 if let url = ExportService.shared.generateMarkdown(from: report) {
                     NSWorkspace.shared.open(url)
                 }
            } else {
                 WDLogger.info("No report to export", category: .general)
            }
        }
    }
}

// MARK: - Connection Errors
enum ConnectionError: Error {
    case invalidURL(String)
    case missingAPIKey
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound(String)
    case rateLimited
    case serverError(Int)
    case httpError(Int)
    
    var message: String {
        switch self {
        case .invalidURL(let detail): return "Invalid URL: \(detail)"
        case .missingAPIKey: return "API Key is required for cloud providers"
        case .invalidResponse: return "Invalid server response"
        case .unauthorized: return "Invalid API Key (401 Unauthorized)"
        case .forbidden: return "Access denied (403 Forbidden)"
        case .notFound(let detail): return detail
        case .rateLimited: return "Rate limited (429). Try again later."
        case .serverError(let code): return "Server error (\(code))"
        case .httpError(let code): return "HTTP error (\(code))"
        }
    }
}

// MARK: - Supporting Views

struct ProviderButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.claudeAccent : Color.gray)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isSelected ? Color.claudeTextPrimary : Color.gray)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(Color.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.claudeAccent.opacity(0.15) : Color.claudeTextPrimary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.claudeAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
    }
}

struct SettingsTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.claudeAccent)
                    .frame(width: 20)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.claudeTextPrimary)
                .padding(12)
                .background(Color.claudeTextPrimary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}



