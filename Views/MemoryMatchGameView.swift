//
//  MemoryMatchGameView.swift
//  StepPet
//

import SwiftUI

// MARK: - Memory Card
struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let color: Color
    var isFlipped: Bool = false
    var isMatched: Bool = false
    
    static func == (lhs: MemoryCard, rhs: MemoryCard) -> Bool {
        lhs.id == rhs.id
    }
    
    static let symbols: [(String, Color)] = [
        ("🦴", .orange),
        ("🐾", .brown),
        ("❤️", .red),
        ("⭐", .yellow),
        ("🎾", .green),
        ("🏠", .blue),
        ("🍖", .pink),
        ("🎀", .purple)
    ]
}

// MARK: - Memory Match Game View
struct MemoryMatchGameView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    let onComplete: (Int) -> Void
    
    // Game state
    @State private var gameState: GameState = .ready
    @State private var cards: [MemoryCard] = []
    @State private var selectedCards: [MemoryCard] = []
    @State private var moves: Int = 0
    @State private var matchedPairs: Int = 0
    @State private var timeElapsed: Int = 0
    @State private var isProcessing: Bool = false
    @State private var showMatchAnimation: Bool = false
    
    // Timer
    @State private var gameTimer: Timer?
    
    private let totalPairs = 8
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    enum GameState {
        case ready, playing, finished
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "667eea"),
                    Color(hex: "764ba2")
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
        HStack {
            // Close button
            Button(action: {
                stopGame()
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: 20) {
                // Moves
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.white)
                    
                    Text("\(moves)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // Timer
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.white)
                    
                    Text(formatTime(timeElapsed))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
            )
            
            Spacer()
            
            // Pairs found
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("\(matchedPairs)/\(totalPairs)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 10)
    }
    
    // MARK: - Cards Grid
    private var cardsGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(cards) { card in
                CardView(card: card) {
                    cardTapped(card)
                }
                .aspectRatio(0.7, contentMode: .fit)
            }
        }
    }
    
    // MARK: - Ready Overlay
    private var readyOverlay: some View {
        VStack(spacing: 24) {
            // Pet
            AnimatedPetView(petType: userSettings.pet.type, moodState: .happy)
                .frame(height: 120)
            
            Text("🃏 Memory Match 🃏")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 12) {
                Text("Match all the pairs!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Find matching cards in fewest moves")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
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
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
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
            
            // Stats
            VStack(spacing: 16) {
                StatRow(icon: "clock.fill", label: "Time", value: formatTime(timeElapsed))
                StatRow(icon: "hand.tap.fill", label: "Moves", value: "\(moves)")
                StatRow(icon: "star.fill", label: "Rating", value: getRating())
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.15))
            )
            
            // Fun game - no health reward
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
                    .fill(Color.purple.opacity(0.2))
            )
            
            Button(action: {
                onComplete(0) // No health reward
            }) {
                Text("Done!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
    }
    
    // MARK: - Game Logic
    private func startGame() {
        // Create pairs of cards
        var newCards: [MemoryCard] = []
        for (symbol, color) in MemoryCard.symbols {
            newCards.append(MemoryCard(symbol: symbol, color: color))
            newCards.append(MemoryCard(symbol: symbol, color: color))
        }
        
        // Shuffle
        cards = newCards.shuffled()
        
        // Reset state
        moves = 0
        matchedPairs = 0
        timeElapsed = 0
        selectedCards = []
        gameState = .playing
        
        // Start timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
        
        HapticFeedback.medium.trigger()
    }
    
    private func cardTapped(_ card: MemoryCard) {
        guard gameState == .playing,
              !isProcessing,
              !card.isFlipped,
              !card.isMatched,
              selectedCards.count < 2 else { return }
        
        // Find and flip the card
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                cards[index].isFlipped = true
            }
            selectedCards.append(cards[index])
            HapticFeedback.light.trigger()
            
            // Check for match if two cards selected
            if selectedCards.count == 2 {
                moves += 1
                isProcessing = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    checkForMatch()
                }
            }
        }
    }
    
    private func checkForMatch() {
        guard selectedCards.count == 2 else { return }
        
        let first = selectedCards[0]
        let second = selectedCards[1]
        
        if first.symbol == second.symbol {
            // Match found!
            if let index1 = cards.firstIndex(where: { $0.id == first.id }),
               let index2 = cards.firstIndex(where: { $0.id == second.id }) {
                
                withAnimation(.spring(response: 0.3)) {
                    cards[index1].isMatched = true
                    cards[index2].isMatched = true
                }
                
                matchedPairs += 1
                HapticFeedback.success.trigger()
                
                // Check if game complete
                if matchedPairs == totalPairs {
                    endGame()
                }
            }
        } else {
            // No match - flip back
            if let index1 = cards.firstIndex(where: { $0.id == first.id }),
               let index2 = cards.firstIndex(where: { $0.id == second.id }) {
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    cards[index1].isFlipped = false
                    cards[index2].isFlipped = false
                }
                
                HapticFeedback.warning.trigger()
            }
        }
        
        selectedCards = []
        isProcessing = false
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
        // Rating based on moves (fewer is better)
        if moves <= 16 {
            return "⭐⭐⭐"
        } else if moves <= 24 {
            return "⭐⭐"
        } else {
            return "⭐"
        }
    }
    
    private func calculateHealthReward() -> Int {
        // Base: 15-30 based on performance
        if moves <= 16 {
            return 30
        } else if moves <= 20 {
            return 25
        } else if moves <= 24 {
            return 20
        } else {
            return 15
        }
    }
}

// MARK: - Card View
struct CardView: View {
    let card: MemoryCard
    let action: () -> Void
    
    @State private var rotation: Double = 0
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Card back
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
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
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.3))
                    )
                    .opacity(card.isFlipped || card.isMatched ? 0 : 1)
                
                // Card front
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(card.isMatched ? Color.green : card.color.opacity(0.5), lineWidth: 3)
                    )
                    .overlay(
                        Text(card.symbol)
                            .font(.system(size: 40))
                    )
                    .opacity(card.isFlipped || card.isMatched ? 1 : 0)
            }
            .rotation3DEffect(
                .degrees(card.isFlipped || card.isMatched ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .scaleEffect(card.isMatched ? 0.95 : 1.0)
            .opacity(card.isMatched ? 0.7 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(card.isMatched)
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.yellow)
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
