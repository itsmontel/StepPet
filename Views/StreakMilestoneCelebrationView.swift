//
//  StreakMilestoneCelebrationView.swift
//  VirtuPet
//

import SwiftUI

// MARK: - Milestone Streak Celebration View
struct StreakMilestoneCelebrationView: View {
    let streak: Int
    let petType: PetType
    let petName: String
    let onDismiss: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    // Animation states
    @State private var showOverlay = false
    @State private var showCard = false
    @State private var cardScale: CGFloat = 0.3
    @State private var cardOpacity: Double = 0
    @State private var showPet = false
    @State private var petScale: CGFloat = 0.5
    @State private var petBounce: CGFloat = 0
    @State private var showFireworks = false
    @State private var showStreakBadge = false
    @State private var badgeScale: CGFloat = 0
    @State private var badgeRotation: Double = -30
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var glowPulse: CGFloat = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0
    @State private var confettiParticles: [StreakConfetti] = []
    
    // Check if this is a milestone streak
    static func isMilestoneStreak(_ streak: Int) -> Bool {
        // Special milestones (excluding 1, which is handled separately)
        let milestones = [3, 7, 14, 365]
        if milestones.contains(streak) {
            return true
        }
        // Every 10 days (10, 20, 30, 40, 50, 60, 70, 80, 90, 100, etc.)
        if streak >= 10 && streak % 10 == 0 {
            return true
        }
        return false
    }
    
    // Check if first day streak celebration should show (only once ever)
    static func shouldShowFirstDayCelebration() -> Bool {
        let key = "hasShownFirstDayStreakCelebration"
        if UserDefaults.standard.bool(forKey: key) {
            return false // Already shown
        }
        // Mark as shown
        UserDefaults.standard.set(true, forKey: key)
        return true
    }
    
    // Combined check for milestone or first day
    static func shouldShowCelebration(for streak: Int) -> Bool {
        if streak == 1 {
            return shouldShowFirstDayCelebration()
        }
        return isMilestoneStreak(streak)
    }
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black
                .opacity(showOverlay ? 0.85 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    if showButton {
                        dismissWithAnimation()
                    }
                }
            
            // Confetti layer
            if showFireworks {
                StreakConfettiView(particles: confettiParticles, streakColor: streakColor)
            }
            
