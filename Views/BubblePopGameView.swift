//
//  BubblePopGameView.swift
//  StepPet
//

import SwiftUI

// MARK: - Bubble
struct Bubble: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let speed: CGFloat
    let color: Color
    let points: Int
    let emoji: String
    var isPopped: Bool = false
    var wobbleOffset: CGFloat = 0
    
    enum BubbleType: CaseIterable {
        case normal
        case golden
        case rainbow
        case bomb
        
        var points: Int {
            switch self {
            case .normal: return 10
            case .golden: return 25
            case .rainbow: return 50
            case .bomb: return -20
            }
        }
        
        var color: Color {
            switch self {
            case .normal: return Color.cyan.opacity(0.6)
            case .golden: return Color.yellow.opacity(0.7)
            case .rainbow: return Color.purple.opacity(0.6)
            case .bomb: return Color.red.opacity(0.6)
            }
        }
        
        var emoji: String {
            switch self {
            case .normal: return ["🦴", "🐾", "⭐", "🎾"].randomElement()!
            case .golden: return "💎"
            case .rainbow: return "🌈"
            case .bomb: return "💣"
            }
        }
        
        static func random() -> BubbleType {
            let rand = Double.random(in: 0...1)
            if rand < 0.1 {
                return .bomb
            } else if rand < 0.2 {
                return .golden
            } else if rand < 0.25 {
                return .rainbow
            } else {
                return .normal
            }
        }
    }
    
    static func create(screenWidth: CGFloat, screenHeight: CGFloat) -> Bubble {
        let type = BubbleType.random()
        let size = CGFloat.random(in: 50...80)
        let x = CGFloat.random(in: size...(screenWidth - size))
        let y = screenHeight + size
        let speed = CGFloat.random(in: 1.5...3.5)
        
        return Bubble(
            x: x,
            y: y,
            size: size,
            speed: speed,
            color: type.color,
            points: type.points,
            emoji: type.emoji
        )
    }
}

// MARK: - Pop Effect
struct PopEffect: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let points: Int
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
}

