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
    
    // Animation states (entrance only, no continuous animations)
    @State private var animatePet = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateInput = false
    @State private var animateButton = false
    
    var isNameValid: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            // Simple background (consistent with other onboarding pages)
            OnboardingBackground()
            
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Progress bar at top
                        OnboardingProgressBar(currentStep: 1, totalSteps: StepPetOnboardingStep.totalSteps)
                            .padding(.top, 60)
                            .padding(.horizontal, 24)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // Hero section with pet
                        heroSection
                        
                        Spacer()
                            .frame(height: 32)
                        
                        // Name input section
                        nameInputSection
                            .id("nameInput")
                        
                        Spacer()
                            .frame(height: 24)
                        
                        // Button section
                        buttonSection
                            .id("buttonSection")
                        
                        // Static spacer to allow scrolling
                        Spacer()
                            .frame(height: 120)
                            .id("bottomSpacer")
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: isNameFieldFocused) { _, isFocused in
                    if isFocused {
                        // Wait for keyboard animation to settle slightly, then scroll smoothly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                scrollProxy.scrollTo("buttonSection", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .task {
            await MainActor.run {
                showPetVideo = true
            }
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Pet (static, no bouncing)
            ZStack {
                // Subtle background circle
                Circle()
                    .fill(themeManager.accentColor.opacity(0.08))
                    .frame(width: 200, height: 200)
                
                // Pet container
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(themeManager.cardBackgroundColor)
                        .frame(width: 168, height: 168)
                    
                    if showPetVideo {
                        AnimatedPetVideoView(
                            petType: .dog,
                            moodState: .fullHealth
                        )
                        .frame(width: 156, height: 156)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .transition(.opacity)
                    } else {
                        Image("dog_happy")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 156, height: 156)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .scaleEffect(animatePet ? 1.0 : 0.9)
            .opacity(animatePet ? 1.0 : 0)
            
            // Title section
            VStack(spacing: 14) {
                // Welcome text
                Text("Welcome to VirtuPet")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                    .multilineTextAlignment(.center)
                    .opacity(animateTitle ? 1.0 : 0)
                    .offset(y: animateTitle ? 0 : 10)
                
                // Badge
                HStack(spacing: 6) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 13, weight: .bold))
                    Text("Step Tracker")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(themeManager.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(themeManager.accentColor.opacity(0.12))
                )
                .opacity(animateSubtitle ? 1.0 : 0)
                .scaleEffect(animateSubtitle ? 1.0 : 0.9)
                
                // Tagline
                Text("Care for your pet by caring for yourself")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animateSubtitle ? 1.0 : 0)
            }
        }
    }
    
    // MARK: - Name Input Section
    private var nameInputSection: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Text("What's your name?")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .opacity(animateInput ? 1.0 : 0)
            
            // Input field
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.accentColor)
                
                TextField("Enter your name", text: $userName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(themeManager.primaryTextColor)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($isNameFieldFocused)
                
                if !userName.isEmpty {
                    Button(action: { userName = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.tertiaryTextColor)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        showNameError ? Color.red :
                            (isNameFieldFocused ? themeManager.accentColor.opacity(0.5) : Color.clear),
                        lineWidth: 2
                    )
            )
            .padding(.horizontal, 24)
            .opacity(animateInput ? 1.0 : 0)
            
            // Error message
            if showNameError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Please enter your name")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Button Section
    private var buttonSection: some View {
        VStack(spacing: 14) {
            Button(action: handleContinue) {
                HStack(spacing: 8) {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    isNameValid ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.4)
                )
                .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .scaleEffect(animateButton ? 1.0 : 0.95)
            .opacity(animateButton ? 1.0 : 0)
            
            // Time estimate
            Text("Takes less than 2 minutes")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
                .opacity(animateButton ? 1.0 : 0)
        }
        .padding(.bottom, 48)
    }
    
    // MARK: - Helper Methods
    
    private func handleContinue() {
        if isNameValid {
            userSettings.userName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
            showNameError = false
            HapticFeedback.light.trigger()
            onContinue()
        } else {
            withAnimation(.spring(response: 0.3)) {
                showNameError = true
            }
            HapticFeedback.warning.trigger()
        }
    }
    
    private func startAnimations() {
        // Staggered entrance animations only
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            animatePet = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
            animateTitle = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            animateSubtitle = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.55)) {
            animateInput = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            animateButton = true
        }
    }
}
