//
//  OnboardingView.swift
//  StepPet
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var currentStep: StepPetOnboardingStep = .welcome
    
    private func goBack() {
        withAnimation(.easeOut(duration: 0.15)) {
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
            }
        }
        HapticFeedback.light.trigger()
    }
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack {
                switch currentStep {
                case .welcome:
                    StepOnboardingWelcomeView(
                        onContinue: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                currentStep = .petSelection
                            }
                            HapticFeedback.light.trigger()
                        }
                    )
                    
                case .petSelection:
                    StepOnboardingPetSelectionView(
                        onContinue: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                currentStep = .petPreview
                            }
                            HapticFeedback.light.trigger()
                        },
                        onBack: goBack
                    )
                    
                case .petPreview:
                    StepOnboardingPetPreviewView(
                        onContinue: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                currentStep = .motivation
                            }
                            HapticFeedback.light.trigger()
                        },
                        onBack: goBack
                    )
                    
                case .motivation:
                    StepOnboardingMotivationView(
                        onContinue: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                currentStep = .didYouKnow
                            }
                            HapticFeedback.light.trigger()
                        },
                        onBack: goBack
                    )
                    
                case .didYouKnow:
                    StepOnboardingDidYouKnowView(
                        onContinue: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                currentStep = .goalInput
                            }
                            HapticFeedback.light.trigger()
                        },
                        onBack: goBack
                    )
                    
                case .goalInput:
                    StepOnboardingGoalInputView(
                        onContinue: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                currentStep = .lifetimeCalculation
                            }
                            HapticFeedback.light.trigger()
                        },
                        onBack: goBack
                    )
                    
                case .lifetimeCalculation:
                    StepOnboardingLifetimeCalcView(
                        onContinue: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                currentStep = .whyChooseStepPet
                            }
                            HapticFeedback.light.trigger()
                        },
                        onBack: goBack
                    )
                    
                case .whyChooseStepPet:
                    StepOnboardingWhyChooseView(
                        onContinue: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                currentStep = .notificationPermission
                            }
                            HapticFeedback.light.trigger()
                        },
                        onBack: goBack
                    )
                    
                case .notificationPermission:
                    StepOnboardingNotificationView(
                        onContinue: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                currentStep = .healthKitPermission
                            }
                            HapticFeedback.light.trigger()
                        },
                        onBack: goBack
                    )
                    
                case .healthKitPermission:
                    StepOnboardingHealthKitView(
                        onContinue: {
                            completeOnboarding()
                        },
                        onBack: goBack
                    )
                }
            }
        }
    }
    
    private func completeOnboarding() {
        // Mark onboarding as complete
        userSettings.hasCompletedOnboarding = true
        HapticFeedback.success.trigger()
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
        .environmentObject(HealthKitManager())
}
