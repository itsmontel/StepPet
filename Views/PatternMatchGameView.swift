//
//  PatternMatchGameView.swift
//  StepPet
//

import SwiftUI

// MARK: - Pattern Game State
enum PatternGameState {
    case ready
    case showing
    case input
    case levelComplete
    case gameComplete
    case failure
}

// MARK: - Pattern Match Game View
struct PatternMatchGameView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    let onComplete: (Int) -> Void
    
    // Game state
    @State private var gameState: PatternGameState = .ready
    @State private var currentLevel: Int = 1
    @State private var currentShowIndex: Int = 0
    @State private var showElement: PetMoodState? = nil
    @State private var userInput: [PetMoodState] = []
    @State private var attemptsLeft: Int = 3
    @State private var currentSequence: [PetMoodState] = []
    @State private var isAnimating: Bool = false
    
    // Best level tracking
    @State private var bestLevel: Int = PatternMatchHighScoreManager.shared.bestLevel
    @State private var isNewBestLevel: Bool = false
    
    // Pattern lengths per level: Level 1 = 4, Level 2 = 5, ... Level 5 = 8
    private func patternLengthForLevel(_ level: Int) -> Int {
        return 3 + level // Level 1 = 4, Level 2 = 5, etc.
    }
    
    private let maxLevel = 5
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "11998e"),
                    Color(hex: "38ef7d")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                gameHeader
                
                // Content
                if gameState == .ready {
                    readyOverlay
                } else if gameState == .showing {
                    showingView
                } else if gameState == .input {
                    inputView
                } else if gameState == .levelComplete {
                    levelCompleteOverlay
                } else if gameState == .gameComplete {
                    gameCompleteOverlay
                } else if gameState == .failure {
                    failureOverlay
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Game Header
    private var gameHeader: some View {
        HStack(spacing: 12) {
            // Close button - fixed width for alignment
            Button(action: {
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.1), radius: 4)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 36)
            
            Spacer()
            
            // Level - Centered and prominent
            HStack(spacing: 6) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                
                Text("Level \(currentLevel)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.1), radius: 4)
            )
            
            Spacer()
            
            // Attempts - fixed width for alignment
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < attemptsLeft ? "heart.fill" : "heart.slash.fill")
                        .font(.system(size: 14))
                        .foregroundColor(index < attemptsLeft ? .red : .gray.opacity(0.4))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.1), radius: 4)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 55)
        .padding(.bottom, 12)
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
            
            Text("Pattern Match")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Best level
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Best: Level \(bestLevel)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.white.opacity(0.2)))
            
            VStack(spacing: 12) {
                Text("Remember the pattern!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Watch the pet moods, then repeat in order")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Level info
            VStack(spacing: 8) {
                Text("5 Levels to Complete")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { level in
                        VStack(spacing: 2) {
                            Text("L\(level)")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(3 + level)")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                        )
                        .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
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
                        .fill(Color(hex: "11998e"))
                        .shadow(color: Color(hex: "11998e").opacity(0.5), radius: 10, x: 0, y: 5)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Showing View
    private var showingView: some View {
        VStack(spacing: 30) {
            Text("Watch carefully...")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            // Current element display
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 180, height: 180)
                
                if let element = showElement {
                    VStack(spacing: 12) {
                        let imageName = userSettings.pet.type.imageName(for: element)
                        if let uiImage = UIImage(named: imageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                        } else {
                            Text(userSettings.pet.type.emoji)
                                .font(.system(size: 60))
                        }
                        
                        Text(element.displayName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(element.color)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "questionmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            Text("Item \(min(currentShowIndex + 1, patternLengthForLevel(currentLevel))) of \(patternLengthForLevel(currentLevel))")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<patternLengthForLevel(currentLevel), id: \.self) { index in
                    Circle()
                        .fill(index < currentShowIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Input View
    private var inputView: some View {
        VStack(spacing: 20) {
            Text("Repeat the pattern!")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            // User's input display
            HStack(spacing: 8) {
                ForEach(0..<patternLengthForLevel(currentLevel), id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(index < userInput.count ? Color.white : Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        if index < userInput.count {
                            let mood = userInput[index]
                            let imageName = userSettings.pet.type.imageName(for: mood)
                            if let uiImage = UIImage(named: imageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32)
                            }
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            
            Text("\(userInput.count) / \(patternLengthForLevel(currentLevel))")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Input buttons - 5 pet moods
            VStack(spacing: 12) {
                Text("Tap the moods in order")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 12) {
                    ForEach(PetMoodState.allCases, id: \.self) { mood in
                        Button(action: {
                            addElement(mood)
                        }) {
                            VStack(spacing: 6) {
                                let imageName = userSettings.pet.type.imageName(for: mood)
                                if let uiImage = UIImage(named: imageName) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                } else {
                                    Text(userSettings.pet.type.emoji)
                                        .font(.system(size: 36))
                                }
                                
                                Text(mood.displayName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(mood.color)
                            }
                            .frame(width: 65, height: 85)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Level Complete Overlay
    private var levelCompleteOverlay: some View {
        VStack(spacing: 24) {
            Text("🎉 Level \(currentLevel) Complete! 🎉")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Pet celebration
            let imageName = userSettings.pet.type.imageName(for: .happy)
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            }
            
            // Level progress
            VStack(spacing: 8) {
                Text("Level \(currentLevel) Complete!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                
                Text("\(maxLevel - currentLevel) levels remaining")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
            )
            
            Button(action: startNextLevel) {
                HStack(spacing: 10) {
                    Text("Level \(currentLevel + 1)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color(hex: "11998e"))
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - Game Complete Overlay
    private var gameCompleteOverlay: some View {
        VStack(spacing: 24) {
            Text("🏆 All Levels Complete! 🏆")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Pet celebration
            let imageName = userSettings.pet.type.imageName(for: .fullHealth)
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
            }
            
            // Level achievement
            VStack(spacing: 12) {
                Text("Level 5 Mastered!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        Image(systemName: "star.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.yellow)
                    }
                }
                
                if isNewBestLevel {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("NEW BEST LEVEL!")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.yellow.opacity(0.2)))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.15))
            )
            
            // Message
            VStack(spacing: 4) {
                Text("Amazing memory!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(userSettings.pet.name) is impressed!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
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
                            .fill(Color(hex: "11998e"))
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
        .padding(.horizontal, 24)
    }
    
    // MARK: - Failure Overlay
    private var failureOverlay: some View {
        VStack(spacing: 24) {
            Text(attemptsLeft > 0 ? "❌ Wrong Order!" : "💔 Out of Attempts!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            // Pet sad
            let imageName = userSettings.pet.type.imageName(for: .sad)
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            }
            
            if attemptsLeft > 0 {
                Text("You have \(attemptsLeft) attempt\(attemptsLeft == 1 ? "" : "s") left")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 16) {
                    Button(action: retryLevel) {
                        Text("Try Again")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "11998e"))
                            )
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Quit")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                            )
                    }
                }
                .padding(.horizontal, 40)
            } else {
                // Game over
                VStack(spacing: 12) {
                    Text("Reached: Level \(currentLevel > 1 ? currentLevel - 1 : 1)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                    
                    if isNewBestLevel {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("NEW BEST LEVEL!")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.15))
                )
                
                HStack(spacing: 16) {
                    Button(action: restartGame) {
                        Text("Play Again")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "11998e"))
                            )
                    }
                    
                    Button(action: {
                        onComplete(0)
                    }) {
                        Text("Done")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                            )
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
        .padding(.horizontal, 24)
    }
    
    // MARK: - Game Logic
    private func startGame() {
        currentLevel = 1
        attemptsLeft = 3
        isNewBestLevel = false
        startLevel()
        HapticFeedback.medium.trigger()
    }
    
    private func startLevel() {
        // Generate truly random sequence for current level
        // Ensure variety by avoiding too many consecutive same moods
        let length = patternLengthForLevel(currentLevel)
        var sequence: [PetMoodState] = []
        var lastTwoMoods: [PetMoodState] = []
        
        for _ in 0..<length {
            var availableMoods = PetMoodState.allCases
            
            // If last two moods are the same, exclude that mood for more variety
            if lastTwoMoods.count >= 2 && lastTwoMoods[0] == lastTwoMoods[1] {
                availableMoods = availableMoods.filter { $0 != lastTwoMoods[0] }
            }
            
            // Shuffle for better randomness
            let randomMood = availableMoods.shuffled().first!
            sequence.append(randomMood)
            
            // Track last two moods
            lastTwoMoods.append(randomMood)
            if lastTwoMoods.count > 2 {
                lastTwoMoods.removeFirst()
            }
        }
        
        currentSequence = sequence
        userInput = []
        currentShowIndex = 0
        showElement = nil
        
        // Start showing sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            gameState = .showing
            showNextElement()
        }
    }
    
    private func showNextElement() {
        guard currentShowIndex < currentSequence.count else {
            // Finished showing all elements
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    gameState = .input
                }
            }
            return
        }
        
        // Show element
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showElement = currentSequence[currentShowIndex]
            isAnimating = true
        }
        HapticFeedback.light.trigger()
        
        // Hide element after 1.2 seconds and show next
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                showElement = nil
                isAnimating = false
            }
            
            currentShowIndex += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showNextElement()
            }
        }
    }
    
    private func addElement(_ element: PetMoodState) {
        let currentIndex = userInput.count
        
        // Check if this is the correct element
        if currentIndex < currentSequence.count && element == currentSequence[currentIndex] {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                userInput.append(element)
            }
            HapticFeedback.success.trigger()
            
            // Check if sequence is complete
            if userInput.count == currentSequence.count {
                // Level complete - check for best level
                isNewBestLevel = PatternMatchHighScoreManager.shared.checkAndUpdateBestLevel(currentLevel)
                
                if currentLevel == maxLevel {
                    // Game complete!
                    gameState = .gameComplete
                } else {
                    gameState = .levelComplete
                }
                HapticFeedback.success.trigger()
            }
        } else {
            // Wrong element
            HapticFeedback.error.trigger()
            attemptsLeft -= 1
            
            // Update best level even on failure (current level -1 since we failed this one)
            if currentLevel > 1 {
                isNewBestLevel = PatternMatchHighScoreManager.shared.checkAndUpdateBestLevel(currentLevel - 1)
            }
            
            gameState = .failure
        }
    }
    
    private func retryLevel() {
        userInput = []
        currentShowIndex = 0
        showElement = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            gameState = .showing
            showNextElement()
        }
    }
    
    private func startNextLevel() {
        // Reset state first before incrementing level
        gameState = .ready
        currentLevel += 1
        
        // Small delay before starting to show the transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            startLevel()
        }
    }
    
    private func restartGame() {
        currentLevel = 1
        attemptsLeft = 3
        isNewBestLevel = false
        startLevel()
    }
}

// MARK: - Best Level Manager
class PatternMatchHighScoreManager {
    static let shared = PatternMatchHighScoreManager()
    
    private let bestLevelKey = "PatternMatchBestLevel"
    
    var bestLevel: Int {
        get { UserDefaults.standard.integer(forKey: bestLevelKey) }
        set { UserDefaults.standard.set(newValue, forKey: bestLevelKey) }
    }
    
    func checkAndUpdateBestLevel(_ level: Int) -> Bool {
        if level > bestLevel {
            bestLevel = level
            return true
        }
        return false
    }
}

// MARK: - Preview
#Preview {
    PatternMatchGameView(onComplete: { _ in })
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}

