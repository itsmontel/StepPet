//
//  AppTutorialView.swift
//  VirtuPet
//
//  Comprehensive app tutorial for first-time users
//

import SwiftUI

// MARK: - Tutorial Step Model
struct TutorialStep: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let features: [TutorialFeature]
    let backgroundGradient: [Color]
}

struct TutorialFeature: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

// MARK: - App Tutorial View
struct AppTutorialView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var showContent = false
    @State private var featureAnimations: [Bool] = []
    @State private var iconBounce = false
    @State private var progressAnimation = false
    
    let onComplete: () -> Void
    
    private let tutorialSteps: [TutorialStep] = [
        // Welcome
        TutorialStep(
            icon: "sparkles",
            iconColor: Color(red: 0.4, green: 0.8, blue: 0.6),
            title: "Welcome to VirtuPet!",
            subtitle: "Let me guide you through how to use this app most efficiently",
            features: [
                TutorialFeature(icon: "heart.fill", text: "Care for your virtual pet by staying active"),
                TutorialFeature(icon: "figure.walk", text: "Your daily steps keep your pet healthy & happy"),
                TutorialFeature(icon: "star.fill", text: "Unlock achievements and build streaks")
            ],
            backgroundGradient: [Color(red: 0.4, green: 0.8, blue: 0.6), Color(red: 0.3, green: 0.7, blue: 0.5)]
        ),
        
        // Today Page
        TutorialStep(
            icon: "house.fill",
            iconColor: Color(red: 0.95, green: 0.6, blue: 0.3),
            title: "Today",
            subtitle: "Your daily command center at a glance",
            features: [
                TutorialFeature(icon: "pawprint.fill", text: "See your pet's current health and mood"),
                TutorialFeature(icon: "flame.fill", text: "Track your daily step progress in real-time"),
                TutorialFeature(icon: "chart.bar.fill", text: "View your streak and daily achievements"),
                TutorialFeature(icon: "bolt.fill", text: "Quick access to play credits for bad days")
            ],
            backgroundGradient: [Color(red: 0.95, green: 0.6, blue: 0.3), Color(red: 0.9, green: 0.5, blue: 0.2)]
        ),
        
        // Insights Page
        TutorialStep(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: Color(red: 0.5, green: 0.6, blue: 0.9),
            title: "Insights",
            subtitle: "Deep dive into your activity patterns",
            features: [
                TutorialFeature(icon: "calendar", text: "View weekly and monthly step trends"),
                TutorialFeature(icon: "chart.pie.fill", text: "Analyze your activity distribution"),
                TutorialFeature(icon: "target", text: "See how often you hit your goals"),
                TutorialFeature(icon: "arrow.up.right", text: "Track your progress over time")
            ],
            backgroundGradient: [Color(red: 0.5, green: 0.6, blue: 0.9), Color(red: 0.4, green: 0.5, blue: 0.8)]
        ),
        
        // Activity Page
        TutorialStep(
            icon: "figure.run",
            iconColor: Color(red: 0.3, green: 0.75, blue: 0.85),
            title: "Activity",
            subtitle: "Track your walks with precision",
            features: [
                TutorialFeature(icon: "map.fill", text: "Beautiful maps that track your routes"),
                TutorialFeature(icon: "cloud.sun.fill", text: "Real-time weather for your walks"),
                TutorialFeature(icon: "flame.fill", text: "Calories burned during activities"),
                TutorialFeature(icon: "timer", text: "Duration, pace, and distance tracking")
            ],
            backgroundGradient: [Color(red: 0.3, green: 0.75, blue: 0.85), Color(red: 0.2, green: 0.65, blue: 0.75)]
        ),
        
        // Challenges - Games
        TutorialStep(
            icon: "gamecontroller.fill",
            iconColor: Color(red: 0.9, green: 0.45, blue: 0.55),
            title: "Minigames",
            subtitle: "Play games with your pet to build your bond",
            features: [
                TutorialFeature(icon: "bubble.left.and.bubble.right.fill", text: "Bubble Pop - Tap bubbles for points"),
                TutorialFeature(icon: "brain.head.profile", text: "Memory Match - Test your memory"),
                TutorialFeature(icon: "square.grid.3x3.fill", text: "Pattern Match - Follow the sequence"),
                TutorialFeature(icon: "gift.fill", text: "Earn rewards and strengthen your bond")
            ],
            backgroundGradient: [Color(red: 0.9, green: 0.45, blue: 0.55), Color(red: 0.8, green: 0.35, blue: 0.45)]
        ),
        
        // Pet Care Credits
        TutorialStep(
            icon: "bolt.heart.fill",
            iconColor: Color(red: 0.95, green: 0.75, blue: 0.3),
            title: "Pet Care Credits",
            subtitle: "Having a bad step day? No worries!",
            features: [
                TutorialFeature(icon: "fork.knife", text: "Feed your pet a delicious treat"),
                TutorialFeature(icon: "tennisball.fill", text: "Play ball together for fun"),
                TutorialFeature(icon: "tv.fill", text: "Watch TV and relax with your pet"),
                TutorialFeature(icon: "plus.circle.fill", text: "Each activity adds +20 health instantly!")
            ],
            backgroundGradient: [Color(red: 0.95, green: 0.75, blue: 0.3), Color(red: 0.9, green: 0.65, blue: 0.2)]
        ),
        
        // Awards & Achievements
        TutorialStep(
            icon: "trophy.fill",
            iconColor: Color(red: 0.85, green: 0.55, blue: 0.9),
            title: "Awards & Achievements",
            subtitle: "Stay motivated and reach your goals",
            features: [
                TutorialFeature(icon: "medal.fill", text: "Unlock achievements as you progress"),
                TutorialFeature(icon: "flame.fill", text: "Build streaks for consecutive goal days"),
                TutorialFeature(icon: "star.circle.fill", text: "Earn badges for milestones"),
                TutorialFeature(icon: "crown.fill", text: "Become a VirtuPet champion!")
            ],
            backgroundGradient: [Color(red: 0.85, green: 0.55, blue: 0.9), Color(red: 0.75, green: 0.45, blue: 0.8)]
        ),
        
        // Settings
        TutorialStep(
            icon: "gearshape.fill",
            iconColor: Color(red: 0.6, green: 0.6, blue: 0.65),
            title: "Settings",
            subtitle: "Customize your VirtuPet experience",
            features: [
                TutorialFeature(icon: "moon.fill", text: "Switch between light and dark mode"),
                TutorialFeature(icon: "pawprint.fill", text: "Change or rename your pet anytime"),
                TutorialFeature(icon: "target", text: "Adjust your daily step goals"),
                TutorialFeature(icon: "bell.fill", text: "Configure reminders and notifications")
            ],
            backgroundGradient: [Color(red: 0.6, green: 0.6, blue: 0.65), Color(red: 0.5, green: 0.5, blue: 0.55)]
        )
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Animated background
                LinearGradient(
                    colors: tutorialSteps[currentStep].backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentStep)
                
                // Decorative circles
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -200)
                    .blur(radius: 30)
                
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .offset(x: 150, y: 300)
                    .blur(radius: 20)
                
                VStack(spacing: 0) {
                    // Progress indicator
                    HStack(spacing: 6) {
                        ForEach(0..<tutorialSteps.count, id: \.self) { index in
                            Capsule()
                                .fill(index <= currentStep ? Color.white : Color.white.opacity(0.3))
                                .frame(width: index == currentStep ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentStep)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Skip button
                    HStack {
                        Spacer()
                        Button(action: completeTutorial) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    
                    Spacer()
                    
                    // Main content
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                            
                            Image(systemName: tutorialSteps[currentStep].icon)
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundColor(tutorialSteps[currentStep].iconColor)
                                .scaleEffect(iconBounce ? 1.1 : 1.0)
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.5)
                        
                        // Title and subtitle
                        VStack(spacing: 12) {
                            Text(tutorialSteps[currentStep].title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(tutorialSteps[currentStep].subtitle)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        
                        // Features list
                        VStack(spacing: 12) {
                            ForEach(Array(tutorialSteps[currentStep].features.enumerated()), id: \.element.id) { index, feature in
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: feature.icon)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(feature.text)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(16)
                                .opacity(index < featureAnimations.count && featureAnimations[index] ? 1 : 0)
                                .offset(x: index < featureAnimations.count && featureAnimations[index] ? 0 : -30)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        // Back button
                        if currentStep > 0 {
                            Button(action: previousStep) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(30)
                            }
                            .transition(.opacity)
                        }
                        
                        Spacer()
                        
                        // Next/Finish button
                        Button(action: {
                            if currentStep == tutorialSteps.count - 1 {
                                completeTutorial()
                            } else {
                                nextStep()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text(currentStep == tutorialSteps.count - 1 ? "Let's Go!" : "Next")
                                    .font(.system(size: 16, weight: .bold))
                                Image(systemName: currentStep == tutorialSteps.count - 1 ? "checkmark" : "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(tutorialSteps[currentStep].iconColor)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(30)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            animateContent()
        }
    }
    
    private func animateContent() {
        // Reset animations
        showContent = false
        featureAnimations = Array(repeating: false, count: tutorialSteps[currentStep].features.count)
        iconBounce = false
        
        // Animate content appearing
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showContent = true
        }
        
        // Bounce icon
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.2)) {
            iconBounce = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                iconBounce = false
            }
        }
        
        // Animate features one by one
        for index in 0..<tutorialSteps[currentStep].features.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(index) * 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if index < featureAnimations.count {
                        featureAnimations[index] = true
                    }
                }
            }
        }
        
        HapticFeedback.light.trigger()
    }
    
    private func nextStep() {
        guard currentStep < tutorialSteps.count - 1 else { return }
        
        withAnimation(.easeOut(duration: 0.2)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentStep += 1
            animateContent()
        }
    }
    
    private func previousStep() {
        guard currentStep > 0 else { return }
        
        withAnimation(.easeOut(duration: 0.2)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentStep -= 1
            animateContent()
        }
    }
    
    private func completeTutorial() {
        HapticFeedback.success.trigger()
        userSettings.hasCompletedAppTutorial = true
        onComplete()
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    AppTutorialView(onComplete: {})
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}

