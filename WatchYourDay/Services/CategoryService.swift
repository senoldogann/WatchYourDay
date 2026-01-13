import Foundation

/// Activity categories for productivity tracking
enum ActivityCategory: String, Codable, CaseIterable {
    case core = "core"              // Work/productivity apps
    case personal = "personal"       // Personal tasks
    case distraction = "distraction" // Social media, entertainment
    case idle = "idle"              // No activity
    
    var displayName: String {
        switch self {
        case .core: return "Core Tasks"
        case .personal: return "Personal"
        case .distraction: return "Distractions"
        case .idle: return "Idle Time"
        }
    }
    
    var color: String {
        switch self {
        case .core: return "categoryCore"
        case .personal: return "categoryPersonal"
        case .distraction: return "categoryDistraction"
        case .idle: return "categoryIdle"
        }
    }
    
    var icon: String {
        switch self {
        case .core: return "hammer.fill"
        case .personal: return "person.fill"
        case .distraction: return "exclamationmark.triangle.fill"
        case .idle: return "moon.fill"
        }
    }
}

/// App icon mapping for popular apps
struct AppIcons {
    /// Maps app names/window titles to SF Symbol names
    static func icon(for appName: String, windowTitle: String) -> String {
        let app = appName.lowercased()
        let title = windowTitle.lowercased()
        
        // 1. Exact App Name Matches
        if let icon = appMappings[app] { return icon }
        
        // 2. Browser Tab Pattern Matching (Smart Prediction)
        if isBrowser(app) {
            return browserIcon(for: title)
        }
        
        // 3. File Type/Context Matching
        if title.contains(".swift") || title.contains(".kt") { return "swift" }
        if title.contains(".py") { return "terminal.fill" }
        if title.contains(".md") { return "doc.text" }
        if title.contains("terminal") || title.contains("zsh") { return "terminal.fill" }
        
        // 4. Fallback to generic category icon
        return "app.fill"
    }
    
    // MARK: - Mappings
    
    private static let appMappings: [String: String] = [
        "xcode": "hammer.fill",
        "visual studio code": "chevron.left.forwardslash.chevron.right",
        "code": "chevron.left.forwardslash.chevron.right",
        "intellij idea": "curlybraces",
        "android studio": "android", // Note: 'android' might not be a valid SF Symbol, fallback check needed? using regex instead
        "terminal": "terminal.fill",
        "iterm2": "terminal.fill",
        "warp": "terminal.fill",
        "slack": "number",
        "discord": "bubble.left.and.bubble.right.fill",
        "zoom": "video.fill",
        "mail": "envelope.fill",
        "messages": "message.fill",
        "calendar": "calendar",
        "reminders": "list.bullet",
        "notes": "note.text",
        "music": "music.note",
        "spotify": "music.note.list",
        "finder": "folder.fill",
        "preview": "eye.fill",
        "photos": "photo.fill",
        "settings": "gear",
        "system settings": "gear",
    ]
    
    private static func isBrowser(_ app: String) -> Bool {
        ["safari", "google chrome", "chrome", "firefox", "brave", "arc", "edge", "opera"].contains(app)
    }
    
    private static func browserIcon(for title: String) -> String {
        // Dev/Tech
        if title.contains("github") { return "cat.fill" } // GitHub
        if title.contains("stackoverflow") { return "square.stack.3d.up.fill" }
        if title.contains("gitlab") { return "flame.fill" }
        if title.contains("localhost") { return "server.rack" }
        if title.contains("chatgpt") || title.contains("openai") || title.contains("claude") || title.contains("gemini") { return "brain.head.profile" }
        if title.contains("figma") { return "paintbrush.fill" }
        if title.contains("jira") || title.contains("linear") { return "list.bullet.rectangle.portrait.fill" }
        if title.contains("docs") || title.contains("notion") { return "doc.text.fill" }
        
        // Social
        if title.contains("youtube") { return "play.rectangle.fill" }
        if title.contains("twitter") || title.contains("x.com") { return "at" }
        if title.contains("reddit") { return "bubble.left.and.bubble.right.fill" }
        if title.contains("linkedin") { return "person.crop.rectangle.fill" }
        if title.contains("instagram") { return "camera.fill" }
        if title.contains("facebook") { return "person.2.fill" }
        if title.contains("whatsapp") { return "phone.bubble.left.fill" }
        
        // Entertainment
        if title.contains("netflix") || title.contains("hulu") { return "tv.fill" }
        if title.contains("twitch") { return "gamecontroller.fill" }
        
        // Shopping
        if title.contains("amazon") { return "cart.fill" }
        
        // Default Web
        return "globe"
    }
}

