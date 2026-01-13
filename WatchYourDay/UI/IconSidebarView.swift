import SwiftUI

enum SidebarTab: String, CaseIterable {

    case timeline = "clock"
    case search = "magnifyingglass"
    case stats = "chart.pie"
    case settings = "gear"
}

struct IconSidebarView: View {
    @Binding var selectedTab: SidebarTab
    var onClearData: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var themeIcon: String {
        switch themeManager.currentTheme {
        case .system: return "laptopcomputer"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    private var themeColor: Color {
        switch themeManager.currentTheme {
        case .system: return Color.claudeAccent
        case .light: return Color.orange
        case .dark: return Color.indigo
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo / App Icon
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.claudeAccent)
                .padding(.vertical, 20)
            
            Divider()
                .background(Color.claudeTextPrimary.opacity(0.1))
            
            // Navigation Icons
            ForEach(SidebarTab.allCases, id: \.self) { tab in
                IconButton(
                    systemName: tab.rawValue,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
            
            Spacer()
            
            // Theme Toggle
            Button(action: cycleTheme) {
                Image(systemName: themeIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(themeColor)
                    .frame(width: 44, height: 44)
                    .background(themeColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
            .help("Theme: \(themeManager.currentTheme.rawValue)")
            .padding(.vertical, 8)
            
            // Delete Button (Bottom)
            IconButton(
                systemName: "trash",
                isSelected: false,
                tint: .red
            ) {
                onClearData()
            }
            .padding(.bottom, 20)
        }
        .frame(width: 60)
        .background(Color.claudeSurface)
    }
    
    private func cycleTheme() {
        let themes = AppTheme.allCases
        guard let currentIndex = themes.firstIndex(of: themeManager.currentTheme) else { return }
        let nextIndex = (currentIndex + 1) % themes.count
        themeManager.setTheme(themes[nextIndex])
    }
}

struct IconButton: View {
    let systemName: String
    let isSelected: Bool
    var tint: Color = Color.claudeAccent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20))
                .foregroundStyle(isSelected ? tint : Color.gray)
                .frame(width: 44, height: 44)
                .background(
                    isSelected ? tint.opacity(0.15) : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            if isHovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    IconSidebarView(selectedTab: .constant(.timeline), onClearData: {})
        .frame(height: 400)
        .background(Color.claudeBackground)
}
