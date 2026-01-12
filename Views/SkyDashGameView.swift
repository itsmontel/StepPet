//
//  SkyDashGameView.swift
//  VirtuPet
//
//  Sky Dash - Dodge walls and rise to the top!
//

import SwiftUI
import CoreMotion

// MARK: - High Score Manager
class SkyDashHighScoreManager {
    static let shared = SkyDashHighScoreManager()
    
    private let highScoreKey = "skyDashHighScore"
    
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: highScoreKey) }
        set { UserDefaults.standard.set(newValue, forKey: highScoreKey) }
    }
}

// MARK: - Motion Manager
class SkyDashMotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var tilt: Double = 0
    
    func startUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 1/60
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            
            // Smoother tilt with more interpolation for less hectic feel
            let newTilt = data.acceleration.x * 1.8
            self.tilt = self.tilt * 0.5 + newTilt * 0.5  // More smoothing
        }
    }
    
    func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
        tilt = 0
    }
    
    func reset() {
        tilt = 0
    }
}

// MARK: - Wall Obstacle
struct Wall: Identifiable {
    let id = UUID()
    var y: CGFloat
    let gapX: CGFloat      // Center of the gap
    let gapWidth: CGFloat  // Width of the gap
    var passed: Bool = false
}

// MARK: - Collectible
struct SkyCollectible: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let type: CollectibleType
    var collected: Bool = false
    
    enum CollectibleType {
        case star       // Extra points
        case shield     // Invincibility
        
        var emoji: String {
            switch self {
            case .star: return "⭐"
            case .shield: return "🛡️"
            }
        }
        
        var points: Int {
            switch self {
            case .star: return 50
            case .shield: return 10
            }
        }
    }
}

// MARK: - Particle Effect
struct SkyParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    let color: Color
}

// MARK: - Game State
enum SkyDashState {
    case ready
    case playing
    case gameOver
}