            // Main celebration card
            if showCard {
                celebrationCard
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
            }
        }
        .onAppear {
            startCelebrationSequence()
        }
    }
    
    // MARK: - Celebration Card
    private var celebrationCard: some View {
        VStack(spacing: 16) {
            // Glowing rings behind pet
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [streakColor.opacity(0.6), streakColor.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
                
                // Inner glow ring
                Circle()
                    .stroke(streakColor.opacity(0.3), lineWidth: 8)
                    .frame(width: 160, height: 160)
                    .scaleEffect(ringScale * 0.95)
                    .opacity(ringOpacity * 0.7)
                    .blur(radius: 4)
                
                // Pulsing glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [streakColor.opacity(0.4), streakColor.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 100
                        )
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(1.0 + glowPulse * 0.15)
                    .opacity(0.8)
                
                // Pet image
                if showPet {
                    let imageName = petType.imageName(for: .fullHealth)
                    if let uiImage = UIImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                            .shadow(color: streakColor.opacity(0.5), radius: 20)
                            .scaleEffect(petScale)
                            .offset(y: petBounce)
                    }
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 8)
            
            // Streak badge
            if showStreakBadge {
                streakBadgeView
                    .scaleEffect(badgeScale)
                    .rotationEffect(.degrees(badgeRotation))
            }
            
            // Title
            if showTitle {
                Text(milestoneTitle)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 20)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
            
            // Subtitle
            if showSubtitle {
                Text(milestoneSubtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Continue button
            if showButton {
                Button(action: dismissWithAnimation) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                        Text("Keep Going!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [streakColor, streakColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: streakColor.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: streakColor.opacity(glowPulse * 0.3), radius: 40, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(
                    LinearGradient(
                        colors: [streakColor.opacity(0.5), streakColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
    
    // MARK: - Streak Badge
    private var streakBadgeView: some View {
        VStack(spacing: 4) {
            // Icon
            Image(systemName: streakIcon)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [streakColor, streakColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: streakColor.opacity(0.5), radius: 8, x: 0, y: 4)
            
            // Number
            Text("\(streak)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [streakColor, streakColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: streakColor.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Label
            Text("DAY STREAK")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.secondaryTextColor)
                .tracking(2)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Animation Sequence
    private func startCelebrationSequence() {
        generateConfetti()
        
        // Stage 1: Overlay fade in
        withAnimation(.easeOut(duration: 0.4)) {
            showOverlay = true
        }
        
        // Stage 2: Card appears with spring
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showCard = true
                cardScale = 1.0
                cardOpacity = 1.0
            }
        }
        
        // Stage 3: Rings appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }
            
            // Start glow pulse
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = 1.0
            }
        }
        
        // Stage 4: Pet appears with bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.5)) {
                showPet = true
                petScale = 1.0
            }
            
            HapticFeedback.medium.trigger()
            
            // Pet bounce animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.3).repeatCount(3, autoreverses: true)) {
                    petBounce = -12
                }
            }
        }
        
        // Stage 5: Streak badge with rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                showStreakBadge = true
                badgeScale = 1.0
                badgeRotation = 0
            }
            
            HapticFeedback.success.trigger()
        }
        
        // Stage 6: Confetti!
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showFireworks = true
            }
            
            HapticFeedback.heavy.trigger()
        }
        
        // Stage 7: Title
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showTitle = true
            }
        }
        
        // Stage 8: Subtitle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showSubtitle = true
            }
        }
        
        // Stage 9: Button
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showButton = true
            }
        }
    }
    
    private func dismissWithAnimation() {
        HapticFeedback.light.trigger()
        
        withAnimation(.easeIn(duration: 0.25)) {
            cardScale = 0.8
            cardOpacity = 0
            showOverlay = false
            showFireworks = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [
            streakColor,
            streakColor.opacity(0.7),
            .yellow,
            .orange,
            .pink,
            .purple,
            .cyan
        ]
        
        confettiParticles = (0..<60).map { _ in
            StreakConfetti(
                x: Double.random(in: 0...1),
                y: Double.random(in: -0.3...0),
                color: colors.randomElement() ?? streakColor,
                size: CGFloat.random(in: 6...12),
                delay: Double.random(in: 0...1.5),
                duration: Double.random(in: 3...5)
            )
        }
    }
    
    // MARK: - Computed Properties
    private var streakColor: Color {
        switch streak {
        case 1:
            return Color(red: 0.4, green: 0.8, blue: 0.6) // Light green
        case 3:
            return Color(red: 0.3, green: 0.85, blue: 0.7) // Teal
        case 7:
            return Color.orange // StepPet accent
        case 10:
            return Color(red: 0.2, green: 0.7, blue: 0.5) // Green
        case 14:
            return Color(red: 0.2, green: 0.6, blue: 0.9) // Sky blue
        case 20:
            return Color(red: 0.3, green: 0.5, blue: 0.9) // Blue
        case 30:
            return Color(red: 0.6, green: 0.3, blue: 0.9) // Purple
        case 40:
            return Color(red: 0.8, green: 0.3, blue: 0.6) // Magenta
        case 50:
            return Color(red: 0.9, green: 0.5, blue: 0.2) // Orange gold
        case 60:
            return Color(red: 0.9, green: 0.4, blue: 0.4) // Coral
        case 70:
            return Color(red: 0.5, green: 0.4, blue: 0.9) // Indigo
        case 80:
            return Color(red: 0.4, green: 0.7, blue: 0.8) // Cyan
        case 90:
            return Color(red: 0.7, green: 0.6, blue: 0.3) // Bronze
        case 100:
            return Color(red: 0.9, green: 0.75, blue: 0.1) // Gold
        case 365:
            return Color(red: 1.0, green: 0.84, blue: 0.0) // Bright gold for 1 year
        default:
            // Every 100 days gets a unique rotating color
            if streak % 100 == 0 {
                let hue = Double((streak / 100) % 10) * 0.1
                return Color(hue: hue, saturation: 0.8, brightness: 0.9)
            }
            // Every 10 days between 100s
            if streak % 10 == 0 {
                let tens = (streak % 100) / 10
                let hue = Double(tens) * 0.1
                return Color(hue: hue, saturation: 0.7, brightness: 0.85)
            }
            return Color.orange
        }
    }
    
    private var streakIcon: String {
        switch streak {
        case 1:
            return "star.circle.fill"
        case 3:
            return "heart.fill"
        case 7:
            return "flame.fill"
        case 10:
            return "10.circle.fill"
        case 14:
            return "star.fill"
        case 20:
            return "20.circle.fill"
        case 30:
            return "crown.fill"
        case 40:
            return "40.circle.fill"
        case 50:
            return "bolt.fill"
        case 60:
            return "60.circle.fill"
        case 70:
            return "70.circle.fill"
        case 80:
            return "80.circle.fill"
        case 90:
            return "90.circle.fill"
        case 100:
            return "trophy.fill"
        case 365:
            return "party.popper"
        default:
            // For 200, 300, etc.
            if streak % 100 == 0 {
                return "trophy.fill"
            }
            // For 110, 120, 130, etc.
            if streak % 10 == 0 {
                return "flame.fill"
            }
            return "sparkles"
        }
    }
    
    private var milestoneTitle: String {
        switch streak {
        case 1:
            return "First Day Victory! ⭐"
        case 3:
            return "3 Day Streak! 💚"
        case 7:
            return "One Week Champion! 🔥"
        case 10:
            return "10 Days Strong! 🔟"
        case 14:
            return "Two Weeks Strong! ⭐"
        case 20:
            return "20 Days! Keep Going! 💪"
        case 30:
            return "One Month Legend! 👑"
        case 40:
            return "40 Days! Amazing! 🌟"
        case 50:
            return "50 Days Unstoppable! ⚡"
        case 60:
            return "60 Days! Incredible! ✨"
        case 70:
            return "70 Days! Fantastic! 🎯"
        case 80:
            return "80 Days! Almost There! 🚀"
        case 90:
            return "90 Days! So Close! 🏅"
        case 100:
            return "100 Days! Incredible! 🏆"
        case 200:
            return "200 Days! Legend! 💎"
        case 300:
            return "300 Days! Unstoppable! 🌟"
        case 365:
            return "ONE FULL YEAR! 🎉🎊"
        case 400:
            return "400 Days! Superhero! 🦸"
        case 500:
            return "500 Days! Legendary! 👑"
        default:
            if streak % 100 == 0 {
                return "\(streak) Days! Phenomenal! ✨"
            }
            if streak % 10 == 0 {
                return "\(streak) Days! Amazing! 🔥"
            }
            return "Amazing Milestone! 🎯"
        }
    }
    
    private var milestoneSubtitle: String {
        switch streak {
        case 1:
            return "Amazing start! \(petName) is already smiling!"
        case 3:
            return "3 days in! \(petName) loves your dedication!"
        case 7:
            return "\(petName) is proud of your first week!"
        case 10:
            return "Double digits! \(petName) is so happy!"
        case 14:
            return "Two weeks strong! \(petName) is thriving!"
        case 20:
            return "20 days! \(petName) is cheering you on!"
        case 30:
            return "A whole month! \(petName) couldn't be happier!"
        case 40:
            return "40 days! \(petName) is impressed!"
        case 50:
            return "50 days! \(petName) thinks you're amazing!"
        case 60:
            return "60 days! Two months with \(petName)!"
        case 70:
            return "70 days! \(petName) is so proud of you!"
        case 80:
            return "80 days! You and \(petName) are crushing it!"
        case 90:
            return "90 days! Three months almost done!"
        case 100:
            return "100 days! You and \(petName) are unstoppable!"
        case 365:
            return "365 days of stepping with \(petName)! You're incredible! 🎊"
        default:
            if streak % 100 == 0 {
                return "\(petName) is in awe of your \(streak)-day journey!"
            }
            if streak % 10 == 0 {
                return "\(petName) celebrates \(streak) days with you!"
            }
            return "\(petName) celebrates this milestone with you!"
        }
    }
}

