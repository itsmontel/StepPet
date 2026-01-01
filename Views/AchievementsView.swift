//
//  AchievementsView.swift
//  VirtuPet
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var achievementManager: AchievementManager
    
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var showUnlockedOnly = false
    @State private var selectedAchievement: Achievement?
    
    private var filteredAchievements: [Achievement] {
        var achievements = achievementManager.achievements
        
        if let category = selectedCategory {
            achievements = achievements.filter { $0.category == category }
        }
        
        if showUnlockedOnly {
            achievements = achievements.filter { $0.isUnlocked }
        }
        
        return achievements
    }
    
    private var categories: [(AchievementCategory?, String, String, Color)] {
        var cats: [(AchievementCategory?, String, String, Color)] = [
            (nil, "All", "(\(achievementManager.totalCount))", themeManager.accentColor)
        ]
        
        for category in AchievementCategory.allCases {
            let count = achievementManager.achievements(for: category).count
            cats.append((category, category.rawValue, "(\(count))", themeManager.categoryColor(for: category)))
        }
        
        return cats
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Category Filter
                categoryFilter
                
                // Show Unlocked Toggle
                showUnlockedToggle
                
                // Achievements Grid
                achievementsGrid
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Achievements")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("\(achievementManager.unlockedCount) of \(achievementManager.totalCount) unlocked")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.15))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [themeManager.accentColor, themeManager.successColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * achievementManager.completionPercentage, height: 8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: achievementManager.completionPercentage)
                    }
                }
                .frame(height: 8)
                .padding(.top, 8)
            }
            
            Spacer()
            
            // Percentage Circle
            ZStack {
                Circle()
                    .stroke(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.15), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: achievementManager.completionPercentage)
                    .stroke(
                        LinearGradient(
                            colors: [themeManager.accentColor, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: achievementManager.completionPercentage)
                
                Text("\(Int(achievementManager.completionPercentage * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.1) { category, name, count, color in
                    CategoryPill(
                        name: name,
                        count: count,
                        color: color,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Show Unlocked Toggle
    private var showUnlockedToggle: some View {
        HStack {
            Text("Show unlocked only")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(themeManager.primaryTextColor)
            
            Spacer()
            
            Toggle("", isOn: $showUnlockedOnly)
                .toggleStyle(SwitchToggleStyle(tint: themeManager.accentColor))
        }
    }
    
    // MARK: - Achievements Grid
    private var achievementsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(filteredAchievements) { achievement in
                AchievementCard(achievement: achievement)
                    .onTapGesture {
                        selectedAchievement = achievement
                    }
            }
        }
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let name: String
    let count: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 12, weight: .semibold))
                }
                
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                
                Text(count)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryIcon: String {
        switch name {
        case "Getting Started": return "star.fill"
        case "Streak": return "flame.fill"
        case "Steps": return "figure.walk"
        case "Health": return "heart.fill"
        case "Consistency": return "calendar"
        case "Milestones": return "flag.fill"
        case "Special": return "sparkles"
        default: return "list.bullet"
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    
    @EnvironmentObject var themeManager: ThemeManager
    
    private var categoryColor: Color {
        themeManager.categoryColor(for: achievement.category)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        achievement.isUnlocked 
                            ? categoryColor.opacity(0.2)
                            : themeManager.isDarkMode ? Color.white.opacity(0.05) : Color.gray.opacity(0.1)
                    )
                    .frame(height: 80)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(achievement.isUnlocked ? categoryColor : themeManager.tertiaryTextColor)
            }
            
            // Rarity Badge
            Text(achievement.rarity.rawValue)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(achievement.isUnlocked ? themeManager.rarityColor(for: achievement.rarity) : Color.gray)
                )
            
            // Title
            Text(achievement.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(themeManager.primaryTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Description
            Text(achievement.description)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Spacer()
            
            // Status
            HStack(spacing: 4) {
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.successColor)
                    
                    Text("Unlocked")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(themeManager.successColor)
                } else {
                    // Progress
                    if achievement.targetProgress > 1 {
                        Text("\(achievement.progress)/\(achievement.targetProgress)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(themeManager.secondaryTextColor)
                    } else {
                        Text("Locked")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(themeManager.tertiaryTextColor)
                    }
                }
                
                Spacer()
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(achievement.isUnlocked ? categoryColor : themeManager.tertiaryTextColor)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(themeManager.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            achievement.isUnlocked ? categoryColor.opacity(0.3) : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Achievement Detail Sheet
struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            achievement.isUnlocked
                                ? themeManager.categoryColor(for: achievement.category).opacity(0.2)
                                : Color.gray.opacity(0.2)
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(
                            achievement.isUnlocked
                                ? themeManager.categoryColor(for: achievement.category)
                                : themeManager.tertiaryTextColor
                        )
                }
                .padding(.top, 20)
                
                // Title & Rarity
                VStack(spacing: 8) {
                    Text(achievement.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(achievement.rarity.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(themeManager.rarityColor(for: achievement.rarity))
                        )
                }
                
                // Description
                Text(achievement.description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // Progress
                if !achievement.isUnlocked && achievement.targetProgress > 1 {
                    VStack(spacing: 8) {
                        Text("Progress")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.15))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(themeManager.categoryColor(for: achievement.category))
                                    .frame(width: geometry.size.width * achievement.progressPercentage, height: 12)
                            }
                        }
                        .frame(height: 12)
                        .padding(.horizontal, 40)
                        
                        Text("\(achievement.progress) / \(achievement.targetProgress)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                }
                
                // Status
                if achievement.isUnlocked {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.successColor)
                            
                            Text("Unlocked!")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(themeManager.successColor)
                        }
                        
                        if let date = achievement.unlockedDate {
                            Text(formatDate(date))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                }
                
                Spacer()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    AchievementsView()
        .environmentObject(ThemeManager())
        .environmentObject(AchievementManager())
}