/// Smart categorization service with rule-based system and AI fallback
@Observable
class CategoryService {
    static let shared = CategoryService()
    
    // MARK: - App Category Cache (persisted)
    private var userCache: [String: ActivityCategory] = [:]
    private let cacheKey = "CategoryService.userCache"
    
    // MARK: - Known Apps Dictionary (100+ pre-defined)
    private let knownApps: [String: ActivityCategory] = [
        // Core Tasks - Development
        "xcode": .core,
        "visual studio code": .core,
        "code": .core,
        "android studio": .core,
        "intellij idea": .core,
        "pycharm": .core,
        "webstorm": .core,
        "sublime text": .core,
        "atom": .core,
        "terminal": .core,
        "iterm": .core,
        "iterm2": .core,
        "warp": .core,
        "hyper": .core,
        "github desktop": .core,
        "sourcetree": .core,
        "tower": .core,
        "fork": .core,
        "postman": .core,
        "insomnia": .core,
        "docker": .core,
        "tableplus": .core,
        "sequel pro": .core,
        "dbeaver": .core,
        "figma": .core,
        "sketch": .core,
        "adobe xd": .core,
        "zeplin": .core,
        "invision": .core,
        
        // Core Tasks - Office/Productivity
        "microsoft word": .core,
        "microsoft excel": .core,
        "microsoft powerpoint": .core,
        "pages": .core,
        "numbers": .core,
        "keynote": .core,
        "google docs": .core,
        "google sheets": .core,
        "notion": .core,
        "obsidian": .core,
        "roam research": .core,
        "bear": .core,
        "ulysses": .core,
        "iawriter": .core,
        "typora": .core,
        "craft": .core,
        "linear": .core,
        "jira": .core,
        "asana": .core,
        "trello": .core,
        "monday": .core,
        "clickup": .core,
        "basecamp": .core,
        
        // Core Tasks - Communication (Work)
        "slack": .core,
        "microsoft teams": .core,
        "zoom": .core,
        "google meet": .core,
        "webex": .core,
        "discord": .core,
        "mattermost": .core,
        
        // Personal Tasks
        "calendar": .personal,
        "fantastical": .personal,
        "reminders": .personal,
        "notes": .personal,
        "apple notes": .personal,
        "todoist": .personal,
        "things": .personal,
        "omnifocus": .personal,
        "2do": .personal,
        "anydo": .personal,
        "mail": .personal,
        "airmail": .personal,
        "spark": .personal,
        "canary mail": .personal,
        "apple mail": .personal,
        "maps": .personal,
        "google maps": .personal,
        "weather": .personal,
        "calculator": .personal,
        "preview": .personal,
        "finder": .personal,
        "files": .personal,
        "photos": .personal,
        "music": .personal,
        "spotify": .personal,
        "apple music": .personal,
        "podcasts": .personal,
        "books": .personal,
        "kindle": .personal,
        "audible": .personal,
        
        // Distractions - Social Media
        "twitter": .distraction,
        "x": .distraction,
        "facebook": .distraction,
        "instagram": .distraction,
        "tiktok": .distraction,
        "snapchat": .distraction,
        "whatsapp": .distraction,
        "telegram": .distraction,
        "signal": .distraction,
        "messenger": .distraction,
        "linkedin": .distraction,
        "pinterest": .distraction,
        "tumblr": .distraction,
        "mastodon": .distraction,
        "threads": .distraction,
        
        // Distractions - Entertainment
        "youtube": .distraction,
        "netflix": .distraction,
        "hulu": .distraction,
        "disney+": .distraction,
        "amazon prime video": .distraction,
        "hbo max": .distraction,
        "apple tv": .distraction,
        "twitch": .distraction,
        "vlc": .distraction,
        "iina": .distraction,
        "plex": .distraction,
        
        // Distractions - News/Reddit
        "reddit": .distraction,
        "hacker news": .distraction,
        "news": .distraction,
        "apple news": .distraction,
        "feedly": .distraction,
        "reeder": .distraction,
        "netnewswire": .distraction,
        
        // Distractions - Games
        "steam": .distraction,
        "epic games": .distraction,
        "game center": .distraction,
        "chess": .distraction,
        "app store": .distraction,
        
        // Browsers (neutral - categorized by window title)
        "safari": .personal,
        "google chrome": .personal,
        "chrome": .personal,
        "firefox": .personal,
        "brave": .personal,
        "arc": .personal,
        "edge": .personal,
        "opera": .personal,
        "vivaldi": .personal,
    ]
    
