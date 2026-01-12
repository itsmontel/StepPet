//
//  StepOnboardingWelcomeView.swift
//  VirtuPet
//

import SwiftUI

struct StepOnboardingWelcomeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    let onContinue: () -> Void
    
    @State private var userName: String = ""
    @State private var showNameError = false
    @State private var showPetVideo = false
    @FocusState private var isNameFieldFocused: Bool
    
    var isNameValid: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            VStack(spacing: 0) {
                // Progress bar at top
                OnboardingProgressBar(currentStep: 1, totalSteps: StepPetOnboardingStep.totalSteps)
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // Pet animation and title
                VStack(spacing: 24) {
                    // Pet with subtle glow
                    ZStack {
                        Circle()
                            .fill(themeManager.accentColor.opacity(0.1))
                            .frame(width: 200, height: 200)
                            .blur(radius: 20)
                        
                        // Show static image first, then swap to video after UI is ready
                        if showPetVideo {
                            AnimatedPetVideoView(
                                petType: .dog,
                                moodState: .fullHealth
                            )
                            .frame(width: 160, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .transition(.opacity)
                        } else {
                            Image("dog_happy")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Text("Welcome to VirtuPet")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                            .multilineTextAlignment(.center)
                        
                        // Step Tracker badge
                        Text("Step Tracker")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(themeManager.accentColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(themeManager.accentColor.opacity(0.15))
                            )
                        
                        Text("Care for your VirtuPet by caring for yourself")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .lineSpacing(4)
                    }
                }
                .padding(.top, 20)
                
                Spacer(minLength: 10)
                
                // Name input section
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's your name?")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.accentColor)
                                .frame(width: 36, alignment: .center)
                            
                            TextField("Enter your name", text: $userName)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(themeManager.primaryTextColor)
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .focused($isNameFieldFocused)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    showNameError ? Color.red : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    if showNameError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                            
                            Text("Please enter your name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                Spacer()
                
                // Button section
                VStack(spacing: 16) {
                    Button(action: {
                        if isNameValid {
                            userSettings.userName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
                            showNameError = false
                            HapticFeedback.light.trigger()
                            onContinue()
                        } else {
                            showNameError = true
                            HapticFeedback.warning.trigger()
                        }
                    }) {
                        Text("Get started")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(isNameValid ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.4))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    
                    Text("Takes less than 2 minutes")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(.bottom, 48)
            }
        }
        .task {
            // Load video asynchronously to not block UI
            await MainActor.run {
                showPetVideo = true
            }
        }
    }
}

