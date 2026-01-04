//
//  ThemeManager.swift
//  VirtuPet
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
    
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║                    🎨 BRAND COLORS                               ║
    // ║         Cute, playful palette for our adorable pet app! 🐾       ║
    // ╚══════════════════════════════════════════════════════════════════╝
    
    // MARK: - Primary Colors (Indigo Blue - Deep & Trustworthy!)
    
    /// The signature VirtuPet indigo blue - deep, trustworthy, professional
    var primaryColor: Color {
        Color(hex: "4A6CF7")  // Deeper indigo-blue
    }
    
    var primaryDarkColor: Color {
        Color(hex: "3D5BD9")
    }
    
    var primaryLightColor: Color {
        Color(hex: "6B8AFF")
    }
    
    var primaryExtraLight: Color {
        Color(hex: "A3B8FF")
    }
    
    // MARK: - Secondary Colors (Mint Teal - Fresh & Cute!)
    
    /// Refreshing mint teal - represents health and activity
    var secondaryColor: Color {
        Color(hex: "5CD9C5")  // More minty, friendlier
    }
    
    var secondaryDarkColor: Color {
        Color(hex: "4CC9B5")
    }
    
    var secondaryLightColor: Color {
        Color(hex: "8FEDE0")
    }
    
    var secondaryExtraLight: Color {
        Color(hex: "C5F8F0")
    }
    
    // MARK: - 🍬 Cute Pastel Accent Colors (Candy-like!)
    
    /// Sunshine yellow - joy, achievements, celebrations ☀️
    var accentYellow: Color {
        Color(hex: "FFDC5D")  // Warmer, friendlier yellow
    }
    
    var accentYellowLight: Color {
        Color(hex: "FFE98A")
    }
    
    var accentYellowDark: Color {
        Color(hex: "FFCF33")
    }
    
    /// Lavender purple - premium, special, magical 💜
    var accentPurple: Color {
        Color(hex: "B58FFF")  // Softer lavender
    }
    
    var accentPurpleLight: Color {
        Color(hex: "D4BDFF")
    }
    
    var accentPurpleDark: Color {
        Color(hex: "9B6FFF")
    }
    
    /// Sweet pink - love, care, affection 💕
    var accentPink: Color {
        Color(hex: "FF85B3")  // Softer bubblegum pink
    }
    
    var accentPinkLight: Color {
        Color(hex: "FFB3D1")
    }
    
    var accentPinkDark: Color {
        Color(hex: "FF5C99")
    }
    
    /// Fresh green - success, health, growth 🌿
    var accentGreen: Color {
        Color(hex: "5DD98F")  // Softer mint green
    }
    
    var accentGreenLight: Color {
        Color(hex: "8FEDB3")
    }
    
    var accentGreenDark: Color {
        Color(hex: "3DC975")
    }
    
    /// Sky blue - calm, trust, stats 💙
    var accentBlue: Color {
        Color(hex: "5DB9FF")  // Brighter, friendlier blue
    }
    
    var accentBlueLight: Color {
        Color(hex: "8FCFFF")
    }
    
    /// Peach orange - warmth, energy 🍑
    var accentPeach: Color {
        Color(hex: "FFAB8F")
    }
    
    var accentPeachLight: Color {
        Color(hex: "FFCDBF")
    }
    
    /// Lilac - dreamy, soft 💜
    var accentLilac: Color {
        Color(hex: "C9A7FF")
    }
    
    /// Aqua - refreshing, playful 🌊
    var accentAqua: Color {
        Color(hex: "7FDBFF")
    }
    
    // MARK: - 🎯 Semantic Colors
    
    var successColor: Color { accentGreen }
    var warningColor: Color { accentYellow }
    var dangerColor: Color { Color(hex: "FF6B6B") }  // Softer red
    var infoColor: Color { accentBlue }
    
    // Legacy accent color reference
    var accentColor: Color { primaryColor }
    
    // MARK: - 🏷️ Tab Bar Colors (Unified blue theme)
    
    var activityTabColor: Color { primaryColor }
    var insightsTabColor: Color { primaryColor }
    var todayTabColor: Color { primaryColor }
    var challengesTabColor: Color { primaryColor }
    var settingsTabColor: Color { primaryColor }
    
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║                    🖼️ BACKGROUND COLORS                          ║
    // ║           Soft pastels & cozy vibes for a cute pet app! 🎀       ║
    // ╚══════════════════════════════════════════════════════════════════╝
    
    // MARK: - Background Colors
    
    /// Main app background - soft warm cream in light, charcoal-black in dark
    var backgroundColor: Color {
        isDarkMode ? Color(hex: "121212") : Color(hex: "FFF8F5")  // Charcoal-black dark mode
    }
    
    /// Slightly elevated background
    var backgroundElevated: Color {
        isDarkMode ? Color(hex: "1E1E1E") : Color(hex: "FFFFFF")
    }
    
    /// Card backgrounds - with subtle warmth
    var cardBackgroundColor: Color {
        isDarkMode ? Color(hex: "1E1E1E") : Color(hex: "FFFFFF")
    }
    
    /// Secondary card/section background - subtle tint
    var secondaryCardColor: Color {
        isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "FFF2EE")
    }
    
    /// Warm peachy background for highlighted sections 🍑
    var warmBackgroundColor: Color {
        isDarkMode ? Color(hex: "2A2525") : Color(hex: "FFE5D9")
    }
    
    /// Extra warm/coral tinted background 🧡
    var coralBackgroundColor: Color {
        isDarkMode ? Color(hex: "2A2222") : Color(hex: "FFEBE5")
    }
    
    /// Mint teal tinted background 🌿
    var tealBackgroundColor: Color {
        isDarkMode ? Color(hex: "1A2A28") : Color(hex: "E5FFF8")
    }
    
    /// Lavender purple tinted background 💜
    var purpleBackgroundColor: Color {
        isDarkMode ? Color(hex: "252030") : Color(hex: "F5EEFF")
    }
    
    /// Sunshine yellow tinted background ☀️
    var goldBackgroundColor: Color {
        isDarkMode ? Color(hex: "2A2820") : Color(hex: "FFFBE5")
    }
    
    /// Baby pink background 🎀
    var pinkBackgroundColor: Color {
        isDarkMode ? Color(hex: "2A2025") : Color(hex: "FFF0F5")
    }
    
    /// Sky blue background 💙
    var blueBackgroundColor: Color {
        isDarkMode ? Color(hex: "1E2530") : Color(hex: "F0F8FF")
    }
    
    /// Mint green background 🌱
    var mintBackgroundColor: Color {
        isDarkMode ? Color(hex: "1E2A25") : Color(hex: "F0FFF5")
    }
    
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║                    ✏️ TEXT COLORS                                ║
    // ╚══════════════════════════════════════════════════════════════════╝
    
    // MARK: - Text Colors
    
    var primaryTextColor: Color {
        isDarkMode ? Color.white : Color(hex: "1F1F1F")
    }
    
    var secondaryTextColor: Color {
        isDarkMode ? Color(hex: "A0AEC0") : Color(hex: "4A5568")
    }
    
    var tertiaryTextColor: Color {
        isDarkMode ? Color(hex: "718096") : Color(hex: "718096")
    }
    
    var mutedTextColor: Color {
        isDarkMode ? Color(hex: "4A5568") : Color(hex: "A0AEC0")
    }
    
    /// Text on primary colored backgrounds
    var onPrimaryTextColor: Color {
        Color.white
    }
    
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║                    🌈 GRADIENTS                                   ║
    // ║         Cute candy gradients for that adorable pet feel! 🍭      ║
    // ╚══════════════════════════════════════════════════════════════════╝
    
    // MARK: - Primary Gradients
    
    /// Main brand gradient - indigo blue (solid)
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, primaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Coral only gradient - peachy soft
    var coralGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF7B6B"), Color(hex: "FFA799")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Mint teal gradient - fresh and cute
    var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "5CD9C5"), Color(hex: "7FDBFF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Teal to aqua - refreshing!
    var tealGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "5CD9C5"), Color(hex: "7FDBFF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - 🍬 Cute Accent Gradients
    
    /// Sunset gradient - coral to pink 🌅
    var sunsetGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF7B6B"), Color(hex: "FF85B3")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Sunshine gradient - warm and happy ☀️
    var goldGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFDC5D"), Color(hex: "FFAB8F")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Lavender magic gradient - dreamy 💜
    var purpleGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "B58FFF"), Color(hex: "C9A7FF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Purple to pink - magical unicorn vibes! 🦄
    var magicGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "B58FFF"), Color(hex: "FF85B3")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Bubblegum pink gradient - sweet! 🎀
    var pinkGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF85B3"), Color(hex: "FFB3D1")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Mint green gradient - healthy! 🌿
    var successGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "5DD98F"), Color(hex: "8FEDB3")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Sky blue gradient - dreamy 💙
    var blueGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "5DB9FF"), Color(hex: "7FDBFF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Rainbow gradient - celebrations! 🌈
    var rainbowGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "FF7B6B"),   // Coral
                Color(hex: "FFDC5D"),   // Yellow
                Color(hex: "5DD98F"),   // Mint green
                Color(hex: "5CD9C5"),   // Teal
                Color(hex: "B58FFF")    // Lavender
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    /// Cotton candy gradient - super cute! 🍭
    var cottonCandyGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFB3D1"), Color(hex: "B58FFF"), Color(hex: "7FDBFF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Peachy keen gradient 🍑
    var peachGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFAB8F"), Color(hex: "FFCDBF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Aqua splash gradient 🌊
    var aquaGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "7FDBFF"), Color(hex: "5CD9C5")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Background Gradients
    
    /// Hero/header background gradient
    var heroGradient: LinearGradient {
        LinearGradient(
            colors: isDarkMode
                ? [Color(hex: "0F0F1A"), Color(hex: "1A1A2E")]
                : [Color(hex: "FFF9F5"), Color(hex: "FFE8DC")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Header gradient
    var headerGradient: LinearGradient {
        heroGradient
    }
    
    /// Card background gradient
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: isDarkMode
                ? [Color(hex: "1A1A2E"), Color(hex: "16213E")]
                : [Color.white, Color(hex: "FFF9F5")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Spotlight/feature section gradient
    var spotlightGradient: LinearGradient {
        LinearGradient(
            colors: isDarkMode
                ? [Color(hex: "1A1A2E"), Color(hex: "232340")]
                : [Color(hex: "FFFBF7"), Color(hex: "FFF5EE")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Mesh-style radial gradient for special backgrounds
    var meshGradient: RadialGradient {
        RadialGradient(
            colors: isDarkMode
                ? [Color(hex: "2A1F35"), Color(hex: "1A1A2E"), Color(hex: "0F0F1A")]
                : [Color(hex: "FFE8DC"), Color(hex: "FFF5EE"), Color(hex: "FFF9F5")],
            center: .topTrailing,
            startRadius: 0,
            endRadius: 500
        )
    }
    
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║                    🐾 PET HEALTH COLORS                          ║
    // ║            Dynamic colors based on pet's mood/health             ║
    // ╚══════════════════════════════════════════════════════════════════╝
    
    // MARK: - Health Colors
    
    func healthColor(for health: Int) -> Color {
        switch health {
        case 0...20: return Color(hex: "EF4444")   // 🔴 Red - Sick
        case 21...40: return Color(hex: "FF6B4A")  // 🟠 Coral - Sad  
        case 41...60: return Color(hex: "FFD93D")  // 🟡 Yellow - Content
        case 61...80: return Color(hex: "4ECDC4")  // 🔵 Teal - Happy
        default: return Color(hex: "22C55E")       // 🟢 Green - Full Health
        }
    }
    
    func healthGradient(for health: Int) -> LinearGradient {
        switch health {
        case 0...20:
            return LinearGradient(colors: [Color(hex: "EF4444"), Color(hex: "DC2626")], startPoint: .leading, endPoint: .trailing)
        case 21...40:
            return LinearGradient(colors: [Color(hex: "FF6B4A"), Color(hex: "E85A3A")], startPoint: .leading, endPoint: .trailing)
        case 41...60:
            return LinearGradient(colors: [Color(hex: "FFD93D"), Color(hex: "F59E0B")], startPoint: .leading, endPoint: .trailing)
        case 61...80:
            return LinearGradient(colors: [Color(hex: "4ECDC4"), Color(hex: "06B6D4")], startPoint: .leading, endPoint: .trailing)
        default:
            return LinearGradient(colors: [Color(hex: "22C55E"), Color(hex: "10B981")], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    /// Background tint based on health
    func healthBackgroundColor(for health: Int) -> Color {
        switch health {
        case 0...20: return isDarkMode ? Color(hex: "2D1A1A") : Color(hex: "FEE2E2")
        case 21...40: return isDarkMode ? Color(hex: "2D1F1F") : Color(hex: "FFF0EB")
        case 41...60: return isDarkMode ? Color(hex: "2D2A1A") : Color(hex: "FFFBEB")
        case 61...80: return isDarkMode ? Color(hex: "1A2D2B") : Color(hex: "E8FAF8")
        default: return isDarkMode ? Color(hex: "1A2D1A") : Color(hex: "ECFDF5")
        }
    }
    
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║                    🏆 ACHIEVEMENT & STREAK COLORS                ║
    // ╚══════════════════════════════════════════════════════════════════╝
    
    // MARK: - Streak Badge Colors
    
    func streakBadgeColor(for badge: StreakBadge) -> Color {
        switch badge {
        case .none: return Color(hex: "718096")
        case .bronze: return Color(hex: "CD7F32")
        case .silver: return Color(hex: "C0C0C0")
        case .gold: return Color(hex: "FFD93D")
        case .platinum: return Color(hex: "E5E4E2")
        case .diamond: return Color(hex: "4ECDC4")
        }
    }
    
    func streakBadgeGradient(for badge: StreakBadge) -> LinearGradient {
        switch badge {
        case .none:
            return LinearGradient(colors: [Color(hex: "718096"), Color(hex: "4A5568")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .bronze:
            return LinearGradient(colors: [Color(hex: "CD7F32"), Color(hex: "8B5A2B")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .silver:
            return LinearGradient(colors: [Color(hex: "E8E8E8"), Color(hex: "A8A8A8")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold:
            return LinearGradient(colors: [Color(hex: "FFD93D"), Color(hex: "F59E0B")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .platinum:
            return LinearGradient(colors: [Color(hex: "E5E4E2"), Color(hex: "C0C0C0")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .diamond:
            return LinearGradient(colors: [Color(hex: "4ECDC4"), Color(hex: "06B6D4"), Color(hex: "A855F7")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    // MARK: - Achievement Rarity Colors
    
    func rarityColor(for rarity: AchievementRarity) -> Color {
        switch rarity {
        case .common: return Color(hex: "718096")
        case .uncommon: return Color(hex: "4ECDC4")
        case .rare: return Color(hex: "FF6B4A")
        case .epic: return Color(hex: "A855F7")
        case .legendary: return Color(hex: "FFD93D")
        }
    }
    
    func rarityGradient(for rarity: AchievementRarity) -> LinearGradient {
        switch rarity {
        case .common:
            return LinearGradient(colors: [Color(hex: "718096"), Color(hex: "4A5568")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .uncommon:
            return LinearGradient(colors: [Color(hex: "4ECDC4"), Color(hex: "06B6D4")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rare:
            return LinearGradient(colors: [Color(hex: "FF6B4A"), Color(hex: "FF8E53")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .epic:
            return LinearGradient(colors: [Color(hex: "A855F7"), Color(hex: "EC4899")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .legendary:
            return LinearGradient(colors: [Color(hex: "FFD93D"), Color(hex: "FF6B4A"), Color(hex: "EC4899")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    // MARK: - Category Colors
    
    func categoryColor(for category: AchievementCategory) -> Color {
        switch category {
        case .gettingStarted: return Color(hex: "4ECDC4")
        case .streak: return Color(hex: "FF6B4A")
        case .steps: return Color(hex: "22C55E")
        case .health: return Color(hex: "EC4899")
        case .consistency: return Color(hex: "A855F7")
        case .milestones: return Color(hex: "FFD93D")
        case .special: return Color(hex: "FF6B4A")
        }
    }
    
    func categoryGradient(for category: AchievementCategory) -> LinearGradient {
        switch category {
        case .gettingStarted:
            return tealGradient
        case .streak:
            return coralGradient
        case .steps:
            return successGradient
        case .health:
            return pinkGradient
        case .consistency:
            return purpleGradient
        case .milestones:
            return goldGradient
        case .special:
            return sunsetGradient
        }
    }
    
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║                    🎮 MINIGAME COLORS                            ║
    // ╚══════════════════════════════════════════════════════════════════╝
    
    // MARK: - Minigame Theme Colors
    
    var moodCatchColor: Color { Color(hex: "FF6B4A") }
    var memoryMatchColor: Color { Color(hex: "A855F7") }
    var skyDashColor: Color { Color(hex: "667EEA") }
    var patternMatchColor: Color { Color(hex: "11998E") }
    
    var moodCatchGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: "FF6B4A"), Color(hex: "FFD93D")], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var memoryMatchGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: "A855F7"), Color(hex: "EC4899")], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var skyDashGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: "667EEA"), Color(hex: "764BA2")], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var patternMatchGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: "11998E"), Color(hex: "38EF7D")], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║                    🔘 BUTTON STYLES                              ║
    // ╚══════════════════════════════════════════════════════════════════╝
    
    // MARK: - Button Styles
    
    var primaryButtonBackground: some View {
        primaryGradient
    }
    
    var secondaryButtonBackground: Color {
        isDarkMode ? Color(hex: "232340") : Color.white
    }
    
    var destructiveButtonBackground: LinearGradient {
        LinearGradient(colors: [Color(hex: "EF4444"), Color(hex: "DC2626")], startPoint: .leading, endPoint: .trailing)
    }
    
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║                    🌑 SHADOWS                                    ║
    // ╚══════════════════════════════════════════════════════════════════╝
    
    // MARK: - Shadow Colors
    
    var primaryShadowColor: Color {
        Color(hex: "FF6B4A").opacity(0.3)
    }
    
    var cardShadowColor: Color {
        isDarkMode ? Color.black.opacity(0.4) : Color.black.opacity(0.08)
    }
    
    var glowColor: Color {
        Color(hex: "FF6B4A").opacity(0.4)
    }
    
    var tealGlowColor: Color {
        Color(hex: "4ECDC4").opacity(0.4)
    }
    
    var purpleGlowColor: Color {
        Color(hex: "A855F7").opacity(0.4)
    }
    
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║                    📊 CHART COLORS                               ║
    // ╚══════════════════════════════════════════════════════════════════╝
    
    // MARK: - Chart & Data Visualization Colors
    
    var chartColors: [Color] {
        [
            Color(hex: "FF6B4A"),
            Color(hex: "4ECDC4"),
            Color(hex: "FFD93D"),
            Color(hex: "A855F7"),
            Color(hex: "EC4899"),
            Color(hex: "22C55E"),
            Color(hex: "3B82F6")
        ]
    }
    
    var chartBarColor: Color {
        primaryColor
    }
    
    var chartBarGradient: LinearGradient {
        coralGradient
    }
    
    var chartLineColor: Color {
        secondaryColor
    }
    
    var chartGridColor: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
    }
    
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║                    ✨ SPECIAL EFFECTS                            ║
    // ╚══════════════════════════════════════════════════════════════════╝
    
    // MARK: - Special Effect Colors
    
    /// Shimmer overlay color
    var shimmerColor: Color {
        Color.white.opacity(0.3)
    }
    
    /// Confetti colors for celebrations
    var confettiColors: [Color] {
        [
            Color(hex: "FF6B4A"),
            Color(hex: "FFD93D"),
            Color(hex: "4ECDC4"),
            Color(hex: "A855F7"),
            Color(hex: "EC4899"),
            Color(hex: "22C55E")
        ]
    }
    
    /// Separator/divider color
    var separatorColor: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
    }
    
    /// Overlay color for modals
    var overlayColor: Color {
        Color.black.opacity(isDarkMode ? 0.6 : 0.4)
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
