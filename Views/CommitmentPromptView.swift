//
//  CommitmentPromptView.swift
//  VirtuPet
//
//  Emotional commitment prompt shown after first-time tutorial
//

import SwiftUI

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
    
    // Celebration animation states
    @State private var celebrationScale: CGFloat = 0.5
    @State private var celebrationOpacity: Double = 0
    @State private var petBounce = false
    @State private var confettiParticles: [CommitmentConfetti] = []
    @State private var showContinueButton = false
    
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
            // Header spacer
            Spacer()
                .frame(height: 60)
            
            // Title
            VStack(spacing: 8) {
                Text("I, \(userName), will use")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("VirtuPet to")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
            
            // Subtitle commitment text
            Text("take better care of \(petName), stay active,\nand build healthy habits together.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 16)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Tap and hold circle with pet icon
            ZStack {
                // Outer pulsing rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(themeManager.accentColor.opacity(0.15), lineWidth: 2)
                        .frame(width: 180 + CGFloat(i * 30), height: 180 + CGFloat(i * 30))
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.5)
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.4),
                            value: pulseAnimation
                        )
                }
                
                // Progress ring background
                Circle()
                    .stroke(
                        themeManager.accentColor.opacity(0.2),
                        lineWidth: 8
                    )
                    .frame(width: 160, height: 160)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        LinearGradient(
                            colors: themeManager.accentColorTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.05), value: holdProgress)
                
                // Main circle button
                ZStack {
                    // Gradient fill
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: themeManager.accentColorTheme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: themeManager.accentColor.opacity(0.4), radius: 20, x: 0, y: 10)
                    
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
                        .frame(width: 140, height: 140)
                    
                    // Fingerprint pattern (subtle)
                    if !showCheckmark {
                        Image(systemName: "touchid")
                            .font(.system(size: 50, weight: .thin))
                            .foregroundColor(.white.opacity(0.3))
                            .offset(y: -10)
                    }
                    
                    // Pet icon or checkmark
                    if showCheckmark {
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                    }
                }
                .scaleEffect(isHolding ? 0.95 : (ringScale))
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
            .padding(.vertical, 40)
            
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
            
            Spacer()
            
            // Skip button (subtle)
            Button(action: {
                HapticFeedback.light.trigger()
                dismissView()
            }) {
                Text("Skip for now")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor.opacity(0.6))
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Celebration View
    private var celebrationView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Yay committed header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Yay, committed!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            .scaleEffect(celebrationScale)
            .opacity(celebrationOpacity)
            
            Spacer()
                .frame(height: 40)
            
            // Pet at full health with video animation
            ZStack {
                // Glow behind pet
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                themeManager.accentColor.opacity(0.2),
                                themeManager.accentColor.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                
                // Pet video animation at full health
                VStack(spacing: 12) {
                    AnimatedPetVideoView(petType: userSettings.pet.type, moodState: .fullHealth)
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
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
            .scaleEffect(celebrationScale)
            .opacity(celebrationOpacity)
            
            Spacer()
                .frame(height: 30)
            
            // Encouraging message
            VStack(spacing: 8) {
                Text("\(petName) can't wait to")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Text("start this journey with you! 🎉")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            .multilineTextAlignment(.center)
            .scaleEffect(celebrationScale)
            .opacity(celebrationOpacity)
            
            Spacer()
            
            // Continue button
            if showContinueButton {
                Button(action: {
                    HapticFeedback.medium.trigger()
                    dismissView()
                }) {
                    Text("Let's Go!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: themeManager.accentColorTheme.gradientColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: themeManager.accentColor.opacity(0.4), radius: 10, y: 5)
                        )
                }
                .padding(.horizontal, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
                .frame(height: 50)
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
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCheckmark = true
        }
        
        // Transition to celebration after brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showCelebrationView()
        }
    }
    
    private func showCelebrationView() {
        // Generate confetti
        generateConfetti()
        
        withAnimation(.easeInOut(duration: 0.4)) {
            showCelebration = true
        }
        
        // Animate celebration elements
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            celebrationScale = 1.0
            celebrationOpacity = 1.0
        }
        
        // Start pet bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            petBounce = true
        }
        
        // Show continue button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showContinueButton = true
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
    
    private func dismissView() {
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
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

// MARK: - Preview
#Preview {
    CommitmentPromptView(isPresented: .constant(true), onComplete: {})
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