// MARK: - Streak Confetti Particle
struct StreakConfetti: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    let color: Color
    let size: CGFloat
    let delay: Double
    let duration: Double
    var rotation: Double = Double.random(in: 0...360)
    var rotationSpeed: Double = Double.random(in: 180...540)
    var xVelocity: Double = Double.random(in: -0.3...0.3)
}

// MARK: - Streak Confetti View
struct StreakConfettiView: View {
    let particles: [StreakConfetti]
    let streakColor: Color
    
    @State private var animatedParticles: [StreakConfetti] = []
    @State private var particleRotations: [UUID: Double] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(animatedParticles) { particle in
                    RoundedRectangle(cornerRadius: particle.size / 3)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size * 1.5)
                        .rotationEffect(.degrees(particleRotations[particle.id] ?? particle.rotation))
                        .position(
                            x: geometry.size.width * particle.x,
                            y: geometry.size.height * particle.y
                        )
                        .opacity(particle.y < 1.2 ? 1.0 : 0)
                }
            }
        }
        .onAppear {
            animatedParticles = particles
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Initialize rotations
        for particle in animatedParticles {
            particleRotations[particle.id] = particle.rotation
        }
        
        // Animate each particle falling
        for index in animatedParticles.indices {
            let particle = animatedParticles[index]
            
            withAnimation(
                .easeIn(duration: particle.duration)
                .delay(particle.delay)
            ) {
                animatedParticles[index].y = 1.3
                animatedParticles[index].x += particle.xVelocity
            }
        }
        
        // Continuous rotation animation
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for index in animatedParticles.indices {
                let particle = animatedParticles[index]
                let currentRotation = particleRotations[particle.id] ?? 0
                particleRotations[particle.id] = currentRotation + (particle.rotationSpeed * 0.016)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "FFFAE3").ignoresSafeArea()
        
        StreakMilestoneCelebrationView(
            streak: 30,
            petType: .cat,
            petName: "Buddy",
            onDismiss: {}
        )
        .environmentObject(ThemeManager())
    }
}

