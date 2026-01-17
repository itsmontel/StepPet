//
//  BubblePopGameView.swift
//  VirtuPet
//
//  "Pet Jump" - Tilt-controlled endless jumping game
//

import SwiftUI
import CoreMotion

// MARK: - High Score Manager
class PetJumpHighScoreManager {
    static let shared = PetJumpHighScoreManager()
    
    private let highScoreKey = "petJumpHighScore"
    
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: highScoreKey) }
        set { UserDefaults.standard.set(newValue, forKey: highScoreKey) }
    }
}

// MARK: - Motion Manager - Responsive Tilt
class TiltMotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var tilt: Double = 0
    
    func startUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 1/60
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            
            // Direct accelerometer - multiply for more sensitivity
            // Light smoothing to remove noise but stay responsive
            let newTilt = data.acceleration.x * 1.8
            self.tilt = self.tilt * 0.3 + newTilt * 0.7 // 70% new, 30% old
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

// MARK: - Platform
struct JumpPlatform: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let width: CGFloat
    var isMoving: Bool
    var movingSpeed: CGFloat
    var movingDirection: CGFloat = 1
    var opacity: Double = 1.0
}

// MARK: - Game State
enum JumpGameState {
    case ready
    case playing
    case gameOver
}

// MARK: - Pet Jump Game View
struct BubblePopGameView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    let onComplete: (Int) -> Void
    
    // Motion manager for tilt controls
    @StateObject private var motionManager = TiltMotionManager()
    
    // Game state
    @State private var gameState: JumpGameState = .ready
    @State private var score: Int = 0
    @State private var highScore: Int = PetJumpHighScoreManager.shared.highScore
    @State private var isNewHighScore: Bool = false
    
    // Pet physics
    @State private var petX: CGFloat = 0
    @State private var petY: CGFloat = 0
    @State private var petVelocityY: CGFloat = 0
    @State private var petRotation: Double = 0
    @State private var petSquash: CGFloat = 1.0
    @State private var isFalling: Bool = false
    
    // World
    @State private var platforms: [JumpPlatform] = []
    @State private var worldOffset: CGFloat = 0
    @State private var highestY: CGFloat = 0
    @State private var platformsJumped: Int = 0
    
    // Timers
    @State private var gameTimer: Timer?
    
    // Screen
    @State private var screenSize: CGSize = .zero
    
    // Visual effects
    @State private var backgroundHue: Double = 0.55
    
    // Physics constants
    private let gravity: CGFloat = 0.32
    private let jumpForce: CGFloat = -11.0 // Consistent jump
    private let maxFallSpeed: CGFloat = 11
    private let platformWidth: CGFloat = 80
    private let platformHeight: CGFloat = 14
    private let platformSpacing: CGFloat = 90 // Fixed spacing
    private let tiltSensitivity: CGFloat = 14 // Responsive tilt
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sky background
                skyBackground
                
                // Clouds decoration
                cloudsDecoration
                
                // Game content
                ZStack {
                    // Platforms
                    ForEach(platforms) { platform in
                        PlatformView(platform: platform, themeColor: themeManager.accentColor)
                            .offset(y: worldOffset)
                    }
                    
                    // Pet
                    if gameState == .playing || gameState == .gameOver {
                        petView
                            .offset(y: worldOffset)
                    }
                }
                
                // UI Overlay
                VStack {
                    gameHeader
                    Spacer()
                }
                
                // State overlays
                if gameState == .ready {
                    readyOverlay
                }
                
                if gameState == .gameOver {
                    gameOverOverlay
                }
            }
            .onAppear {
                screenSize = geometry.size
                petX = geometry.size.width / 2
                petY = geometry.size.height - 150
            }
        }
    }
    
    // MARK: - Sky Background
    private var skyBackground: some View {
        LinearGradient(
            colors: [
                Color(hue: backgroundHue, saturation: 0.5, brightness: 0.95),
                Color(hue: backgroundHue + 0.08, saturation: 0.4, brightness: 0.98),
                Color(hue: 0.12, saturation: 0.2, brightness: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Clouds Decoration
    private var cloudsDecoration: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Text("☁️")
                    .font(.system(size: CGFloat(35 + i * 5)))
                    .opacity(0.25)
                    .offset(
                        x: CGFloat((i * 70) - 150) + (worldOffset * 0.05).truncatingRemainder(dividingBy: 80),
                        y: CGFloat(i * 130 + 80)
                    )
            }
        }
    }
    
    // MARK: - Pet View
    private var petView: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.15))
                .frame(width: 45, height: 12)
                .offset(y: 30)
                .blur(radius: 4)
            
            // Pet
            let mood: PetMoodState = isFalling ? .sad : .happy
            let imageName = userSettings.pet.type.imageName(for: mood)
            
            Group {
                if let _ = UIImage(named: imageName) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 54, height: 54)
                } else {
                    Text(userSettings.pet.type.emoji)
                        .font(.system(size: 40))
                }
            }
            .scaleEffect(x: 1.0, y: petSquash)
            .rotationEffect(.degrees(petRotation))
        }
        .position(x: petX, y: petY)
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
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 4)
            }
            
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
                    .fill(Color.black.opacity(0.25))
            )
            
            Spacer()
            
            if gameState == .playing {
                // Score
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(score)m")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.25))
                )
                
                Spacer()
                
                // High score
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text("\(highScore)m")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.2))
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Ready Overlay
    private var readyOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Pet preview
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [themeManager.accentColor.opacity(0.3), Color.clear],
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
                            .frame(width: 90, height: 90)
                    } else {
                        Text(userSettings.pet.type.emoji)
                            .font(.system(size: 60))
                    }
                }
                
                // Title
                Text("Pet Jump")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, themeManager.accentColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4)
                
                // Instructions
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 22))
                            .foregroundColor(themeManager.accentColor)
                        
                        Text("Tilt your phone to move")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.green)
                        
                        Text("Land on platforms to jump")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.orange)
                        
                        Text("Don't fall!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                
                // High score
                if highScore > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("Best: \(highScore)m")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.yellow.opacity(0.2)))
                }
                
                // Start button
                Button(action: startGame) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("START")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: themeManager.accentColor.opacity(0.5), radius: 12, x: 0, y: 6)
                    )
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Game Over Overlay
    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // New high score or game over
                if isNewHighScore {
                    VStack(spacing: 10) {
                        Text("🎉 NEW RECORD! 🎉")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.5), radius: 8)
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("Game Over")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        let imageName = userSettings.pet.type.imageName(for: .sad)
                        if let _ = UIImage(named: imageName) {
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                        } else {
                            Text(userSettings.pet.type.emoji)
                                .font(.system(size: 45))
                        }
                    }
                }
                
                // Stats
                VStack(spacing: 16) {
                    // Height reached
                    VStack(spacing: 4) {
                        Text("HEIGHT")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("\(score)m")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    HStack(spacing: 30) {
                        VStack(spacing: 4) {
                            Text("BEST")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.yellow.opacity(0.8))
                            
                            Text("\(highScore)m")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.yellow)
                        }
                        
                        VStack(spacing: 4) {
                            Text("JUMPS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.cyan.opacity(0.8))
                            
                            Text("\(platformsJumped)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 40)
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: startGame) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Try Again")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    
                    Button(action: {
                        onComplete(0)
                    }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 50)
            }
        }
    }
    
    // MARK: - Game Logic
    private func startGame() {
        // Deduct credit when starting the game (and record for achievements)
        guard userSettings.useGameCredit(for: .bubblePop) else {
            // If no credits, close the game
            dismiss()
            return
        }
        
        gameState = .playing
        score = 0
        isNewHighScore = false
        petVelocityY = 0
        petRotation = 0
        petSquash = 1.0
        isFalling = false
        worldOffset = 0
        highestY = 0
        platformsJumped = 0
        backgroundHue = 0.55
        
        // Reset position
        petX = screenSize.width / 2
        petY = screenSize.height - 150
        
        // Reset motion
        motionManager.reset()
        
        // Generate initial platforms
        generateInitialPlatforms()
        
        // Start motion updates
        motionManager.startUpdates()
        
        // Start game loop
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateGame()
        }
        
        HapticFeedback.medium.trigger()
    }
    
    private func generateInitialPlatforms() {
        platforms = []
        
        // Starting platform (always under pet, wide and centered)
        let startPlatform = JumpPlatform(
            x: screenSize.width / 2,
            y: screenSize.height - 100,
            width: platformWidth + 30,
            isMoving: false,
            movingSpeed: 0
        )
        platforms.append(startPlatform)
        
        // Generate platforms going up with CONSISTENT spacing
        var currentY = screenSize.height - 100 - platformSpacing
        
        for i in 0..<25 {
            // Random X position but ensure platform stays on screen
            let minX = platformWidth / 2 + 10
            let maxX = screenSize.width - platformWidth / 2 - 10
            let platformX = CGFloat.random(in: minX...maxX)
            
            // Progressive difficulty - moving platforms appear after platform 20
            let shouldMove = i > 20 && Double.random(in: 0...1) < Double(i - 20) * 0.1
            let speed: CGFloat = shouldMove ? CGFloat.random(in: 1.2...1.8) : 0
            
            let platform = JumpPlatform(
                x: platformX,
                y: currentY,
                width: platformWidth,
                isMoving: shouldMove,
                movingSpeed: speed,
                movingDirection: Bool.random() ? 1 : -1
            )
            platforms.append(platform)
            
            // FIXED spacing - always the same distance
            currentY -= platformSpacing
        }
    }
    
    private func updateGame() {
        guard gameState == .playing else { return }
        
        // Gravity - constant, smooth
        petVelocityY += gravity
        petVelocityY = min(petVelocityY, maxFallSpeed)
        petY += petVelocityY
        
        // Tilt controls - DIRECT and responsive
        let tiltForce = CGFloat(motionManager.tilt) * tiltSensitivity
        petX += tiltForce
        
        // Visual rotation matches tilt directly
        petRotation = Double(motionManager.tilt) * 18
        
        // Screen wrap
        if petX < 0 { petX = screenSize.width }
        if petX > screenSize.width { petX = 0 }
        
        // Update falling state
        isFalling = petVelocityY > 1
        
        // Simple squash/stretch
        if petVelocityY < -3 {
            petSquash = 1.08
        } else if petVelocityY > 3 {
            petSquash = 0.92
        } else {
            petSquash = 1.0
        }
        
        // Check platform collisions (only when falling)
        if petVelocityY > 0 {
            for i in platforms.indices {
                let platform = platforms[i]
                let platformScreenY = platform.y + worldOffset
                let petFeet = petY + 27
                
                // Simple collision - pet feet hits platform top
                let platformTop = platformScreenY - 7
                let platformBottom = platformScreenY + 7
                let platformLeft = platform.x - platform.width / 2
                let platformRight = platform.x + platform.width / 2
                
                if petFeet >= platformTop && petFeet <= platformBottom &&
                   petX >= platformLeft && petX <= platformRight {
                    bounce()
                    break
                }
            }
        }
        
        // Update moving platforms
        for i in platforms.indices {
            if platforms[i].isMoving {
                platforms[i].x += platforms[i].movingDirection * platforms[i].movingSpeed
                
                // Reverse at edges with some padding
                if platforms[i].x < platformWidth / 2 + 10 {
                    platforms[i].movingDirection = 1
                } else if platforms[i].x > screenSize.width - platformWidth / 2 - 10 {
                    platforms[i].movingDirection = -1
                }
            }
        }
        
        // Scroll world up if pet goes high
        let screenThreshold = screenSize.height * 0.35
        if petY < screenThreshold {
            let diff = screenThreshold - petY
            worldOffset += diff
            petY = screenThreshold
            
            // Track highest point and update score
            if worldOffset > highestY {
                let heightGain = Int((worldOffset - highestY) / 8)
                if heightGain > 0 {
                    withAnimation(.easeOut(duration: 0.1)) {
                        score += heightGain
                    }
                }
                highestY = worldOffset
            }
            
            // Update sky color gradually
            updateSkyColor()
            
            // Generate new platforms above
            generateMorePlatforms()
            
            // Remove platforms far below screen
            platforms.removeAll { $0.y + worldOffset > screenSize.height + 150 }
        }
        
        // Check game over (fell below screen)
        if petY + worldOffset > screenSize.height + 80 {
            endGame()
        }
    }
    
    private func bounce() {
        // Consistent jump force every time
        petVelocityY = jumpForce
        platformsJumped += 1
        HapticFeedback.light.trigger()
    }
    
    private func generateMorePlatforms() {
        // Find highest platform
        let highestPlatformY = platforms.map { $0.y }.min() ?? 0
        
        // Generate new platforms above with CONSISTENT spacing
        var currentY = highestPlatformY - platformSpacing
        let difficultyLevel = Int(highestY / 500)
        
        for _ in 0..<4 {
            // Random X position but ensure platform stays on screen
            let minX = platformWidth / 2 + 10
            let maxX = screenSize.width - platformWidth / 2 - 10
            let platformX = CGFloat.random(in: minX...maxX)
            
            // Progressive difficulty - more moving platforms as you go higher
            let movingChance = min(0.5, Double(difficultyLevel) * 0.05)
            let shouldMove = Double.random(in: 0...1) < movingChance
            let speed: CGFloat = shouldMove ? CGFloat.random(in: 1.3...2.0) : 0
            
            let platform = JumpPlatform(
                x: platformX,
                y: currentY,
                width: platformWidth,
                isMoving: shouldMove,
                movingSpeed: speed,
                movingDirection: Bool.random() ? 1 : -1
            )
            platforms.append(platform)
            
            // FIXED spacing - always the same distance
            currentY -= platformSpacing
        }
    }
    
    private func updateSkyColor() {
        // Gradually shift sky color as you go higher
        let heightProgress = min(highestY / 8000, 1.0)
        withAnimation(.easeOut(duration: 0.5)) {
            backgroundHue = 0.55 - heightProgress * 0.35
        }
    }
    
    private func endGame() {
        gameState = .gameOver
        stopGame()
        
        // Check high score
        if score > highScore {
            highScore = score
            PetJumpHighScoreManager.shared.highScore = score
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

// MARK: - Platform View
struct PlatformView: View {
    let platform: JumpPlatform
    let themeColor: Color
    
    var body: some View {
        ZStack {
            // Platform shadow
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.15))
                .frame(width: platform.width, height: 14)
                .offset(y: 4)
                .blur(radius: 3)
            
            // Platform body
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: platform.isMoving 
                            ? [Color(hex: "FFB347"), Color(hex: "FF8C00")]
                            : [themeColor, themeColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: platform.width, height: 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        .offset(y: -1)
                )
                .shadow(color: (platform.isMoving ? Color.orange : themeColor).opacity(0.3), radius: 6, y: 2)
            
            // Moving indicator
            if platform.isMoving {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 8, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.white.opacity(0.6))
                .offset(y: -1)
            }
        }
        .opacity(platform.opacity)
        .position(x: platform.x, y: platform.y)
    }
}

// MARK: - Preview
#Preview {
    BubblePopGameView(onComplete: { _ in })
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
