//
//  SettingsView.swift
//  StepPet
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
    @State private var newUserName = ""
    @State private var newPetName = ""
    @State private var selectedGoal = 10000
    
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
                    subtitle: "Switch your companion",
                    showChevron: true,
                    action: {
                        // Navigate to pet customization (handled by tab)
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
                        selectedGoal = userSettings.dailyStepGoal
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
                        // Open mail
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
                        // Open privacy policy
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
                        // Open terms
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
            VStack(spacing: 24) {
                // Pet Preview
                AnimatedPetView(petType: userSettings.pet.type, moodState: .happy)
                    .frame(height: 150)
                    .padding(.top, 20)
                
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
                        get: { Double(selectedGoal) },
                        set: { selectedGoal = Int($0) }
                    ), in: 3000...20000, step: 500)
                    .accentColor(themeManager.accentColor)
                    .padding(.horizontal, 20)
                    
                    HStack {
                        Text("3,000")
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
        ("How does StepPet work?", "StepPet syncs with Apple Health to track your daily steps. Your pet's health is determined by how close you get to your daily step goal. Walk more, and your pet thrives!"),
        ("How is pet health calculated?", "Pet health = (Current Steps / Daily Goal) × 100. If your goal is 10,000 steps and you walk 6,700, your pet will be at 67% health."),
        ("What happens at midnight?", "Your pet's health resets at midnight local time. Each day is a fresh start—no punishment carried over from bad days!"),
        ("How do streaks work?", "Streaks track consecutive days of hitting your step goal. Break a streak by missing a day, but you keep your earned badges!"),
        ("What pets are available?", "There are 5 pets: Dog (free), Cat, Bunny, Hamster, and Horse (premium). Each has unique personality vibes!"),
        ("How do I sync with Apple Health?", "StepPet automatically syncs when you grant HealthKit permissions. Make sure you've allowed step count access in Settings."),
        ("Can I change my pet?", "Yes! Go to the Pets tab to select a different pet. Premium members can access all 5 pets."),
        ("How do notifications work?", "StepPet sends motivational reminders throughout the day. Customize timing and types in Settings.")
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

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
        .environmentObject(AchievementManager())
}

