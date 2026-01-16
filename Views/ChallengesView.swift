//
//  ChallengesView.swift
//  VirtuPet
//

import SwiftUI
import RevenueCat

struct ChallengesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var tutorialManager: TutorialManager
    @ObservedObject var purchaseManager = PurchaseManager.shared
    
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var showCompletedOnly = false
    @State private var selectedChallenge: Achievement?
    @State private var selectedSegment = 0 // 0 = Minigames, 1 = Play with Pet, 2 = Achievements
    
    // Activities & Minigames States
    @State private var showCreditsSheet = false
    @State private var showCreditsPurchaseError = false
    @State private var creditsPurchaseErrorMessage = ""
    @State private var selectedActivity: PetActivity?
    @State private var showHealthBoostAnimation = false
    @State private var healthBoostAmount = 0
    @State private var selectedGame: MinigameType?
    @State private var showTreatCatch = false
    @State private var showMemoryMatch = false
    @State private var showBubblePop = false
    @State private var showPatternMatch = false
    @State private var showSkyFall = false
    @State private var currentPlayingGame: String = "" // Track which game is being played
    
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
        .onChange(of: tutorialManager.challengesSegment) { _, newSegment in
            // Switch segment when tutorial requires it
            if tutorialManager.isActive {
                withAnimation {
                    selectedSegment = newSegment
                }
            }
        }
        .sheet(item: $selectedChallenge) { challenge in
            ChallengeDetailSheet(challenge: challenge)
        }
        .sheet(isPresented: $showCreditsSheet) { creditsSheet }
        .alert("Unable to Purchase", isPresented: $showCreditsPurchaseError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(creditsPurchaseErrorMessage)
        }
        .sheet(item: $selectedActivity) { activity in
                ActivityPlaySheet(
                    activity: activity,
                    petType: userSettings.pet.type,
                    onComplete: { handleActivityComplete() }
                )
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
        .fullScreenCover(isPresented: $showSkyFall) {
            SkyFallGameView(onComplete: handleMinigameComplete)
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
        // Track the game that was played for achievements
        trackMinigamePlayed()
        
        showTreatCatch = false
        showMemoryMatch = false
        showBubblePop = false
        showPatternMatch = false
        showSkyFall = false
        currentPlayingGame = ""
        HapticFeedback.success.trigger()
    }
    
    private func trackMinigamePlayed() {
        // Map game name to UserSettings.MinigameType
        let gameType: UserSettings.MinigameType
        switch currentPlayingGame {
        case "treat_catch":
            gameType = .moodCatch
        case "memory_match":
            gameType = .memoryMatch
        case "sky_fall":
            gameType = .skyFall
        case "pattern_match":
            gameType = .patternMatch
        default:
            gameType = .moodCatch
        }
        
        // Record the game played
        userSettings.recordMinigamePlayed(type: gameType)
        
        // Check game achievements
        achievementManager.checkGameAchievements(
            totalMinigamesPlayed: userSettings.totalMinigamesPlayed,
            totalPetActivitiesPlayed: userSettings.totalPetActivitiesPlayed,
            moodCatchPlayed: userSettings.moodCatchPlayed,
            memoryMatchPlayed: userSettings.memoryMatchPlayed,
            skyFallPlayed: userSettings.skyFallPlayed,
            patternMatchPlayed: userSettings.patternMatchPlayed,
            feedActivityCount: userSettings.feedActivityCount,
            playBallActivityCount: userSettings.playBallActivityCount,
            watchTVActivityCount: userSettings.watchTVActivityCount,
            totalCreditsUsed: userSettings.totalCreditsUsed,
            consecutiveGameDays: userSettings.consecutiveGameDays,
            didAllActivitiesToday: userSettings.didAllActivitiesToday
        )
    }
    
    // Start a minigame (no longer deducts credit - happens in game view)
    private func startMinigame(_ game: () -> Void) {
        // Just check if they have credits before opening
        guard userSettings.totalCredits > 0 else {
            showCreditsSheet = true
            return
        }
        HapticFeedback.medium.trigger()
        game()
    }
    
    // MARK: - Segment Picker (3 Tabs)
    private var segmentPicker: some View {
        HStack(spacing: 4) {
            // Minigames Tab
            SegmentButton(
                title: "Games",
                icon: "gamecontroller.fill",
                isSelected: selectedSegment == 0,
                badge: "\(userSettings.totalCredits)",
                badgeColor: .yellow
            ) {
                withAnimation(.spring(response: 0.3)) { selectedSegment = 0 }
                HapticFeedback.light.trigger()
            }
            
            // Play with Pet Tab
            SegmentButton(
                title: "Pet",
                icon: "heart.fill",
                isSelected: selectedSegment == 1,
                badge: "\(userSettings.totalCredits)",
                badgeColor: .pink
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
            // Credits Header for Games
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
                        Text("\(userSettings.totalCredits)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Play Credits")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("\(userSettings.dailyFreeCredits) daily")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                        
                        if userSettings.playCredits > 0 {
                            Text("•")
                                .foregroundColor(themeManager.tertiaryTextColor)
                            Image(systemName: "bag.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("\(userSettings.playCredits) bought")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.accentColor)
                        Text("1 credit = +3 health")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
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
            
            // Game Cards - ALL FREE (use credits)
            VStack(spacing: 14) {
                // Mood Catch Game
                CreditGameCard(
                    title: "Mood Catch",
                    description: "Catch happy moods, avoid sad ones!",
                    icon: "heart.circle.fill",
                    color: themeManager.moodCatchColor,
                    gradient: [Color(hex: "FF6B4A"), Color(hex: "FFD93D")],
                    emoji: "",
                    hasCredits: userSettings.totalCredits > 0
                ) {
                    currentPlayingGame = "treat_catch"
                    startMinigame { showTreatCatch = true }
                }
                
                // Memory Match Game
                CreditGameCard(
                    title: "Memory Match",
                    description: "Match pairs to test your memory!",
                    icon: "square.grid.2x2.fill",
                    color: themeManager.memoryMatchColor,
                    gradient: [Color(hex: "A855F7"), Color(hex: "EC4899")],
                    emoji: "🧠",
                    hasCredits: userSettings.totalCredits > 0
                ) {
                    currentPlayingGame = "memory_match"
                    startMinigame { showMemoryMatch = true }
                }
                
                // Sky Fall Game
                CreditGameCard(
                    title: "Sky Fall",
                    description: "Dodge walls and rise to the top!",
                    icon: "arrow.up.forward.circle.fill",
                    color: themeManager.skyFallColor,
                    gradient: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                    emoji: "🌟",
                    hasCredits: userSettings.totalCredits > 0
                ) {
                    currentPlayingGame = "sky_fall"
                    startMinigame { showSkyFall = true }
                }
                
                // Pattern Match Game
                CreditGameCard(
                    title: "Pattern Match",
                    description: "Remember the pattern, beat 5 levels!",
                    icon: "brain.head.profile",
                    color: themeManager.patternMatchColor,
                    gradient: [Color(hex: "11998E"), Color(hex: "38EF7D")],
                    emoji: "🧩",
                    hasCredits: userSettings.totalCredits > 0
                ) {
                    currentPlayingGame = "pattern_match"
                    startMinigame { showPatternMatch = true }
                }
            }
            
            // Daily credits info
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(userSettings.isPremium ? "10 free credits every day!" : "5 free credits every day!")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(themeManager.primaryTextColor)
                    Text("Resets at midnight • Buy more anytime")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.1))
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
                                colors: [Color.pink.opacity(0.3), Color.red.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    VStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.pink)
                        Text("\(userSettings.totalCredits)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pet Activities")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("\(userSettings.dailyFreeCredits) daily")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                        
                        if userSettings.playCredits > 0 {
                            Text("•")
                                .foregroundColor(themeManager.tertiaryTextColor)
                            Image(systemName: "bag.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("\(userSettings.playCredits) bought")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.pink)
                        Text("1 credit = +5 health")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    if userSettings.todayPlayHealthBoost > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
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
                        hasCredits: userSettings.totalCredits > 0
                    ) {
                        if userSettings.totalCredits > 0 {
                            selectedActivity = activity
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
                        Text(userSettings.totalCredits == 0 ? "Get Credits to Play" : "Buy More Credits")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("Starting at \(CreditPackage.packages.first?.price ?? "$1.99") for \(CreditPackage.packages.first?.credits ?? 5) credits")
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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero Section with Credit Balance
                    VStack(spacing: 14) {
                        // Credit count
                        VStack(spacing: 3) {
                            Text("\(userSettings.totalCredits)")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [themeManager.primaryDarkColor, themeManager.primaryColor, themeManager.primaryLightColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Credits Available")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        // Credit breakdown pills with theme colors
                        HStack(spacing: 10) {
                            HStack(spacing: 5) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 11))
                                Text("\(userSettings.dailyFreeCredits) free")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(themeManager.successColor)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(themeManager.successColor.opacity(0.12))
                            )
                            
                            HStack(spacing: 5) {
                                Image(systemName: "bag.fill")
                                    .font(.system(size: 11))
                                Text("\(userSettings.playCredits) bought")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(themeManager.primaryColor)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(themeManager.primaryColor.opacity(0.12))
                            )
                        }
                    }
                    .padding(.top, 8)
                    
                    // Credit Packages Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(themeManager.primaryColor)
                            
                            Text("Get More Credits")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(spacing: 10) {
                            ForEach(Array(CreditPackage.packages.enumerated()), id: \.element.id) { index, package in
                                creditPackageCard(package: package, index: index)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        purchaseCredits(package: package)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // How Credits Work Section with theme colors
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(themeManager.infoColor)
                            
                            Text("How Credits Work")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(spacing: 10) {
                            // Daily credits info
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.successColor.opacity(0.12))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(themeManager.successColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Daily Free Credits")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.primaryTextColor)
                                    Text(userSettings.isPremium ? "10 credits reset at midnight" : "5 credits reset at midnight")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                
                                Spacer()
                            }
                            
                            Divider().opacity(0.3)
                            
                            // Games info
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.infoColor.opacity(0.12))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(themeManager.infoColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Mini Games")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.primaryTextColor)
                                    Text("1 credit = +3 pet health")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                Text("+3 ❤️")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(themeManager.infoColor)
                            }
                            
                            Divider().opacity(0.3)
                            
                            // Activities info
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.accentPink.opacity(0.12))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(themeManager.accentPink)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Pet Activities")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.primaryTextColor)
                                    Text("1 credit = +5 pet health")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                Text("+5 ❤️")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(themeManager.accentPink)
                            }
                        }
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(themeManager.cardBackgroundColor)
                                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.04), radius: 8, y: 3)
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Footer
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.successColor)
                            Text("Secure purchase via App Store")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Text("Credits never expire!")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(themeManager.successColor)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showCreditsSheet = false }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    // MARK: - Credit Package Card
    @ViewBuilder
    private func creditPackageCard(package: CreditPackage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 14) {
                // Credit coin stack with theme colors
                ZStack {
                    // Multiple coins effect
                    ForEach(0..<min(3, max(1, package.credits / 8)), id: \.self) { i in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [themeManager.primaryColor, themeManager.primaryLightColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40 - CGFloat(i * 4), height: 40 - CGFloat(i * 4))
                            .offset(x: CGFloat(i * 3), y: CGFloat(i * -3))
                            .shadow(color: themeManager.primaryColor.opacity(0.2), radius: 2, y: 1)
                    }
                    
                    Text("\(package.credits)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 1, y: 1)
                }
                .frame(width: 50, height: 50)
                
                // Package info
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(package.credits) Credits")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    if let savings = package.savings {
                        Text(savings)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.successColor)
                    } else {
                        Text("Perfect for trying out!")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                // Price button with theme gradient
                Text(package.price)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: package.isPopular ? 
                                    [themeManager.primaryDarkColor, themeManager.primaryColor, themeManager.primaryLightColor] :
                                    [themeManager.primaryColor, themeManager.primaryLightColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: themeManager.primaryColor.opacity(0.35), radius: 8, y: 4)
                )
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                package.isPopular ?
                                LinearGradient(
                                    colors: [themeManager.primaryDarkColor, themeManager.primaryColor, themeManager.primaryLightColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing),
                                lineWidth: package.isPopular ? 2.5 : 0
                            )
                    )
                    .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: package.isPopular ? 12 : 8, y: package.isPopular ? 6 : 3)
            )
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
        // Credits and health already handled when user clicked "Start"
        // Just close the sheet
        selectedActivity = nil
    }
    
    private func purchaseCredits(package: CreditPackage) {
        // Find matching RevenueCat package by product ID
        print("🛒 Attempting to purchase: \(package.productId)")
        print("📦 Available credit products: \(purchaseManager.creditProducts.count)")
        print("📦 Product IDs: \(purchaseManager.creditProducts.map { $0.storeProduct.productIdentifier })")
        
        Task {
            if let rcPackage = purchaseManager.creditProducts.first(where: { 
                $0.storeProduct.productIdentifier == package.productId
            }) {
                print("✅ Found matching package, starting purchase...")
                let success = await purchaseManager.purchaseCredits(package: rcPackage, userSettings: userSettings)
                if success {
                    HapticFeedback.success.trigger()
                    showCreditsSheet = false
                }
            } else {
                // Products not loaded from RevenueCat - show error alert
                await MainActor.run {
                    HapticFeedback.error.trigger()
                    creditsPurchaseErrorMessage = "Credit packages are still loading. Please wait a moment and try again.\n\nIf this persists, products may still be syncing with App Store Connect (can take 1-2 hours after first upload)."
                    showCreditsPurchaseError = true
                    print("❌ Credit package not found: \(package.productId)")
                    print("❌ Available packages: \(purchaseManager.creditProducts.map { $0.storeProduct.productIdentifier })")
                }
            }
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
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Pet (no badge)
            AnimatedPetVideoView(
                petType: userSettings.pet.type,
                moodState: .fullHealth
            )
            .frame(width: 55, height: 55)
            .clipShape(Circle())
        }
        .padding(.top, 16)
    }
    
    // MARK: - Progress Banner
    private var progressBanner: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("🏆")
                            .font(.system(size: 16))
                        Text("Your Progress")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                    
                    Text("\(achievementManager.unlockedCount) of \(achievementManager.totalCount) completed")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Percentage in indigo-blue
                Text("\(Int(achievementManager.completionPercentage * 100))%")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryColor)
            }
            
            // Progress Bar in indigo-blue
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 14)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.primaryColor)
                        .frame(width: geometry.size.width * achievementManager.completionPercentage, height: 14)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: achievementManager.completionPercentage)
                        .shadow(color: themeManager.primaryColor.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: 14)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.secondaryCardColor)
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
    @EnvironmentObject var achievementManager: AchievementManager
    @Environment(\.dismiss) var dismiss
    
    @State private var hasStarted = false
    @State private var animationComplete = false
    @State private var pulseAnimation = false
    @State private var isGIFAnimating = false
    
    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.height < 600
            let animationSize: CGFloat = isCompact ? min(geo.size.width * 0.7, 280) : min(geo.size.width * 0.80, 320)
            
            ZStack {
                // Background gradient matching app theme
                LinearGradient(
                    colors: themeManager.isDarkMode 
                        ? [Color(red: 0.12, green: 0.12, blue: 0.14), Color(red: 0.18, green: 0.18, blue: 0.20)]
                        : [Color(red: 1.0, green: 0.98, blue: 0.90), Color(red: 1.0, green: 0.96, blue: 0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Decorative circles
                Circle()
                    .fill(activity.color.opacity(0.08))
                    .frame(width: geo.size.width * 0.8)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.2)
                    .blur(radius: 60)
                
                Circle()
                    .fill(activity.color.opacity(0.06))
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.3)
                    .blur(radius: 50)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.secondaryTextColor)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(themeManager.cardBackgroundColor))
                        }
                        
                        Spacer()
                        
                        // Credits badge
                        HStack(spacing: 5) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow)
                            Text("\(userSettings.totalCredits)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(themeManager.cardBackgroundColor)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Main content - GIF is always loaded, just with overlay when not started
                    VStack(spacing: isCompact ? 16 : 24) {
                        // GIF container - always visible, loads immediately
                        ZStack {
                            // Glow effect behind GIF
                            RoundedRectangle(cornerRadius: 24)
                                .fill(activity.color.opacity(0.15))
                                .frame(width: animationSize + 20, height: animationSize + 20)
                                .blur(radius: 20)
                                .scaleEffect(pulseAnimation && hasStarted ? 1.05 : 1.0)
                            
                            // GIF card - ALWAYS present for preloading
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(themeManager.cardBackgroundColor)
                                    .shadow(color: activity.color.opacity(0.2), radius: 20, y: 8)
                                
                                // GIF is always in view tree, just controls animation state
                                GIFImage(activity.gifName(for: petType), isAnimating: $isGIFAnimating)
                                    .frame(width: animationSize - 16, height: animationSize - 16)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                // Overlay with play icon when not started
                                if !hasStarted {
                                    ZStack {
                                        Color.black.opacity(0.3)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        
                                        VStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.white.opacity(0.9))
                                                    .frame(width: 60, height: 60)
                                                
                                                Image(systemName: "play.fill")
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(activity.color)
                                            }
                                            .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                                            
                                            Text("Tap Start to Play")
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(width: animationSize - 16, height: animationSize - 16)
                                }
                            }
                            .frame(width: animationSize, height: animationSize)
                        }
                        
                        // Activity title
                        Text(activity.displayName(for: petType))
                            .font(.system(size: isCompact ? 20 : 24, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        // Status text
                        if animationComplete {
                            VStack(spacing: 10) {
                                // Success emoji
                                Text("🎉")
                                    .font(.system(size: isCompact ? 32 : 44))
                                
                                Text("\(userSettings.pet.name) loved it!")
                                    .font(.system(size: isCompact ? 16 : 18, weight: .bold, design: .rounded))
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                // Health boost badge
                                HStack(spacing: 6) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 12))
                                    Text("+5 Health")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                )
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else if hasStarted {
                            // Playing indicator
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { i in
                                    Circle()
                                        .fill(activity.color)
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(pulseAnimation ? 1.0 : 0.5)
                                        .animation(
                                            .easeInOut(duration: 0.6)
                                            .repeatForever()
                                            .delay(Double(i) * 0.15),
                                            value: pulseAnimation
                                        )
                                }
                                
                                Text("Playing")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                        } else {
                            // Cost info when not started
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.yellow)
                                
                                Text("Costs 1 Credit")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.yellow.opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom button
                    if animationComplete {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Done!")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.85)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Color.green.opacity(0.3), radius: 10, y: 5)
                            )
                        }
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if !hasStarted {
                        Button(action: startActivity) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Start Activity")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [activity.color, activity.color.opacity(0.85)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: activity.color.opacity(0.3), radius: 10, y: 5)
                            )
                        }
                        .padding(.horizontal, 20)
                        .disabled(userSettings.totalCredits <= 0)
                        .opacity(userSettings.totalCredits > 0 ? 1 : 0.5)
                    }
                    
                    Spacer().frame(height: isCompact ? 20 : 30)
                }
            }
        }
    }
    
    private func startActivity() {
        // Deduct credit and add health immediately
        guard userSettings.useActivityCredit() else {
            dismiss()
            return
        }
        
        // Track pet activity for achievements
        trackPetActivity()
        
        HapticFeedback.medium.trigger()
        
        // Start GIF animation and update state
        isGIFAnimating = true
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            hasStarted = true
            pulseAnimation = true
        }
        
        // Complete after animation plays
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animationComplete = true
            }
            HapticFeedback.success.trigger()
        }
    }
    
    private func trackPetActivity() {
        // Map PetActivity to UserSettings.PetActivityType
        let activityType: UserSettings.PetActivityType
        switch activity {
        case .feed:
            activityType = .feed
        case .playBall:
            activityType = .playBall
        case .watchTV:
            activityType = .watchTV
        }
        
        // Record the pet activity
        userSettings.recordPetActivity(type: activityType)
        
        // Check game achievements
        achievementManager.checkGameAchievements(
            totalMinigamesPlayed: userSettings.totalMinigamesPlayed,
            totalPetActivitiesPlayed: userSettings.totalPetActivitiesPlayed,
            moodCatchPlayed: userSettings.moodCatchPlayed,
            memoryMatchPlayed: userSettings.memoryMatchPlayed,
            skyFallPlayed: userSettings.skyFallPlayed,
            patternMatchPlayed: userSettings.patternMatchPlayed,
            feedActivityCount: userSettings.feedActivityCount,
            playBallActivityCount: userSettings.playBallActivityCount,
            watchTVActivityCount: userSettings.watchTVActivityCount,
            totalCreditsUsed: userSettings.totalCreditsUsed,
            consecutiveGameDays: userSettings.consecutiveGameDays,
            didAllActivitiesToday: userSettings.didAllActivitiesToday
        )
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
    var isFree: Bool = false
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
                    
                    // Free badge (only show if isFree)
                    if isFree {
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

// MARK: - Credit Game Card Component (uses credits instead of premium)
struct CreditGameCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let gradient: [Color]
    let emoji: String
    let hasCredits: Bool
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
                    
                    // Credit cost badge
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text("1 credit")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text("•")
                            .foregroundColor(themeManager.tertiaryTextColor)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("+3 health")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.yellow.opacity(0.1)))
                }
                
                Spacer()
                
                // Play button or lock
                ZStack {
                    Circle()
                        .fill(hasCredits ? color.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: hasCredits ? "play.fill" : "lock.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(hasCredits ? color : .gray)
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
                    .stroke(hasCredits ? color.opacity(0.2) : Color.clear, lineWidth: 1)
            )
            .opacity(hasCredits ? 1 : 0.7)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Premium Game Card Component (with lock for non-premium users)
struct PremiumGameCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let gradient: [Color]
    let emoji: String
    let isPremium: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showPremiumAlert = false
    
    var body: some View {
        Button(action: {
            if isPremium {
                action()
            } else {
                HapticFeedback.warning.trigger()
                showPremiumAlert = true
            }
        }) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: isPremium ? gradient : [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: (isPremium ? color : Color.gray).opacity(0.4), radius: 8, y: 4)
                    
                    if isPremium {
                        if emoji.isEmpty {
                            Image(systemName: icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Text(emoji)
                                .font(.system(size: 32))
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(isPremium ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
                    
                    Text(description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(2)
                    
                    // Premium badge
                    HStack(spacing: 4) {
                        Image(systemName: isPremium ? "crown.fill" : "lock.fill")
                            .font(.system(size: 10))
                        Text(isPremium ? "Premium" : "Premium Only")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(isPremium ? .yellow : themeManager.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill((isPremium ? Color.yellow : themeManager.accentColor).opacity(0.15)))
                }
                
                Spacer()
                
                // Play/Lock button
                ZStack {
                    Circle()
                        .fill((isPremium ? color : Color.gray).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isPremium ? "play.fill" : "lock.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isPremium ? color : .gray)
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
                    .stroke((isPremium ? color : Color.gray).opacity(0.2), lineWidth: 1)
            )
            .opacity(isPremium ? 1 : 0.8)
        }
        .buttonStyle(ScaleButtonStyle())
        .alert("Premium Feature", isPresented: $showPremiumAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(title) is a premium game. Upgrade to unlock all games and features!")
        }
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
                        
                        // Reward - +5 health for pet activities
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.pink)
                            Text("+5 health")
                                .font(.system(size: 11, weight: .bold))
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
    func makeBody(configuration: Self.Configuration) -> some View {
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

