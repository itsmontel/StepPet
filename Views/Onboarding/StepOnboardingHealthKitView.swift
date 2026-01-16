//
//  StepOnboardingHealthKitView.swift
//  VirtuPet
//

import SwiftUI
import HealthKit

struct StepOnboardingHealthKitView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var healthKitManager: HealthKitManager
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    @State private var isRequesting = false
    @State private var animateIcon = false
    @State private var animateContent = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var petType: PetType {
        userSettings.pet.type
    }
    
    private var petName: String {
        userSettings.pet.name
    }
    
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            VStack(spacing: 0) {
                // Header with back button and progress bar
                OnboardingHeader(
                    currentStep: StepPetOnboardingStep.healthKitPermission.stepNumber,
                    totalSteps: StepPetOnboardingStep.totalSteps,
                    showBackButton: true,
                    onBack: onBack
                )
                
                Spacer().frame(height: 30)
                
                // Health icon with glow
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 70, height: 70)
                        .blur(radius: 15)
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.15), Color.pink.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.red, Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .scaleEffect(animateIcon ? 1.0 : 0.8)
                .opacity(animateIcon ? 1.0 : 0.0)
                
                Spacer().frame(height: 20)
                
                // Title and subtitle
                VStack(spacing: 6) {
                    Text("Connect to Health")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("VirtuPet needs access to your step data to track \(petName)'s health")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineLimit(2)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer().frame(height: 32)
                
                // Benefits
                VStack(alignment: .leading, spacing: 14) {
                    OnboardingBenefitRow(
                        icon: "figure.walk",
                        color: .green,
                        title: "Automatic Step Tracking",
                        description: "Syncs your steps from Apple Health"
                    )
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(x: animateContent ? 0 : 30)
                    
                    OnboardingBenefitRow(
                        icon: "chart.bar.fill",
                        color: themeManager.accentColor,
                        title: "Detailed Analytics",
                        description: "View weekly and monthly progress"
                    )
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(x: animateContent ? 0 : 30)
                    
                    OnboardingBenefitRow(
                        icon: "lock.shield.fill",
                        color: .purple,
                        title: "Private & Secure",
                        description: "Your data stays on your device"
                    )
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(x: animateContent ? 0 : 30)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Connect button
                Button(action: {
                    requestHealthKitAccess()
                }) {
                    HStack(spacing: 10) {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Connect to Apple Health")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ResponsiveButtonStyle())
                .disabled(isRequesting)
                .padding(.horizontal, 32)
                .padding(.bottom, 8)
                .opacity(animateContent ? 1.0 : 0.0)
                
                // Info text
                Text("VirtuPet only reads your step count data.\nWe never share your health information.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(2)
                    .opacity(animateContent ? 1.0 : 0.0)
                
                Spacer().frame(height: 40)
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
        .alert("Health Access Required", isPresented: $showError) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Continue Anyway") {
                onContinue()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func requestHealthKitAccess() {
        isRequesting = true
        HapticFeedback.medium.trigger()
        
        healthKitManager.requestAuthorization { success in
            DispatchQueue.main.async {
                isRequesting = false
                
                if success {
                    HapticFeedback.success.trigger()
                } else {
                    HapticFeedback.warning.trigger()
                }
                
                // Continue regardless of authorization result
                onContinue()
            }
        }
    }
}

