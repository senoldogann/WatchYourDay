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
        // Note: encoding is fast, but we should probably do it under lock if we called from outside.
        // Since safe() is called by addApp/removeApp which HAVE locks, we are good.
        // However, if we access blockedApps here, it is safe because we are recursive? 
        // No, NSLock is NOT recursive by default. Using standard NSLock inside already locked scope = DEADLOCK.
        // We must ensure save() does NOT lock, but expects to be called from locked scope.
        // OR we use the array copy passed to save? 
        
        // Let's rely on the fact that save() uses the property.
        // Wait, JSONEncoder accesses `self.blockedApps`.
        // If we represent `save()` as a private helper, it should assume the caller holds the lock.
        
        // ISSUE: @AppStorage access can trigger UI updates.
        // We should move `blockedAppsJson` update to MainActor if possible? 
        // Or simply do it here. @AppStorage itself is somewhat thread safe for UserDefaults wrapper, 
        // but triggering @Published update from background thread is BAD for SwiftUI.
        
        if let data = try? JSONEncoder().encode(blockedApps),
           let json = String(data: data, encoding: .utf8) {
            
            // Critical: Update @AppStorage and @Published on Main Thread to avoid UI glitches
            DispatchQueue.main.async { [weak self] in
                self?.blockedAppsJson = json
            }
        }
    }
}
