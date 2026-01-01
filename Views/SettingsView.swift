//
//  SettingsView.swift
//  VirtuPet
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var achievementManager: AchievementManager
    
    @State private var showRenameSheet = false
    @State private var showGoalSheet = false
    @State private var showPremiumSheet = false
    @State private var showFAQSheet = false
    @State private var showChangePetSheet = false
    @State private var showPrivacySheet = false
    @State private var showTermsSheet = false
    @State private var showContactSheet = false
    @State private var newUserName = ""
    @State private var newPetName = ""
    @State private var selectedGoal = 10000
    @State private var selectedPetType: PetType = .cat
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Streak Card
                streakCard
                
                // My Companion Section
                companionSection
                
                // Preferences Section
                preferencesSection
                
                // Support Section
                supportSection
                
                // About Section
                aboutSection
                
                // Version
                versionInfo
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .onChange(of: userSettings.notificationsEnabled) { _, newValue in
            if newValue {
                achievementManager.updateProgress(achievementId: "notifications_on", progress: 1)
            }
        }
        .sheet(isPresented: $showRenameSheet) {
            renameSheet
        }
        .sheet(isPresented: $showGoalSheet) {
            goalSettingSheet
        }
        .sheet(isPresented: $showPremiumSheet) {
            PremiumView()
        }
        .sheet(isPresented: $showFAQSheet) {
            FAQView()
        }
        .sheet(isPresented: $showChangePetSheet) {
            changePetSheet
        }
        .sheet(isPresented: $showPrivacySheet) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsSheet) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showContactSheet) {
            ContactSupportView()
        }
        .onAppear {
            selectedPetType = userSettings.pet.type
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        Text("Settings")
            .font(.system(size: 34, weight: .bold))
            .foregroundColor(themeManager.primaryTextColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 20)
    }
    
    // MARK: - Streak Card
    private var streakCard: some View {
        HStack(spacing: 16) {
            // Flame Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text("🔥")
                    .font(.system(size: 26))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(userSettings.streakData.currentStreak)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Day Streak")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Pet Image
            let imageName = userSettings.pet.type.imageName(for: .fullHealth)
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
            } else {
                Text(userSettings.pet.type.emoji)
                    .font(.system(size: 50))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.secondaryCardColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - My Companion Section
    private var companionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Companion")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeManager.secondaryTextColor)
            
            VStack(spacing: 0) {
                // Change Pet
                SettingsRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .blue,
                    iconBackground: Color.blue.opacity(0.15),
                    title: "Change Pet",
                    subtitle: "Current: \(userSettings.pet.type.displayName)",
                    showChevron: true,
                    action: {
                        showChangePetSheet = true
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                // Rename Pet
                SettingsRow(
                    icon: "pencil",
                    iconColor: .purple,
                    iconBackground: Color.purple.opacity(0.15),
                    title: "Rename Pet",
                    subtitle: "Current: \(userSettings.pet.name)",
                    showChevron: true,
                    action: {
                        newPetName = userSettings.pet.name
                        showRenameSheet = true
                    }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeManager.secondaryTextColor)
            
            VStack(spacing: 0) {
                // Daily Goal
                SettingsRow(
                    icon: "target",
                    iconColor: .green,
                    iconBackground: Color.green.opacity(0.15),
                    title: "Daily Step Goal",
                    subtitle: "\(userSettings.dailyStepGoal.formatted()) steps",
                    showChevron: true,
                    action: {
                        // Ensure goal is at least 500
                        selectedGoal = max(500, userSettings.dailyStepGoal)
                        showGoalSheet = true
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                // Notifications
                SettingsToggleRow(
                    icon: "bell.fill",
                    iconColor: .red,
                    iconBackground: Color.red.opacity(0.15),
                    title: "Notifications",
                    subtitle: userSettings.notificationsEnabled ? "Enabled" : "Disabled",
                    subtitleColor: userSettings.notificationsEnabled ? .green : .gray,
                    isOn: $userSettings.notificationsEnabled
                )
                
                Divider()
                    .padding(.leading, 60)
                
                // Haptics
                SettingsToggleRow(
                    icon: "hand.tap.fill",
                    iconColor: .green,
                    iconBackground: Color.green.opacity(0.15),
                    title: "Haptics",
                    subtitle: "Vibrations on interaction",
                    isOn: $userSettings.hapticsEnabled
                )
                
                Divider()
                    .padding(.leading, 60)
                
                // Dark Mode
                SettingsToggleRow(
                    icon: "moon.stars.fill",
                    iconColor: .indigo,
                    iconBackground: Color.indigo.opacity(0.15),
                    title: "Dark Mode",
                    subtitle: "Adjust appearance",
                    isOn: $themeManager.isDarkMode
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeManager.secondaryTextColor)
            
            VStack(spacing: 0) {
                // FAQ
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .orange,
                    iconBackground: Color.orange.opacity(0.15),
                    title: "FAQ",
                    subtitle: "Common questions",
                    showChevron: true,
                    action: {
                        showFAQSheet = true
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                // Contact Support
                SettingsRow(
                    icon: "envelope.fill",
                    iconColor: .blue,
                    iconBackground: Color.blue.opacity(0.15),
                    title: "Contact Support",
                    subtitle: "Get help",
                    showChevron: true,
                    action: {
                        showContactSheet = true
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                // Rate App
                SettingsRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    iconBackground: Color.yellow.opacity(0.15),
                    title: "Rate StepPet",
                    subtitle: "Share your feedback",
                    showChevron: true,
                    action: {
                        // Open App Store review
                    }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeManager.secondaryTextColor)
            
            VStack(spacing: 0) {
                // Premium
                SettingsRow(
                    icon: "crown.fill",
                    iconColor: .orange,
                    iconBackground: Color.orange.opacity(0.15),
                    title: userSettings.isPremium ? "Premium Member" : "Upgrade to Premium",
                    subtitle: userSettings.isPremium ? "Thank you for your support!" : "Unlock all pets & features",
                    showChevron: !userSettings.isPremium,
                    action: {
                        if !userSettings.isPremium {
                            showPremiumSheet = true
                        }
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                // Privacy Policy
                SettingsRow(
                    icon: "hand.raised.fill",
                    iconColor: .gray,
                    iconBackground: Color.gray.opacity(0.15),
                    title: "Privacy Policy",
                    subtitle: nil,
                    showChevron: true,
                    action: {
                        showPrivacySheet = true
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                // Terms of Service
                SettingsRow(
                    icon: "doc.text.fill",
                    iconColor: .gray,
                    iconBackground: Color.gray.opacity(0.15),
                    title: "Terms of Service",
                    subtitle: nil,
                    showChevron: true,
                    action: {
                        showTermsSheet = true
                    }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
    }
    
    // MARK: - Version Info
    private var versionInfo: some View {
        Text("Version 1.0.0")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(themeManager.tertiaryTextColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
    }
    
    // MARK: - Rename Sheet
    private var renameSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Pet Preview - MP4 Video (smaller size)
                AnimatedPetVideoView(petType: userSettings.pet.type, moodState: .happy)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .padding(.top, 16)
                
                // Text Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pet Name")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    TextField("Enter pet name", text: $newPetName)
                        .font(.system(size: 18, weight: .medium))
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    if !newPetName.isEmpty {
                        userSettings.pet.name = newPetName
                        achievementManager.updateProgress(achievementId: "pet_parent", progress: 1)
                    }
                    showRenameSheet = false
                }) {
                    Text("Save Name")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(themeManager.accentColor)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Rename Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showRenameSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Change Pet Sheet
    private var changePetSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Selected Pet Preview - MP4 Video
                VStack(spacing: 12) {
                    AnimatedPetVideoView(petType: selectedPetType, moodState: .fullHealth)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: themeManager.accentColor.opacity(0.2), radius: 15, x: 0, y: 8)
                    
                    Text(selectedPetType.displayName)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    if selectedPetType.isPremium && !userSettings.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("Premium")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                    }
                }
                .padding(.top, 16)
                
                // Pet Selection Grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose Your Companion")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(PetType.allCases, id: \.self) { petType in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedPetType = petType
                                    }
                                    HapticFeedback.light.trigger()
                                }) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedPetType == petType ? themeManager.accentColor.opacity(0.2) : themeManager.cardBackgroundColor)
                                                .frame(width: 70, height: 70)
                                            
                                            // Pet image
                                            let imageName = petType.imageName(for: .fullHealth)
                                            if let _ = UIImage(named: imageName) {
                                                Image(imageName)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 50, height: 50)
                                                    .grayscale(petType.isPremium && !userSettings.isPremium ? 0.8 : 0)
                                                    .opacity(petType.isPremium && !userSettings.isPremium ? 0.6 : 1)
                                            } else {
                                                Text(petType.emoji)
                                                    .font(.system(size: 32))
                                            }
                                            
                                            // Lock icon for premium
                                            if petType.isPremium && !userSettings.isPremium {
                                                Circle()
                                                    .fill(Color.black.opacity(0.5))
                                                    .frame(width: 20, height: 20)
                                                    .overlay(
                                                        Image(systemName: "lock.fill")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.white)
                                                    )
                                                    .offset(x: 24, y: -24)
                                            }
                                            
                                            // Selection indicator
                                            if selectedPetType == petType {
                                                Circle()
                                                    .stroke(themeManager.accentColor, lineWidth: 3)
                                                    .frame(width: 70, height: 70)
                                            }
                                        }
                                        
                                        Text(petType.displayName)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(selectedPetType == petType ? themeManager.accentColor : themeManager.secondaryTextColor)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
                
                // Select Button
                Button(action: {
                    if selectedPetType.isPremium && !userSettings.isPremium {
                        showPremiumSheet = true
                    } else {
                        userSettings.changePet(to: selectedPetType)
                        achievementManager.updateProgress(achievementId: "customizer", progress: 1)
                        achievementManager.updateProgress(achievementId: "pet_lover", progress: userSettings.petsUsed.count)
                        showChangePetSheet = false
                    }
                }) {
                    HStack(spacing: 8) {
                        if selectedPetType.isPremium && !userSettings.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                        }
                        Text(selectedPetType.isPremium && !userSettings.isPremium ? "Unlock Premium" : "Select \(selectedPetType.displayName)")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                selectedPetType.isPremium && !userSettings.isPremium
                                    ? LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [themeManager.accentColor, themeManager.accentColor], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Change Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        selectedPetType = userSettings.pet.type
                        showChangePetSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Goal Setting Sheet
    private var goalSettingSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("How many steps do you want to walk each day?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                // Goal Display
                VStack(spacing: 4) {
                    Text("\(selectedGoal.formatted())")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("steps")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                // Slider
                VStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { Double(max(500, selectedGoal)) },
                        set: { selectedGoal = max(500, min(20000, Int($0))) }
                    ), in: 500...20000, step: 500)
                    .accentColor(themeManager.accentColor)
                    .padding(.horizontal, 20)
                    
                    HStack {
                        Text("500")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Spacer()
                        
                        Text("20,000")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Quick Select
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Select:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        GoalQuickButton(goal: 5000, label: "Easy", selectedGoal: $selectedGoal)
                        GoalQuickButton(goal: 7500, label: "Moderate", selectedGoal: $selectedGoal)
                        GoalQuickButton(goal: 10000, label: "Goal", selectedGoal: $selectedGoal)
                        GoalQuickButton(goal: 12500, label: "Hard", selectedGoal: $selectedGoal)
                        GoalQuickButton(goal: 15000, label: "Expert", selectedGoal: $selectedGoal)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    userSettings.dailyStepGoal = selectedGoal
                    achievementManager.updateProgress(achievementId: "goal_setter", progress: 1)
                    showGoalSheet = false
                }) {
                    Text("Save Goal")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(themeManager.accentColor)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Set Your Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showGoalSheet = false
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconBackground)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.tertiaryTextColor)
                }
            }
            .padding(14)
            .contentShape(Rectangle()) // Makes entire row tappable
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    let subtitle: String?
    var subtitleColor: Color? = nil
    @Binding var isOn: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBackground)
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(subtitleColor ?? themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: themeManager.accentColor))
        }
        .padding(14)
    }
}

