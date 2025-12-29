//
//  StepOnboardingPetPreviewView.swift
//  StepPet
//

import SwiftUI

struct StepOnboardingPetPreviewView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    @State private var selectedHealthIndex: Double = 4 // Start at full health
    @State private var animateTitle = false
    @State private var animatePet = false
    @State private var animateSlider = false
    @State private var animateButton = false
    
    private let healthStates: [PetMoodState] = [.sick, .sad, .content, .happy, .fullHealth]
    
    private var currentHealthState: PetMoodState {
        healthStates[Int(selectedHealthIndex)]
    }
    
    private var petName: String {
        userSettings.pet.name
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
                    currentStep: StepPetOnboardingStep.petPreview.stepNumber,
                    totalSteps: StepPetOnboardingStep.totalSteps,
                    showBackButton: true,
                    onBack: onBack
                )
                
                Spacer()
                
                // Header text
                VStack(spacing: 16) {
                    Text("See for yourself")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                        .multilineTextAlignment(.center)
                        .opacity(animateTitle ? 1.0 : 0.0)
                    
                    Text("Your daily steps directly affect \(petName)'s health")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(animateTitle ? 1.0 : 0.0)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Pet Display with Health State
                VStack(spacing: 24) {
                    AnimatedPetView(
                        petType: petType,
                        moodState: currentHealthState
                    )
                    .frame(height: 200)
                    .id(currentHealthState)
                    .transition(.scale.combined(with: .opacity))
                    .scaleEffect(animatePet ? 1.0 : 0.8)
                    .opacity(animatePet ? 1.0 : 0.0)
                    
                    // Health State Info
                    VStack(spacing: 12) {
                        Text(currentHealthState.displayName)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(healthStateColor)
                        
                        Text(healthStateDescription)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 32)
                    }
                    .opacity(animatePet ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Health Slider
                VStack(spacing: 16) {
                    HStack {
                        Text("Sick")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(themeManager.dangerColor)
                        
                        Spacer()
                        
                        Text("Full health")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(themeManager.successColor)
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateSlider ? 1.0 : 0.0)
                    
                    Slider(value: $selectedHealthIndex, in: 0...4, step: 1)
                        .tint(healthStateColor)
                        .padding(.horizontal, 24)
                        .opacity(animateSlider ? 1.0 : 0.0)
                        .onChange(of: selectedHealthIndex) {
                            HapticFeedback.light.trigger()
                        }
                    
                    // Health Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(index <= Int(selectedHealthIndex) ? healthStates[index].color(themeManager: themeManager) : themeManager.secondaryTextColor.opacity(0.3))
                                .frame(width: 12, height: 12)
                        }
                    }
                    .opacity(animateSlider ? 1.0 : 0.0)
                }
                .padding(.vertical, 20)
                
                Spacer()
                
                // Continue Button
                OnboardingPrimaryButton(
                    title: "Continue",
                    isEnabled: true,
                    action: onContinue
                )
                .scaleEffect(animateButton ? 1.0 : 0.95)
                .opacity(animateButton ? 1.0 : 0.0)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .animation(.easeOut(duration: 0.2), value: selectedHealthIndex)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animateTitle = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                animatePet = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                animateSlider = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.7)) {
                animateButton = true
            }
        }
    }
    
    private var healthStateColor: Color {
        currentHealthState.color(themeManager: themeManager)
    }
    
    private var healthStateDescription: String {
        switch currentHealthState {
        case .sick:
            return "Walking very little today. \(petName) needs your help!"
        case .sad:
            return "Getting some steps in. \(petName) hopes you'll walk more."
        case .content:
            return "Decent progress today. \(petName) is doing okay."
        case .happy:
            return "Great walking today! \(petName) is feeling good."
        case .fullHealth:
            return "You hit your goal! \(petName) is thriving!"
        }
    }
}

// MARK: - PetMoodState Extension for Color
extension PetMoodState {
    func color(themeManager: ThemeManager) -> Color {
        switch self {
        case .sick: return themeManager.dangerColor
        case .sad: return Color.orange
        case .content: return themeManager.warningColor
        case .happy: return Color.green.opacity(0.8)
        case .fullHealth: return themeManager.successColor
        }
    }
}

