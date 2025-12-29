//
//  StepOnboardingWelcomeView.swift
//  StepPet
//

import SwiftUI

struct StepOnboardingWelcomeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    let onContinue: () -> Void
    
    @State private var petAnimation = false
    @State private var textAnimation = false
    @State private var nameFieldAnimation = false
    @State private var buttonAnimation = false
    @State private var userName: String = ""
    @State private var showNameError = false
    
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
                        
                        AnimatedPetVideoView(
                            petType: .dog,
                            moodState: .fullHealth
                        )
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .scaleEffect(petAnimation ? 1.0 : 0.8)
                    .opacity(petAnimation ? 1.0 : 0.0)
                    
                    VStack(spacing: 12) {
                        Text("Welcome to StepPet")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                            .multilineTextAlignment(.center)
                            .opacity(textAnimation ? 1.0 : 0.0)
                        
                        Text("Your personal companion for healthier habits through walking")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .lineSpacing(4)
                            .opacity(textAnimation ? 1.0 : 0.0)
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
                    .opacity(nameFieldAnimation ? 1.0 : 0.0)
                    
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
                        .opacity(nameFieldAnimation ? 1.0 : 0.0)
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
                            withAnimation(.easeInOut(duration: 0.2)) {
                                onContinue()
                            }
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
                    .scaleEffect(buttonAnimation ? 1.0 : 0.95)
                    .opacity(buttonAnimation ? 1.0 : 0.0)
                    .padding(.horizontal, 24)
                    
                    Text("Takes less than 2 minutes")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .opacity(buttonAnimation ? 1.0 : 0.0)
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                petAnimation = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                textAnimation = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                nameFieldAnimation = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.9)) {
                buttonAnimation = true
            }
        }
    }
}