// MARK: - Goal Quick Button
struct GoalQuickButton: View {
    let goal: Int
    let label: String
    @Binding var selectedGoal: Int
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: {
            selectedGoal = goal
        }) {
            VStack(spacing: 4) {
                Text("\(goal / 1000)k")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(selectedGoal == goal ? .white : themeManager.primaryTextColor)
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(selectedGoal == goal ? .white.opacity(0.8) : themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedGoal == goal ? themeManager.accentColor : themeManager.isDarkMode ? Color.white.opacity(0.05) : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Premium View
struct PremiumView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var selectedPlan: String = "yearly"
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // All Pets Animation
                    HStack(spacing: -20) {
                        ForEach(PetType.allCases, id: \.self) { petType in
                            let imageName = petType.imageName(for: .fullHealth)
                            if let _ = UIImage(named: imageName) {
                                Image(imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                            } else {
                                Text(petType.emoji)
                                    .font(.system(size: 40))
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text("Unlock the Full Experience")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 14) {
                        PremiumFeatureRow(text: "All 5 Pets (Dog, Cat, Bunny, Hamster, Horse)")
                        PremiumFeatureRow(text: "Unlimited Pet Name Changes")
                        PremiumFeatureRow(text: "Detailed Statistics & Trends")
                        PremiumFeatureRow(text: "Home Screen Widget")
                        PremiumFeatureRow(text: "Custom Notification Messages")
                        PremiumFeatureRow(text: "Support Independent Development")
                    }
                    .padding(.horizontal, 20)
                    
                    // Plan Selection
                    VStack(spacing: 12) {
                        // Monthly
                        PlanButton(
                            title: "Monthly",
                            price: "$5.99/month",
                            isSelected: selectedPlan == "monthly",
                            isBestValue: false,
                            action: { selectedPlan = "monthly" }
                        )
                        
                        // Yearly
                        PlanButton(
                            title: "Yearly",
                            price: "$39.99/year",
                            subtitle: "SAVE 44%",
                            isSelected: selectedPlan == "yearly",
                            isBestValue: true,
                            action: { selectedPlan = "yearly" }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Trial info
                    Text("7-day free trial included\nCancel anytime")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                    
                    // Subscribe Button
                    Button(action: {
                        // Handle subscription
                        userSettings.isPremium = true
                        dismiss()
                    }) {
                        Text("Start Free Trial")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [themeManager.accentColor, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Links
                    HStack(spacing: 20) {
                        Button("Terms") {}
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Button("Privacy") {}
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Button("Restore Purchase") {}
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.bottom, 30)
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("StepPet Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
        }
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    let text: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(themeManager.successColor)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(themeManager.primaryTextColor)
            
            Spacer()
        }
    }
}

// MARK: - Plan Button
struct PlanButton: View {
    let title: String
    let price: String
    var subtitle: String? = nil
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        if isBestValue {
                            Text("⭐ BEST VALUE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.orange))
                        }
                    }
                    
                    Text(price)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(themeManager.successColor)
                }
                
                // Radio Button
                ZStack {
                    Circle()
                        .stroke(isSelected ? themeManager.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - FAQ View
struct FAQView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    let faqs: [(String, String)] = [
        ("How does StepPet work?", "StepPet syncs with Apple Health to track your daily steps. Your pet's health is determined by how close you get to your daily step goal. Walk more, and your pet thrives! You can also track activities, play minigames, and complete challenges."),
        ("How is pet health calculated?", "Pet health = (Current Steps / Daily Goal) × 100. If your goal is 10,000 steps and you walk 6,700, your pet will be at 67% health. Your pet has 5 mood states: Sick (0-20%), Sad (21-40%), Content (41-60%), Happy (61-80%), and Full Health (81-100%)."),
        ("What happens at midnight?", "Your pet's health resets at midnight local time. Each day is a fresh start—no punishment carried over from bad days! Daily achievements also reset if not completed."),
        ("How do streaks work?", "Streaks track consecutive days where your pet ends the day at 100% health. This can be achieved by hitting your step goal or by playing pet activities. Break a streak by missing a day."),
        ("What pets are available?", "There are 5 pets: Cat (free), Dog, Bunny, Hamster, and Horse (premium). Each has unique moods and animations!"),
        ("What are play credits?", "Play credits let you interact with your pet through activities like Feed, Play Ball, or Watch TV. Each activity costs 1 credit and boosts your pet's health by 20%. You can purchase more credits in the Challenges tab."),
        ("Are minigames free?", "Yes! All minigames (Mood Catch, Memory Match, Bubble Pop, Pattern Match) are completely free to play. They don't cost credits and are just for fun with your pet."),
        ("How do achievements work?", "Complete various challenges to unlock achievements! Some are daily (like step goals), some are cumulative (like total steps walked), and some are one-time accomplishments. Track your progress in the Challenges tab."),
        ("How does activity tracking work?", "In the Activity tab, you can start tracking walks with real-time GPS, weather effects on the map, and detailed stats. After completing an activity, you can add photos, notes, and rate your mood."),
        ("How do I sync with Apple Health?", "StepPet automatically syncs when you grant HealthKit permissions during onboarding. Make sure you've allowed step count access in your device's Settings > Privacy > Health."),
        ("Can I change my pet?", "Yes! Go to Settings and tap 'Change Pet' to select a different companion. Premium members can access all 5 pets."),
        ("How do notifications work?", "StepPet can send you motivational reminders throughout the day. Enable notifications in Settings and customize your preferences.")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(faqs.indices, id: \.self) { index in
                        FAQCard(question: faqs[index].0, answer: faqs[index].1)
                    }
                }
                .padding(20)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - FAQ Card
struct FAQCard: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.primaryTextColor)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.cardBackgroundColor)
        )
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [themeManager.accentColor.opacity(0.2), themeManager.accentColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 36))
                                .foregroundColor(themeManager.accentColor)
                        }
                        
                        Text("Privacy Policy")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("Last updated: December 2024")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    
                    // Privacy Sections
                    PrivacySection(
                        icon: "doc.text",
                        title: "Introduction",
                        content: "Welcome to VirtuPet: Step Tracker! Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use our app. By using VirtuPet: Step Tracker, you agree to the collection and use of information in accordance with this policy."
                    )
                    
                    PrivacySection(
                        icon: "info.circle",
                        title: "Information We Collect",
                        content: """
                        • Health Data: With your permission, we access step count data from Apple Health to calculate your pet's health and track your daily progress.
                        • Location Data: When using activity tracking, we access your location to record walking routes and display weather conditions.
                        • Photos: If you choose to add photos to your activities, we store them locally on your device.
                        • Usage Data: We collect anonymous usage statistics to improve the app experience.
                        """
                    )
                    
                    PrivacySection(
                        icon: "gearshape",
                        title: "How We Use Your Information",
                        content: """
                        • To provide and maintain our app's functionality
                        • To calculate your pet's health based on your step count
                        • To track and display your walking activities
                        • To save your preferences and progress
                        • To improve our app and develop new features
                        """
                    )
                    
                    PrivacySection(
                        icon: "lock.shield",
                        title: "Data Storage & Security",
                        content: "Your data is stored locally on your device. Health data accessed from Apple Health remains on your device and is not transmitted to external servers. We implement appropriate security measures to protect your personal information."
                    )
                    
                    PrivacySection(
                        icon: "hand.raised",
                        title: "Your Rights",
                        content: """
                        You have the right to:
                        • Access the data we collect about you
                        • Request deletion of your data
                        • Opt out of data collection at any time
                        • Revoke health data access through iOS Settings
                        """
                    )
                    
                    PrivacySection(
                        icon: "person.2",
                        title: "Third-Party Services",
                        content: "We use Apple Health to access step data. This integration is subject to Apple's privacy policies. We may use anonymous analytics services to improve app performance, but no personally identifiable information is shared."
                    )
                    
                    PrivacySection(
                        icon: "envelope",
                        title: "Contact Us",
                        content: "If you have any questions about this Privacy Policy, please contact us at support@steppet.app"
                    )
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
}

// MARK: - Terms of Service View
struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Terms of Service")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("Last updated: December 2024")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    
                    // Terms Sections
                    PrivacySection(
                        icon: "checkmark.circle",
                        title: "Acceptance of Terms",
                        content: "By downloading, installing, or using StepPet, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app."
                    )
                    
                    PrivacySection(
                        icon: "iphone",
                        title: "Use of the App",
                        content: """
                        StepPet is a fitness companion app designed to motivate you to walk more by caring for a virtual pet. You agree to:
                        • Use the app only for its intended purpose
                        • Not attempt to reverse engineer or modify the app
                        • Not use the app for any illegal or unauthorized purpose
                        • Provide accurate information when required
                        """
                    )
                    
                    PrivacySection(
                        icon: "heart.fill",
                        title: "Health Information Disclaimer",
                        content: "StepPet is not a medical device and should not be used as a substitute for professional medical advice. The step tracking and health features are for motivational purposes only. Always consult a healthcare professional before starting any new fitness routine."
                    )
                    
                    PrivacySection(
                        icon: "creditcard",
                        title: "In-App Purchases",
                        content: """
                        StepPet offers optional in-app purchases including:
                        • Premium subscription for access to all pets
                        • Play credits for pet activities
                        
                        All purchases are processed through Apple's App Store and are subject to Apple's terms and conditions. Prices may vary by region and are subject to change.
                        """
                    )
                    
                    PrivacySection(
                        icon: "person.fill",
                        title: "User Accounts",
                        content: "Your StepPet data is stored locally on your device. You are responsible for maintaining the security of your device. We are not liable for any loss of data due to device issues or unauthorized access."
                    )
                    
                    PrivacySection(
                        icon: "exclamationmark.triangle",
                        title: "Limitation of Liability",
                        content: "StepPet is provided \"as is\" without warranties of any kind. We are not liable for any damages arising from your use of the app, including but not limited to direct, indirect, incidental, or consequential damages."
                    )
                    
                    PrivacySection(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Changes to Terms",
                        content: "We reserve the right to modify these Terms of Service at any time. Continued use of the app after changes constitutes acceptance of the new terms. We will notify users of significant changes through the app."
                    )
                    
                    PrivacySection(
                        icon: "building.columns",
                        title: "Governing Law",
                        content: "These Terms shall be governed by and construed in accordance with applicable laws. Any disputes arising from these terms shall be resolved through appropriate legal channels."
                    )
                    
                    PrivacySection(
                        icon: "envelope",
                        title: "Contact Us",
                        content: "If you have any questions about these Terms of Service, please contact us at support@steppet.app"
                    )
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
}

// MARK: - Privacy Section Component
struct PrivacySection: View {
    let icon: String
    let title: String
    let content: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.accentColor)
                
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            
            Text(content)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.cardBackgroundColor)
        )
    }
}

