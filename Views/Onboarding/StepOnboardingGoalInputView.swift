//
//  StepOnboardingGoalInputView.swift
//  StepPet
//

import SwiftUI

struct StepOnboardingGoalInputView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var achievementManager: AchievementManager
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    @State private var selectedSteps: Double = 10000
    @State private var animateIllustration = false
    @State private var animateContent = false
    
    private var petType: PetType {
        userSettings.pet.type
    }
    
    // Determine pet health state based on goal (higher goal = more challenging = happier pet when achieved)
    private var petHealthState: PetMoodState {
        let steps = Int(selectedSteps)
        switch steps {
        case 0...4999:
            return .content
        case 5000...7499:
            return .happy
        case 7500...9999:
            return .happy
        default: // 10000+
            return .fullHealth
        }
    }
    
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            VStack(spacing: 0) {
                // Header with back button and progress bar
                OnboardingHeader(
                    currentStep: StepPetOnboardingStep.goalInput.stepNumber,
                    totalSteps: StepPetOnboardingStep.totalSteps,
                    showBackButton: true,
                    onBack: onBack
                )
                
                // Pet animation based on goal
                VStack(spacing: 16) {
                    AnimatedPetVideoView(
                        petType: petType,
                        moodState: petHealthState
                    )
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .scaleEffect(animateIllustration ? 1.0 : 0.8)
                    .opacity(animateIllustration ? 1.0 : 0.0)
                    .id(petHealthState)
                    
                    VStack(spacing: 12) {
                        Text("Set your daily step goal")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                            .opacity(animateContent ? 1.0 : 0.0)
                        
                        Text("How many steps do you want to walk each day?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.top, 24)
                
                Spacer(minLength: 10)
                
                // Steps display
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(Int(selectedSteps).formatted())")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(stepsColor)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: selectedSteps)
                            .opacity(animateContent ? 1.0 : 0.0)
                        
                        Text("steps per day")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .opacity(animateContent ? 1.0 : 0.0)
                    }
                    
                    // Slider
                    VStack(spacing: 12) {
                        Slider(value: $selectedSteps, in: 500...15000, step: 500)
                            .tint(themeManager.accentColor)
                            .frame(height: 40)
                            .opacity(animateContent ? 1.0 : 0.0)
                        
                        HStack {
                            Text("500")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                            Spacer()
                            Text("15,000")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                    }
                    .padding(.horizontal, 32)
                    
                    // Quick select buttons
                    HStack(spacing: 10) {
                        QuickGoalButton(goal: 5000, label: "Easy", selectedGoal: $selectedSteps)
                        QuickGoalButton(goal: 7500, label: "Moderate", selectedGoal: $selectedSteps)
                        QuickGoalButton(goal: 10000, label: "Active", selectedGoal: $selectedSteps)
                        QuickGoalButton(goal: 12500, label: "Hard", selectedGoal: $selectedSteps)
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateContent ? 1.0 : 0.0)
                    
                    // Feedback message
                    Text(feedbackMessage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(stepsColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Continue button
                OnboardingPrimaryButton(
                    title: "Continue",
                    isEnabled: true,
                    action: {
                        userSettings.dailyStepGoal = Int(selectedSteps)
                        // Trigger goal_setter achievement for setting first goal
                        achievementManager.updateProgress(achievementId: "goal_setter", progress: 1)
                        onContinue()
                    }
                )
                .scaleEffect(animateContent ? 1.0 : 0.95)
                .opacity(animateContent ? 1.0 : 0.0)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateIllustration = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateContent = true
            }
        }
    }
    
    private var feedbackMessage: String {
        let steps = Int(selectedSteps)
        switch steps {
        case 0...4999:
            return "A gentle start. Perfect for building the habit."
        case 5000...6499:
            return "A good starting point for better health."
        case 6500...7999:
            return "Solid goal! This is above average."
        case 8000...9999:
            return "Great goal! You'll see real health benefits."
        case 10000...11999:
            return "The classic goal! Perfect for active people."
        case 12000...13999:
            return "Ambitious! You're serious about walking."
        default:
            return "Impressive! You're going for elite level."
        }
    }
    
    private var stepsColor: Color {
        let steps = Int(selectedSteps)
        
        switch steps {
        case 0...4999: return Color(red: 0.3, green: 0.7, blue: 0.9) // Light blue
        case 5000...6499: return Color(red: 0.2, green: 0.8, blue: 0.6) // Teal
        case 6500...7999: return Color(red: 0.1, green: 0.85, blue: 0.4) // Green
        case 8000...9999: return Color(red: 0.3, green: 0.9, blue: 0.3) // Bright green
        case 10000...11999: return Color(red: 0.9, green: 0.7, blue: 0.1) // Gold
        case 12000...13999: return Color(red: 0.95, green: 0.5, blue: 0.2) // Orange
        default: return Color(red: 1.0, green: 0.3, blue: 0.3) // Red for extreme
        }
    }
}

// MARK: - Quick Goal Button
struct QuickGoalButton: View {
    let goal: Int
    let label: String
    @Binding var selectedGoal: Double
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var isSelected: Bool {
        Int(selectedGoal) == goal
    }
    
    var body: some View {
        Button(action: {
            selectedGoal = Double(goal)
            HapticFeedback.light.trigger()
        }) {
            VStack(spacing: 4) {
                Text("\(goal / 1000)k")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isSelected ? .white : themeManager.primaryTextColor)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

