//
//  ChallengesView.swift
//  StepPet
//

import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var achievementManager: AchievementManager
    
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var showCompletedOnly = false
    @State private var selectedChallenge: Achievement?
    
    private var filteredChallenges: [Achievement] {
        var challenges = achievementManager.achievements
        
        if let category = selectedCategory {
            challenges = challenges.filter { $0.category == category }
        }
        
        if showCompletedOnly {
            challenges = challenges.filter { $0.isUnlocked }
        }
        
        return challenges
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
                headerSection
                progressBanner
                categoryFilter
                showCompletedToggle
                challengesGrid
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .sheet(item: $selectedChallenge) { challenge in
            ChallengeDetailSheet(challenge: challenge)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Challenges")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Complete challenges to earn rewards!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Trophy with count
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                VStack(spacing: 2) {
                    Text("🏆")
                        .font(.system(size: 24))
                    
                    Text("\(achievementManager.unlockedCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(themeManager.primaryTextColor)
                }
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Progress Banner
    private var progressBanner: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Progress")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("\(achievementManager.unlockedCount) of \(achievementManager.totalCount) completed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Percentage
                Text("\(Int(achievementManager.completionPercentage * 100))%")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.accentColor)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [themeManager.accentColor, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * achievementManager.completionPercentage, height: 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: achievementManager.completionPercentage)
                }
            }
            .frame(height: 12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.1) { category, name, count, color in
                    ChallengeCategoryPill(
                        name: name,
                        count: count,
                        color: color,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                            HapticFeedback.light.trigger()
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Show Completed Toggle
    private var showCompletedToggle: some View {
        HStack {
            Text("Show completed only")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.primaryTextColor)
            
            Spacer()
            
            Toggle("", isOn: $showCompletedOnly)
                .toggleStyle(SwitchToggleStyle(tint: themeManager.accentColor))
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Challenges Grid
    private var challengesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(filteredChallenges) { challenge in
                ChallengeCard(challenge: challenge)
                    .onTapGesture {
                        selectedChallenge = challenge
                        HapticFeedback.light.trigger()
                    }
            }
        }
    }
}

// MARK: - Challenge Category Pill
struct ChallengeCategoryPill: View {
    let name: String
    let count: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                
                Text(count)
                    .font(.system(size: 11, weight: .medium))
                    .opacity(0.8)
            }
            .foregroundColor(isSelected ? .white : themeManager.primaryTextColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : themeManager.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(isSelected ? 0 : 0.04), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Challenge Card
struct ChallengeCard: View {
    let challenge: Achievement
    
    @EnvironmentObject var themeManager: ThemeManager
    
    private var categoryColor: Color {
        themeManager.categoryColor(for: challenge.category)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        challenge.isUnlocked
                            ? categoryColor.opacity(0.15)
                            : Color.gray.opacity(0.08)
                    )
                    .frame(height: 70)
                
                Image(systemName: challenge.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(challenge.isUnlocked ? categoryColor : themeManager.tertiaryTextColor)
            }
            
            // Title
            Text(challenge.title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 36)
            
            // Rarity Badge
            Text(challenge.rarity.rawValue)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(challenge.isUnlocked ? themeManager.rarityColor(for: challenge.rarity) : Color.gray.opacity(0.5))
                )
            
            Spacer()
            
            // Status
            if challenge.isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    
                    Text("Complete")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                }
            } else if challenge.targetProgress > 1 {
                // Progress
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(categoryColor)
                                .frame(width: geometry.size.width * challenge.progressPercentage, height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("\(challenge.progress)/\(challenge.targetProgress)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    
                    Text("Locked")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(themeManager.tertiaryTextColor)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            challenge.isUnlocked ? categoryColor.opacity(0.3) : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.04), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Challenge Detail Sheet
struct ChallengeDetailSheet: View {
    let challenge: Achievement
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            challenge.isUnlocked
                                ? themeManager.categoryColor(for: challenge.category).opacity(0.15)
                                : Color.gray.opacity(0.1)
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: challenge.icon)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(
                            challenge.isUnlocked
                                ? themeManager.categoryColor(for: challenge.category)
                                : themeManager.tertiaryTextColor
                        )
                }
                .padding(.top, 20)
                
                // Title & Rarity
                VStack(spacing: 8) {
                    Text(challenge.title)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(challenge.rarity.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(themeManager.rarityColor(for: challenge.rarity))
                        )
                }
                
                // Description
                Text(challenge.description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // Progress (if not unlocked)
                if !challenge.isUnlocked && challenge.targetProgress > 1 {
                    VStack(spacing: 10) {
                        Text("Progress")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(themeManager.categoryColor(for: challenge.category))
                                    .frame(width: geometry.size.width * challenge.progressPercentage, height: 12)
                            }
                        }
                        .frame(height: 12)
                        .padding(.horizontal, 40)
                        
                        Text("\(challenge.progress) / \(challenge.targetProgress)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                }
                
                // Status
                if challenge.isUnlocked {
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.green)
                            
                            Text("Challenge Complete!")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        
                        if let date = challenge.unlockedDate {
                            Text(formatDate(date))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    .padding(.top, 10)
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
                    .font(.system(size: 16, weight: .semibold))
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
    ChallengesView()
        .environmentObject(ThemeManager())
        .environmentObject(AchievementManager())
}