// MARK: - Contact Support View
struct ContactSupportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTopic = "General"
    @State private var messageText = ""
    @State private var showConfirmation = false
    
    let topics = ["General", "Bug Report", "Feature Request", "Account Issue", "Premium/Purchases", "Other"]
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.2), Color.teal.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.green)
                        }
                        
                        Text("Contact Support")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("We're here to help!")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.bottom, 8)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        HStack(spacing: 12) {
                            QuickActionButton(
                                icon: "envelope.fill",
                                title: "Email Us",
                                color: .blue,
                                action: {
                                    if let url = URL(string: "mailto:support@steppet.app") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            QuickActionButton(
                                icon: "star.fill",
                                title: "Rate App",
                                color: .yellow,
                                action: {
                                    // Open App Store review
                                }
                            )
                        }
                        
                        HStack(spacing: 12) {
                            QuickActionButton(
                                icon: "questionmark.circle.fill",
                                title: "FAQ",
                                color: .orange,
                                action: {
                                    dismiss()
                                }
                            )
                            
                            QuickActionButton(
                                icon: "globe",
                                title: "Website",
                                color: .purple,
                                action: {
                                    if let url = URL(string: "https://steppet.app") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                        }
                    }
                    
                    // Send a Message Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Send a Message")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        // Topic Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Topic")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            Menu {
                                ForEach(topics, id: \.self) { topic in
                                    Button(topic) {
                                        selectedTopic = topic
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedTopic)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(themeManager.primaryTextColor)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.cardBackgroundColor)
                                )
                            }
                        }
                        
                        // Message Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            TextEditor(text: $messageText)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(themeManager.primaryTextColor)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.cardBackgroundColor)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Send Button
                        Button(action: {
                            // Send message action
                            if let url = URL(string: "mailto:support@steppet.app?subject=\(selectedTopic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(messageText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                                UIApplication.shared.open(url)
                            }
                            showConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Send Message")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .disabled(messageText.isEmpty)
                        .opacity(messageText.isEmpty ? 0.6 : 1.0)
                    }
                    
                    // Response Time
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text("Typical response time: 24-48 hours")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.top, 8)
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .alert("Message Sent!", isPresented: $showConfirmation) {
                Button("OK") {
                    messageText = ""
                }
            } message: {
                Text("Thank you for reaching out. We'll get back to you within 24-48 hours.")
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
        .environmentObject(AchievementManager())
}

