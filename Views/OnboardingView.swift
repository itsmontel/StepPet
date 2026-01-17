//
//  OnboardingView.swift
//  VirtuPet
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var currentStep: StepPetOnboardingStep = .welcome
    @State private var showCommitment = false
    @State private var showPaywall = false
    @State private var showSuccessTransition = false
    
    private func goBack() {
        HapticFeedback.light.trigger()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            switch currentStep {
            case .welcome:
                break // No back from welcome
            case .petSelection:
                currentStep = .welcome
            case .petPreview:
                currentStep = .petSelection
            case .motivation:
                currentStep = .petPreview
            case .didYouKnow:
                currentStep = .motivation
            case .goalInput:
                currentStep = .didYouKnow
            case .lifetimeCalculation:
                currentStep = .goalInput
            case .whyChooseStepPet:
                currentStep = .lifetimeCalculation
            case .notificationPermission:
                currentStep = .whyChooseStepPet
            case .healthKitPermission:
                currentStep = .notificationPermission
            case .commitment:
                break // No back from commitment (it's a commitment screen)
            case .paywall:
                break // No back from paywall
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Light yellow background for onboarding
            (themeManager.isDarkMode ? Color(hex: "121212") : Color(hex: "FFFAE6"))
                .ignoresSafeArea()
            
            if showSuccessTransition {
                // Success transition animation
                OnboardingSuccessTransition()
                    .transition(.opacity)
            } else {
                VStack {
                    switch currentStep {
                case .welcome:
                    StepOnboardingWelcomeView(
                        onContinue: {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                currentStep = .petSelection
                            }
                        }
                    )
                    
                case .petSelection:
                    StepOnboardingPetSelectionView(
                        onContinue: {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                currentStep = .petPreview
                            }
                        },
                        onBack: goBack
                    )
                    
                case .petPreview:
                    StepOnboardingPetPreviewView(
                        onContinue: {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                currentStep = .motivation
                            }
                        },
                        onBack: goBack
                    )
                    
                case .motivation:
                    StepOnboardingMotivationView(
                        onContinue: {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                currentStep = .didYouKnow
                            }
                        },
                        onBack: goBack
                    )
                    
                case .didYouKnow:
                    StepOnboardingDidYouKnowView(
                        onContinue: {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                currentStep = .goalInput
                            }
                        },
                        onBack: goBack
                    )
                    
                case .goalInput:
                    StepOnboardingGoalInputView(
                        onContinue: {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                currentStep = .lifetimeCalculation
                            }
                        },
                        onBack: goBack
                    )
                    
                case .lifetimeCalculation:
                    StepOnboardingLifetimeCalcView(
                        onContinue: {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                currentStep = .whyChooseStepPet
                            }
                        },
                        onBack: goBack
                    )
                    
                case .whyChooseStepPet:
                    StepOnboardingWhyChooseView(
                        onContinue: {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                currentStep = .notificationPermission
                            }
                        },
                        onBack: goBack
                    )
                    
                case .notificationPermission:
                    StepOnboardingNotificationView(
                        onContinue: {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                currentStep = .healthKitPermission
                            }
                        },
                        onBack: goBack
                    )
                    
                case .healthKitPermission:
                    StepOnboardingHealthKitView(
                        onContinue: {
                            // After HealthKit, show Commitment screen
                            HapticFeedback.light.trigger()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                currentStep = .commitment
                            }
                        },
                        onBack: goBack
                    )
                    
                case .commitment:
                    // Commitment screen - full screen view (no skip option)
                    OnboardingCommitmentView(
                        onComplete: {
                            // After commitment, show paywall
                            HapticFeedback.light.trigger()
                            // Small delay to ensure GIF preload completes for smooth transition
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                    currentStep = .paywall
                                }
                            }
                        }
                    )
                    
                case .paywall:
                    // Paywall screen - full screen view
                    OnboardingPaywallView(isPresented: .constant(true), onComplete: {
                        completeOnboarding()
                    })
                }
                }
            }
        }
    }
    
    private func completeOnboarding() {
        // Show success transition animation
        HapticFeedback.success.trigger()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showSuccessTransition = true
        }
        
        // After animation, transition to app
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.4)) {
                userSettings.hasCompletedOnboarding = true
            }
        }
    }
}

// MARK: - Success Transition Animation
struct OnboardingSuccessTransition: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var checkmarkScale: CGFloat = 0.3
    @State private var checkmarkOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var confetti: [OnboardingConfetti] = []
    
    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            // Confetti
            ForEach(confetti) { piece in
                Text(piece.emoji)
                    .font(.system(size: piece.size))
                    .position(piece.position)
                    .opacity(piece.opacity)
            }
            
            VStack(spacing: 24) {
                // Success checkmark with ring
                ZStack {
                    // Expanding rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(themeManager.accentColor.opacity(0.3 - Double(i) * 0.1), lineWidth: 3)
                            .frame(width: 120 + CGFloat(i * 30), height: 120 + CGFloat(i * 30))
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)
                    }
                    
                    // Main circle
                    Circle()
                        .fill(themeManager.accentColor)
                        .frame(width: 100, height: 100)
                        .shadow(color: themeManager.accentColor.opacity(0.4), radius: 20, y: 8)
                        .scaleEffect(checkmarkScale)
                        .opacity(checkmarkOpacity)
                    
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkmarkScale)
                        .opacity(checkmarkOpacity)
                }
                
                // Text
                VStack(spacing: 8) {
                    Text("You're all set!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("Let's start your journey with \(userSettings.pet.name)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Generate confetti
        generateConfetti()
        
        // Checkmark animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            checkmarkScale = 1.0
            checkmarkOpacity = 1.0
        }
        
        // Ring animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.8)) {
                ringScale = 1.3
                ringOpacity = 0.6
            }
            
            // Fade out rings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    ringOpacity = 0
                }
            }
        }
        
        // Text animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.5)) {
                textOpacity = 1.0
            }
        }
    }
    
    private func generateConfetti() {
        let emojis = ["🎉", "✨", "⭐️", "🌟", "💫", "❤️", "🧡", "💛"]
        let screenWidth = UIScreen.main.bounds.width
        
        for i in 0..<20 {
            let startX = CGFloat.random(in: 20...(screenWidth - 20))
            let startY = CGFloat.random(in: -30...0)
            
            let piece = OnboardingConfetti(
                id: i,
                emoji: emojis.randomElement() ?? "✨",
                position: CGPoint(x: startX, y: startY),
                size: CGFloat.random(in: 18...28),
                opacity: Double.random(in: 0.7...1.0)
            )
            confetti.append(piece)
        }
        
        // Animate confetti falling
        for i in 0..<confetti.count {
            let delay = Double.random(in: 0...0.3)
            let duration = Double.random(in: 2.5...4.0)
            
            withAnimation(.easeIn(duration: duration).delay(delay)) {
                confetti[i].position.y += UIScreen.main.bounds.height + 100
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(delay + duration - 1.0)) {
                confetti[i].opacity = 0
            }
        }
    }
}

// MARK: - Onboarding Confetti
struct OnboardingConfetti: Identifiable {
    let id: Int
    let emoji: String
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
}

// MARK: - Onboarding Commitment View Wrapper
// Wraps CommitmentPromptView for use in onboarding flow
struct OnboardingCommitmentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    var onComplete: () -> Void
    
    @State private var isPresented = true
    
    var body: some View {
        CommitmentPromptView(isPresented: $isPresented) {
            // Called when user completes commitment
            onComplete()
        }
        .environmentObject(themeManager)
        .environmentObject(userSettings)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
        .environmentObject(HealthKitManager())
}
