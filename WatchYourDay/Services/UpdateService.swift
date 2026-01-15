import Foundation
import SwiftUI
import Combine

struct ReleaseInfo: Decodable {
    let tagName: String
    let body: String
    let htmlUrl: String
    let assets: [ReleaseAsset]
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case htmlUrl = "html_url"
        case assets
    }
}

struct ReleaseAsset: Decodable {
    let name: String
    let browserDownloadUrl: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
    }
}

@MainActor
class UpdateService: ObservableObject {
    static let shared = UpdateService()
    
    @Published var isUpdateAvailable: Bool = false
    @Published var latestRelease: ReleaseInfo?
    @Published var errorMessage: String?
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    
    private let repoOwner = "senoldogann"
    private let repoName = "WatchYourDay"
    
    private init() {}
    
    func checkForUpdates() async {
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                WDLogger.error("Update Check: Failed with status invalid", category: .network)
                return
            }
            
            let release = try JSONDecoder().decode(ReleaseInfo.self, from: data)
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            
            if isNewer(remote: release.tagName, current: currentVersion) {
                print("Update Available: \(release.tagName)")
                self.latestRelease = release
                self.isUpdateAvailable = true
            } else {
                print("App is up to date.")
                self.isUpdateAvailable = false
            }
            
        } catch {
            WDLogger.error("Update Check Failed: \(error.localizedDescription)", category: .network)
            self.errorMessage = error.localizedDescription
        }
    }
    
    func downloadAndInstallUpdate() async {
        guard let release = latestRelease else { return }
        
        // Find the asset (assume generic .zip or matching app name)
        // Prefer assets containing "WatchYourDay" and ending in ".zip"
        guard let asset = release.assets.first(where: { $0.name.hasSuffix(".zip") }) else {
            self.errorMessage = "No compatible update file found (looking for .zip)."
            return
        }
        
        guard let url = URL(string: asset.browserDownloadUrl) else { return }
        
        self.isDownloading = true
        self.downloadProgress = 0.1
        
        do {
            let (localURL, _) = try await URLSession.shared.download(from: url)
            self.downloadProgress = 0.5
            try installUpdate(from: localURL)
        } catch {
            self.errorMessage = "Update Failed: \(error.localizedDescription)"
            self.isDownloading = false
        }
    }
    
    private func installUpdate(from zipURL: URL) throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // 1. Unzip
        let unzipProcess = Process()
        unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzipProcess.arguments = ["-o", zipURL.path, "-d", tempDir.path]
        try unzipProcess.run()
        unzipProcess.waitUntilExit()
        
        self.downloadProgress = 0.8
        
        // 2. Find .app
        let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        guard let newAppURL = contents.first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "UpdateService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find .app in update zip."])
        }
        
        // 3. Prepare Swap Script
        let currentAppURL = Bundle.main.bundleURL
        let scriptURL = tempDir.appendingPathComponent("update_script.sh")
        
        let script = """
        #!/bin/bash
        # Wait for parent process to exit
        sleep 2
        
        echo "Replacing \(currentAppURL.path)"
        
        # Remove old app and Move new app
        rm -rf "\(currentAppURL.path)"
        mv "\(newAppURL.path)" "\(currentAppURL.path)"
        
        # Open new app
        open "\(currentAppURL.path)"
        """
        
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        
        self.downloadProgress = 1.0
        
        // 4. Run Script and Terminate
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path]
        try process.run()
        
        NSApp.terminate(nil)
    }
    
    private func isNewer(remote: String, current: String) -> Bool {
        let cleanRemote = remote.replacingOccurrences(of: "v", with: "")
        let cleanCurrent = current.replacingOccurrences(of: "v", with: "")
        
        return cleanRemote.compare(cleanCurrent, options: .numeric) == .orderedDescending
    }
}
