//
//  StepOnboardingLifetimeCalcView.swift
//  StepPet
//

import SwiftUI

struct StepOnboardingLifetimeCalcView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    @State private var showTitle = false
    @State private var showCalculation = false
    @State private var showComparison = false
    @State private var showPet = false
    @State private var showButton = false
    @State private var animatedMiles: Double = 0.0
    @State private var animationTasks: [Task<Void, Never>] = []
    
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
                
                Spacer()
                
                VStack(spacing: 32) {
                    // Title
                    if showTitle {
                        VStack(spacing: 8) {
                            Text("If you hit your goal every day")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(themeManager.secondaryTextColor)
                                .multilineTextAlignment(.center)
                            
                            Text("In just ONE year you'll walk...")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(themeManager.secondaryTextColor)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(showTitle ? 1.0 : 0.0)
                        .scaleEffect(showTitle ? 1.0 : 0.8)
                    }
                    
                    // Big distance number
                    if showCalculation {
                        VStack(spacing: 12) {
                            Text("\(Int(animatedMiles).formatted())")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.successColor)
                                .scaleEffect(showCalculation ? 1.0 : 0.3)
                                .opacity(showCalculation ? 1.0 : 0.0)
                            
                            Text("miles")
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                                .opacity(showCalculation ? 1.0 : 0.0)
                        }
                    }
                    
                    // Fun comparison
                    if showComparison {
                        VStack(spacing: 16) {
                            Text(distanceComparison.emoji)
                                .font(.system(size: 56))
                            
                            Text(distanceComparison.text)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .scaleEffect(showComparison ? 1.0 : 0.8)
                        .opacity(showComparison ? 1.0 : 0.0)
                    }
                    
                    // Pet celebration
                    if showPet {
                        VStack(spacing: 16) {
                            AnimatedPetView(
                                petType: petType,
                                moodState: .fullHealth
                            )
                            .frame(height: 140)
                            .scaleEffect(showPet ? 1.0 : 0.3)
                            .opacity(showPet ? 1.0 : 0.0)
                            
                            Text("Your pet is excited to start this journey with you!")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                                .multilineTextAlignment(.center)
                                .opacity(showPet ? 1.0 : 0.0)
                        }
                    }
                }
                
                Spacer()
                
                // Continue button
                if showButton {
                    OnboardingGradientButton(
                        title: "Let's make it happen",
                        icon: "arrow.right",
                        colors: [themeManager.accentColor, Color.green]
                    ) {
                        onContinue()
                    }
                    .scaleEffect(showButton ? 1.0 : 0.8)
                    .opacity(showButton ? 1.0 : 0.0)
                    .padding(.horizontal, 24)
                }
                
                Spacer().frame(height: 48)
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
        // Show title
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            showTitle = true
        }
        
        // Show calculation container
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(1.2)) {
            showCalculation = true
            HapticFeedback.heavy.trigger()
        }
        
        // Counting animation for miles
        let countingTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            
            guard !Task.isCancelled else { return }
            
            let targetMiles = yearlyMiles
            let duration: Double = 1.2
            let steps = 30
            let increment = targetMiles / Double(steps)
            
            for i in 0...steps {
                guard !Task.isCancelled else { return }
                
                try? await Task.sleep(nanoseconds: UInt64((duration / Double(steps)) * 1_000_000_000))
                
                guard !Task.isCancelled else { return }
                
                animatedMiles = increment * Double(i)
                
                if i == steps {
                    HapticFeedback.success.trigger()
                }
            }
        }
        animationTasks.append(countingTask)
        
        // Show comparison with delay
        let comparisonTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            
            guard !Task.isCancelled else { return }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                showComparison = true
                HapticFeedback.medium.trigger()
            }
        }
        animationTasks.append(comparisonTask)
        
        // Show pet with delay
        let petTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            
            guard !Task.isCancelled else { return }
            
            withAnimation(.spring(response: 1.0, dampingFraction: 0.5)) {
                showPet = true
            }
        }
        animationTasks.append(petTask)
        
        // Show button with delay
        let buttonTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            
            guard !Task.isCancelled else { return }
            
            withAnimation(.easeOut(duration: 0.6)) {
                showButton = true
            }
        }
        animationTasks.append(buttonTask)
    }
}

