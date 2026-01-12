//
//  TreatCatchGameView.swift
//  VirtuPet
//

import SwiftUI

// MARK: - Game Item Types
enum GameItemType: CaseIterable {
    // Good moods - catch these!
    case fullHealth
    case happy
    
    // Bad moods - avoid these!
    case sick
    case sad
    
    var moodState: PetMoodState {
        switch self {
        case .fullHealth: return .fullHealth
        case .happy: return .happy
        case .sick: return .sick
        case .sad: return .sad
        }
    }
    
    var points: Int {
        switch self {
        case .fullHealth: return 20
        case .happy: return 15
        case .sick: return 0
        case .sad: return 0
        }
    }
    
    var isGood: Bool {
        switch self {
        case .fullHealth, .happy: return true
        case .sick, .sad: return false
        }
    }
    
    var itemColor: Color {
        isGood ? .green : .red
    }
    
    var size: CGFloat { 55 }
    
    static func randomItem() -> GameItemType {
        let rand = Double.random(in: 0...1)
        
        if rand < 0.55 {
            // 55% good moods
            return [.fullHealth, .happy].randomElement()!
        } else {
            // 45% bad moods
            return [.sick, .sad].randomElement()!
        }
    }
}

// MARK: - Falling Game Item
struct GameItem: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let type: GameItemType
    let speed: CGFloat
    var wobble: CGFloat = 0
    var isCollected: Bool = false
}

// MARK: - Catch Effect
struct CatchEffect: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let text: String
    let color: Color
    var opacity: Double = 1.0
    var offsetY: CGFloat = 0
    var scale: CGFloat = 1.0
}

// MARK: - High Score Manager
class TreatCatchHighScoreManager {
    static let shared = TreatCatchHighScoreManager()
    private let highScoreKey = "treatCatchHighScore"
    
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: highScoreKey) }
        set { UserDefaults.standard.set(newValue, forKey: highScoreKey) }
    }
    
    func checkAndUpdateHighScore(_ score: Int) -> Bool {
        if score > highScore {
            highScore = score
            return true
        }
        return false
    }
}

