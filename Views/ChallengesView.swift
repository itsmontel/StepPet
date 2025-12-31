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
    @State private var selectedSegment = 0 // 0 = Minigames, 1 = Play with Pet, 2 = Achievements
    
    // Activities & Minigames States
    @State private var showCreditsSheet = false
    @State private var showActivitySheet = false
    @State private var selectedActivity: PetActivity?
    @State private var showHealthBoostAnimation = false
    @State private var healthBoostAmount = 0
    @State private var selectedGame: MinigameType?
    @State private var showTreatCatch = false
    @State private var showMemoryMatch = false
    @State private var showBubblePop = false
    @State private var showPatternMatch = false
    
    private var filteredChallenges: [Achievement] {
        var challenges = achievementManager.achievements
        
        if let category = selectedCategory {
            challenges = challenges.filter { $0.category == category }
        }
        
        if showCompletedOnly {
            challenges = challenges.filter { $0.isUnlocked }
        }
        
        // Sort: completed first, then by progress percentage
        challenges.sort { first, second in
            if first.isUnlocked != second.isUnlocked {
                return first.isUnlocked // Completed first
            }
            return first.progressPercentage > second.progressPercentage
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
                
                switch selectedSegment {
                case 0:
                    // Minigames Tab
                    minigamesFullSection
                case 1:
                    // Play with Pet Tab
                    playWithPetSection
                default:
                    // Achievements Tab
                    progressBanner
                    categoryFilter
                    showCompletedToggle
                    challengesGrid
                }
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .onAppear {
            // Check if we should navigate to a specific segment
            if let targetSegment = UserDefaults.standard.object(forKey: "challengesTargetSegment") as? Int {
                selectedSegment = targetSegment
                // Clear the target so it doesn't trigger again
                UserDefaults.standard.removeObject(forKey: "challengesTargetSegment")
            }
        }
        .sheet(item: $selectedChallenge) { challenge in
            ChallengeDetailSheet(challenge: challenge)
        }
        .sheet(isPresented: $showCreditsSheet) { creditsSheet }
        .sheet(isPresented: $showActivitySheet) {
            if let activity = selectedActivity {
                ActivityPlaySheet(
                    activity: activity,
                    petType: userSettings.pet.type,
                    onComplete: { handleActivityComplete() }
                )
            }
        }
        .fullScreenCover(isPresented: $showTreatCatch) {
            TreatCatchGameView(onComplete: handleMinigameComplete)
                .environmentObject(themeManager)
                .environmentObject(userSettings)
        }
        .fullScreenCover(isPresented: $showMemoryMatch) {
            MemoryMatchGameView(onComplete: handleMinigameComplete)
                .environmentObject(themeManager)
                .environmentObject(userSettings)
        }
        .fullScreenCover(isPresented: $showBubblePop) {
            BubblePopGameView(onComplete: handleMinigameComplete)
                .environmentObject(themeManager)
                .environmentObject(userSettings)
        }
        .fullScreenCover(isPresented: $showPatternMatch) {
            PatternMatchGameView(onComplete: handleMinigameComplete)
                .environmentObject(themeManager)
                .environmentObject(userSettings)
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
    
    private func handleMinigameComplete(_ healthBonus: Int) {
        showTreatCatch = false
        showMemoryMatch = false
        showBubblePop = false
        showPatternMatch = false
        HapticFeedback.success.trigger()
    }
    
    // MARK: - Segment Picker (3 Tabs)
    private var segmentPicker: some View {
        HStack(spacing: 4) {
            // Minigames Tab
            SegmentButton(
                title: "Games",
                icon: "gamecontroller.fill",
                isSelected: selectedSegment == 0,
                badge: "FREE",
                badgeColor: .green
            ) {
                withAnimation(.spring(response: 0.3)) { selectedSegment = 0 }
                HapticFeedback.light.trigger()
            }
            
            // Play with Pet Tab
            SegmentButton(
                title: "Pet",
                icon: "heart.fill",
                isSelected: selectedSegment == 1,
                badge: "\(userSettings.playCredits)",
                badgeColor: .yellow
            ) {
                withAnimation(.spring(response: 0.3)) { selectedSegment = 1 }
                HapticFeedback.light.trigger()
            }
            
            // Achievements Tab
            SegmentButton(
                title: "Awards",
                icon: "trophy.fill",
                isSelected: selectedSegment == 2,
                badge: "\(achievementManager.unlockedCount)",
                badgeColor: themeManager.accentColor
            ) {
                withAnimation(.spring(response: 0.3)) { selectedSegment = 2 }
                HapticFeedback.light.trigger()
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 8, y: 3)
        )
    }
    
    // MARK: - Full Minigames Section
    private var minigamesFullSection: some View {
        VStack(spacing: 20) {
            // Header with pet
            HStack(spacing: 16) {
                // Pet preview
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeManager.accentColor.opacity(0.2), themeManager.accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    AnimatedPetVideoView(petType: userSettings.pet.type, moodState: .happy)
                        .frame(width: 65, height: 65)
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Play with \(userSettings.pet.name)!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("All games are FREE to play")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 10, y: 4)
            )
            
            // Game Cards
            VStack(spacing: 14) {
                // Mood Catch Game
                GameCard(
                    title: "Mood Catch",
                    description: "Catch happy moods, avoid sad ones!",
                    icon: "heart.circle.fill",
                    color: .orange,
                    gradient: [Color.orange, Color.yellow],
                    emoji: ""
                ) {
                    HapticFeedback.medium.trigger()
                    showTreatCatch = true
                }
                
                // Memory Match Game
                GameCard(
                    title: "Memory Match",
                    description: "Match pairs to test your memory!",
                    icon: "square.grid.2x2.fill",
                    color: .purple,
                    gradient: [Color.purple, Color.pink],
                    emoji: "🧠"
                ) {
                    HapticFeedback.medium.trigger()
                    showMemoryMatch = true
                }
                
                // Bubble Pop Game
                GameCard(
                    title: "Bubble Pop",
                    description: "Pop bubbles before they float away!",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: .cyan,
                    gradient: [Color.cyan, Color.blue],
                    emoji: "🫧"
                ) {
                    HapticFeedback.medium.trigger()
                    showBubblePop = true
                }
                
                // Pattern Match Game
                GameCard(
                    title: "Pattern Match",
                    description: "Remember the pattern, beat 5 levels!",
                    icon: "brain.head.profile",
                    color: Color(hex: "11998e"),
                    gradient: [Color(hex: "11998e"), Color(hex: "38ef7d")],
                    emoji: "🧩"
                ) {
                    HapticFeedback.medium.trigger()
                    showPatternMatch = true
                }
            }
            
            // Fun fact
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                
                Text("Playing games is a great way to bond with \(userSettings.pet.name)!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.yellow.opacity(0.1))
            )
        }
    }
    
    // MARK: - Play with Pet Section
    private var playWithPetSection: some View {
        VStack(spacing: 20) {
            // Credits Header
            HStack(spacing: 16) {
                // Credits display
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    VStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                        Text("\(userSettings.playCredits)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Play Credits")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("Each activity costs 1 credit & gives +20 health")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    if userSettings.todayPlayHealthBoost > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            Text("+\(userSettings.todayPlayHealthBoost) earned today")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                // Buy button
                Button(action: { showCreditsSheet = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(themeManager.accentColor)
                        Text("Buy")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 10, y: 4)
            )
            
            // Activity Cards
            VStack(spacing: 14) {
                ForEach(PetActivity.allCases) { activity in
                    PetActivityCard(
                        activity: activity,
                        petType: userSettings.pet.type,
                        hasCredits: userSettings.playCredits > 0
                    ) {
                        if userSettings.playCredits > 0 {
                            selectedActivity = activity
                            showActivitySheet = true
                        } else {
                            showCreditsSheet = true
                        }
                    }
                }
            }
            
            // Buy Credits Card
            Button(action: { showCreditsSheet = true }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userSettings.playCredits == 0 ? "Get Credits to Play" : "Buy More Credits")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("Starting at $1.99 for 3 credits")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.tertiaryTextColor)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.15), Color.orange.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1.5)
                        )
                )
            }
        }
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
            
            HapticFeedback.success.trigger()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showHealthBoostAnimation = false
                }
            }
        }
    }
    
    private func purchaseCredits(package: CreditPackage) {
        userSettings.playCredits += package.credits
        HapticFeedback.medium.trigger()
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
    
    @State private var isReady = false
    @State private var showAnimation = false
    @State private var animationComplete = false
    
    // Smaller animation size
    private let animationSize: CGFloat = 140
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer()
                
                if isReady {
                    if showAnimation {
                        VStack(spacing: 14) {
                            // GIF Animation for activity - smaller size
                            GIFImage(activity.gifName(for: petType))
                                .frame(width: animationSize, height: animationSize)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .id("\(activity.id)-\(petType.rawValue)-\(UUID())")
                            
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
                } else {
                    // Loading state
                    ProgressView()
                        .scaleEffect(1.2)
                }
                
                Spacer()
                
                if isReady {
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
        .onAppear {
            // Ensure view is ready before showing content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeIn(duration: 0.2)) {
                    isReady = true
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
            HapticFeedback.success.trigger()
        }
    }
}

// MARK: - Segment Button Component
struct SegmentButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let badge: String
    let badgeColor: Color
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : themeManager.secondaryTextColor)
                    
                    // Badge
                    Text(badge)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(badgeColor))
                        .offset(x: 14, y: -10)
                }
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? themeManager.accentColor : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Game Card Component
struct GameCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let gradient: [Color]
    let emoji: String
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: color.opacity(0.4), radius: 8, y: 4)
                    
                    if emoji.isEmpty {
                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Text(emoji)
                            .font(.system(size: 32))
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(2)
                    
                    // Free badge
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 10))
                        Text("Free to Play")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
                }
                
                Spacer()
                
                // Play button
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 10, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Pet Activity Card Component
struct PetActivityCard: View {
    let activity: PetActivity
    let petType: PetType
    let hasCredits: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Activity Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [activity.color, activity.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: activity.color.opacity(0.3), radius: 6, y: 3)
                    
                    Image(systemName: activity.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.rawValue)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    HStack(spacing: 8) {
                        // Cost
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text("1 credit")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Text("•")
                            .foregroundColor(themeManager.tertiaryTextColor)
                        
                        // Reward
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.pink)
                            Text("+20 health")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.pink)
                        }
                    }
                }
                
                Spacer()
                
                // Play button or lock
                if hasCredits {
                    ZStack {
                        Circle()
                            .fill(activity.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(activity.color)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.tertiaryTextColor)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 8, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(hasCredits ? activity.color.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(hasCredits ? 1 : 0.7)
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ChallengesView()
        .environmentObject(ThemeManager())
        .environmentObject(AchievementManager())
        .environmentObject(UserSettings())
}

