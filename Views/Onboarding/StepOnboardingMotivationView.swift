//
//  StepOnboardingMotivationView.swift
//  StepPet
//

import SwiftUI

// MARK: - Walking Motivation Options
enum WalkingMotivation: String, CaseIterable {
    case getMoreActive = "I want to get more active"
    case loseWeight = "I'm trying to lose weight"
    case buildHealthyHabits = "Building healthier habits"
    case mentalHealth = "Improve my mental health"
    case exploreOutdoors = "Explore the outdoors more"
    case accountability = "I need accountability to walk"
}

struct StepOnboardingMotivationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    @State private var selectedMotivations: Set<WalkingMotivation> = []
    @State private var animateTitle = false
    @State private var animateOptions = false
    @State private var animateButton = false
    
    private var petType: PetType {
        userSettings.pet.type
    }
    
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            VStack(spacing: 0) {
                // Header with back button and progress bar
                OnboardingHeader(
                    currentStep: StepPetOnboardingStep.motivation.stepNumber,
                    totalSteps: StepPetOnboardingStep.totalSteps,
                    showBackButton: true,
                    onBack: onBack
                )
                
                Spacer()
                
                // Header with pet animation
                VStack(spacing: 24) {
                    AnimatedPetView(
                        petType: petType,
                        moodState: .content
                    )
                    .frame(height: 120)
                    .opacity(animateTitle ? 1.0 : 0.0)
                    .scaleEffect(animateTitle ? 1.0 : 0.8)
                    
                    VStack(spacing: 16) {
                        Text("You're here for a reason")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(animateTitle ? 1.0 : 0.0)
                        
                        Text("What is that reason?")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .opacity(animateTitle ? 1.0 : 0.0)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Motivation options
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(Array(WalkingMotivation.allCases.enumerated()), id: \.element) { index, motivation in
                            OnboardingSelectionRow(
                                text: motivation.rawValue,
                                isSelected: selectedMotivations.contains(motivation),
                                delay: Double(index) * 0.08
                            ) {
                                toggleMotivation(motivation)
                            }
                            .opacity(animateOptions ? 1.0 : 0.0)
                            .offset(x: animateOptions ? 0 : 50)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxHeight: 340)
                
                Spacer()
                
                // Continue button
                OnboardingPrimaryButton(
                    title: "Continue",
                    isEnabled: !selectedMotivations.isEmpty,
                    action: {
                        // Could save motivations to user settings if needed
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
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animateTitle = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateOptions = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                animateButton = true
            }
        }
    }
    
    private func toggleMotivation(_ motivation: WalkingMotivation) {
        if selectedMotivations.contains(motivation) {
            selectedMotivations.remove(motivation)
        } else {
            selectedMotivations.insert(motivation)
        }
        HapticFeedback.light.trigger()
    }
}

