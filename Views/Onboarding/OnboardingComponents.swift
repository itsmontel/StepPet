//
//  OnboardingComponents.swift
//  VirtuPet
//

import SwiftUI

// MARK: - Haptic Feedback Helper
enum HapticFeedback {
    case light, medium, heavy, success, warning, error
    
    // Static property to control haptics globally - set this from UserSettings
    static var isEnabled: Bool = true
    
    func trigger() {
        // Check if haptics are enabled before triggering
        guard HapticFeedback.isEnabled else { return }
        
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Onboarding Step Enum
enum StepPetOnboardingStep: CaseIterable {
    case welcome
    case petSelection
    case petPreview
    case motivation
    case didYouKnow
    case goalInput
    case lifetimeCalculation
    case whyChooseStepPet
    case notificationPermission
    case healthKitPermission
    case commitment       // Emotional commitment after HealthKit
    case paywall          // Paywall after commitment
    
    var stepNumber: Int {
        switch self {
        case .welcome: return 1
        case .petSelection: return 2
        case .petPreview: return 3
        case .motivation: return 4
        case .didYouKnow: return 5
        case .goalInput: return 6
        case .lifetimeCalculation: return 7
        case .whyChooseStepPet: return 8
        case .notificationPermission: return 9
        case .healthKitPermission: return 10
        case .commitment: return 11
        case .paywall: return 12
        }
    }
    
    // Note: Progress bar only shows for steps 1-10 (the main onboarding flow)
    // Commitment and Paywall are handled as full-screen views without progress bar
    static var totalSteps: Int { 10 }
}

// MARK: - Onboarding Background
struct OnboardingBackground: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    themeManager.accentColor.opacity(0.03),
                    Color.clear,
                    themeManager.accentColor.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Onboarding Progress Bar
struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(themeManager.secondaryTextColor.opacity(0.2))
                    .frame(height: 4)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(themeManager.accentColor)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Onboarding Header
struct OnboardingHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let showBackButton: Bool
    let onBack: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 16) {
            if showBackButton, let onBack = onBack {
                OnboardingBackButton(action: onBack)
            } else {
                Spacer()
                    .frame(width: 44)
            }
            
            OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps)
        }
        .padding(.top, 60)
        .padding(.horizontal, 24)
    }
}

// MARK: - Onboarding Back Button
struct OnboardingBackButton: View {
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(themeManager.cardBackgroundColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.primaryTextColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Primary Button Style
struct OnboardingPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: {
            if isEnabled {
                HapticFeedback.light.trigger()
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3))
                .cornerRadius(16)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Gradient Button Style
struct OnboardingGradientButton: View {
    let title: String
    let icon: String?
    let colors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.medium.trigger()
            action()
        }) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: colors.first?.opacity(0.3) ?? Color.clear, radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Fact Card Component
struct OnboardingFactCard: View {
    let icon: String
    let iconColor: Color
    let text: String
    let delay: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
        )
        .scaleEffect(animate ? 1.0 : 0.95)
        .opacity(animate ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                animate = true
            }
        }
    }
}

// MARK: - Feature Card Component
struct OnboardingFeatureCard: View {
    let icon: String
    let gradient: [Color]
    let title: String
    let description: String
    let delay: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: gradient.first?.opacity(0.1) ?? Color.clear, radius: 12, x: 0, y: 4)
        )
        .scaleEffect(animate ? 1.0 : 0.95)
        .opacity(animate ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                animate = true
            }
        }
    }
}

// MARK: - Benefit Row Component
struct OnboardingBenefitRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Selection Row Component  
struct OnboardingSelectionRow: View {
    let text: String
    let isSelected: Bool
    let delay: Double
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var animate = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(isSelected ? themeManager.accentColor : Color.clear)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .stroke(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .scaleEffect(animate ? 1.0 : 0.95)
        .opacity(animate ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                animate = true
            }
        }
    }
}


