import SwiftUI
import Combine

struct AISetupView: View {
    @StateObject private var ollamaManager = OllamaManager.shared
    
    // Timer to auto-check status
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 60))
                .foregroundStyle(statusColor)
                .symbolEffect(.pulse, isActive: ollamaManager.pullProgress > 0 && ollamaManager.pullProgress < 1.0)
            
            Text("AI Engine Setup")
                .font(.title)
                .bold()
            
            VStack(spacing: 8) {
                Text(ollamaManager.currentStatus)
                    .font(.headline)
                    .foregroundStyle(statusColor)
                
                if ollamaManager.isServerRunning && !ollamaManager.isModelInstalled {
                    Text("We need to download a small brain model (2.0 GB) to process your data locally.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }
            }
            
            // Interaction Area
            if !ollamaManager.isServerRunning {
                // Case 1: Ollama Missing
                VStack(spacing: 12) {
                    Text("WatchYourDay runs 100% locally using Ollama.")
                        .foregroundStyle(.secondary)
                    
                    Button("Download Ollama") {
                        ollamaManager.openDownloadPage()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Retry Connection") {
                        Task { await ollamaManager.checkStatus() }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            } else if !ollamaManager.isModelInstalled {
                // Case 2: Ollama Ready, Model Missing
                VStack(spacing: 15) {
                    if ollamaManager.pullProgress > 0 {
                        VStack {
                            ProgressView(value: ollamaManager.pullProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 200)
                            Text("\(Int(ollamaManager.pullProgress * 100))%")
                                .font(.caption)
                        }
                    } else {
                        Button("Initialize Brain") {
                            Task { await ollamaManager.pullModel() }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.purple)
                    }
                }
            } else {
                // Case 3: Ready
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("System is Intelligent")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding()
        .onReceive(timer) { _ in
            if !ollamaManager.isModelInstalled {
                Task { await ollamaManager.checkStatus() }
            }
        }
    }
    
    var statusColor: Color {
        if ollamaManager.isModelInstalled { return .green }
        if ollamaManager.isServerRunning { return .purple }
        return .orange
    }
}
