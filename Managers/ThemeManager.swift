//
//  ThemeManager.swift
//  StepPet
//

import Foundation
import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }
    
    // MARK: - Background Colors
    var backgroundColor: Color {
        isDarkMode ? Color(hex: "1C1C1E") : Color(hex: "FFF9E6")
    }
    
    var cardBackgroundColor: Color {
        isDarkMode ? Color(hex: "2C2C2E") : Color.white
    }
    
    var secondaryCardColor: Color {
        isDarkMode ? Color(hex: "3A3A3C") : Color(hex: "FFF5D6")
    }
    
    // MARK: - Text Colors
    var primaryTextColor: Color {
        isDarkMode ? Color.white : Color(hex: "1C1C1E")
    }
    
    var secondaryTextColor: Color {
        isDarkMode ? Color(hex: "8E8E93") : Color(hex: "6B7280")
    }
    
    var tertiaryTextColor: Color {
        isDarkMode ? Color(hex: "636366") : Color(hex: "9CA3AF")
    }
    
    // MARK: - Accent Colors
    var accentColor: Color {
        Color(hex: "4169E1") // Royal Blue
    }
    
    var successColor: Color {
        Color(hex: "34C759")
    }
    
    var warningColor: Color {
        Color(hex: "FF9500")
    }
    
    var dangerColor: Color {
        Color(hex: "FF3B30")
    }
    
    // MARK: - Health Colors
    func healthColor(for health: Int) -> Color {
        switch health {
        case 0...20: return Color(hex: "FF3B30") // Red - Sick
        case 21...40: return Color(hex: "FF9500") // Orange - Sad
        case 41...60: return Color(hex: "FFCC00") // Yellow - Content
        case 61...80: return Color(hex: "A8D96C") // Light Green - Happy
        default: return Color(hex: "34C759") // Green - Full Health
        }
    }
    
    // MARK: - Streak Badge Colors
    func streakBadgeColor(for badge: StreakBadge) -> Color {
        switch badge {
        case .none: return Color.gray
        case .bronze: return Color(hex: "CD7F32")
        case .silver: return Color(hex: "C0C0C0")
        case .gold: return Color(hex: "FFD700")
        case .platinum: return Color(hex: "E5E4E2")
        case .diamond: return Color(hex: "B9F2FF")
        }
    }
    
    // MARK: - Gradient Backgrounds
    var headerGradient: LinearGradient {
        LinearGradient(
            colors: isDarkMode 
                ? [Color(hex: "2C2C2E"), Color(hex: "1C1C1E")]
                : [Color(hex: "FFF9E6"), Color(hex: "FFE4B5")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: isDarkMode
                ? [Color(hex: "3A3A3C"), Color(hex: "2C2C2E")]
                : [Color.white, Color(hex: "FFF9E6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Achievement Rarity Colors
    func rarityColor(for rarity: AchievementRarity) -> Color {
        switch rarity {
        case .common: return Color(hex: "8E8E93")
        case .uncommon: return Color(hex: "34C759")
        case .rare: return Color(hex: "007AFF")
        case .epic: return Color(hex: "AF52DE")
        case .legendary: return Color(hex: "FF9500")
        }
    }
    
    // MARK: - Category Colors
    func categoryColor(for category: AchievementCategory) -> Color {
        switch category {
        case .gettingStarted: return Color(hex: "34C759")
        case .streak: return Color(hex: "FF9500")
        case .steps: return Color(hex: "007AFF")
        case .health: return Color(hex: "FF3B30")
        case .consistency: return Color(hex: "AF52DE")
        case .milestones: return Color(hex: "FFCC00")
        case .special: return Color(hex: "FF2D55")
        }
    }
}

// MARK: - Color Extension
extension Color {
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