// MARK: - Treat Catch Game View
struct TreatCatchGameView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    let onComplete: (Int) -> Void
    
    // Game state
    @State private var gameState: GameState = .ready
    @State private var score: Int = 0
    @State private var petPosition: CGFloat = 0.5
    @State private var targetPosition: CGFloat = 0.5
    @State private var items: [GameItem] = []
    @State private var effects: [CatchEffect] = []
    @State private var combo: Int = 0
    @State private var maxCombo: Int = 0
    @State private var lastCatchWasGood: Bool = true
    @State private var isNewHighScore: Bool = false
    @State private var catchCount: Int = 0
    @State private var missCount: Int = 0
    @State private var badMoodsCaught: Int = 0 // 3 strikes and you're out!
    @State private var gameOverReason: GameOverReason = .timeUp
    
    enum GameOverReason {
        case timeUp
        case threeStrikes
    }
    
    // Visual effects
    @State private var screenShake: CGFloat = 0
    @State private var scoreFlash: Bool = false
    @State private var petScale: CGFloat = 1.0
    @State private var wobblePhase: Double = 0
    
    // Timers
    @State private var updateTimer: Timer?
    
    // Screen
    @State private var screenSize: CGSize = .zero
    
    // Constants
    private let petWidth: CGFloat = 90
    private let catchRadius: CGFloat = 55
    
    enum GameState {
        case ready, playing, finished
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Beautiful gradient background
                gameBackground
                
                VStack(spacing: 0) {
                    // Only show header when playing
                    if gameState == .playing {
                        gameHeader
                    } else {
                        // Show just the close button when not playing
                        HStack {
                            Button(action: {
                                stopGame()
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
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 45)
                        .padding(.bottom, 10)
                    }
                    
                    ZStack {
                        // Falling items (only when playing)
                        if gameState == .playing {
                            ForEach(items) { item in
                                if !item.isCollected {
                                    FallingItemView(
                                        item: item,
                                        petType: userSettings.pet.type,
                                        accentColor: themeManager.accentColor
                                    )
                                }
                            }
                            
                            // Catch effects
                            ForEach(effects) { effect in
                                CatchEffectView(effect: effect)
                            }
                            
                            // Pet catcher (only when playing)
                            petCatcher
                                .position(
                                    x: petPosition * (geometry.size.width - petWidth) + petWidth / 2,
                                    y: geometry.size.height - 200
                                )
                                .scaleEffect(petScale)
                            
                            // Combo display
                            if combo > 1 {
                                comboDisplay
                            }
                        }
                        
                        // Overlays
                        if gameState == .ready {
                            readyOverlay
                        } else if gameState == .finished {
                            finishedOverlay
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if gameState == .playing {
                                    let newPos = value.location.x / geometry.size.width
                                    targetPosition = max(0.08, min(0.92, newPos))
                                }
                            }
                    )
                }
            }
            .offset(x: screenShake, y: 0)
            .onAppear {
                screenSize = geometry.size
            }
        }
    }
    
    // MARK: - Background
    private var gameBackground: some View {
        ZStack {
            // Main gradient
            LinearGradient(
                colors: [
                    themeManager.accentColor.opacity(0.3),
                    Color(hex: "87CEEB").opacity(0.6),
                    Color(hex: "98FB98").opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative circles
            Circle()
                .fill(themeManager.accentColor.opacity(0.1))
                .frame(width: 300, height: 300)
                .offset(x: -100, y: -200)
                .blur(radius: 50)
            
            Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 250, height: 250)
                .offset(x: 150, y: 300)
                .blur(radius: 40)
            
            // Ground
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color(hex: "228B22").opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header
    private var gameHeader: some View {
        HStack(spacing: 10) {
            // Close button
            Button(action: {
                stopGame()
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
            
            // Credits indicator
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                
                Text("\(userSettings.totalCredits)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.1), radius: 4)
            )
            
            Spacer()
            
            // Score - centered and prominent
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))
                
                Text("\(score)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: scoreFlash ? themeManager.accentColor.opacity(0.5) : .clear, radius: 10)
                    .shadow(color: .black.opacity(0.1), radius: 4)
            )
            .scaleEffect(scoreFlash ? 1.05 : 1.0)
            
            Spacer()
            
            // Lives (3 strikes indicator)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < (3 - badMoodsCaught) ? "heart.fill" : "heart.slash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(index < (3 - badMoodsCaught) ? .red : .gray.opacity(0.4))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.1), radius: 4)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 55)
        .padding(.bottom, 12)
    }
    
    // MARK: - Pet Catcher
    private var petCatcher: some View {
        VStack(spacing: -8) {
            // Pet image
            let imageName = userSettings.pet.type.imageName(for: lastCatchWasGood ? .happy : .sad)
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (lastCatchWasGood ? themeManager.accentColor : Color.red).opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                
                // Pet
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: petWidth, height: petWidth)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                } else {
                    // Fallback
                    Text(userSettings.pet.type.emoji)
                        .font(.system(size: 60))
                }
            }
            
            // Platform/shadow
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.3), Color.black.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: petWidth + 20, height: 20)
                .blur(radius: 4)
        }
    }
    
    // MARK: - Combo Display (positioned at top-left, below header)
    private var comboDisplay: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 18))
                .foregroundColor(.orange)
            
            Text("x\(combo)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.95))
                .shadow(color: .orange.opacity(0.4), radius: 8)
        )
        .position(x: 70, y: 130)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Ready Overlay
    @State private var buttonPulse: Bool = false
    @State private var petBounce: Bool = false
    
    private var readyOverlay: some View {
        ZStack {
            // Same gradient as game background
            LinearGradient(
                colors: [
                    themeManager.accentColor.opacity(0.3),
                    Color(hex: "87CEEB").opacity(0.6),
                    Color(hex: "98FB98").opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative circles (matching game)
            Circle()
                .fill(themeManager.accentColor.opacity(0.15))
                .frame(width: 250, height: 250)
                .offset(x: -100, y: -250)
                .blur(radius: 40)
            
            Circle()
                .fill(Color(hex: "98FB98").opacity(0.2))
                .frame(width: 200, height: 200)
                .offset(x: 120, y: 300)
                .blur(radius: 40)
            
            VStack(spacing: 16) {
                Spacer()
                
                // Pet mascot with bounce
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 90, height: 90)
                        .blur(radius: 10)
                    
                    let imageName = userSettings.pet.type.imageName(for: .fullHealth)
                    if let uiImage = UIImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 75, height: 75)
                            .shadow(color: .black.opacity(0.2), radius: 8)
                    }
                }
                .offset(y: petBounce ? -4 : 4)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: petBounce)
                
                // Title
                Text("Mood Catch!")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                // High score
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(Color(hex: "FFD700"))
                    Text("Best: \(TreatCatchHighScoreManager.shared.highScore)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.1), radius: 4)
                )
                
                // Compact Instructions
                VStack(spacing: 10) {
                    // CATCH row
                    compactInstructionRow(
                        title: "CATCH",
                        moods: [.fullHealth, .happy],
                        color: Color(hex: "00D26A"),
                        icon: "heart.fill"
                    )
                    
                    // AVOID row
                    compactInstructionRow(
                        title: "AVOID",
                        moods: [.sick, .sad],
                        color: Color(hex: "FF6B6B"),
                        icon: "xmark.circle.fill"
                    )
                    
                    // Warning
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text("3 bad catches = Game Over!")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                    )
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                )
                .padding(.horizontal, 20)
                
                // Drag hint
                HStack(spacing: 6) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 12))
                    Text("Drag to move \(userSettings.pet.name)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundColor(themeManager.secondaryTextColor)
                
                // Start Button
                Button(action: startGame) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18))
                        Text("START")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(themeManager.accentColor)
                            .shadow(color: themeManager.accentColor.opacity(0.4), radius: buttonPulse ? 15 : 8, y: 6)
                    )
                    .scaleEffect(buttonPulse ? 1.03 : 1.0)
                }
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: buttonPulse)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            petBounce = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                buttonPulse = true
            }
        }
    }
    
    // MARK: - Compact Instruction Row
    private func compactInstructionRow(title: String, moods: [PetMoodState], color: Color, icon: String) -> some View {
        HStack(spacing: 10) {
            // Pet previews
            HStack(spacing: -8) {
                ForEach(moods, id: \.self) { mood in
                    let imageName = userSettings.pet.type.imageName(for: mood)
                    if let uiImage = UIImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(color.opacity(0.5), lineWidth: 1.5))
                    }
                }
            }
            
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(color)
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
    
    // MARK: - Finished Overlay
    private var finishedOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Game over reason
                if gameOverReason == .threeStrikes {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.slash.fill")
                            Text("3 STRIKES!")
                            Image(systemName: "heart.slash.fill")
                        }
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                        
                        Text("Caught too many sad moods")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(0.2))
                    )
                } else if isNewHighScore {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                        Text("NEW BEST!")
                        Image(systemName: "crown.fill")
                    }
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.yellow.opacity(0.2)))
                } else {
                    Text("⏰ TIME'S UP!")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // Pet reaction - sad if 3 strikes
                let petMood: PetMoodState = gameOverReason == .threeStrikes ? .sad : (score > 100 ? .fullHealth : .happy)
                let imageName = userSettings.pet.type.imageName(for: petMood)
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 85, height: 85)
                        .clipShape(Circle())
                        .shadow(color: gameOverReason == .threeStrikes ? Color.red.opacity(0.3) : themeManager.accentColor.opacity(0.3), radius: 15)
                }
                
                // Score
                VStack(spacing: 6) {
                    Text("SCORE")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(score)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .shadow(color: themeManager.accentColor.opacity(0.5), radius: 20)
                }
                
                // Stats
                HStack(spacing: 16) {
                    resultStat(title: "Combo", value: "\(maxCombo)x", color: .orange)
                    resultStat(title: "Caught", value: "\(catchCount)", color: .green)
                    resultStat(title: "Strikes", value: "\(badMoodsCaught)/3", color: .red)
                }
                
                // High score
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("Best: \(TreatCatchHighScoreManager.shared.highScore)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Buttons
                VStack(spacing: 10) {
                    Button(action: resetAndStart) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Play Again")
                        }
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(themeManager.accentColor))
                    }
                    
                    Button(action: { onComplete(0) }) {
                        Text("Done")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(28)
        }
    }
    
    private func resultStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 80)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Game Logic
    private func startGame() {
        // Deduct credit when actually starting the game
        guard userSettings.useGameCredit() else {
            // If no credits, close the game
            dismiss()
            return
        }
        
        gameState = .playing
        score = 0
        items = []
        effects = []
        combo = 0
        maxCombo = 0
        petPosition = 0.5
        targetPosition = 0.5
        isNewHighScore = false
        catchCount = 0
        missCount = 0
        badMoodsCaught = 0
        gameOverReason = .threeStrikes
        lastCatchWasGood = true
        wobblePhase = 0
        
        // 60fps update for smooth gameplay
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            updateGame()
        }
        
        scheduleNextSpawn()
        HapticFeedback.medium.trigger()
    }
    
    private func scheduleNextSpawn() {
        guard gameState == .playing else { return }
        
        // Faster spawn rate - 0.45 to 0.65 seconds between items (harder)
        let interval = Double.random(in: 0.45...0.65)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            if gameState == .playing {
                spawnItem()
                scheduleNextSpawn()
            }
        }
    }
    
    private func spawnItem() {
        guard screenSize.width > 0 else { return }
        
        let type = GameItemType.randomItem()
        let padding: CGFloat = 60
        let x = CGFloat.random(in: padding...(screenSize.width - padding))
        
        // Increased falling speed - base 4.2 with variation (harder)
        let baseSpeed: CGFloat = 4.0
        let speed = baseSpeed + CGFloat.random(in: 0...2.0)
        
        let item = GameItem(x: x, y: -60, type: type, speed: speed)
        items.append(item)
    }
    
    private func updateGame() {
        guard gameState == .playing else { return }
        
        // Smooth pet movement - higher value = more responsive
        petPosition += (targetPosition - petPosition) * 0.35
        
        // Wobble animation
        wobblePhase += 0.1
        
        let catchY = screenSize.height - 230
        let petX = petPosition * (screenSize.width - petWidth) + petWidth / 2
        
        for i in items.indices.reversed() {
            guard i < items.count else { continue }
            
            items[i].y += items[i].speed
            items[i].wobble = sin(wobblePhase + Double(i)) * 3
            
            if !items[i].isCollected {
                let itemX = items[i].x + items[i].wobble
                let itemY = items[i].y
                
                if itemY >= catchY - 30 && itemY <= catchY + 50 {
                    if abs(itemX - petX) < catchRadius {
                        catchItem(at: i)
                    }
                }
                
                if itemY > screenSize.height + 50 {
                    if items[i].type.isGood {
                        combo = 0
                        missCount += 1
                    }
                }
            }
        }
        
        items.removeAll { $0.y > screenSize.height + 50 || $0.isCollected }
        effects.removeAll { $0.opacity <= 0 }
    }
    
    private func catchItem(at index: Int) {
        guard index < items.count else { return }
        
        items[index].isCollected = true
        let item = items[index]
        
        var effectText = ""
        var effectColor: Color = .white
        
        if item.type.isGood {
            // Caught a good mood!
            combo += 1
            maxCombo = max(maxCombo, combo)
            let comboBonus = combo > 1 ? combo * 5 : 0
            let points = item.type.points + comboBonus
            score += points
            catchCount += 1
            
            effectText = "+\(points)"
            effectColor = .green
            lastCatchWasGood = true
            
            // Very subtle scale animation
            withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                petScale = 1.02
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { petScale = 1.0 }
            }
            
            withAnimation(.easeInOut(duration: 0.15)) { scoreFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { scoreFlash = false }
            }
        } else {
            // Caught a bad mood - Strike!
            combo = 0
            missCount += 1
            badMoodsCaught += 1
            
            effectText = badMoodsCaught >= 3 ? "💀" : "Strike \(badMoodsCaught)!"
            effectColor = .red
            lastCatchWasGood = false
            
            // Screen shake
            withAnimation(.easeInOut(duration: 0.04).repeatCount(5)) {
                screenShake = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                screenShake = 0
            }
            
            HapticFeedback.error.trigger()
            
            // Check for 3 strikes - Game Over!
            if badMoodsCaught >= 3 {
                gameOverReason = .threeStrikes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    endGame()
                }
                return
            }
        }
        
        addCatchEffect(at: item.x, y: item.y, text: effectText, color: effectColor)
    }
    
    private func addCatchEffect(at x: CGFloat, y: CGFloat, text: String, color: Color) {
        let effect = CatchEffect(x: x, y: y, text: text, color: color)
        effects.append(effect)
        
        let effectId = effect.id
        withAnimation(.easeOut(duration: 0.6)) {
            if let index = effects.firstIndex(where: { $0.id == effectId }) {
                effects[index].offsetY = -45
                effects[index].opacity = 0
                effects[index].scale = 1.3
            }
        }
    }
    
    private func endGame() {
        gameState = .finished
        stopGame()
        isNewHighScore = TreatCatchHighScoreManager.shared.checkAndUpdateHighScore(score)
        if isNewHighScore { HapticFeedback.success.trigger() }
    }
    
    private func stopGame() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func resetAndStart() {
        items = []
        effects = []
        startGame()
    }
}

// MARK: - Falling Item View
struct FallingItemView: View {
    let item: GameItem
    let petType: PetType
    let accentColor: Color
    
    var body: some View {
        let mood = item.type.moodState
        let imageName = petType.imageName(for: mood)
        
        ZStack {
            // Glow
            Circle()
                .fill(item.type.itemColor.opacity(0.3))
                .frame(width: item.type.size + 10, height: item.type.size + 10)
            
            // Pet image
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: item.type.size, height: item.type.size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(item.type.itemColor, lineWidth: 3)
                    )
            }
        }
        .position(x: item.x + item.wobble, y: item.y)
    }
}

// MARK: - Catch Effect View
struct CatchEffectView: View {
    let effect: CatchEffect
    
    var body: some View {
        Text(effect.text)
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundColor(effect.color)
            .shadow(color: effect.color.opacity(0.5), radius: 6)
            .scaleEffect(effect.scale)
            .opacity(effect.opacity)
            .offset(y: effect.offsetY)
            .position(x: effect.x, y: effect.y)
    }
}

// MARK: - Preview
#Preview {
    TreatCatchGameView(onComplete: { _ in })
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
