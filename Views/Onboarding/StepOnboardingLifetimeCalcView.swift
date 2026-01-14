//
//  StepOnboardingLifetimeCalcView.swift
//  VirtuPet
//

import SwiftUI

struct StepOnboardingLifetimeCalcView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    @State private var animateTitle = false
    @State private var animateNumber = false
    @State private var animateComparison = false
    @State private var animatePet = false
    @State private var animateButton = false
    @State private var animatedMiles: Double = 0.0
    @State private var animationTasks: [Task<Void, Never>] = []
    
    // Enhanced effects
    @State private var glowPulse = false
    @State private var numberScale: CGFloat = 0.5
    @State private var showSparkles = false
    @State private var sparkleRotation: Double = 0
    
    private var dailyGoal: Int {
        userSettings.dailyStepGoal
    }
    
    // Calculate yearly miles (average stride length is about 2.5 feet)
    private var yearlyMiles: Double {
        let yearlySteps = Double(dailyGoal) * 365
        let strideLengthFeet = 2.5
        let feetPerMile = 5280.0
        return (yearlySteps * strideLengthFeet) / feetPerMile
    }
    
    // Fun comparisons based on distance
    private var distanceComparison: (emoji: String, text: String) {
        let miles = yearlyMiles
        
        if miles >= 2000 {
            return ("🇺🇸", "That's like walking across the entire United States!")
        } else if miles >= 1500 {
            return ("🏔️", "That's the length of the Appalachian Trail!")
        } else if miles >= 1000 {
            return ("🌴", "That's like walking the entire California coastline... twice!")
        } else if miles >= 800 {
            return ("🗽", "That's New York to Miami!")
        } else if miles >= 600 {
            return ("🌉", "That's like walking from LA to San Francisco... 4 times!")
        } else if miles >= 400 {
            return ("🎰", "That's LA to Las Vegas... and back!")
        } else if miles >= 300 {
            return ("🏖️", "That's the entire length of Florida!")
        } else if miles >= 200 {
            return ("🗼", "That's like climbing the Eiffel Tower 2,000 times!")
        } else {
            return ("🚶", "That's an incredible journey of health!")
        }
    }
    
    private var petType: PetType {
        userSettings.pet.type
    }
    
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            VStack(spacing: 0) {
                // Header with back button and progress bar
                OnboardingHeader(
                    currentStep: StepPetOnboardingStep.lifetimeCalculation.stepNumber,
                    totalSteps: StepPetOnboardingStep.totalSteps,
                    showBackButton: true,
                    onBack: onBack
                )
                
                // Title section
                VStack(spacing: 8) {
                    Text("If you hit your goal every day")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                    
                    Text("In one year you'll walk...")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .opacity(animateTitle ? 1.0 : 0.0)
                .offset(y: animateTitle ? 0 : 10)
                .padding(.top, 32)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Big miles number with glow and sparkles
                ZStack {
                    // Pulsing glow behind number
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.accentColor.opacity(0.25),
                                    themeManager.accentColor.opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                        .scaleEffect(glowPulse ? 1.15 : 1.0)
                        .opacity(animateNumber ? 1.0 : 0.0)
                    
                    // Sparkles around number
                    if showSparkles {
                        ForEach(0..<6, id: \.self) { i in
                            Image(systemName: "sparkle")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(themeManager.accentColor.opacity(0.7))
                                .offset(x: 90)
                                .rotationEffect(.degrees(Double(i) * 60 + sparkleRotation))
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(Int(animatedMiles).formatted())")
                            .font(.system(size: 80, weight: .black, design: .rounded))
                            .foregroundColor(themeManager.accentColor)
                            .shadow(color: themeManager.accentColor.opacity(0.2), radius: 8, y: 4)
                        
                        Text("miles")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .textCase(.uppercase)
                            .tracking(2)
                    }
                    .scaleEffect(numberScale)
                    .opacity(animateNumber ? 1.0 : 0.0)
                }
                
                Spacer()
                    .frame(height: 32)
                
                // Comparison card
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(themeManager.accentColor.opacity(0.1))
                            .frame(width: 56, height: 56)
                        
                        Text(distanceComparison.emoji)
                            .font(.system(size: 28))
                    }
                    
                    Text(distanceComparison.text)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.cardBackgroundColor)
                )
                .padding(.horizontal, 24)
                .scaleEffect(animateComparison ? 1.0 : 0.9)
                .opacity(animateComparison ? 1.0 : 0.0)
                
                Spacer()
                    .frame(height: 20)
                
                // Pet motivation card
                HStack(spacing: 14) {
                    AnimatedPetVideoView(
                        petType: petType,
                        moodState: .fullHealth
                    )
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Let's do this together!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("\(userSettings.pet.name) believes in you 🐾")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.cardBackgroundColor)
                )
                .padding(.horizontal, 24)
                .scaleEffect(animatePet ? 1.0 : 0.9)
                .opacity(animatePet ? 1.0 : 0.0)
                
                Spacer()
                
                // Continue button
                OnboardingPrimaryButton(
                    title: "Let's make it happen",
                    isEnabled: true,
                    action: {
                        HapticFeedback.medium.trigger()
                        onContinue()
                    }
                )
                .scaleEffect(animateButton ? 1.0 : 0.95)
                .opacity(animateButton ? 1.0 : 0.0)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            for task in animationTasks {
                task.cancel()
            }
            animationTasks.removeAll()
        }
    }
    
    private func startAnimations() {
        // Title fade in - delayed start for tension
        withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
            animateTitle = true
        }
        
        // Number container appears with dramatic scale
        let numberTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s delay for tension
            guard !Task.isCancelled else { return }
            
            HapticFeedback.medium.trigger()
            
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                animateNumber = true
                numberScale = 1.1
            }
            
            // Settle back
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                numberScale = 1.0
            }
        }
        animationTasks.append(numberTask)
        
        // Start glow pulse after number appears
        let glowTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        animationTasks.append(glowTask)
        
        // Counting animation for miles - SLOWER for more impact
        let countingTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            guard !Task.isCancelled else { return }
            
            let targetMiles = yearlyMiles
            let duration: Double = 2.5 // Even slower for maximum drama
            let steps = 60
            let increment = targetMiles / Double(steps)
            
            for i in 0...steps {
                guard !Task.isCancelled else { return }
                
                try? await Task.sleep(nanoseconds: UInt64((duration / Double(steps)) * 1_000_000_000))
                guard !Task.isCancelled else { return }
                
                animatedMiles = increment * Double(i)
                
                // Haptic at 25%, 50%, 75%, and end for more engagement
                if i == steps / 4 || i == steps / 2 || i == (steps * 3) / 4 {
                    HapticFeedback.light.trigger()
                }
                if i == steps {
                    HapticFeedback.success.trigger()
                }
            }
        }
        animationTasks.append(countingTask)
        
        // Show sparkles after counting completes - LONGER PAUSE
        let sparkleTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_500_000_000) // Extra 0.5s pause
            guard !Task.isCancelled else { return }
            
            showSparkles = true
            
            // Rotate sparkles
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
        animationTasks.append(sparkleTask)
        
        // LONGER PAUSE before comparison - let the number sink in
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(5.5)) {
            animateComparison = true
        }
        
        // Haptic when comparison appears
        let comparisonHapticTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_500_000_000)
            guard !Task.isCancelled else { return }
            HapticFeedback.medium.trigger()
        }
        animationTasks.append(comparisonHapticTask)
        
        // MUCH LONGER PAUSE before pet card - let comparison sink in
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(7.5)) {
            animatePet = true
        }
        
        // Haptic when pet appears
        let petHapticTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 7_500_000_000)
            guard !Task.isCancelled else { return }
            HapticFeedback.light.trigger()
        }
        animationTasks.append(petHapticTask)
        
        // Button appears last - after emotional moment
        withAnimation(.easeOut(duration: 0.6).delay(8.5)) {
            animateButton = true
        }
    }
}
