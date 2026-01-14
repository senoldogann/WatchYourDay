import Foundation
import SwiftUI
import Combine

struct ReleaseInfo: Decodable {
    let tagName: String
    let body: String
    let htmlUrl: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case htmlUrl = "html_url"
    }
}

@MainActor
class UpdateService: ObservableObject {
    static let shared = UpdateService()
    
    @Published var isUpdateAvailable: Bool = false
    @Published var latestRelease: ReleaseInfo?
    @Published var errorMessage: String?
    
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
    
    private func isNewer(remote: String, current: String) -> Bool {
        let cleanRemote = remote.replacingOccurrences(of: "v", with: "")
        let cleanCurrent = current.replacingOccurrences(of: "v", with: "")
        
        return cleanRemote.compare(cleanCurrent, options: .numeric) == .orderedDescending
    }
}
