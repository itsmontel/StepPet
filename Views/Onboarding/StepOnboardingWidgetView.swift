//
//  StepOnboardingWidgetView.swift
//  VirtuPet
//
//  Widget onboarding page to inform users about home screen widgets
//

import SwiftUI

struct StepOnboardingWidgetView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    @State private var animateImage = false
    @State private var animateTitle = false
    @State private var animateSteps = false
    @State private var animateButton = false
    @State private var selectedTab: WidgetTab = .homeScreen
    
    enum WidgetTab {
        case homeScreen
    }
    
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            VStack(spacing: 0) {
                // Header with back button and progress bar
                OnboardingHeader(
                    currentStep: StepPetOnboardingStep.widgets.stepNumber,
                    totalSteps: StepPetOnboardingStep.totalSteps,
                    showBackButton: true,
                    onBack: onBack
                )
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title
                        Text("We have widgets!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                            .multilineTextAlignment(.center)
                            .opacity(animateTitle ? 1.0 : 0.0)
                            .padding(.top, 20)
                        
                        // Widget preview image
                        ZStack {
                            // Background card
                            RoundedRectangle(cornerRadius: 24)
                                .fill(themeManager.accentColor.opacity(0.08))
                                .frame(height: 280)
                            
                            // Widget image - try to load from bundle
                            if let uiImage = UIImage(named: "Widgetonboarding") ?? 
                               UIImage(contentsOfFile: Bundle.main.path(forResource: "Widgetonboarding", ofType: "PNG") ?? "") {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                            } else {
                                // Fallback placeholder if image not found
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(themeManager.accentColor.opacity(0.2))
                                    .frame(height: 250)
                                    .overlay(
                                        VStack(spacing: 12) {
                                            Image(systemName: "apps.iphone")
                                                .font(.system(size: 50))
                                                .foregroundColor(themeManager.accentColor)
                                            Text("Widget Preview")
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundColor(themeManager.secondaryTextColor)
                                        }
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .scaleEffect(animateImage ? 1.0 : 0.9)
                        .opacity(animateImage ? 1.0 : 0.0)
                        
                        // Tab selector (for future lock screen support)
                        HStack(spacing: 12) {
                            WidgetTabButton(
                                title: "Home Screen",
                                isSelected: selectedTab == .homeScreen,
                                accentColor: themeManager.accentColor
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTab = .homeScreen
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .opacity(animateSteps ? 1.0 : 0.0)
                        
                        // How to steps
                        VStack(alignment: .leading, spacing: 16) {
                            WidgetStepRow(
                                stepNumber: 1,
                                text: "Tap & Hold anywhere on your Home Screen",
                                accentColor: themeManager.accentColor,
                                delay: 0.1
                            )
                            .environmentObject(themeManager)
                            
                            WidgetStepRow(
                                stepNumber: 2,
                                text: "Tap the \"+\" button in the top corner. Then search for \"VirtuPet\".",
                                accentColor: themeManager.accentColor,
                                delay: 0.2
                            )
                            .environmentObject(themeManager)
                            
                            WidgetStepRow(
                                stepNumber: 3,
                                text: "Choose your widget size & tap \"Add Widget\".",
                                accentColor: themeManager.accentColor,
                                delay: 0.3
                            )
                            .environmentObject(themeManager)
                        }
                        .padding(.horizontal, 32)
                        .opacity(animateSteps ? 1.0 : 0.0)
                        
                        Spacer(minLength: 20)
                    }
                }
                
                // Bottom buttons
                VStack(spacing: 16) {
                    // Continue button
                    HStack(spacing: 16) {
                        // Back button
                        if let onBack = onBack {
                            Button(action: {
                                HapticFeedback.light.trigger()
                                onBack()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(themeManager.cardBackgroundColor)
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(themeManager.primaryTextColor)
                                }
                            }
                        }
                        
                        // Finish button
                        Button(action: {
                            HapticFeedback.medium.trigger()
                            onContinue()
                        }) {
                            HStack(spacing: 10) {
                                Text("Finish")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: themeManager.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 32)
                    .opacity(animateButton ? 1.0 : 0.0)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateTitle = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateImage = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                animateSteps = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                animateButton = true
            }
        }
    }
}

// MARK: - Widget Tab Button
struct WidgetTabButton: View {
    let title: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : accentColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? accentColor : accentColor.opacity(0.1))
                )
        }
    }
}

// MARK: - Widget Step Row
struct WidgetStepRow: View {
    let stepNumber: Int
    let text: String
    let accentColor: Color
    let delay: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var animate = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Text("\(stepNumber)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
            }
            
            // Step text
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .opacity(animate ? 1.0 : 0.0)
        .offset(x: animate ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                animate = true
            }
        }
    }
}

