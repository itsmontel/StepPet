//
//  StepOnboardingPetSelectionView.swift
//  StepPet
//

import SwiftUI

struct StepOnboardingPetSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    let onContinue: () -> Void
    let onBack: (() -> Void)?
    
    @State private var selectedPetType: PetType = .dog
    @State private var petName: String = ""
    @State private var showNameInput = false
    @State private var animatePawPrints = false
    @State private var animateTitle = false
    @State private var animatePets = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            if showNameInput {
                // Pet naming screen
                petNamingView
            } else {
                // Pet selection screen
                petSelectionView
            }
        }
        .onAppear {
            if !showNameInput {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    animatePawPrints = true
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    animateTitle = true
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                    animatePets = true
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.7)) {
                    animateButton = true
                }
            }
        }
    }
    
    // MARK: - Pet Selection View
    private var petSelectionView: some View {
        VStack(spacing: 0) {
            // Header with back button and progress bar
            OnboardingHeader(
                currentStep: StepPetOnboardingStep.petSelection.stepNumber,
                totalSteps: StepPetOnboardingStep.totalSteps,
                showBackButton: true,
                onBack: onBack
            )
            
            // Paw prints header
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 32))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .scaleEffect(animatePawPrints ? 1.0 : 0.5)
                        .opacity(animatePawPrints ? 1.0 : 0.0)
                    
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.tertiaryTextColor)
                        .scaleEffect(animatePawPrints ? 1.0 : 0.5)
                        .opacity(animatePawPrints ? 1.0 : 0.0)
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    Text("Choose your pet")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                        .multilineTextAlignment(.center)
                        .opacity(animateTitle ? 1.0 : 0.0)
                    
                    Text("Select one of five adorable pets to\naccompany you on your walking\njourney! Your pet's health will reflect\nyour daily step progress.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                        .opacity(animateTitle ? 1.0 : 0.0)
                }
            }
            
            Spacer()
            
            // Horizontal scrollable pet selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(PetType.allCases.enumerated()), id: \.element) { index, petType in
                        OnboardingPetCard(
                            petType: petType,
                            isSelected: selectedPetType == petType,
                            delay: Double(index) * 0.1
                        ) {
                            withAnimation(.spring(response: 0.4)) {
                                selectedPetType = petType
                                HapticFeedback.light.trigger()
                            }
                        }
                        .opacity(animatePets ? 1.0 : 0.0)
                        .scaleEffect(animatePets ? 1.0 : 0.8)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Continue button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showNameInput = true
                }
                HapticFeedback.light.trigger()
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(themeManager.accentColor)
                    .cornerRadius(20)
            }
            .scaleEffect(animateButton ? 1.0 : 0.95)
            .opacity(animateButton ? 1.0 : 0.0)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
    
    // MARK: - Pet Naming View
    private var petNamingView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Back button for naming screen
                HStack {
                    OnboardingBackButton(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showNameInput = false
                        }
                        HapticFeedback.light.trigger()
                    })
                    .padding(.top, 60)
                    .padding(.leading, 24)
                    Spacer()
                }
                
                VStack(spacing: 32) {
                    // Selected pet display
                    let imageName = selectedPetType.imageName(for: .fullHealth)
                    if let _ = UIImage(named: imageName) {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 220, height: 220)
                            .padding(.top, 20)
                    } else {
                        Text(selectedPetType.emoji)
                            .font(.system(size: 120))
                            .padding(.top, 20)
                    }
                    
                    VStack(spacing: 16) {
                        Text("Name your \(selectedPetType.displayName.lowercased())")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 8) {
                            Text("Give your new companion a")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                            Text("special name! This \(selectedPetType.displayName.lowercased())")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                            Text("will be your walking buddy.")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    }
                    
                    // Name input field
                    VStack(spacing: 8) {
                        TextField("", text: $petName)
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 2)
                                    .background(themeManager.cardBackgroundColor)
                                    .cornerRadius(14)
                            )
                            .padding(.horizontal, 32)
                        
                        Text("Choose a name that makes you smile")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .padding(.horizontal, 32)
                    }
                    
                    // Pet description
                    Text(selectedPetType.personality)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    
                    // Continue button
                    Button(action: {
                        if !petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            savePet()
                            HapticFeedback.light.trigger()
                            onContinue()
                        }
                    }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                themeManager.secondaryTextColor.opacity(0.3) :
                                themeManager.accentColor
                            )
                            .cornerRadius(20)
                    }
                    .disabled(petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 60)
                }
            }
        }
    }
    
    private func savePet() {
        let finalName = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        userSettings.pet = Pet(type: selectedPetType, name: finalName)
    }
}

// MARK: - Pet Card for Onboarding
struct OnboardingPetCard: View {
    let petType: PetType
    let isSelected: Bool
    let delay: Double
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animate = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Pet image
                let imageName = petType.imageName(for: .fullHealth)
                if let _ = UIImage(named: imageName) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                } else {
                    Text(petType.emoji)
                        .font(.system(size: 60))
                }
                
                // Pet name and description
                VStack(spacing: 8) {
                    Text(petType.displayName)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? themeManager.accentColor : themeManager.primaryTextColor)
                    
                    Text(petType.personality)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Premium/Free badge
                    Text(petType.isPremium ? "Premium" : "Free")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(petType.isPremium ? .orange : .green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(petType.isPremium ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                        )
                }
            }
            .padding(20)
            .frame(width: 170, height: 230)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 3)
                    )
            )
        }
        .scaleEffect(animate ? 1.0 : 0.9)
        .opacity(animate ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                animate = true
            }
        }
    }
}

