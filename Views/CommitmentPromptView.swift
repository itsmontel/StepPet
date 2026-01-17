//
//  CommitmentPromptView.swift
//  VirtuPet
//
//  Emotional commitment prompt shown after first-time tutorial
//

import SwiftUI
import Foundation

struct CommitmentPromptView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Binding var isPresented: Bool
    var onComplete: () -> Void
    
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var showCheckmark = false
    @State private var pulseAnimation = false
    @State private var ringScale: CGFloat = 1.0
    @State private var hasCompleted = false
    @State private var showCelebration = false
    
    // Intermediate celebration states (before Yay Committed screen)
    @State private var showCommittedText = false
    @State private var celebrationRingScale: CGFloat = 1.0
    @State private var celebrationRingOpacity: Double = 0
    @State private var sparkleRotation: Double = 0
    @State private var showSparkles = false
    @State private var checkmarkScale: CGFloat = 1.0
    @State private var intermediateConfetti: [CommitmentConfetti] = []
    
    // Celebration animation states
    @State private var celebrationScale: CGFloat = 0.5
    @State private var celebrationOpacity: Double = 0
    @State private var petBounce = false
    @State private var confettiParticles: [CommitmentConfetti] = []
    @State private var showContinueButton = false
    
    // Enhanced celebration states
    @State private var headerScale: CGFloat = 0.3
    @State private var headerOpacity: Double = 0
    @State private var petScale: CGFloat = 0.5
    @State private var petOpacity: Double = 0
    @State private var messageScale: CGFloat = 0.8
    @State private var messageOpacity: Double = 0
    @State private var glowPulse = false
    @State private var checkmarkBounce: CGFloat = 0
    @State private var starBurst = false
    @State private var floatingHearts: [FloatingHeart] = []
    
    // Party confetti states
    @State private var partyConfetti: [PartyConfettiPiece] = []
    
    private var userName: String {
        userSettings.userName.isEmpty ? "Friend" : userSettings.userName
    }
    
    private var petName: String {
        userSettings.pet.name.isEmpty ? "Buddy" : userSettings.pet.name
    }
    
    var body: some View {
        ZStack {
            // Background - same color throughout
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            // Confetti particles
            if showCelebration {
                ForEach(confettiParticles) { particle in
                    Text(particle.emoji)
                        .font(.system(size: particle.size))
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            
            if showCelebration {
                // CELEBRATION VIEW
                celebrationView
                    .transition(.opacity.combined(with: .scale))
            } else {
                // COMMITMENT VIEW
                commitmentView
            }
        }
        .onAppear {
            withAnimation {
                pulseAnimation = true
            }
            
            // Subtle breathing animation for the button
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                ringScale = 1.03
            }
        }
    }
    
    // MARK: - Commitment View
    private var commitmentView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)
            
            // Title section - improved layout
            VStack(spacing: 12) {
                Text("I, \(userName), will use")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("VirtuPet to")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.accentColor)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            
            Spacer()
                .frame(height: 20)
            
            // Commitment text in a card
            VStack(spacing: 6) {
                Text("Take better care of \(petName)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Stay active & build healthy habits together")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
            )
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Tap and hold circle with pet icon - BIGGER
            ZStack {
                // Celebration expanding rings (shown after completion)
                if showSparkles {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(themeManager.accentColor.opacity(0.6 - Double(i) * 0.15), lineWidth: 4)
                            .frame(width: 180, height: 180)
                            .scaleEffect(celebrationRingScale + CGFloat(i) * 0.3)
                            .opacity(celebrationRingOpacity)
                    }
                }
                
                // Sparkle stars rotating around
                if showSparkles {
                    ForEach(0..<8, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.accentColor)
                            .offset(x: 130)
                            .rotationEffect(.degrees(Double(i) * 45 + sparkleRotation))
                            .opacity(celebrationRingOpacity)
                    }
                }
                
                // Intermediate confetti burst
                ForEach(intermediateConfetti) { particle in
                    Text(particle.emoji)
                        .font(.system(size: particle.size))
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
                
                // Outer pulsing rings (hidden after completion) - BIGGER
                if !hasCompleted {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(themeManager.accentColor.opacity(0.12), lineWidth: 2)
                            .frame(width: 220 + CGFloat(i * 35), height: 220 + CGFloat(i * 35))
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .opacity(pulseAnimation ? 0 : 0.5)
                            .animation(
                                .easeInOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.4),
                                value: pulseAnimation
                            )
                    }
                }
                
                // Progress ring background - BIGGER
                Circle()
                    .stroke(
                        themeManager.accentColor.opacity(0.2),
                        lineWidth: 10
                    )
                    .frame(width: 200, height: 200)
                    .opacity(hasCompleted ? 0 : 1)
                
                // Progress ring - BIGGER
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        LinearGradient(
                            colors: themeManager.accentColorTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.05), value: holdProgress)
                
                // Main circle button - BIGGER (180x180)
                ZStack {
                    // Gradient fill (changes to solid green on completion)
                    Circle()
                        .fill(
                            showCheckmark ?
                            LinearGradient(colors: [Color.green, Color.green], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(
                                colors: themeManager.accentColorTheme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 180, height: 180)
                        .shadow(color: showCheckmark ? Color.green.opacity(0.5) : themeManager.accentColor.opacity(0.4), radius: showCheckmark ? 35 : 25, x: 0, y: 12)
                    
                    // Inner shine
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .frame(width: 180, height: 180)
                    
                    // Fingerprint pattern (subtle)
                    if !showCheckmark {
                        Image(systemName: "touchid")
                            .font(.system(size: 60, weight: .thin))
                            .foregroundColor(.white.opacity(0.25))
                            .offset(y: -12)
                    }
                    
                    // Pet icon or checkmark - BIGGER
                    if showCheckmark {
                        Image(systemName: "checkmark")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(checkmarkScale)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                }
                .scaleEffect(isHolding ? 0.93 : (hasCompleted ? 1.0 : ringScale))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHolding)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !hasCompleted {
                                startHolding()
                            }
                        }
                        .onEnded { _ in
                            if !hasCompleted {
                                stopHolding()
                            }
                        }
                )
            }
            
            Spacer()
                .frame(height: 32)
            
            // "Committed!" text that appears after completion
            if showCommittedText {
                Text("Committed!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(Color.green)
                    .transition(.scale.combined(with: .opacity))
                    .padding(.bottom, 20)
            } else {
                // Instruction text
                VStack(spacing: 4) {
                    Text("Tap and hold on the")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(themeManager.accentColor)
                        
                        Text("paw to commit.")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                }
            }
            
            Spacer()
                .frame(height: 60)
        }
    }
    
    // MARK: - Celebration View
    private var celebrationView: some View {
        ZStack {
            // Party popper confetti - explosive burst from corners
            ForEach(partyConfetti) { piece in
                Text(piece.emoji)
                    .font(.system(size: piece.size))
                    .position(piece.position)
                    .rotationEffect(.degrees(piece.rotation))
                    .opacity(piece.opacity)
            }
            
            // Floating hearts in background
            ForEach(floatingHearts) { heart in
                Text(heart.emoji)
                    .font(.system(size: heart.size))
                    .position(heart.position)
                    .opacity(heart.opacity)
            }
            
            // Star burst effect
            if starBurst {
                ForEach(0..<12, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.accentColor.opacity(0.6))
                        .offset(x: starBurst ? 150 : 0)
                        .rotationEffect(.degrees(Double(i) * 30))
                        .opacity(starBurst ? 0 : 1)
                }
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Yay committed header - BIGGER and more celebratory
                VStack(spacing: 16) {
                    ZStack {
                        // Pulsing glow behind checkmark
                        Circle()
                            .fill(themeManager.accentColor.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .scaleEffect(glowPulse ? 1.3 : 1.0)
                            .opacity(glowPulse ? 0.3 : 0.6)
                        
                        // Main checkmark circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: themeManager.accentColor.opacity(0.5), radius: 12, y: 4)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .offset(y: checkmarkBounce)
                    }
                    
                    Text("Yay, committed!")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .scaleEffect(headerScale)
                .opacity(headerOpacity)
                
                Spacer()
                    .frame(height: 30)
                
                // Pet at full health with video animation
                ZStack {
                    // Animated pulsing glow rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(themeManager.accentColor.opacity(0.2), lineWidth: 2)
                            .frame(width: 260 + CGFloat(i * 40), height: 260 + CGFloat(i * 40))
                            .scaleEffect(glowPulse ? 1.1 : 1.0)
                            .opacity(glowPulse ? 0.3 : 0.6)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                                value: glowPulse
                            )
                    }
                    
                    // Main glow behind pet
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.accentColor.opacity(0.35),
                                    themeManager.accentColor.opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(glowPulse ? 1.05 : 1.0)
                    
                    // Pet video animation at full health
                    VStack(spacing: 12) {
                        AnimatedPetVideoView(petType: userSettings.pet.type, moodState: .fullHealth)
                            .frame(width: 220, height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: themeManager.accentColor.opacity(0.3), radius: 20, y: 8)
                            .offset(y: petBounce ? -8 : 0)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true),
                                value: petBounce
                            )
                        
                        // Health bar at 100%
                        VStack(spacing: 6) {
                            HStack {
                                Text("Health")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(themeManager.secondaryTextColor)
                                Spacer()
                                Text("100%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .frame(width: 140)
                            
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(themeManager.secondaryCardColor)
                                    .frame(width: 140, height: 10)
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green, Color.mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 140, height: 10)
                                
                                // Sparkle effect
                                HStack {
                                    Spacer()
                                    Circle()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: 4, height: 4)
                                        .offset(x: -6)
                                }
                                .frame(width: 140)
                            }
                        }
                    }
                }
                .scaleEffect(petScale)
                .opacity(petOpacity)
                
                Spacer()
                    .frame(height: 24)
                
                // Encouraging message - More impactful
                VStack(spacing: 6) {
                    Text("\(petName) can't wait to")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("start this journey with you!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .multilineTextAlignment(.center)
                .scaleEffect(messageScale)
                .opacity(messageOpacity)
                
                Spacer()
                
                // Continue button - Solid orange to match onboarding
                if showContinueButton {
                    Button(action: {
                        HapticFeedback.medium.trigger()
                        dismissView()
                    }) {
                        HStack(spacing: 10) {
                            Text("Let's Go!")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(themeManager.accentColor)
                                .shadow(color: themeManager.accentColor.opacity(0.4), radius: 12, y: 6)
                        )
                    }
                    .buttonStyle(ResponsiveButtonStyle())
                    .padding(.horizontal, 40)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                        removal: .opacity
                    ))
                }
                
                Spacer()
                    .frame(height: 50)
            }
        }
    }
    
    // MARK: - Actions
    
    private func startHolding() {
        guard !isHolding else { return }
        isHolding = true
        HapticFeedback.light.trigger()
        
        // Animate progress over 1.5 seconds
        let totalDuration: Double = 1.5
        let steps = 100
        let stepDuration = totalDuration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                if isHolding && !hasCompleted {
                    withAnimation(.linear(duration: stepDuration)) {
                        holdProgress = CGFloat(i) / CGFloat(steps)
                    }
                    
                    // Trigger haptic at intervals
                    if i % 25 == 0 && i > 0 {
                        HapticFeedback.light.trigger()
                    }
                    
                    // Complete when full
                    if i == steps {
                        completeCommitment()
                    }
                }
            }
        }
    }
    
    private func stopHolding() {
        guard !hasCompleted else { return }
        isHolding = false
        
        // Reset progress if not completed
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            holdProgress = 0
        }
    }
    
    private func completeCommitment() {
        hasCompleted = true
        isHolding = false
        HapticFeedback.success.trigger()
        
        // Start preloading paywall GIF early for smooth transition
        GIFCacheManager.shared.preload("paywalldog")
        
        // Show checkmark with bounce
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            showCheckmark = true
        }
        
        // Checkmark bounce animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                checkmarkScale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    checkmarkScale = 1.0
                }
            }
        }
        
        // Start sparkles and celebration rings
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showSparkles = true
            HapticFeedback.medium.trigger()
            
            // Expanding rings
            withAnimation(.easeOut(duration: 0.8)) {
                celebrationRingScale = 2.5
                celebrationRingOpacity = 0.8
            }
            
            // Fade out rings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.5)) {
                    celebrationRingOpacity = 0
                }
            }
            
            // Rotating sparkles
            withAnimation(.linear(duration: 1.5)) {
                sparkleRotation = 180
            }
        }
        
        // Show "Committed!" text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCommittedText = true
            }
            HapticFeedback.light.trigger()
        }
        
        // Second haptic burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            HapticFeedback.success.trigger()
        }
        
        // Transition to celebration after extended celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            showCelebrationView()
        }
    }
    
    
    private func showCelebrationView() {
        // Generate confetti and floating hearts
        generateConfetti()
        generateFloatingHearts()
        generatePartyConfetti() // Gentle falling confetti
        
        // Trigger star burst
        withAnimation(.easeOut(duration: 0.8)) {
            starBurst = true
        }
        
        // Show the celebration view
        withAnimation(.easeInOut(duration: 0.3)) {
            showCelebration = true
        }
        
        // STAGGERED ANIMATIONS for dramatic effect
        
        // 1. Header drops in with bounce (0.1s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                headerScale = 1.0
                headerOpacity = 1.0
            }
            HapticFeedback.medium.trigger()
            
            // Checkmark bounce
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4).delay(0.2)) {
                checkmarkBounce = -10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    checkmarkBounce = 0
                }
            }
        }
        
        // 2. Pet zooms in (0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                petScale = 1.0
                petOpacity = 1.0
            }
            HapticFeedback.light.trigger()
        }
        
        // 3. Start glow pulse (0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            glowPulse = true
        }
        
        // 4. Pet bounce starts (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            petBounce = true
        }
        
        // 5. Message fades in (0.9s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                messageScale = 1.0
                messageOpacity = 1.0
            }
        }
        
        // 6. Continue button slides up (2.5s - more delay for celebration to land)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContinueButton = true
            }
            HapticFeedback.light.trigger()
        }
    }
    
    private func generateFloatingHearts() {
        let emojis = ["❤️", "🧡", "💛", "💚", "💙", "💜", "🤍", "✨", "⭐️"]
        let screenWidth = UIScreen.main.bounds.width
        
        for i in 0..<15 {
            let heart = FloatingHeart(
                id: i,
                emoji: emojis.randomElement() ?? "❤️",
                position: CGPoint(
                    x: CGFloat.random(in: 30...(screenWidth - 30)),
                    y: CGFloat.random(in: 100...700)
                ),
                size: CGFloat.random(in: 18...32),
                opacity: Double.random(in: 0.4...0.8)
            )
            floatingHearts.append(heart)
        }
        
        // Animate hearts floating up and fading
        for i in 0..<floatingHearts.count {
            let delay = Double.random(in: 0...1.0)
            
            withAnimation(.easeOut(duration: 4).delay(delay)) {
                floatingHearts[i].position.y -= 200
                floatingHearts[i].opacity = 0
            }
        }
    }
    
    private func generateConfetti() {
        let emojis = ["🎉", "✨", "⭐️", "🌟", "💫", "🎊", "❤️", "🧡", "💛", "💚"]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for i in 0..<25 {
            let particle = CommitmentConfetti(
                id: i,
                emoji: emojis.randomElement() ?? "✨",
                position: CGPoint(
                    x: CGFloat.random(in: 20...(screenWidth - 20)),
                    y: CGFloat.random(in: 50...(screenHeight - 100))
                ),
                size: CGFloat.random(in: 16...28),
                opacity: Double.random(in: 0.6...1.0)
            )
            confettiParticles.append(particle)
        }
        
        // Animate confetti falling and fading
        for i in 0..<confettiParticles.count {
            let delay = Double.random(in: 0...0.5)
            
            withAnimation(.easeOut(duration: 3).delay(delay)) {
                confettiParticles[i].position.y += 100
                confettiParticles[i].opacity = 0
            }
        }
    }
    
    private func generatePartyConfetti() {
        let confettiEmojis = ["🎊", "🎉", "✨", "🌟", "⭐️", "💫", "🎀", "🥳", "🎈", "💜", "💛", "🧡"]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Create gentle confetti falling from top
        for i in 0..<40 {
            let startX = CGFloat.random(in: 20...(screenWidth - 20))
            let startY = CGFloat.random(in: -50...0) // Start above screen
            
            // Gentle falling path with slight horizontal drift
            let endX = startX + CGFloat.random(in: -60...60)
            let endY = screenHeight + 50 // Fall below screen
            
            let piece = PartyConfettiPiece(
                id: i,
                emoji: confettiEmojis.randomElement() ?? "🎊",
                position: CGPoint(x: startX, y: startY),
                endPosition: CGPoint(x: endX, y: endY),
                size: CGFloat.random(in: 20...32),
                rotation: Double.random(in: 0...180),
                endRotation: Double.random(in: 360...720),
                opacity: Double.random(in: 0.7...1.0)
            )
            partyConfetti.append(piece)
        }
        
        // Smooth, gentle falling animation
        for i in 0..<partyConfetti.count {
            let delay = Double(i) * 0.05 // Staggered start
            let duration = Double.random(in: 4.0...6.0) // Slow fall
            
            // Gentle easeInOut for smooth motion
            withAnimation(.easeInOut(duration: duration).delay(delay)) {
                partyConfetti[i].position = partyConfetti[i].endPosition
                partyConfetti[i].rotation = partyConfetti[i].endRotation
            }
            
            // Fade out near the end
            withAnimation(.easeOut(duration: 1.5).delay(delay + duration - 1.5)) {
                partyConfetti[i].opacity = 0
            }
        }
        
        // Single satisfying haptic
        HapticFeedback.success.trigger()
    }
    
    private func dismissView() {
        // Trigger completion immediately - no delay
        onComplete()
    }
}

// MARK: - Commitment Confetti
struct CommitmentConfetti: Identifiable {
    let id: Int
    let emoji: String
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
}

// MARK: - Floating Heart
struct FloatingHeart: Identifiable {
    let id: Int
    let emoji: String
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
}

// MARK: - Party Confetti Piece
struct PartyConfettiPiece: Identifiable {
    let id: Int
    let emoji: String
    var position: CGPoint
    var endPosition: CGPoint
    let size: CGFloat
    var rotation: Double
    var endRotation: Double
    var opacity: Double
}

// MARK: - Preview
#Preview {
    CommitmentPromptView(isPresented: .constant(true), onComplete: {})
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
