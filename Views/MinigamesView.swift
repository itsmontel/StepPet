//
//  MinigamesView.swift
//  StepPet
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
    
    var healthReward: String {
        switch self {
        case .treatCatch: return "+10-25"
        case .memoryMatch: return "+15-30"
        case .bubblePop: return "+10-20"
        }
    }
}

// MARK: - Minigames View
struct MinigamesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedGame: MinigameType?
    @State private var showGame = false
    
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
        .fullScreenCover(isPresented: $showGame) {
            if let game = selectedGame {
                switch game {
                case .treatCatch:
                    TreatCatchGameView(onComplete: handleGameComplete)
                        .environmentObject(themeManager)
                        .environmentObject(userSettings)
                case .memoryMatch:
                    MemoryMatchGameView(onComplete: handleGameComplete)
                        .environmentObject(themeManager)
                        .environmentObject(userSettings)
                case .bubblePop:
                    BubblePopGameView(onComplete: handleGameComplete)
                        .environmentObject(themeManager)
                        .environmentObject(userSettings)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Pet preview
            AnimatedPetView(petType: userSettings.pet.type, moodState: .happy)
                .frame(height: 100)
            
            Text("\(userSettings.pet.name) wants to play!")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            // Credits display
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)
                
                Text("\(userSettings.playCredits) credits available")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(themeManager.cardBackgroundColor)
            )
        }
        .padding(.top, 20)
    }
    
    // MARK: - Games Section
    private var gamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a Game")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            ForEach(MinigameType.allCases) { game in
                MinigameCard(
                    game: game,
                    isEnabled: userSettings.playCredits > 0
                ) {
                    if userSettings.playCredits > 0 {
                        selectedGame = game
                        showGame = true
                        HapticFeedback.medium.trigger()
                    }
                }
            }
        }
    }
    
    // MARK: - Handle Game Complete
    private func handleGameComplete(healthBonus: Int) {
        showGame = false
        
        if healthBonus > 0 {
            // Deduct credit and add health
            userSettings.playCredits -= 1
            userSettings.todayPlayHealthBoost += healthBonus
            userSettings.lastPlayBoostDate = Date()
            userSettings.pet.health = min(100, userSettings.pet.health + healthBonus)
            
            HapticFeedback.success.trigger()
        }
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
                    
                    // Reward badge
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.pink)
                        
                        Text("\(game.healthReward) health")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.pink)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.pink.opacity(0.12))
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
