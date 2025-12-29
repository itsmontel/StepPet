//
//  StepOnboardingNotificationView.swift
//  StepPet
//

import SwiftUI
import UserNotifications

struct StepOnboardingNotificationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    @State private var isRequesting = false
    @State private var animateIcon = false
    @State private var animateContent = false
    @State private var showSkipConfirmation = false
    
    private var petType: PetType {
        userSettings.pet.type
    }
    
    private var petName: String {
        userSettings.pet.name
    }
    
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with back button and progress bar
                    OnboardingHeader(
                        currentStep: StepPetOnboardingStep.notificationPermission.stepNumber,
                        totalSteps: StepPetOnboardingStep.totalSteps,
                        showBackButton: true,
                        onBack: onBack
                    )
                    
                    // Pet animation at full health
                    AnimatedPetView(
                        petType: petType,
                        moodState: .fullHealth
                    )
                    .frame(height: 130)
                    .opacity(animateIcon ? 1.0 : 0.0)
                    .scaleEffect(animateIcon ? 1.0 : 0.8)
                    .padding(.top, 32)
                    .padding(.bottom, 32)
                    
                    // Title and subtitle
                    VStack(spacing: 12) {
                        Text("Stay Connected")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                        
                        Text("Get reminders to keep \(petName) happy")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 36)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 20) {
                        OnboardingBenefitRow(
                            icon: "bell.badge.fill",
                            color: themeManager.accentColor,
                            title: "Daily Reminders",
                            description: "Gentle nudges to get your steps in"
                        )
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(x: animateContent ? 0 : 30)
                        
                        OnboardingBenefitRow(
                            icon: "flame.fill",
                            color: .orange,
                            title: "Streak Alerts",
                            description: "Don't break your walking streak"
                        )
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(x: animateContent ? 0 : 30)
                        
                        OnboardingBenefitRow(
                            icon: "heart.fill",
                            color: .pink,
                            title: "Pet Updates",
                            description: "Check on \(petName)'s wellbeing"
                        )
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(x: animateContent ? 0 : 30)
                        
                        OnboardingBenefitRow(
                            icon: "trophy.fill",
                            color: .yellow,
                            title: "Achievements",
                            description: "Celebrate your milestones"
                        )
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(x: animateContent ? 0 : 30)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    
                    // Enable button
                    Button(action: {
                        requestNotificationPermission()
                    }) {
                        HStack(spacing: 10) {
                            if isRequesting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Enable Notifications")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: themeManager.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isRequesting)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                    .opacity(animateContent ? 1.0 : 0.0)
                    
                    // Skip button
                    Button(action: {
                        HapticFeedback.light.trigger()
                        showSkipConfirmation = true
                    }) {
                        Text("Skip for Now")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.bottom, 48)
                    .opacity(animateContent ? 1.0 : 0.0)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateIcon = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateContent = true
            }
        }
        .alert("Skip Notifications?", isPresented: $showSkipConfirmation) {
            Button("Enable Notifications", role: .cancel) {
                requestNotificationPermission()
            }
            Button("Skip Anyway", role: .destructive) {
                userSettings.notificationsEnabled = false
                onContinue()
            }
        } message: {
            Text("Notifications help you stay on track with your walking goals and keep \(petName) healthy.\n\nYou can enable notifications later in Settings.")
        }
    }
    
    private func requestNotificationPermission() {
        isRequesting = true
        HapticFeedback.medium.trigger()
        
        NotificationManager.shared.requestAuthorization { granted in
            DispatchQueue.main.async {
                isRequesting = false
                
                if granted {
                    HapticFeedback.success.trigger()
                    userSettings.notificationsEnabled = true
                } else {
                    HapticFeedback.warning.trigger()
                    userSettings.notificationsEnabled = false
                }
                
                // Continue regardless of result
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onContinue()
                }
            }
        }
    }
}

