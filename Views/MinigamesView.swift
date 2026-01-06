//
//  MinigamesView.swift
//  VirtuPet
//

import SwiftUI

// MARK: - Minigame Type
enum MinigameType: String, CaseIterable, Identifiable {
    case treatCatch = "Treat Catch"
    case memoryMatch = "Memory Match"
    case bubblePop = "Bubble Pop"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .treatCatch: return "fork.knife"
        case .memoryMatch: return "square.grid.3x3.fill"
        case .bubblePop: return "bubble.left.and.bubble.right.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .treatCatch: return .orange
        case .memoryMatch: return .purple
        case .bubblePop: return .cyan
        }
    }
    
    var description: String {
        switch self {
        case .treatCatch: return "Catch falling treats!"
        case .memoryMatch: return "Match the cards!"
        case .bubblePop: return "Pop the bubbles!"
        }
    }
    
    var funDescription: String {
        switch self {
        case .treatCatch: return "Catch treats and avoid broccoli!"
        case .memoryMatch: return "Match pairs to win!"
        case .bubblePop: return "Pop bubbles for points!"
        }
    }
}

// MARK: - Minigames View
struct MinigamesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var achievementManager: AchievementManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedGame: MinigameType?
    @State private var showTreatCatch = false
    @State private var showMemoryMatch = false
    @State private var showBubblePop = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Info
                    headerSection
                    
                    // Games Grid
                    gamesSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Minigames")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .fullScreenCover(isPresented: $showTreatCatch) {
            TreatCatchGameView(onComplete: handleGameComplete)
                .environmentObject(themeManager)
                .environmentObject(userSettings)
        }
        .fullScreenCover(isPresented: $showMemoryMatch) {
            MemoryMatchGameView(onComplete: handleGameComplete)
                .environmentObject(themeManager)
                .environmentObject(userSettings)
        }
        .fullScreenCover(isPresented: $showBubblePop) {
            BubblePopGameView(onComplete: handleGameComplete)
                .environmentObject(themeManager)
                .environmentObject(userSettings)
        }
    }
    
    private func showGame(_ game: MinigameType) {
        selectedGame = game
        
        // Small delay to ensure state is set
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            switch game {
            case .treatCatch:
                showTreatCatch = true
            case .memoryMatch:
                showMemoryMatch = true
            case .bubblePop:
                showBubblePop = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Pet preview (MP4)
            AnimatedPetVideoView(petType: userSettings.pet.type, moodState: .happy)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: themeManager.accentColor.opacity(0.15), radius: 10, x: 0, y: 5)
            
            Text("\(userSettings.pet.name) wants to play!")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            // Free to play badge
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                
                Text("Free to Play - No Credits Needed!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.15))
            )
        }
        .padding(.top, 20)
    }
    
    // MARK: - Games Section
    private var gamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Choose a Game")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                // Free badge
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("FREE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.green.opacity(0.15)))
            }
            
            Text("Play fun games with \(userSettings.pet.name)! No credits needed.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
            
            ForEach(MinigameType.allCases) { game in
                MinigameCard(
                    game: game,
                    isEnabled: true // Always enabled - free to play
                ) {
                    HapticFeedback.medium.trigger()
                    showGame(game)
                }
            }
        }
    }
    
    // MARK: - Handle Game Complete
    private func handleGameComplete(healthBonus: Int) {
        // Track the game that was played for achievements
        if let game = selectedGame {
            trackGamePlayed(game)
        }
        
        // Close all game sheets
        showTreatCatch = false
        showMemoryMatch = false
        showBubblePop = false
        
        // Minigames are free - no credits deducted, no health added
        // Just a fun game to play!
        HapticFeedback.success.trigger()
        selectedGame = nil
    }
    
    // MARK: - Track Game for Achievements
    private func trackGamePlayed(_ game: MinigameType) {
        // Map MinigameType to UserSettings.MinigameType
        let settingsGameType: UserSettings.MinigameType
        switch game {
        case .bubblePop:
            settingsGameType = .bubblePop
        case .memoryMatch:
            settingsGameType = .memoryMatch
        case .treatCatch:
            settingsGameType = .patternMatch // Using patternMatch for treat catch
        }
        
        // Record the game played
        userSettings.recordMinigamePlayed(type: settingsGameType)
        
        // Check game achievements
        achievementManager.checkGameAchievements(
            totalMinigamesPlayed: userSettings.totalMinigamesPlayed,
            totalPetActivitiesPlayed: userSettings.totalPetActivitiesPlayed,
            bubblePopPlayed: userSettings.bubblePopPlayed,
            memoryMatchPlayed: userSettings.memoryMatchPlayed,
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

// MARK: - Minigame Card
struct MinigameCard: View {
    let game: MinigameType
    let isEnabled: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(game.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: game.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(game.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.rawValue)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(game.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    // Free badge
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        
                        Text("Free to Play")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.12))
                    )
                }
                
                Spacer()
                
                // Play button
                ZStack {
                    Circle()
                        .fill(isEnabled ? game.color : Color.gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 8, x: 0, y: 4)
            )
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
}

// MARK: - Preview
#Preview {
    MinigamesView()
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
