//
//  ChallengesView.swift
//  StepPet
//

import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var showCompletedOnly = false
    @State private var selectedChallenge: Achievement?
    @State private var selectedSegment = 0 // 0 = Challenges, 1 = Activities
    
    // Activities & Minigames States
    @State private var showCreditsSheet = false
    @State private var showActivitySheet = false
    @State private var selectedActivity: PetActivity?
    @State private var showHealthBoostAnimation = false
    @State private var healthBoostAmount = 0
    @State private var showMinigames = false
    
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
                segmentPicker
                
                if selectedSegment == 0 {
                    // Challenges Tab
                    progressBanner
                    categoryFilter
                    showCompletedToggle
                    challengesGrid
                } else {
                    // Activities & Minigames Tab
                    activitiesSection
                    minigamesSection
                }
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .sheet(item: $selectedChallenge) { challenge in
            ChallengeDetailSheet(challenge: challenge)
        }
        .sheet(isPresented: $showCreditsSheet) { creditsSheet }
        .sheet(isPresented: $showMinigames) {
            MinigamesView()
        }
        .sheet(isPresented: $showActivitySheet) {
            if let activity = selectedActivity {
                ActivityPlaySheet(
                    activity: activity,
                    petType: userSettings.pet.type,
                    onComplete: { handleActivityComplete() }
                )
            }
        }
        .onAppear {
            userSettings.checkAndResetDailyBoost()
        }
        .overlay {
            if showHealthBoostAnimation {
                healthBoostOverlay
            }
        }
    }
    
    // MARK: - Segment Picker
    private var segmentPicker: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) { selectedSegment = 0 }
                HapticFeedback.light.trigger()
            }) {
                Text("Challenges")
                    .font(.system(size: 14, weight: selectedSegment == 0 ? .bold : .medium))
                    .foregroundColor(selectedSegment == 0 ? .white : themeManager.primaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedSegment == 0 ? themeManager.accentColor : Color.clear)
                    )
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3)) { selectedSegment = 1 }
                HapticFeedback.light.trigger()
            }) {
                HStack(spacing: 6) {
                    Text("Activities")
                        .font(.system(size: 14, weight: selectedSegment == 1 ? .bold : .medium))
                    
                    // Credits badge
                    HStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                        Text("\(userSettings.playCredits)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.yellow.opacity(0.2)))
                }
                .foregroundColor(selectedSegment == 1 ? .white : themeManager.primaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedSegment == 1 ? themeManager.accentColor : Color.clear)
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.secondaryTextColor.opacity(0.08))
        )
    }
    
    // MARK: - Activities Section
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Play with Pet", systemImage: "figure.play")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                if userSettings.todayPlayHealthBoost > 0 {
                    Text("+\(userSettings.todayPlayHealthBoost) Health Today")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                }
            }
            
            Text("Each activity gives +20 health to your pet!")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
            
            // Activity Cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PetActivity.allCases) { activity in
                    Button(action: {
                        if userSettings.playCredits > 0 {
                            selectedActivity = activity
                            showActivitySheet = true
                        } else {
                            showCreditsSheet = true
                        }
                    }) {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(activity.color.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: activity.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(activity.color)
                            }
                            
                            Text(activity.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(activity.color.opacity(0.08))
                        )
                    }
                    .disabled(userSettings.playCredits <= 0)
                    .opacity(userSettings.playCredits > 0 ? 1 : 0.5)
                }
            }
            
            // Get Credits Button
            if userSettings.playCredits == 0 {
                Button(action: { showCreditsSheet = true }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("Get Credits to Play")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(themeManager.primaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.yellow.opacity(0.15))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.accentColor.opacity(0.06))
        )
    }
    
    // MARK: - Minigames Section
    private var minigamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Minigames", systemImage: "gamecontroller.fill")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
            }
            
            Text("Fun games to boost your pet's health!")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Button(action: {
                if userSettings.playCredits > 0 {
                    showMinigames = true
                } else {
                    showCreditsSheet = true
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                            .opacity(0.15)
                        
                        Text("🎮")
                            .font(.system(size: 28))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Play Minigames")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("Treat Catch, Memory Match, Bubble Pop")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.tertiaryTextColor)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.purple.opacity(0.08))
                )
            }
            .disabled(userSettings.playCredits <= 0)
            .opacity(userSettings.playCredits > 0 ? 1 : 0.6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.purple.opacity(0.06))
        )
    }
    
    // MARK: - Credits Sheet
    private var creditsSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Current Credits
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                        
                        Text("\(userSettings.playCredits)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                    
                    Text("Play Credits")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(.top, 12)
                
                // Info
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.pink)
                    
                    Text("Each activity or minigame gives +20 health!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.pink.opacity(0.08)))
                .padding(.horizontal, 16)
                
                // Packages
                VStack(spacing: 8) {
                    ForEach(CreditPackage.packages) { package in
                        Button(action: { purchaseCredits(package: package) }) {
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.yellow)
                                    
                                    Text("\(package.credits)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.primaryTextColor)
                                }
                                .frame(width: 50)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(package.credits) Credits")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(themeManager.primaryTextColor)
                                    
                                    if let savings = package.savings {
                                        Text(savings)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(package.price)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(themeManager.accentColor))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.accentColor.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(package.isPopular ? themeManager.accentColor : Color.clear, lineWidth: 1.5)
                                    )
                            )
                            .overlay(alignment: .topTrailing) {
                                if package.isPopular {
                                    Text("BEST")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(themeManager.accentColor))
                                        .offset(x: -4, y: -4)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showCreditsSheet = false }
                        .font(.system(size: 14))
                }
            }
        }
    }
    
    // MARK: - Health Boost Overlay
    private var healthBoostOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Text("+\(healthBoostAmount)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                
                Text("Health Boost!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(userSettings.pet.name) feels happier!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .scaleEffect(showHealthBoostAnimation ? 1 : 0.5)
            .opacity(showHealthBoostAnimation ? 1 : 0)
        }
    }
    
    // MARK: - Helper Methods
    private func handleActivityComplete() {
        showActivitySheet = false
        
        if userSettings.usePlayCredit() {
            healthBoostAmount = 20
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showHealthBoostAnimation = true
            }
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showHealthBoostAnimation = false
                }
            }
        }
    }
    
    private func purchaseCredits(package: CreditPackage) {
        userSettings.playCredits += package.credits
        if userSettings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
            
            // Pet with count
            VStack(spacing: 4) {
                AnimatedPetVideoView(
                    petType: userSettings.pet.type,
                    moodState: .fullHealth
                )
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                Text("\(achievementManager.unlockedCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(themeManager.accentColor)
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
                .fill(themeManager.accentColor.opacity(0.1))
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
                    .fill(isSelected ? color : color.opacity(0.12))
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
                .fill(
                    challenge.isUnlocked
                        ? categoryColor.opacity(0.1)
                        : themeManager.secondaryTextColor.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            challenge.isUnlocked ? categoryColor.opacity(0.3) : Color.clear,
                            lineWidth: 2
                        )
                )
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

// MARK: - Activity Play Sheet
struct ActivityPlaySheet: View {
    let activity: PetActivity
    let petType: PetType
    let onComplete: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    @State private var showAnimation = false
    @State private var animationComplete = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer()
                
                if showAnimation {
                    VStack(spacing: 14) {
                        // GIF Animation for activity
                        let size: CGFloat = 220
                        GIFImage(activity.gifName(for: petType))
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .id("\(activity.id)-\(petType.rawValue)")
                        
                        if animationComplete {
                            VStack(spacing: 8) {
                                Text("🎉")
                                    .font(.system(size: 36))
                                
                                Text("\(userSettings.pet.name) loved it!")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                Text("+20 Health")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("Playing...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(activity.color.opacity(0.12))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: activity.icon)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(activity.color)
                        }
                        
                        VStack(spacing: 4) {
                            Text(activity.displayName(for: petType))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                            
                            Text(activity.description)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                            
                            Text("1 Credit (\(userSettings.playCredits) left)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.yellow.opacity(0.15)))
                    }
                }
                
                Spacer()
                
                if animationComplete {
                    Button(action: {
                        dismiss()
                        onComplete()
                    }) {
                        Text("Done!")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.green))
                    }
                    .padding(.horizontal, 16)
                } else if !showAnimation {
                    Button(action: startActivity) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .bold))
                            
                            Text("Start")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(activity.color))
                    }
                    .padding(.horizontal, 16)
                    .disabled(userSettings.playCredits <= 0)
                    .opacity(userSettings.playCredits > 0 ? 1 : 0.5)
                }
                
                Spacer().frame(height: 16)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle(activity.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 14))
                }
            }
        }
    }
    
    private func startActivity() {
        withAnimation(.spring(response: 0.5)) {
            showAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring(response: 0.5)) {
                animationComplete = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Preview
#Preview {
    ChallengesView()
        .environmentObject(ThemeManager())
        .environmentObject(AchievementManager())
        .environmentObject(UserSettings())
}

