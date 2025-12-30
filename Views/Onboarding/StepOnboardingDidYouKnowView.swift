//
//  StepOnboardingDidYouKnowView.swift
//  StepPet
//

import SwiftUI

struct StepOnboardingDidYouKnowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    @State private var animateText = false
    @State private var animateStats = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            VStack(spacing: 0) {
                // Header with back button and progress bar
                OnboardingHeader(
                    currentStep: StepPetOnboardingStep.didYouKnow.stepNumber,
                    totalSteps: StepPetOnboardingStep.totalSteps,
                    showBackButton: true,
                    onBack: onBack
                )
                
                // Header
                VStack(spacing: 16) {
                    Text("Did you know?")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                        .multilineTextAlignment(.center)
                        .opacity(animateText ? 1.0 : 0.0)
                    
                    Text("Walking is one of the best things you can do for your health")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(animateText ? 1.0 : 0.0)
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Fact cards
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        OnboardingFactCard(
                            icon: "heart.fill",
                            iconColor: Color.red,
                            text: "Walking 10,000 steps a day can reduce your risk of heart disease by up to 35%",
                            delay: 0.2
                        )
                        
                        OnboardingFactCard(
                            icon: "brain.head.profile",
                            iconColor: Color.purple,
                            text: "Regular walking improves memory, reduces stress, and boosts creativity",
                            delay: 0.35
                        )
                        
                        OnboardingFactCard(
                            icon: "moon.zzz.fill",
                            iconColor: Color.indigo,
                            text: "People who walk regularly sleep better and feel more energized throughout the day",
                            delay: 0.5
                        )
                        
                        OnboardingFactCard(
                            icon: "flame.fill",
                            iconColor: Color.orange,
                            text: "Walking 10,000 steps burns approximately 400-500 calories",
                            delay: 0.65
                        )
                    }
                    .padding(.horizontal, 24)
                }
                .opacity(animateStats ? 1.0 : 0.0)
                
                Spacer()
                
                // Bottom text and button
                VStack(spacing: 20) {
                    Text("Let's build healthier habits together")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                        .opacity(animateButton ? 1.0 : 0.0)
                    
                    OnboardingPrimaryButton(
                        title: "Continue",
                        isEnabled: true,
                        action: onContinue
                    )
                    .scaleEffect(animateButton ? 1.0 : 0.95)
                    .opacity(animateButton ? 1.0 : 0.0)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animateText = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateStats = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                animateButton = true
            }
        }
    }
}


