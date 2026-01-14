import Foundation
import SwiftUI
import Combine

/// Manages the list of applications that should remain private (never recorded).
class BlacklistManager: ObservableObject {
    static let shared = BlacklistManager()
    
    @AppStorage("blockedAppsJson") private var blockedAppsJson: String = "[]"
    
    @Published var blockedApps: [String] = []
    
    private let lock = NSLock()
    
    private init() {
        loadBlockedApps()
    }
    
    /// Checks if an app is blacklisted (case insensitive) -> Thread Safe
    func isBlacklisted(appName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return blockedApps.contains { $0.localizedCaseInsensitiveCompare(appName) == .orderedSame }
    }
    
    /// Adds an app to the blacklist -> Thread Safe
    func addApp(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        lock.lock()
        defer { lock.unlock() }
        
        guard !trimmed.isEmpty else { return }
        // Check contains inside lock to verify uniqueness safely
        if !blockedApps.contains(where: { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
            blockedApps.append(trimmed)
            save()
        }
    }
    
    /// Removes an app from the blacklist -> Thread Safe
    func removeApp(_ name: String) {
        lock.lock()
        defer { lock.unlock() }
        
        blockedApps.removeAll { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }
        save()
    }
    
    private func loadBlockedApps() {
        guard let data = blockedAppsJson.data(using: .utf8) else { return }
        if let decoded = try? JSONDecoder().decode([String].self, from: data) {
            blockedApps = decoded
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(blockedApps),
           let json = String(data: data, encoding: .utf8) {
            
            DispatchQueue.main.async { [weak self] in
                self?.blockedAppsJson = json
            }
        }
    }
}