// MARK: - Bubble Pop Game View
struct BubblePopGameView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    let onComplete: (Int) -> Void
    
    // Game state
    @State private var gameState: GameState = .ready
    @State private var score: Int = 0
    @State private var timeRemaining: Int = 30
    @State private var bubbles: [Bubble] = []
    @State private var popEffects: [PopEffect] = []
    @State private var poppedCount: Int = 0
    @State private var missedCount: Int = 0
    @State private var combo: Int = 0
    @State private var maxCombo: Int = 0
    
    // Timers
    @State private var gameTimer: Timer?
    @State private var spawnTimer: Timer?
    @State private var updateTimer: Timer?
    
    // Screen size
    @State private var screenSize: CGSize = .zero
    
    enum GameState {
        case ready, playing, finished
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Underwater background
                LinearGradient(
                    colors: [
                        Color(hex: "0077B6"),
                        Color(hex: "00B4D8"),
                        Color(hex: "90E0EF")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Underwater decoration
                underwaterDecoration
                
                // Game content
                VStack(spacing: 0) {
                    // Header
                    gameHeader
                    
                    // Game area
                    ZStack {
                        // Bubbles
                        ForEach(bubbles) { bubble in
                            if !bubble.isPopped {
                                BubbleView(bubble: bubble) {
                                    popBubble(bubble)
                                }
                            }
                        }
                        
                        // Pop effects
                        ForEach(popEffects) { effect in
                            PopEffectView(effect: effect)
                        }
                        
                        // Pet watching from bottom
                        petWatching
                        
                        // Combo display
                        if combo > 2 {
                            comboDisplay
                        }
                        
                        // State overlays
                        if gameState == .ready {
                            readyOverlay
                        } else if gameState == .finished {
                            finishedOverlay
                        }
                    }
                }
            }
            .onAppear {
                screenSize = geometry.size
            }
        }
    }
    
    // MARK: - Underwater Decoration
    private var underwaterDecoration: some View {
        ZStack {
            // Light rays
            ForEach(0..<5, id: \.self) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 400)
                    .rotationEffect(.degrees(Double(i * 15) - 30))
                    .offset(x: CGFloat(i * 80) - 160, y: -100)
            }
            
            // Seaweed at bottom
            HStack(spacing: 40) {
                ForEach(0..<6, id: \.self) { _ in
                    Text("🌿")
                        .font(.system(size: 40))
                        .opacity(0.5)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .offset(y: -60)
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
            
            // Score
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("\(score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
            )
            
            Spacer()
            
            // Timer
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.white)
                
                Text("\(timeRemaining)s")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(timeRemaining <= 10 ? Color.red.opacity(0.6) : Color.black.opacity(0.3))
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 10)
    }
    
    // MARK: - Pet Watching
    private var petWatching: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                let imageName = userSettings.pet.type.imageName(for: combo > 2 ? .fullHealth : .happy)
                if let _ = UIImage(named: imageName) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                } else {
                    Text(userSettings.pet.type.emoji)
                        .font(.system(size: 50))
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Combo Display
    private var comboDisplay: some View {
        VStack {
            Text("🔥 COMBO x\(combo)!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.orange)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 140)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Ready Overlay
    private var readyOverlay: some View {
        VStack(spacing: 24) {
            Text("🫧 Bubble Pop 🫧")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 12) {
                Text("Tap bubbles to pop them!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack(spacing: 16) {
                    Label("Good", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Label("Avoid 💣", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .font(.system(size: 14, weight: .medium))
            }
            
            // Legend
            VStack(spacing: 8) {
                HStack(spacing: 20) {
                    BubbleLegendItem(emoji: "🦴", label: "+10", color: .cyan)
                    BubbleLegendItem(emoji: "💎", label: "+25", color: .yellow)
                }
                HStack(spacing: 20) {
                    BubbleLegendItem(emoji: "🌈", label: "+50", color: .purple)
                    BubbleLegendItem(emoji: "💣", label: "-20", color: .red)
                }
            }
            .padding(.vertical, 10)
            
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
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 10, x: 0, y: 5)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4))
    }
    
    // MARK: - Finished Overlay
    private var finishedOverlay: some View {
        VStack(spacing: 24) {
            Text("🎉 Time's Up! 🎉")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            // Stats
            VStack(spacing: 12) {
                HStack {
                    Text("Score")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(score)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.yellow)
                }
                
                HStack {
                    Text("Bubbles Popped")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(poppedCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Max Combo")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("x\(maxCombo)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.15))
            )
            .padding(.horizontal, 40)
            
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
                    .fill(Color.cyan.opacity(0.2))
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
                                    colors: [.cyan, .blue],
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
        gameState = .playing
        score = 0
        timeRemaining = 30
        bubbles = []
        popEffects = []
        poppedCount = 0
        missedCount = 0
        combo = 0
        maxCombo = 0
        
        // Game timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endGame()
            }
        }
        
        // Spawn timer - spawns faster over time
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            spawnBubble()
        }
        
        // Update timer
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateBubbles()
        }
        
        HapticFeedback.medium.trigger()
    }
    
    private func spawnBubble() {
        guard screenSize.width > 0 else { return }
        let bubble = Bubble.create(screenWidth: screenSize.width, screenHeight: screenSize.height)
        bubbles.append(bubble)
    }
    
    private func updateBubbles() {
        guard gameState == .playing else { return }
        
        // Move bubbles up and add wobble
        for i in bubbles.indices.reversed() {
            guard i < bubbles.count else { continue }
            
            bubbles[i].y -= bubbles[i].speed
            
            // Wobble effect
            let time = Date().timeIntervalSince1970
            bubbles[i].wobbleOffset = sin(time * 3 + Double(i)) * 5
            
            // Check if bubble escaped (missed)
            if bubbles[i].y < -bubbles[i].size && !bubbles[i].isPopped {
                if bubbles[i].points > 0 {
                    // Only count missed for good bubbles
                    missedCount += 1
                    combo = 0
                }
            }
        }
        
        // Remove off-screen bubbles
        bubbles.removeAll { $0.y < -$0.size || $0.isPopped }
        
        // Remove old pop effects
        popEffects.removeAll { $0.opacity <= 0 }
    }
    
    private func popBubble(_ bubble: Bubble) {
        guard let index = bubbles.firstIndex(where: { $0.id == bubble.id }),
              !bubbles[index].isPopped else { return }
        
        bubbles[index].isPopped = true
        
        // Add points
        let points = bubble.points
        
        if points > 0 {
            // Good bubble
            combo += 1
            maxCombo = max(maxCombo, combo)
            let comboBonus = combo > 1 ? combo * 2 : 0
            score += points + comboBonus
            poppedCount += 1
            HapticFeedback.light.trigger()
        } else {
            // Bomb
            score = max(0, score + points)
            combo = 0
            HapticFeedback.error.trigger()
        }
        
        // Add pop effect
        let effect = PopEffect(x: bubble.x, y: bubble.y, points: points)
        popEffects.append(effect)
        
        // Animate effect
        withAnimation(.easeOut(duration: 0.5)) {
            if let effectIndex = popEffects.firstIndex(where: { $0.id == effect.id }) {
                popEffects[effectIndex].scale = 1.5
                popEffects[effectIndex].opacity = 0
            }
        }
    }
    
    private func endGame() {
        gameState = .finished
        stopGame()
        HapticFeedback.success.trigger()
    }
    
    private func stopGame() {
        gameTimer?.invalidate()
        spawnTimer?.invalidate()
        updateTimer?.invalidate()
        gameTimer = nil
        spawnTimer = nil
        updateTimer = nil
    }
    
    private func calculateHealthReward() -> Int {
        // Base: 10-20 based on score
        if score >= 400 {
            return 20
        } else if score >= 250 {
            return 17
        } else if score >= 150 {
            return 14
        } else {
            return 10
        }
    }
}

// MARK: - Bubble View
struct BubbleView: View {
    let bubble: Bubble
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Bubble
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                bubble.color,
                                bubble.color.opacity(0.3)
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: bubble.size
                        )
                    )
                    .frame(width: bubble.size, height: bubble.size)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    )
                    .overlay(
                        // Shine effect
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: bubble.size * 0.25, height: bubble.size * 0.2)
                            .offset(x: -bubble.size * 0.2, y: -bubble.size * 0.2)
                    )
                
                // Emoji inside
                Text(bubble.emoji)
                    .font(.system(size: bubble.size * 0.45))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .position(x: bubble.x + bubble.wobbleOffset, y: bubble.y)
    }
}

// MARK: - Pop Effect View
struct PopEffectView: View {
    let effect: PopEffect
    
    var body: some View {
        VStack(spacing: 4) {
            Text(effect.points >= 0 ? "+\(effect.points)" : "\(effect.points)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(effect.points >= 0 ? .green : .red)
            
            Text("✨")
                .font(.system(size: 20))
        }
        .scaleEffect(effect.scale)
        .opacity(effect.opacity)
        .position(x: effect.x, y: effect.y - 30)
    }
}

// MARK: - Bubble Legend Item
struct BubbleLegendItem: View {
    let emoji: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                Text(emoji)
                    .font(.system(size: 16))
            }
            
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview
#Preview {
    BubblePopGameView(onComplete: { _ in })
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