// MARK: - Sky Dash Game View
struct SkyDashGameView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    let onComplete: (Int) -> Void
    
    // Motion
    @StateObject private var motionManager = SkyDashMotionManager()
    
    // Game state
    @State private var gameState: SkyDashState = .ready
    @State private var score: Int = 0
    @State private var highScore: Int = SkyDashHighScoreManager.shared.highScore
    @State private var isNewHighScore: Bool = false
    
    // Pet
    @State private var petX: CGFloat = 0
    @State private var petRotation: Double = 0
    
    // World
    @State private var walls: [Wall] = []
    @State private var collectibles: [SkyCollectible] = []
    @State private var particles: [SkyParticle] = []
    @State private var worldOffset: CGFloat = 0
    @State private var distance: Int = 0
    
    // Power-ups
    @State private var isInvincible: Bool = false
    @State private var invincibleTimer: CGFloat = 0
    @State private var shieldPulse: CGFloat = 1.0
    
    // Timers
    @State private var gameTimer: Timer?
    
    // Screen
    @State private var screenSize: CGSize = .zero
    
    // Constants
    private let riseSpeed: CGFloat = 3.5
    private let tiltSensitivity: CGFloat = 10  // Reduced for smoother feel
    private let wallHeight: CGFloat = 20
    private let initialGapWidth: CGFloat = 180  // Wider starting gaps
    private let minGapWidth: CGFloat = 100      // Wider minimum gap
    private let wallSpacing: CGFloat = 200
    private let petSize: CGFloat = 50
    
    // Colors
    private let gradientColors = [Color(hex: "667eea"), Color(hex: "764ba2")]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "1a1a2e"),
                        Color(hex: "16213e"),
                        Color(hex: "0f3460")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Stars background
                starsBackground
                
                // Game content
                ZStack {
                    // Walls
                    ForEach(walls) { wall in
                        WallView(
                            wall: wall,
                            screenWidth: screenSize.width,
                            wallHeight: wallHeight,
                            themeColor: themeManager.accentColor
                        )
                        .offset(y: wall.y - worldOffset)
                    }
                    
                    // Collectibles
                    ForEach(collectibles) { collectible in
                        if !collectible.collected {
                            Text(collectible.type.emoji)
                                .font(.system(size: 30))
                                .shadow(color: collectible.type == .shield ? .cyan : .yellow, radius: 10)
                                .position(x: collectible.x, y: collectible.y - worldOffset)
                        }
                    }
                    
                    // Particles
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .opacity(particle.opacity)
                            .position(x: particle.x, y: particle.y - worldOffset)
                    }
                    
                    // Pet
                    if gameState == .playing || gameState == .gameOver {
                        petView
                    }
                }
                
                // Overlays
                if gameState == .ready {
                    readyOverlay
                }
                
                if gameState == .gameOver {
                    gameOverOverlay
                }
                
                // UI - Always on top (after overlays so it's clickable)
                VStack {
                    gameHeader
                    Spacer()
                }
                .zIndex(100) // Ensure header is always accessible
            }
            .onAppear {
                screenSize = geometry.size
                petX = geometry.size.width / 2
            }
        }
    }
    
    // MARK: - Stars Background
    private var starsBackground: some View {
        ZStack {
            ForEach(0..<40, id: \.self) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat(i * 23 % Int(max(screenSize.width, 1))),
                        y: CGFloat((i * 41 + Int(worldOffset * 0.1)) % Int(max(screenSize.height, 1)))
                    )
                    .opacity(Double.random(in: 0.3...0.8))
            }
        }
    }
    
    // MARK: - Pet View
    private var petView: some View {
        ZStack {
            // Shield effect when invincible
            if isInvincible {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: petSize + 20, height: petSize + 20)
                    .scaleEffect(shieldPulse)
                    .opacity(0.8)
                
                Circle()
                    .fill(Color.cyan.opacity(0.2))
                    .frame(width: petSize + 15, height: petSize + 15)
                    .scaleEffect(shieldPulse)
            }
            
            // Pet
            let imageName = userSettings.pet.type.imageName(for: isInvincible ? .fullHealth : .happy)
            Group {
                if let _ = UIImage(named: imageName) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: petSize, height: petSize)
                } else {
                    Text(userSettings.pet.type.emoji)
                        .font(.system(size: 35))
                }
            }
            .rotationEffect(.degrees(petRotation))
        }
        .position(x: petX, y: screenSize.height * 0.7)
    }
    
    // MARK: - Game Header
    private var gameHeader: some View {
        HStack {
            // Close
            Button(action: {
                HapticFeedback.light.trigger()
                stopGame()
                onComplete(0)
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.9))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Credits indicator
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                
                Text("\(userSettings.totalCredits)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.2))
            )
            
            Spacer()
            
            if gameState == .playing {
                // Distance
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                    
                    Text("\(distance)m")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .contentTransition(.numericText())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.2)))
                
                // Shield timer
                if isInvincible {
                    HStack(spacing: 4) {
                        Text("🛡️")
                        Text(String(format: "%.1f", invincibleTimer))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.cyan.opacity(0.3)))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Ready Overlay
    private var readyOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Pet preview
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "667eea").opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    let imageName = userSettings.pet.type.imageName(for: .fullHealth)
                    if let _ = UIImage(named: imageName) {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                    } else {
                        Text(userSettings.pet.type.emoji)
                            .font(.system(size: 55))
                    }
                }
                
                // Title
                Text("Sky Dash")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "667eea")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Instructions
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "iphone.gen3")
                            .foregroundColor(Color(hex: "667eea"))
                        Text("Tilt to move left/right")
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack(spacing: 10) {
                        Text("🧱")
                        Text("Dodge the walls!")
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack(spacing: 10) {
                        Text("🛡️")
                        Text("Shield = 5s invincibility!")
                            .foregroundColor(.cyan)
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                
                // High score
                if highScore > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("Best: \(highScore)m")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.yellow.opacity(0.2)))
                }
                
                // Start
                Button(action: startGame) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .bold))
                        
                        Text("START")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 45)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(hex: "667eea").opacity(0.5), radius: 10)
                    )
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Game Over Overlay
    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                if isNewHighScore {
                    Text("🎉 NEW RECORD! 🎉")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                } else {
                    VStack(spacing: 10) {
                        Text("Game Over")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        let imageName = userSettings.pet.type.imageName(for: .sad)
                        if let _ = UIImage(named: imageName) {
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 65, height: 65)
                        }
                    }
                }
                
                // Stats
                VStack(spacing: 14) {
                    VStack(spacing: 4) {
                        Text("DISTANCE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("\(distance)m")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Divider().background(Color.white.opacity(0.3))
                    
                    VStack(spacing: 4) {
                        Text("BEST")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan.opacity(0.8))
                        
                        Text("\(highScore)m")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                    }
                }
                .padding(22)
                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
                .padding(.horizontal, 40)
                
                // Buttons
                VStack(spacing: 10) {
                    Button(action: startGame) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .bold))
                            Text("Try Again")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(
                                LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                            )
                        )
                    }
                    
                    Button(action: { onComplete(0) }) {
                        Text("Done")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 50)
            }
        }
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
        distance = 0
        isNewHighScore = false
        worldOffset = 0
        isInvincible = false
        invincibleTimer = 0
        walls = []
        collectibles = []
        particles = []
        
        petX = screenSize.width / 2
        petRotation = 0
        
        generateInitialWalls()
        
        motionManager.reset()
        motionManager.startUpdates()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateGame()
        }
        
        HapticFeedback.medium.trigger()
    }
    
    private func generateInitialWalls() {
        var currentY: CGFloat = screenSize.height + 100
        
        for i in 0..<10 {
            // Gap width decreases slowly - first walls are easy
            let gapWidth = max(minGapWidth, initialGapWidth - CGFloat(i) * 2)  // Slower decrease
            let minGapX = gapWidth / 2 + 30
            let maxGapX = screenSize.width - gapWidth / 2 - 30
            let gapX = CGFloat.random(in: minGapX...maxGapX)
            
            let wall = Wall(y: currentY, gapX: gapX, gapWidth: gapWidth)
            walls.append(wall)
            
            // Maybe add shield collectible in gap
            if Double.random(in: 0...1) < 0.25 {  // Only shields now
                let collectible = SkyCollectible(
                    x: gapX,
                    y: currentY - wallSpacing / 2,
                    type: .shield
                )
                collectibles.append(collectible)
            }
            
            currentY += wallSpacing
        }
    }
    
    private func updateGame() {
        guard gameState == .playing else { return }
        
        // Rise up (move world down)
        worldOffset += riseSpeed
        distance = Int(worldOffset / 15)
        
        // Smooth tilt controls - interpolate toward target position
        let targetOffset = CGFloat(motionManager.tilt) * tiltSensitivity
        let currentVelocity = targetOffset * 0.7  // Smooth velocity application
        petX += currentVelocity
        
        // Smooth rotation with damping
        let targetRotation = Double(motionManager.tilt) * 12
        petRotation = petRotation * 0.8 + targetRotation * 0.2
        
        // Clamp to screen with soft bounce
        petX = max(petSize / 2, min(screenSize.width - petSize / 2, petX))
        
        // Update invincibility
        if isInvincible {
            invincibleTimer -= 1/60
            
            // Pulse effect
            shieldPulse = 1.0 + sin(Date().timeIntervalSince1970 * 8) * 0.1
            
            if invincibleTimer <= 0 {
                isInvincible = false
                invincibleTimer = 0
            }
        }
        
        // Check wall collisions
        let petScreenY = screenSize.height * 0.7
        let petRadius = petSize / 2 - 5
        
        for i in walls.indices {
            let wallScreenY = walls[i].y - worldOffset
            
            // Check if pet is at wall level
            if abs(wallScreenY - petScreenY) < wallHeight / 2 + petRadius {
                // Check if pet is NOT in the gap
                let gapLeft = walls[i].gapX - walls[i].gapWidth / 2
                let gapRight = walls[i].gapX + walls[i].gapWidth / 2
                
                if petX < gapLeft + petRadius || petX > gapRight - petRadius {
                    // Hit wall!
                    if !isInvincible {
                        endGame()
                        return
                    } else {
                        // Spawn particles when hitting wall while invincible
                        spawnHitParticles()
                    }
                }
            }
            
            // Mark wall as passed
            if wallScreenY < petScreenY - 50 && !walls[i].passed {
                walls[i].passed = true
            }
        }
        
        // Check collectible collisions
        for i in collectibles.indices {
            if !collectibles[i].collected {
                let collectibleScreenY = collectibles[i].y - worldOffset
                let dist = sqrt(pow(petX - collectibles[i].x, 2) + pow(petScreenY - collectibleScreenY, 2))
                
                if dist < 35 {
                    collectibles[i].collected = true
                    
                    // Only shields now
                    isInvincible = true
                    invincibleTimer = 5.0
                    HapticFeedback.success.trigger()
                    
                    spawnCollectParticles(at: collectibles[i].x, y: collectibleScreenY)
                }
            }
        }
        
        // Generate more walls
        if let lastWall = walls.last {
            if lastWall.y - worldOffset < screenSize.height + 200 {
                generateMoreWalls()
            }
        }
        
        // Clean up
        walls.removeAll { $0.y - worldOffset < -100 }
        collectibles.removeAll { $0.collected || $0.y - worldOffset < -100 }
        updateParticles()
    }
    
    private func generateMoreWalls() {
        let lastY = walls.last?.y ?? worldOffset + screenSize.height
        
        for i in 0..<3 {
            let newY = lastY + wallSpacing * CGFloat(i + 1)
            
            // Gap gets narrower with distance - slower progression (max difficulty at 250m)
            let difficultyFactor = min(CGFloat(distance) / 250, 1.0)
            let gapWidth = initialGapWidth - (initialGapWidth - minGapWidth) * difficultyFactor
            
            let minGapX = gapWidth / 2 + 30
            let maxGapX = screenSize.width - gapWidth / 2 - 30
            let gapX = CGFloat.random(in: minGapX...maxGapX)
            
            let wall = Wall(y: newY, gapX: gapX, gapWidth: gapWidth)
            walls.append(wall)
            
            // Collectibles - only shields
            if Double.random(in: 0...1) < 0.2 {
                let collectible = SkyCollectible(
                    x: gapX,
                    y: newY - wallSpacing / 2,
                    type: .shield
                )
                collectibles.append(collectible)
            }
        }
    }
    
    private func spawnCollectParticles(at x: CGFloat, y: CGFloat) {
        for _ in 0..<8 {
            let particle = SkyParticle(
                x: x + CGFloat.random(in: -20...20),
                y: y + worldOffset + CGFloat.random(in: -20...20),
                size: CGFloat.random(in: 4...8),
                opacity: 1.0,
                color: .cyan  // Shield particles
            )
            particles.append(particle)
        }
    }
    
    private func spawnHitParticles() {
        let petScreenY = screenSize.height * 0.7
        for _ in 0..<10 {
            let particle = SkyParticle(
                x: petX + CGFloat.random(in: -30...30),
                y: petScreenY + worldOffset + CGFloat.random(in: -30...30),
                size: CGFloat.random(in: 5...10),
                opacity: 1.0,
                color: .cyan
            )
            particles.append(particle)
        }
    }
    
    private func updateParticles() {
        for i in particles.indices.reversed() {
            guard i < particles.count else { continue }
            particles[i].opacity -= 0.03
            particles[i].y -= 1
            
            if particles[i].opacity <= 0 {
                particles.remove(at: i)
            }
        }
    }
    
    private func endGame() {
        gameState = .gameOver
        stopGame()
        
        if distance > highScore {
            highScore = distance
            SkyDashHighScoreManager.shared.highScore = distance
            isNewHighScore = true
            HapticFeedback.success.trigger()
        } else {
            HapticFeedback.error.trigger()
        }
    }
    
    private func stopGame() {
        gameTimer?.invalidate()
        gameTimer = nil
        motionManager.stopUpdates()
    }
}

// MARK: - Wall View
struct WallView: View {
    let wall: Wall
    let screenWidth: CGFloat
    let wallHeight: CGFloat
    let themeColor: Color
    
    var body: some View {
        let gapLeft = wall.gapX - wall.gapWidth / 2
        let gapRight = wall.gapX + wall.gapWidth / 2
        
        ZStack {
            // Left wall
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: gapLeft, height: wallHeight)
                .position(x: gapLeft / 2, y: 0)
                .shadow(color: Color(hex: "667eea").opacity(0.5), radius: 8)
            
            // Right wall
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: screenWidth - gapRight, height: wallHeight)
                .position(x: gapRight + (screenWidth - gapRight) / 2, y: 0)
                .shadow(color: Color(hex: "667eea").opacity(0.5), radius: 8)
        }
    }
}

// MARK: - Preview
#Preview {
    SkyDashGameView(onComplete: { _ in })
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}

