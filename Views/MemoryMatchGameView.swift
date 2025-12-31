//
//  MemoryMatchGameView.swift
//  StepPet
//

import SwiftUI

// MARK: - Pet Mood Card
struct PetMoodCard: Identifiable {
    let id = UUID()
    let petType: PetType
    let mood: PetMoodState
    var isMatched: Bool = false
    
    // Unique value for matching (pet + mood combination)
    var value: String {
        "\(petType.rawValue)_\(mood.rawValue)"
    }
    
    var displayName: String {
        "\(petType.displayName) \(mood.displayName)"
    }
}

// MARK: - Memory Match Game View
struct MemoryMatchGameView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    let onComplete: (Int) -> Void
    
    // Game state - Using index-based tracking like reference
    @State private var gameState: MemoryGameState = .ready
    @State private var cards: [PetMoodCard] = []
    @State private var firstFlippedIndex: Int? = nil
    @State private var secondFlippedIndex: Int? = nil
    @State private var moves: Int = 0
    @State private var matchedPairs: Int = 0
    @State private var timeElapsed: Int = 0
    @State private var isProcessing: Bool = false
    @State private var refreshID = UUID() // Force refresh when cards update
    
    // Timer
    @State private var gameTimer: Timer?
    
    private let totalPairs = 8
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    enum MemoryGameState {
        case ready, playing, finished
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    themeManager.accentColor.opacity(0.8),
                    themeManager.accentColor.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                gameHeader
                
                // Game content
                ZStack {
                    if gameState == .ready {
                        readyOverlay
                    } else {
                        // Cards grid
                        cardsGrid
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                        
                        if gameState == .finished {
                            finishedOverlay
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Game Header
    private var gameHeader: some View {
        HStack(spacing: 8) {
            // Close button
            Button(action: {
                stopGame()
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            
            // Moves
            HStack(spacing: 4) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.accentColor)
                
                Text("\(moves)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.95))
            )
            
            // Timer
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.accentColor)
                
                Text(formatTime(timeElapsed))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.95))
            )
            
            Spacer()
            
            // Pairs found
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                
                Text("\(matchedPairs)/\(totalPairs)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.95))
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 10)
    }
    
    // MARK: - Cards Grid
    private var cardsGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                PetMoodCardView(
                    card: card,
                    isFlipped: isCardFlipped(at: index),
                    onTap: {
                        handleCardTap(at: index)
                    }
                )
                .id("\(card.id)-\(card.isMatched)-\(firstFlippedIndex == index)-\(secondFlippedIndex == index)-\(refreshID)")
                .aspectRatio(0.75, contentMode: .fit)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    // Check if a card should appear flipped
    private func isCardFlipped(at index: Int) -> Bool {
        if cards[index].isMatched {
            return true
        }
        return firstFlippedIndex == index || secondFlippedIndex == index
    }
    
    // MARK: - Ready Overlay
    private var readyOverlay: some View {
        VStack(spacing: 24) {
            // Pet preview
            let imageName = userSettings.pet.type.imageName(for: .happy)
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
            }
            
            Text("Memory Match")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 12) {
                Text("Match the pet moods!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Find 8 matching pairs of pets")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Preview of all 5 card types
            HStack(spacing: 10) {
                ForEach(PetMoodState.allCases, id: \.self) { mood in
                    VStack(spacing: 4) {
                        let imageName = userSettings.pet.type.imageName(for: mood)
                        if let _ = UIImage(named: imageName) {
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                        }
                        Text(mood.displayName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
            )
            
            Button(action: startGame) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("START")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(themeManager.accentColor)
                        .shadow(color: themeManager.accentColor.opacity(0.5), radius: 10, x: 0, y: 5)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Finished Overlay
    private var finishedOverlay: some View {
        VStack(spacing: 24) {
            Text("🎊 Complete! 🎊")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            // Pet celebration
            let imageName = userSettings.pet.type.imageName(for: .fullHealth)
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            }
            
            // Stats
            VStack(spacing: 16) {
                MemoryStatRow(icon: "clock.fill", label: "Time", value: formatTime(timeElapsed), color: themeManager.accentColor)
                MemoryStatRow(icon: "hand.tap.fill", label: "Moves", value: "\(moves)", color: themeManager.accentColor)
                MemoryStatRow(icon: "star.fill", label: "Rating", value: getRating(), color: .yellow)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.15))
            )
            
            // Fun game message
            VStack(spacing: 4) {
                Text("Great job!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(userSettings.pet.name) had fun playing!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.accentColor.opacity(0.2))
            )
            
            Button(action: {
                onComplete(0) // No health reward for minigames
            }) {
                Text("Done!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(themeManager.accentColor)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
    }
    
    // MARK: - Game Logic
    private func startGame() {
        // Create pairs using different pet types and moods
        var newCards: [PetMoodCard] = []
        
        // Use 8 different pet/mood combinations
        let petMoodCombinations: [(PetType, PetMoodState)] = [
            (.cat, .fullHealth),
            (.cat, .happy),
            (.dog, .content),
            (.dog, .sad),
            (.bunny, .fullHealth),
            (.bunny, .happy),
            (.hamster, .content),
            (.horse, .fullHealth)
        ]
        
        for (petType, mood) in petMoodCombinations {
            // Create pair
            newCards.append(PetMoodCard(petType: petType, mood: mood))
            newCards.append(PetMoodCard(petType: petType, mood: mood))
        }
        
        // Shuffle
        cards = newCards.shuffled()
        
        // Reset state
        moves = 0
        matchedPairs = 0
        timeElapsed = 0
        firstFlippedIndex = nil
        secondFlippedIndex = nil
        isProcessing = false
        gameState = .playing
        refreshID = UUID()
        
        // Start timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
        
        HapticFeedback.medium.trigger()
    }
    
    private func handleCardTap(at index: Int) {
        // Don't allow tap if processing or card is already matched
        guard !isProcessing else { return }
        guard !cards[index].isMatched else { return }
        
        // Don't allow tapping the same card that's already flipped
        guard firstFlippedIndex != index else { return }
        guard secondFlippedIndex != index else { return }
        
        HapticFeedback.light.trigger()
        
        if firstFlippedIndex == nil {
            // First card flip
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                firstFlippedIndex = index
            }
        } else if secondFlippedIndex == nil {
            // Second card flip
            moves += 1
            isProcessing = true
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                secondFlippedIndex = index
            }
            
            // Check for match after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                checkForMatch()
            }
        }
    }
    
    private func checkForMatch() {
        guard let first = firstFlippedIndex, let second = secondFlippedIndex else {
            isProcessing = false
            return
        }
        
        let firstCard = cards[first]
        let secondCard = cards[second]
        
        if firstCard.value == secondCard.value {
            // Match found!
            matchedPairs += 1
            HapticFeedback.success.trigger()
            
            // Update cards
            var updatedCards = cards
            updatedCards[first].isMatched = true
            updatedCards[second].isMatched = true
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                cards = updatedCards
                refreshID = UUID()
            }
            
            // Keep cards flipped briefly then reset indices
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    firstFlippedIndex = nil
                    secondFlippedIndex = nil
                }
                isProcessing = false
                
                // Check if game complete
                if matchedPairs == totalPairs {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        endGame()
                    }
                }
            }
        } else {
            // No match - flip cards back
            HapticFeedback.error.trigger()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                firstFlippedIndex = nil
                secondFlippedIndex = nil
            }
            isProcessing = false
        }
    }
    
    private func endGame() {
        gameState = .finished
        stopGame()
        HapticFeedback.success.trigger()
    }
    
    private func stopGame() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func getRating() -> String {
        if moves <= 16 {
            return "⭐⭐⭐"
        } else if moves <= 24 {
            return "⭐⭐"
        } else {
            return "⭐"
        }
    }
}

