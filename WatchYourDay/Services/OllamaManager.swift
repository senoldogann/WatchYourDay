import Foundation
import Combine
import AppKit

struct OllamaModel: Decodable {
    let name: String
    let modified_at: String
    let size: Int64
}

struct OllamaModelList: Decodable {
    let models: [OllamaModel]
}

struct OllamaProgress: Decodable {
    let status: String
    let completed: Int64?
    let total: Int64?
}

@MainActor
class OllamaManager: ObservableObject {
    static let shared = OllamaManager()
    
    @Published var isServerRunning = false
    @Published var isModelInstalled = false
    @Published var pullProgress: Double = 0.0
    @Published var currentStatus: String = "Checking..."
    
    // Config
    // Using a small, fast model for the 'Brain'.
    // llama3.2 is excellent and efficient.
    // qwen2.5-coder is better for code, but llama is better for general summarization.
    let targetModel = "llama3.2" 
    
    private let baseURL = URL(string: "http://localhost:11434")!
    
    private init() {
        Task { await checkStatus() }
    }
    
    func checkStatus() async {
        // 1. Check Server
        do {
            var request = URLRequest(url: baseURL)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 2.0 // Fast check
            
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                self.isServerRunning = true
                await checkModel()
            } else {
                self.isServerRunning = false
                self.currentStatus = "Ollama not found"
            }
        } catch {
            self.isServerRunning = false
            self.currentStatus = "Ollama not running"
        }
    }
    
    private func checkModel() async {
        guard isServerRunning else { return }
        
        let url = baseURL.appendingPathComponent("api/tags")
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let list = try JSONDecoder().decode(OllamaModelList.self, from: data)
            
            // Flexible match (e.g. "llama3.2:latest" matches "llama3.2")
            if list.models.contains(where: { $0.name.contains(targetModel) }) {
                self.isModelInstalled = true
                self.currentStatus = "AI Ready"
            } else {
                self.isModelInstalled = false
                self.currentStatus = "Brain Update Required"
            }
        } catch {
            print("Failed to list models: \(error)")
            self.isModelInstalled = false
        }
    }
    
    func pullModel() async {
        guard isServerRunning else { return }
        
        self.currentStatus = "Initializing Brain..."
        let url = baseURL.appendingPathComponent("api/pull")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = ["name": targetModel, "stream": true] as [String : Any]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // Streaming Request
        do {
            let (result, _) = try await URLSession.shared.bytes(for: request)
            
            for try await byte in result.lines {
                if let data = byte.data(using: .utf8),
                   let progress = try? JSONDecoder().decode(OllamaProgress.self, from: data) {
                    
                    self.currentStatus = progress.status
                    
                    if let completed = progress.completed, let total = progress.total, total > 0 {
                        self.pullProgress = Double(completed) / Double(total)
                    }
                    
                    if progress.status == "success" {
                        self.isModelInstalled = true
                        self.currentStatus = "AI Ready"
                    }
                }
            }
        } catch {
            self.currentStatus = "Error: \(error.localizedDescription)"
        }
    }
    
    func openDownloadPage() {
        if let url = URL(string: "https://ollama.com/download") {
            NSWorkspace.shared.open(url)
        }
    }
}
