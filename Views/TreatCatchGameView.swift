//
//  TreatCatchGameView.swift
//  StepPet
//

import SwiftUI

// MARK: - Falling Item
struct FallingItem: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let type: TreatType
    let speed: CGFloat
    var isCollected: Bool = false
    
    enum TreatType: CaseIterable {
        case bone
        case meat
        case cookie
        case carrot
        case broccoli // Bad item
        
        var emoji: String {
            switch self {
            case .bone: return "🦴"
            case .meat: return "🥩"
            case .cookie: return "🍪"
            case .carrot: return "🥕"
            case .broccoli: return "🥦"
            }
        }
        
        var points: Int {
            switch self {
            case .bone: return 10
            case .meat: return 15
            case .cookie: return 20
            case .carrot: return 5
            case .broccoli: return -10
            }
        }
        
        var isBad: Bool {
            self == .broccoli
        }
        
        static var goodItems: [TreatType] {
            [.bone, .meat, .cookie, .carrot]
        }
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
    @State private var timeRemaining: Int = 30
    @State private var petPosition: CGFloat = 0.5 // 0-1 range
    @State private var fallingItems: [FallingItem] = []
    @State private var combo: Int = 0
    @State private var showCombo: Bool = false
    @State private var lastCatchWasGood: Bool = true
    
    // Timers
    @State private var gameTimer: Timer?
    @State private var spawnTimer: Timer?
    @State private var updateTimer: Timer?
    
    // Screen size
    @State private var screenSize: CGSize = .zero
    
    private let petWidth: CGFloat = 80
    private let itemSize: CGFloat = 40
    private let catchZoneHeight: CGFloat = 100
    
    enum GameState {
        case ready, playing, finished
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(hex: "87CEEB"),
                        Color(hex: "98FB98")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Game content
                VStack(spacing: 0) {
                    // Header
                    gameHeader
                    
                    // Game area
                    ZStack {
                        // Falling items
                        ForEach(fallingItems) { item in
                            if !item.isCollected {
                                Text(item.type.emoji)
                                    .font(.system(size: 36))
                                    .position(x: item.x, y: item.y)
                            }
                        }
                        
                        // Pet (catcher)
                        VStack(spacing: 0) {
                            Spacer()
                            
                            petCatcher
                                .position(
                                    x: petPosition * (geometry.size.width - petWidth) + petWidth / 2,
                                    y: geometry.size.height - 200
                                )
                        }
                        
                        // Combo popup
                        if showCombo && combo > 1 {
                            comboPopup
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Game state overlays
                        if gameState == .ready {
                            readyOverlay
                        } else if gameState == .finished {
                            finishedOverlay
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if gameState == .playing {
                                    let newPosition = value.location.x / geometry.size.width
                                    petPosition = max(0, min(1, newPosition))
                                }
                            }
                    )
                    .onTapGesture { location in
                        if gameState == .playing {
                            let newPosition = location.x / geometry.size.width
                            withAnimation(.easeOut(duration: 0.1)) {
                                petPosition = max(0, min(1, newPosition))
                            }
                        }
                    }
                }
            }
            .onAppear {
                screenSize = geometry.size
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
        .padding(.bottom, 20)
    }
    
    // MARK: - Pet Catcher
    private var petCatcher: some View {
        VStack(spacing: 4) {
            // Basket/bowl
            ZStack {
                Ellipse()
                    .fill(Color.brown)
                    .frame(width: petWidth + 20, height: 30)
                
                Ellipse()
                    .fill(Color.brown.opacity(0.7))
                    .frame(width: petWidth + 10, height: 20)
                    .offset(y: -5)
            }
            
            // Pet
            let imageName = userSettings.pet.type.imageName(for: lastCatchWasGood ? .happy : .sad)
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: petWidth, height: petWidth)
            } else {
                Text(userSettings.pet.type.emoji)
                    .font(.system(size: 50))
            }
        }
    }
    
    // MARK: - Combo Popup
    private var comboPopup: some View {
        VStack(spacing: 4) {
            Text("COMBO x\(combo)!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.orange)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            Text("+\(combo * 5) bonus")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.yellow)
        }
        .position(x: UIScreen.main.bounds.width / 2, y: 200)
    }
    
    // MARK: - Ready Overlay
    private var readyOverlay: some View {
        VStack(spacing: 24) {
            Text("🦴 Treat Catch 🦴")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 12) {
                Text("Drag or tap to move \(userSettings.pet.name)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Catch treats, avoid 🥦!")
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
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
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
            
            VStack(spacing: 8) {
                Text("Final Score")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(score)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 10)
            }
            
            // Health reward
            let healthReward = calculateHealthReward()
            VStack(spacing: 4) {
                Text("+\(healthReward) Health")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                
                Text("for \(userSettings.pet.name)!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.2))
            )
            
            Button(action: {
                onComplete(healthReward)
            }) {
                Text("Claim Reward!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
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
        fallingItems = []
        combo = 0
        petPosition = 0.5
        
        // Game timer (countdown)
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endGame()
            }
        }
        
        // Spawn timer
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            spawnItem()
        }
        
        // Update timer (item movement)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateItems()
        }
        
        HapticFeedback.medium.trigger()
    }
    
    private func spawnItem() {
        guard screenSize.width > 0 else { return }
        
        // Random item type (80% good, 20% bad)
        let type: FallingItem.TreatType
        if Double.random(in: 0...1) < 0.2 {
            type = .broccoli
        } else {
            type = FallingItem.TreatType.goodItems.randomElement() ?? .bone
        }
        
        // Random x position
        let padding: CGFloat = 40
        let x = CGFloat.random(in: padding...(screenSize.width - padding))
        
        // Random speed (increases over time)
        let baseSpeed: CGFloat = 3
        let timeBonus = CGFloat(30 - timeRemaining) * 0.1
        let speed = baseSpeed + CGFloat.random(in: 0...2) + timeBonus
        
        let item = FallingItem(x: x, y: -itemSize, type: type, speed: speed)
        fallingItems.append(item)
    }
    
    private func updateItems() {
        guard gameState == .playing else { return }
        
        let catchY = screenSize.height - 250
        let petX = petPosition * (screenSize.width - petWidth) + petWidth / 2
        let catchRadius: CGFloat = 50
        
        for i in fallingItems.indices.reversed() {
            guard i < fallingItems.count else { continue }
            
            // Move item down
            fallingItems[i].y += fallingItems[i].speed
            
            // Check if caught
            if !fallingItems[i].isCollected {
                let itemX = fallingItems[i].x
                let itemY = fallingItems[i].y
                
                // Check catch collision
                if itemY >= catchY - 20 && itemY <= catchY + 40 {
                    let distance = abs(itemX - petX)
                    
                    if distance < catchRadius {
                        // Caught!
                        fallingItems[i].isCollected = true
                        
                        let item = fallingItems[i]
                        
                        if item.type.isBad {
                            // Bad catch
                            score = max(0, score + item.type.points)
                            combo = 0
                            lastCatchWasGood = false
                            HapticFeedback.error.trigger()
                        } else {
                            // Good catch
                            combo += 1
                            let comboBonus = combo > 1 ? combo * 5 : 0
                            score += item.type.points + comboBonus
                            lastCatchWasGood = true
                            
                            if combo > 1 {
                                withAnimation(.spring(response: 0.3)) {
                                    showCombo = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation {
                                        showCombo = false
                                    }
                                }
                            }
                            
                            HapticFeedback.light.trigger()
                        }
                    }
                }
                
                // Remove if off screen
                if itemY > screenSize.height + itemSize {
                    // Missed a good item - break combo
                    if !fallingItems[i].type.isBad {
                        combo = 0
                    }
                }
            }
        }
        
        // Clean up off-screen and collected items
        fallingItems.removeAll { $0.y > screenSize.height + itemSize || $0.isCollected }
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
        // Base: 10-25 based on score
        if score >= 300 {
            return 25
        } else if score >= 200 {
            return 20
        } else if score >= 100 {
            return 15
        } else {
            return 10
        }
    }
}

// MARK: - Preview
#Preview {
    TreatCatchGameView(onComplete: { _ in })
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
