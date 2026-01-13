import SwiftUI
import AppKit
import Combine

// MARK: - Theme Management
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme
    
    static let shared = ThemeManager()
    
    private init() {
        // Load from UserDefaults without triggering didSet
        if let storedTheme = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: storedTheme) {
            _currentTheme = Published(initialValue: theme)
        } else {
            _currentTheme = Published(initialValue: .dark)
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        // Defer state change to avoid publishing during view update
        DispatchQueue.main.async { [weak self] in
            self?.currentTheme = theme
            UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
        }
    }
}

// MARK: - Dynamic Colors (Theme-aware)
extension Color {
    // Light Mode Palette (Anthropic-inspired warm beige)
    private static let lightBackground = Color(hex: "F2F0E9")
    private static let lightSurface = Color(hex: "E6E4DD")
    private static let lightTextPrimary = Color(hex: "1C1C1C")
    private static let lightAccent = Color(hex: "C86B52")
    private static let lightSecondaryAccent = Color(hex: "A69C95")
    
    // Dark Mode Palette (Claude-inspired)
    private static let darkBackground = Color(hex: "141413")
    private static let darkSurface = Color(hex: "2f2e2d")
    private static let darkTextPrimary = Color(hex: "faf9f6")
    private static let darkAccent = Color(hex: "d87656")
    private static let darkSecondaryAccent = Color(hex: "774838")
    
    // Helper to determine if dark mode
    private static var isDarkMode: Bool {
        switch ThemeManager.shared.currentTheme {
        case .dark: return true
        case .light: return false
        case .system:
            return NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        }
    }
    
    static var claudeBackground: Color {
        isDarkMode ? darkBackground : lightBackground
    }
    
    static var claudeSurface: Color {
        isDarkMode ? darkSurface : lightSurface
    }
    
    static var claudeTextPrimary: Color {
        isDarkMode ? darkTextPrimary : lightTextPrimary
    }
    
    static var claudeAccent: Color {
        isDarkMode ? darkAccent : lightAccent
    }
    
    static var claudeSecondaryAccent: Color {
        isDarkMode ? darkSecondaryAccent : lightSecondaryAccent
    }
    
    // Category Colors - Dynamic for light/dark mode visibility
    static var categoryCore: Color {
        isDarkMode ? Color(hex: "89CFF0") : Color(hex: "2196F3")  // Light Blue -> Deeper Blue
    }
    
    static var categoryPersonal: Color {
        isDarkMode ? Color(hex: "FFE4B5") : Color(hex: "EF6C00")  // Darker Orange for better visibility
    }
    
    static var categoryDistraction: Color {
        isDarkMode ? Color(hex: "FFB6C1") : Color(hex: "E91E63")  // Light Pink -> Deep Pink
    }
    
    static var categoryIdle: Color {
        isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "607D8B")  // Gray -> Blue Gray
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - NSColor Helper
extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        let red = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue = CGFloat(b) / 255.0
        let alpha = CGFloat(a) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

struct ClaudeTheme: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .background(Color.claudeBackground)
            .foregroundStyle(Color.claudeTextPrimary)
            .font(.system(.body, design: .monospaced))
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

extension View {
    func claudeStyle() -> some View {
        modifier(ClaudeTheme())
    }
    
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.claudeSurface)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2) // Lighter shadow
    }
}