// MARK: - Pet Mood Card View
struct PetMoodCardView: View {
    let card: PetMoodCard
    let isFlipped: Bool
    let onTap: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Card back (question mark side)
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                    )
                    .opacity((isFlipped || card.isMatched) ? 0 : 1)
                
                // Card front (pet mood side)
                RoundedRectangle(cornerRadius: 12)
                    .fill(card.isMatched ? Color.green.opacity(0.2) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(card.isMatched ? Color.green : themeManager.accentColor.opacity(0.3), lineWidth: 2)
                    )
                    .overlay(
                        VStack(spacing: 4) {
                            let imageName = card.petType.imageName(for: card.mood)
                            if let uiImage = UIImage(named: imageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                            } else {
                                Text(card.petType.emoji)
                                    .font(.system(size: 36))
                            }
                            
                            Text(card.mood.displayName)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(card.mood.color)
                                .lineLimit(1)
                        }
                        .padding(4)
                    )
                    .opacity((isFlipped || card.isMatched) ? 1 : 0)
                
                // Matched checkmark overlay
                if card.isMatched {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                                .padding(4)
                        }
                        Spacer()
                    }
                }
            }
            .scaleEffect(card.isMatched ? 0.95 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFlipped)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: card.isMatched)
        }
        .disabled(card.isMatched)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Memory Stat Row
struct MemoryStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview
#Preview {
    MemoryMatchGameView(onComplete: { _ in })
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