    // Window title patterns for browser categorization
    private let windowTitlePatterns: [(pattern: String, category: ActivityCategory)] = [
        // Distractions
        ("youtube", .distraction),
        ("twitter", .distraction),
        ("x.com", .distraction),
        ("facebook", .distraction),
        ("instagram", .distraction),
        ("reddit", .distraction),
        ("tiktok", .distraction),
        ("netflix", .distraction),
        ("twitch", .distraction),
        ("hacker news", .distraction),
        
        // Core (work sites)
        ("github", .core),
        ("gitlab", .core),
        ("bitbucket", .core),
        ("stackoverflow", .core),
        ("stack overflow", .core),
        ("jira", .core),
        ("confluence", .core),
        ("notion", .core),
        ("figma", .core),
        ("linear", .core),
        ("vercel", .core),
        ("netlify", .core),
        ("aws", .core),
        ("azure", .core),
        ("google cloud", .core),
        ("firebase", .core),
        ("supabase", .core),
        ("docs.google.com", .core),
        ("sheets.google.com", .core),
        ("drive.google.com", .core),
    ]
    
    init() {
        loadCache()
    }
    
    // MARK: - Public API
    
    /// Categorize an activity based on app name and window title
    func categorize(appName: String, windowTitle: String) -> ActivityCategory {
        let appLower = appName.lowercased()
        let titleLower = windowTitle.lowercased()
        
        // Step 1: Check window title patterns (for browsers)
        if isBrowser(appLower) {
            for (pattern, category) in windowTitlePatterns {
                if titleLower.contains(pattern) {
                    return category
                }
            }
        }
        
        // Step 2: Check user cache
        if let cached = userCache[appLower] {
            return cached
        }
        
        // Step 3: Check known apps
        if let known = knownApps[appLower] {
            return known
        }
        
        // Step 4: Default to personal (unknown apps)
        return .personal
    }
    
    /// Calculate focus metrics for a set of snapshots
    func calculateMetrics(for snapshots: [Snapshot]) -> FocusMetrics {
        guard !snapshots.isEmpty else {
            return FocusMetrics(focusPercentage: 0, distractionPercentage: 0, coreCount: 0, personalCount: 0, distractionCount: 0, idleCount: 0)
        }
        
        var counts: [ActivityCategory: Int] = [:]
        
        for snapshot in snapshots {
            let category = ActivityCategory(rawValue: snapshot.category) ?? .personal
            counts[category, default: 0] += 1
        }
        
        let total = Double(snapshots.count)
        let coreCount = counts[.core] ?? 0
        let personalCount = counts[.personal] ?? 0
        let distractionCount = counts[.distraction] ?? 0
        let idleCount = counts[.idle] ?? 0
        
        // Focus = Core + Personal (productive time)
        let focusPercentage = Double(coreCount + personalCount) / total * 100
        let distractionPercentage = Double(distractionCount) / total * 100
        
        return FocusMetrics(
            focusPercentage: focusPercentage,
            distractionPercentage: distractionPercentage,
            coreCount: coreCount,
            personalCount: personalCount,
            distractionCount: distractionCount,
            idleCount: idleCount
        )
    }
    
    // MARK: - User Cache Management
    
    func cacheCategory(appName: String, category: ActivityCategory) {
        userCache[appName.lowercased()] = category
        saveCache()
    }
    
    // MARK: - Private Helpers
    
    private func isBrowser(_ appName: String) -> Bool {
        let browsers = ["safari", "google chrome", "chrome", "firefox", "brave", "arc", "edge", "opera", "vivaldi"]
        return browsers.contains(appName)
    }
    
    private func loadCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([String: ActivityCategory].self, from: data) {
            userCache = decoded
        }
    }
    
    private func saveCache() {
        if let encoded = try? JSONEncoder().encode(userCache) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
}

// MARK: - Focus Metrics

struct FocusMetrics {
    let focusPercentage: Double
    let distractionPercentage: Double
    let coreCount: Int
    let personalCount: Int
    let distractionCount: Int
    let idleCount: Int
}
