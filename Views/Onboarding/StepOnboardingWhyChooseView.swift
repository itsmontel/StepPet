//
//  StepOnboardingWhyChooseView.swift
//  VirtuPet
//

import SwiftUI

struct StepOnboardingWhyChooseView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    @State private var animateTitle = false
    @State private var animateFeatures = false
    @State private var animateButton = false
    @State private var animatePet = false
    
    private var petType: PetType {
        userSettings.pet.type
    }
    
    private var petImageName: String {
        petType.imageName(for: .fullHealth)
    }
    
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with back button and progress bar
                    OnboardingHeader(
                        currentStep: StepPetOnboardingStep.whyChooseStepPet.stepNumber,
                        totalSteps: StepPetOnboardingStep.totalSteps,
                        showBackButton: true,
                        onBack: onBack
                    )
                    
                    // Pet and Header
                    VStack(spacing: 24) {
                        // Pet image with glow effect
                        ZStack {
                            Circle()
                                .fill(themeManager.accentColor.opacity(0.1))
                                .frame(width: 140, height: 140)
                                .blur(radius: 20)
                            
                            if let _ = UIImage(named: petImageName) {
                                Image(petImageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                            } else {
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }
                        .scaleEffect(animatePet ? 1.0 : 0.8)
                        .opacity(animatePet ? 1.0 : 0.0)
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            Text("Why choose VirtuPet?")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                                .multilineTextAlignment(.center)
                                .opacity(animateTitle ? 1.0 : 0.0)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Build walking habits through emotional connection")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                                .multilineTextAlignment(.center)
                                .opacity(animateTitle ? 1.0 : 0.0)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                    }
                    
                    // Key features
                    VStack(spacing: 18) {
                        OnboardingFeatureCard(
                            icon: "heart.fill",
                            gradient: [Color.pink, Color.red],
                            title: "Emotional Accountability",
                            description: "Your pet's health reflects your walking habits. You won't want to let them down!",
                            delay: 0.2
                        )
                        
                        OnboardingFeatureCard(
                            icon: "flame.fill",
                            gradient: [Color.orange, Color.red],
                            title: "Streak System",
                            description: "Build momentum with daily streaks. Earn badges at 3, 7, 14, 30, and 100 days!",
                            delay: 0.35
                        )
                        
                        OnboardingFeatureCard(
                            icon: "trophy.fill",
                            gradient: [Color.yellow, Color.orange],
                            title: "50+ Achievements",
                            description: "Unlock achievements as you progress. From first steps to marathon walker status.",
                            delay: 0.5
                        )
                        
                        OnboardingFeatureCard(
                            icon: "chart.line.uptrend.xyaxis",
                            gradient: [Color.blue, Color.purple],
                            title: "Detailed Analytics",
                            description: "Track your progress with weekly and monthly stats synced from HealthKit.",
                            delay: 0.65
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .opacity(animateFeatures ? 1.0 : 0.0)
                    
                    // Call to action
                    VStack(spacing: 20) {
                        Text("Ready to transform your walking habits?")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                            .multilineTextAlignment(.center)
                            .opacity(animateButton ? 1.0 : 0.0)
                        
                        Button(action: {
                            HapticFeedback.medium.trigger()
                            onContinue()
                        }) {
                            HStack(spacing: 10) {
                                Text("Let's do this")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(themeManager.accentColor)
                            .cornerRadius(20)
                            .shadow(color: themeManager.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(ResponsiveButtonStyle())
                        .scaleEffect(animateButton ? 1.0 : 0.95)
                        .opacity(animateButton ? 1.0 : 0.0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                animatePet = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateTitle = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                animateFeatures = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
                animateButton = true
            }
        }
    }
}

