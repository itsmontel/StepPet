//
//  SettingsView.swift
//  VirtuPet
//

import SwiftUI
import RevenueCat
import RevenueCatUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var tutorialManager: TutorialManager
    
    @State private var showRenameSheet = false
    @State private var showGoalSheet = false
    @State private var showPremiumSheet = false
    @State private var showFAQSheet = false
    @State private var showChangePetSheet = false
    @State private var showPrivacySheet = false
    @State private var showTermsSheet = false
    @State private var showContactSheet = false
    @State private var showSubscriptionManagement = false
    @State private var showRevenueCatPaywall = false
    @State private var showAccentColorSheet = false
    @State private var showGoalChangeAlert = false
    @State private var newUserName = ""
    @State private var newPetName = ""
    @State private var selectedGoal = 10000
    @State private var selectedPetType: PetType = .cat
    
    @Environment(\.requestReview) var requestReview
    
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
                
                // Follow Us & Version
                followUsSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .onChange(of: userSettings.notificationsEnabled) { _, newValue in
            // Actually enable/disable notifications
            if newValue {
                // Request permission and schedule notifications
                NotificationManager.shared.requestAuthorization { granted in
                    if granted {
                        NotificationManager.shared.updateScheduledNotifications(
                            petName: userSettings.pet.name,
                            enabled: true,
                            reminderTime: userSettings.reminderTime
                        )
                    } else {
                        // Permission denied - revert the toggle
                        DispatchQueue.main.async {
                            userSettings.notificationsEnabled = false
                        }
                    }
                }
                achievementManager.updateProgress(achievementId: "notifications_on", progress: 1)
            } else {
                // Disable notifications - cancel all scheduled
                NotificationManager.shared.cancelAllNotifications()
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
        .sheet(isPresented: $showSubscriptionManagement) {
            SubscriptionManagementView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showRevenueCatPaywall) {
            PaywallView(displayCloseButton: true)
        }
        .sheet(isPresented: $showAccentColorSheet) {
            AccentColorPickerView()
                .environmentObject(themeManager)
                .environmentObject(userSettings)
        }
        .onAppear {
            selectedPetType = userSettings.pet.type
            // Force light mode for free users
            if !userSettings.isPremium && themeManager.isDarkMode {
                themeManager.isDarkMode = false
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        Text("Settings")
            .font(.system(size: 34, weight: .black, design: .rounded))
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
                    subtitle: userSettings.hasPendingGoal 
                        ? "\(userSettings.dailyStepGoal.formatted()) steps (→ \(userSettings.pendingStepGoal?.formatted() ?? "") tomorrow)"
                        : "\(userSettings.dailyStepGoal.formatted()) steps",
                    showChevron: true,
                    action: {
                        // If there's a pending goal, show that; otherwise show current
                        selectedGoal = max(500, userSettings.pendingStepGoal ?? userSettings.dailyStepGoal)
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
                
                // Dark Mode - Premium Only
                if userSettings.isPremium {
                    SettingsToggleRow(
                        icon: "moon.stars.fill",
                        iconColor: .indigo,
                        iconBackground: Color.indigo.opacity(0.15),
                        title: "Dark Mode",
                        subtitle: "Adjust appearance",
                        isOn: $themeManager.isDarkMode
                    )
                } else {
                    // Locked Dark Mode for free users
                    Button(action: {
                        showPremiumSheet = true
                    }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.indigo.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.indigo)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dark Mode")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 10))
                                    Text("Premium Feature")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(themeManager.accentColor)
                            }
                            
                            Spacer()
                            
                            // Locked toggle indicator
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.accentColor.opacity(0.6))
                        }
                        .padding(14)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Divider()
                    .padding(.leading, 60)
                
                // Accent Color Theme - Premium Only
                if userSettings.isPremium {
                    SettingsRow(
                        icon: "paintpalette.fill",
                        iconColor: themeManager.primaryColor,
                        iconBackground: themeManager.primaryColor.opacity(0.15),
                        title: "App Theme",
                        subtitle: themeManager.accentColorTheme.rawValue,
                        showChevron: true,
                        action: {
                            showAccentColorSheet = true
                        }
                    )
                } else {
                    // Locked Accent Color for free users
                    Button(action: {
                        showPremiumSheet = true
                    }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(themeManager.primaryColor.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "paintpalette.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeManager.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("App Theme")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 10))
                                    Text("Premium Feature")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(themeManager.accentColor)
                            }
                            
                            Spacer()
                            
                            // Locked indicator
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.accentColor.opacity(0.6))
                        }
                        .padding(14)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
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
                
                // Tutorial
                SettingsRow(
                    icon: "book.fill",
                    iconColor: .purple,
                    iconBackground: Color.purple.opacity(0.15),
                    title: "Tutorial",
                    subtitle: "Learn how to use the app",
                    showChevron: true,
                    action: {
                        // Tutorial from settings CAN be skipped
                        tutorialManager.start(allowSkip: true, isFirstTime: false)
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
                    title: "Rate VirtuPet",
                    subtitle: "Share your feedback",
                    showChevron: true,
                    action: {
                        requestReview()
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
                
                // Manage Subscription (only show for premium users)
                if userSettings.isPremium {
                    Divider()
                        .padding(.leading, 60)
                    
                    SettingsRow(
                        icon: "creditcard.fill",
                        iconColor: .green,
                        iconBackground: Color.green.opacity(0.15),
                        title: "Manage Subscription",
                        subtitle: "View plan details",
                        showChevron: true,
                        action: {
                            showSubscriptionManagement = true
                        }
                    )
                }
                
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
    private var followUsSection: some View {
        VStack(spacing: 16) {
            // Follow Us Header
            Text("FOLLOW US")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
                .tracking(2)
            
            // Social Media Logos
            HStack(spacing: 24) {
                // Instagram
                Button(action: {
                    if let url = URL(string: "https://instagram.com/virtupetapp") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(themeManager.isDarkMode ? "instagramdarklogo" : "instagramlogo")
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: themeManager.isDarkMode ? 42 : 50, height: themeManager.isDarkMode ? 42 : 50)
                }
                
                // TikTok
                Button(action: {
                    if let url = URL(string: "https://www.tiktok.com/@virtupetapp") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image("tiktoklogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // VirtuPet Branding & Version
            VStack(spacing: 6) {
                Text("VIRTUPET")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                    .tracking(2)
                
                Text("VERSION 1.0.0")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.tertiaryTextColor)
                    .tracking(1)
            }
            .padding(.top, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
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
                
                // Info message about delayed goal change
                if selectedGoal != userSettings.dailyStepGoal {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.accentColor)
                        
                        Text("Your goal will be updated tomorrow")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                
                // Save Button
                Button(action: {
                    if selectedGoal != userSettings.dailyStepGoal {
                        // Set as pending goal - will apply tomorrow
                        userSettings.setPendingStepGoal(selectedGoal)
                        achievementManager.updateProgress(achievementId: "goal_setter", progress: 1)
                        showGoalChangeAlert = true
                    } else {
                        showGoalSheet = false
                    }
                }) {
                    Text(selectedGoal != userSettings.dailyStepGoal ? "Schedule Goal Change" : "Keep Current Goal")
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
            .alert("Goal Change Scheduled", isPresented: $showGoalChangeAlert) {
                Button("Got It") {
                    showGoalSheet = false
                }
            } message: {
                Text("Your new daily goal will take effect at midnight. This ensures your current day's progress isn't affected.")
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
    @ObservedObject var purchaseManager = PurchaseManager.shared
    
    @State private var selectedPlan: String = "monthly"
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Animated GIF - large and prominent
                    GIFImage("Virtupetpaywall")
                        .frame(width: 340, height: 120)
                        .padding(.top, 16)
                    
                    // Title
                    Text("Unlock the Full Experience")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 14) {
                        PremiumFeatureRow(text: "All 5 Pets (Dog, Cat, Bunny, Hamster, Horse)")
                        PremiumFeatureRow(text: "10 Daily Credits (vs 5 for Free)")
                        PremiumFeatureRow(text: "Detailed Statistics & Trends")
                        PremiumFeatureRow(text: "Activity Tracking & Walk History")
                        PremiumFeatureRow(text: "Premium Insights & Analytics")
                        PremiumFeatureRow(text: "Dark Mode & Custom Colour Themes")
                    }
                    .padding(.horizontal, 20)
                    
                    // Plan Selection
                    VStack(spacing: 12) {
                        // Monthly (Best Value - shown first)
                        if let monthlyPackage = purchaseManager.monthlyProduct {
                            PlanButton(
                                title: "Monthly",
                                price: monthlyPackage.localizedPriceString + "/month",
                                subtitle: "SAVE \(purchaseManager.monthlySavingsPercentage)%",
                                isSelected: selectedPlan == "monthly",
                                isBestValue: true,
                                action: { selectedPlan = "monthly" }
                            )
                        } else {
                            // Fallback: use helper method which returns localized price if available
                            PlanButton(
                                title: "Monthly",
                                price: purchaseManager.monthlyPriceString + "/month",
                                subtitle: "BEST VALUE",
                                isSelected: selectedPlan == "monthly",
                                isBestValue: true,
                                action: { selectedPlan = "monthly" }
                            )
                        }
                        
                        // Weekly (shown below monthly)
                        if let weeklyPackage = purchaseManager.weeklyProduct {
                            PlanButton(
                                title: "Weekly",
                                price: weeklyPackage.localizedPriceString + "/week",
                                isSelected: selectedPlan == "weekly",
                                isBestValue: false,
                                action: { selectedPlan = "weekly" }
                            )
                        } else {
                            // Fallback: use helper method which returns localized price if available
                            PlanButton(
                                title: "Weekly",
                                price: purchaseManager.weeklyPriceString + "/week",
                                isSelected: selectedPlan == "weekly",
                                isBestValue: false,
                                action: { selectedPlan = "weekly" }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Trial info - different message for first-time vs returning users
                    if purchaseManager.isEligibleForTrial {
                        VStack(spacing: 4) {
                            Text("3-Day Free Trial")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(themeManager.accentColor)
                            Text("No charge until trial ends • Cancel anytime")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .multilineTextAlignment(.center)
                    } else {
                        Text("Cancel anytime in Settings")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Error message
                    if let error = purchaseManager.errorMessage {
                        Text(error)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Subscribe Button - different text for trial eligible users
                    Button(action: {
                        Task {
                            await handlePurchase()
                        }
                    }) {
                        HStack {
                            if purchaseManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(purchaseManager.isLoading ? "Processing..." : (purchaseManager.isEligibleForTrial ? "Start Free Trial" : "Continue"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(purchaseManager.isLoading ? Color.gray : themeManager.accentColor)
                        )
                    }
                    .disabled(purchaseManager.isLoading)
                    .padding(.horizontal, 20)
                    
                    // Restore Purchase
                    Button(action: {
                        Task {
                            let success = await purchaseManager.restorePurchases()
                            restoreMessage = success ? "Purchases restored successfully!" : "No purchases to restore."
                            showRestoreAlert = true
                        }
                    }) {
                        Text("Restore Purchase")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .disabled(purchaseManager.isLoading)
                    .padding(.bottom, 30)
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("VirtuPet Premium")
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
            .alert("Restore", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage)
            }
            .onAppear {
                Task {
                    await purchaseManager.fetchOfferings()
                }
            }
        }
    }
    
    private func handlePurchase() async {
        var packageToPurchase: Package?
        
        switch selectedPlan {
        case "monthly":
            packageToPurchase = purchaseManager.monthlyProduct
        case "weekly":
            packageToPurchase = purchaseManager.weeklyProduct
        default:
            packageToPurchase = purchaseManager.monthlyProduct
        }
        
        guard let package = packageToPurchase else { return }
        
        let success = await purchaseManager.purchase(package: package, petName: userSettings.pet.name)
        if success {
            dismiss()
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
        ("How does VirtuPet work?", "VirtuPet syncs with Apple Health to track your daily steps. Your pet's health is determined by how close you get to your daily step goal. Walk more, and your pet thrives! You can also track activities, play minigames, and complete challenges."),
        ("How is pet health calculated?", "Pet health = (Current Steps / Daily Goal) × 100. If your goal is 10,000 steps and you walk 6,700, your pet will be at 67% health. Your pet has 5 mood states: Sick (0-20%), Sad (21-40%), Content (41-60%), Happy (61-80%), and Full Health (81-100%)."),
        ("What happens at midnight?", "Your pet's health resets at midnight local time. Each day is a fresh start—no punishment carried over from bad days! Daily achievements also reset if not completed."),
        ("How do streaks work?", "Streaks track consecutive days where your pet ends the day at 100% health. This can be achieved by hitting your step goal or by playing pet activities. Break a streak by missing a day."),
        ("What pets are available?", "There are 5 pets: Dog (free), Cat, Bunny, Hamster, and Horse (premium). Each has unique moods and animations!"),
        ("What are play credits?", "Play credits are used in the Challenges tab. Minigames cost 1 credit and boost your pet's health by 3%. Pet activities (Feed, Play Ball, Watch TV) cost 1 credit and boost health by 5%. Free users get 5 credits daily, premium users get 10. Extra credits can be purchased in bundles."),
        ("Are minigames free?", "Minigames in the Challenges tab cost 1 credit each and give +3% health. Free users get 5 credits daily, premium users get 10. Credits reset at midnight and extra can be purchased in the games section."),
        ("How do achievements work?", "Complete various challenges to unlock achievements! Some are daily (like step goals), some are cumulative (like total steps walked), and some are one-time accomplishments. Track your progress in the Challenges tab."),
        ("How does activity tracking work?", "In the Activity tab, you can start tracking walks with real-time GPS, weather effects on the map, and detailed stats. After completing an activity, you can add photos, notes, and rate your mood."),
        ("How do I sync with Apple Health?", "VirtuPet automatically syncs when you grant HealthKit permissions during onboarding. Make sure you've allowed step count access in your device's Settings > Privacy > Health."),
        ("Can I change my pet?", "Yes! Go to Settings and tap 'Change Pet' to select a different companion. Premium members can access all 5 pets."),
        ("How do notifications work?", "VirtuPet can send you motivational reminders throughout the day. Enable notifications in Settings and customize your preferences.")
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
                isExpanded.toggle()
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
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.cardBackgroundColor)
        )
        .animation(.easeOut(duration: 0.2), value: isExpanded)
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
                        
                        Text("Last updated: January 2026")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    
                    // Privacy Sections
                    PrivacySection(
                        icon: "doc.text",
                        title: "Introduction",
                        content: "Welcome to VirtuPet: Step Tracker! Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use our app. By using VirtuPet: Step Tracker, you agree to the collection and use of information in accordance with this policy. This policy applies to all users regardless of location."
                    )
                    
                    PrivacySection(
                        icon: "info.circle",
                        title: "Information We Collect",
                        content: """
                        • Health Data: With your permission, we access step count data from Apple HealthKit to calculate your pet's health and track your daily progress.
                        • Location Data: When using activity tracking, we may access your location to display weather conditions. Location data is processed locally and not stored on external servers.
                        • Device Information: We may collect anonymous device identifiers for analytics purposes.
                        • Usage Data: We collect anonymous usage statistics to improve the app experience.
                        • Purchase Data: Transaction information is processed by Apple and RevenueCat; we do not store payment card details.
                        """
                    )
                    
                    PrivacySection(
                        icon: "gearshape",
                        title: "How We Use Your Information",
                        content: """
                        • To provide and maintain our app's functionality
                        • To calculate your pet's health based on your step count
                        • To track and display your walking activities
                        • To save your preferences and progress locally
                        • To process in-app purchases and subscriptions
                        • To improve our app and develop new features
                        • To send optional push notifications you have consented to
                        """
                    )
                    
                    PrivacySection(
                        icon: "lock.shield",
                        title: "Data Storage & Security",
                        content: "Your personal data is stored locally on your device using Apple's secure storage mechanisms. Health data accessed from Apple HealthKit remains on your device and is never transmitted to external servers. We implement industry-standard security measures including encryption to protect your information. We do not maintain servers that store your personal health or location data."
                    )
                    
                    PrivacySection(
                        icon: "clock",
                        title: "Data Retention",
                        content: "Your data is retained locally on your device for as long as you use the app. When you delete the app, all locally stored data is removed. Anonymous analytics data may be retained for up to 24 months for app improvement purposes. You can request deletion of any data we hold by contacting us."
                    )
                    
                    PrivacySection(
                        icon: "person.2",
                        title: "Third-Party Services",
                        content: """
                        We use the following third-party services:
                        • Apple HealthKit: To access step count data (subject to Apple's Privacy Policy)
                        • RevenueCat: To manage subscriptions and in-app purchases (subject to RevenueCat's Privacy Policy at revenuecat.com/privacy)
                        • Apple App Store: For payment processing (subject to Apple's Terms)
                        • Open-Meteo: For weather data based on general location coordinates
                        
                        These services may collect information as described in their respective privacy policies. We do not sell your personal data to third parties.
                        """
                    )
                    
                    PrivacySection(
                        icon: "hand.raised",
                        title: "Your Rights",
                        content: """
                        Regardless of your location, you have the right to:
                        • Access the data we collect about you
                        • Request correction of inaccurate data
                        • Request deletion of your data
                        • Opt out of data collection at any time
                        • Revoke health data access through iOS Settings > Privacy > Health
                        • Withdraw consent for notifications through iOS Settings
                        • Data portability where applicable
                        """
                    )
                    
                    PrivacySection(
                        icon: "globe",
                        title: "GDPR & CCPA Rights",
                        content: """
                        For EU/EEA residents (GDPR): You have rights to access, rectify, erase, restrict processing, data portability, and object to processing. Our legal basis for processing is your consent and legitimate interests in providing the service.
                        
                        For California residents (CCPA): You have the right to know what personal information is collected, request deletion, and opt-out of sale of personal information. We do not sell personal information.
                        
                        To exercise these rights, contact us at support@virtupet.app.
                        """
                    )
                    
                    PrivacySection(
                        icon: "person.crop.circle.badge.minus",
                        title: "Children's Privacy",
                        content: "VirtuPet is not directed at children under 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately at support@virtupet.app and we will delete such information."
                    )
                    
                    PrivacySection(
                        icon: "airplane",
                        title: "International Data Transfers",
                        content: "Your data is primarily stored locally on your device. Any anonymous analytics data that may be processed uses services that comply with applicable data protection laws. For EU users, any data transfers outside the EU are protected by appropriate safeguards."
                    )
                    
                    PrivacySection(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Changes to This Policy",
                        content: "We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new Privacy Policy in the app and updating the \"Last updated\" date. For significant changes, we will provide notice through the app or via push notification if you have enabled them. Your continued use after changes constitutes acceptance."
                    )
                    
                    PrivacySection(
                        icon: "envelope",
                        title: "Contact Us",
                        content: "If you have any questions about this Privacy Policy, wish to exercise your data rights, or have concerns about our data practices, please contact us at support@virtupet.app. We will respond to your inquiry within 30 days."
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
                        
                        Text("Last updated: January 2026")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    
                    // Terms Sections
                    PrivacySection(
                        icon: "checkmark.circle",
                        title: "Acceptance of Terms",
                        content: "By downloading, installing, or using VirtuPet (\"the App\"), you agree to be bound by these Terms of Service (\"Terms\"). If you do not agree to these Terms, please do not use the App. These Terms constitute a legally binding agreement between you and VirtuPet."
                    )
                    
                    PrivacySection(
                        icon: "iphone",
                        title: "Use of the App",
                        content: """
                        VirtuPet is a fitness companion app designed to motivate you to walk more by caring for a virtual pet. You agree to:
                        • Use the App only for its intended purpose
                        • Not attempt to reverse engineer, decompile, or modify the App
                        • Not use the App for any illegal or unauthorized purpose
                        • Not attempt to circumvent any security features
                        • Not use automated systems or bots to interact with the App
                        • Provide accurate information when required
                        • Be at least 13 years of age to use this App
                        """
                    )
                    
                    PrivacySection(
                        icon: "heart.fill",
                        title: "Health Information Disclaimer",
                        content: "VirtuPet is NOT a medical device and should NOT be used as a substitute for professional medical advice, diagnosis, or treatment. The step tracking and health features are for motivational and entertainment purposes only. Always consult a qualified healthcare professional before starting any new fitness routine or if you have concerns about your health. We make no claims regarding health benefits."
                    )
                    
                    PrivacySection(
                        icon: "creditcard",
                        title: "In-App Purchases & Subscriptions",
                        content: """
                        VirtuPet offers optional in-app purchases including:
                        • Premium subscription for access to all pets, insights, and activity tracking
                        • Play credits for pet activities and minigames
                        
                        All purchases are processed through Apple's App Store and are subject to Apple's terms and conditions. Prices are displayed in your local currency and may vary by region. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage or cancel subscriptions in your Apple ID settings.
                        """
                    )
                    
                    PrivacySection(
                        icon: "arrow.uturn.backward.circle",
                        title: "Refund Policy",
                        content: "All purchases are made through Apple's App Store. Refund requests must be submitted directly to Apple in accordance with Apple's refund policy. We do not have the ability to process refunds directly. To request a refund, visit reportaproblem.apple.com or contact Apple Support. Play credits are non-refundable once used."
                    )
                    
                    PrivacySection(
                        icon: "star.fill",
                        title: "Intellectual Property",
                        content: "All content in VirtuPet, including but not limited to graphics, animations, text, user interface, code, and virtual pets, is owned by VirtuPet or its licensors and is protected by copyright, trademark, and other intellectual property laws. You may not copy, modify, distribute, sell, or lease any part of the App without explicit written permission."
                    )
                    
                    PrivacySection(
                        icon: "person.fill",
                        title: "User Data & Accounts",
                        content: "Your VirtuPet data is stored locally on your device. You are solely responsible for maintaining the security of your device and backing up your data. We are not liable for any loss of data due to device issues, app deletion, software updates, or unauthorized access to your device."
                    )
                    
                    PrivacySection(
                        icon: "xmark.octagon",
                        title: "Termination",
                        content: "We reserve the right to terminate or suspend your access to the App immediately, without prior notice, for any reason including breach of these Terms. Upon termination, your right to use the App will cease immediately. Provisions that by their nature should survive termination shall survive, including ownership, warranty disclaimers, and limitations of liability."
                    )
                    
                    PrivacySection(
                        icon: "exclamationmark.triangle",
                        title: "Disclaimer of Warranties",
                        content: "THE APP IS PROVIDED \"AS IS\" AND \"AS AVAILABLE\" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, OR COURSE OF PERFORMANCE. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR FREE OF HARMFUL COMPONENTS."
                    )
                    
                    PrivacySection(
                        icon: "shield.slash",
                        title: "Limitation of Liability",
                        content: "TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL VIRTUPET, ITS DIRECTORS, EMPLOYEES, PARTNERS, OR AFFILIATES BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING WITHOUT LIMITATION, LOSS OF PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES, RESULTING FROM YOUR USE OR INABILITY TO USE THE APP. OUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID US IN THE PAST 12 MONTHS."
                    )
                    
                    PrivacySection(
                        icon: "person.badge.shield.checkmark",
                        title: "Indemnification",
                        content: "You agree to defend, indemnify, and hold harmless VirtuPet and its officers, directors, employees, and agents from any claims, damages, obligations, losses, liabilities, costs, or debt arising from: (a) your use of the App; (b) your violation of these Terms; (c) your violation of any third-party right, including intellectual property rights; or (d) any claim that your use caused damage to a third party."
                    )
                    
                    PrivacySection(
                        icon: "scale.3d",
                        title: "Dispute Resolution & Arbitration",
                        content: "Any dispute arising from these Terms or your use of the App shall first be attempted to be resolved through informal negotiation by contacting support@virtupet.app. If unresolved within 30 days, disputes shall be resolved through binding arbitration in accordance with applicable arbitration rules. YOU AGREE TO WAIVE YOUR RIGHT TO PARTICIPATE IN CLASS ACTION LAWSUITS OR CLASS-WIDE ARBITRATION."
                    )
                    
                    PrivacySection(
                        icon: "doc.text.below.ecg",
                        title: "Severability",
                        content: "If any provision of these Terms is found to be unenforceable or invalid by a court of competent jurisdiction, that provision shall be limited or eliminated to the minimum extent necessary so that these Terms shall otherwise remain in full force and effect and enforceable."
                    )
                    
                    PrivacySection(
                        icon: "cloud.bolt",
                        title: "Force Majeure",
                        content: "We shall not be liable for any failure to perform our obligations where such failure results from circumstances beyond our reasonable control, including but not limited to natural disasters, war, terrorism, riots, government actions, technical failures, or third-party service outages."
                    )
                    
                    PrivacySection(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Changes to Terms",
                        content: "We reserve the right to modify these Terms at any time. We will notify users of material changes through the App or via push notification. Your continued use of the App after changes constitutes acceptance of the new Terms. If you disagree with changes, you must stop using the App."
                    )
                    
                    PrivacySection(
                        icon: "building.columns",
                        title: "Governing Law",
                        content: "These Terms shall be governed by and construed in accordance with the laws of the United Kingdom, without regard to conflict of law provisions. You agree to submit to the personal and exclusive jurisdiction of courts located in the United Kingdom for resolution of any disputes not subject to arbitration."
                    )
                    
                    PrivacySection(
                        icon: "doc.plaintext",
                        title: "Entire Agreement",
                        content: "These Terms, together with our Privacy Policy, constitute the entire agreement between you and VirtuPet regarding the App and supersede all prior agreements, representations, and understandings."
                    )
                    
                    PrivacySection(
                        icon: "envelope",
                        title: "Contact Us",
                        content: "If you have any questions about these Terms of Service, please contact us at support@virtupet.app. We will respond to your inquiry within 30 days."
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [themeManager.accentColor.opacity(0.2), themeManager.accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    Text("Contact Support")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("We're here to help!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                // Email info
                VStack(spacing: 12) {
                    Text("Email us at")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Button(action: {
                        if let url = URL(string: "mailto:support@virtupet.app") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("support@virtupet.app")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.cardBackgroundColor)
                )
                
                // Website button
                Button(action: {
                    if let url = URL(string: "https://virtupet.app") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "globe")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Visit Website")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
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
                
                Spacer()
                Spacer()
            }
            .padding(20)
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

// MARK: - Onboarding Paywall View (Two-Page Flow)
struct OnboardingPaywallView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @ObservedObject var purchaseManager = PurchaseManager.shared
    @Binding var isPresented: Bool
    var onComplete: (() -> Void)? = nil  // Optional callback for onboarding flow
    
    @State private var currentPage: Int = 0
    @State private var selectedPlan: String = "monthly"
    @State private var pulseAnimation = false
    @State private var showContent = false
    
    // Paywall background color
    private let softYellow = Color(hex: "#FFFAE6") // App background color
    
    var body: some View {
        ZStack {
            // Soft yellow background matching app theme
            softYellow.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button (top right) - smaller and subtle
                HStack {
                    Spacer()
                    Button(action: {
                        skipPaywall()
                    }) {
                        Text("Skip")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                    }
                    .buttonStyle(ResponsiveButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if currentPage == 0 {
                    // PAGE 1: Intro - "We want you to try VirtuPet for free"
                    paywallIntroPage
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    // PAGE 2: Timeline + Pricing
                    paywallPricingPage
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
        }
        .onAppear {
            // Track paywall view
            userSettings.paywallViewCount += 1
            
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    // Helper to dismiss paywall and call completion handler
    private func dismissPaywall() {
        userSettings.hasSeenPaywall = true
        isPresented = false
        onComplete?()
    }
    
    // Helper to skip paywall (tracks skip analytics)
    private func skipPaywall() {
        userSettings.paywallSkipCount += 1
        dismissPaywall()
    }
    
    // Helper: Format date for trial timeline
    private var trialReminderDateString: String {
        let reminderDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "On \(formatter.string(from: reminderDate))"
    }
    
    private var trialChargeDateString: String {
        let chargeDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "On \(formatter.string(from: chargeDate))"
    }
    
    // MARK: - Page 1: Intro
    private var paywallIntroPage: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)
            
            // Paywall dog GIF - larger and more prominent
            GIFImage("paywalldog")
                .frame(width: 200, height: 200)
                .scaleEffect(pulseAnimation ? 1.03 : 1.0)
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, 40)
            
            // Warm, personal headline
            Text("A special offer,\njust for you")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .padding(.horizontal, 40)
                .padding(.bottom, 28)
            
            // Personalized description
            VStack(spacing: 20) {
                if purchaseManager.isEligibleForTrial {
                    // Trial eligible message
                    Group {
                        Text("Because you're here, enjoy ")
                            .foregroundColor(themeManager.secondaryTextColor) +
                        Text("3 days of Premium")
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.secondaryTextColor) +
                        Text(" so you can bond with ")
                            .foregroundColor(themeManager.secondaryTextColor) +
                        Text(userSettings.pet.name.isEmpty ? "your pet" : userSettings.pet.name)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.secondaryTextColor) +
                        Text(".")
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
                    
                    Text("We'll remind you the day before your trial ends.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(themeManager.secondaryTextColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 36)
                } else {
                    // Non-trial message
                    Group {
                        Text("Unlock Premium to get full access and bond with ")
                            .foregroundColor(themeManager.secondaryTextColor) +
                        Text(userSettings.pet.name.isEmpty ? "your pet" : userSettings.pet.name)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.secondaryTextColor) +
                        Text(" like never before.")
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
                }
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            Spacer()
            
            // Continue button
            Button(action: {
                HapticFeedback.light.trigger()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    currentPage = 1
                }
            }) {
                Text(purchaseManager.isEligibleForTrial ? "Start for FREE" : "See plans")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeManager.accentColor)
                            .shadow(color: themeManager.accentColor.opacity(0.4), radius: 12, y: 6)
                    )
            }
            .buttonStyle(ResponsiveButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            .opacity(showContent ? 1 : 0)
        }
    }
    
    // MARK: - Page 2: Pricing with Timeline
    private var paywallPricingPage: some View {
        VStack(spacing: 0) {
            // Headline - different for trial eligible vs returning users
            if purchaseManager.isEligibleForTrial {
                VStack(spacing: 5) {
                    Text("How your free trial works")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
                
                // Timeline (only for trial eligible users)
                VStack(alignment: .leading, spacing: 0) {
                    // Today
                    TimelineItem(
                        icon: "lock.open.fill",
                        iconColor: Color(hex: "#F59E0B"),
                        title: "Today",
                        subtitle: "Unlock full access to VirtuPet and keep your pet happy!",
                        isFirst: true,
                        isLast: false
                    )
                    
                    // In 2 Days - show actual date
                    TimelineItem(
                        icon: "bell.fill",
                        iconColor: Color(hex: "#0EA5E9"),
                        title: trialReminderDateString,
                        subtitle: "We'll send a reminder before your trial ends.",
                        isFirst: false,
                        isLast: false
                    )
                    
                    // In 3 Days - show actual date
                    TimelineItem(
                        icon: "creditcard.fill",
                        iconColor: Color(hex: "#10B981"),
                        title: trialChargeDateString,
                        subtitle: "Your subscription will begin unless you cancel before.",
                        isFirst: false,
                        isLast: true
                    )
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 18)
            } else {
                // Returning users - no trial timeline
                VStack(spacing: 5) {
                    Text("Choose your plan")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            
            // Animated GIF - large and prominent
            GIFImage("Virtupetpaywall1")
                .frame(width: 330, height: 116)
                .scaleEffect(pulseAnimation ? 1.03 : 1.0)
                .padding(.bottom, 10)
            
            // Pricing Card
            VStack(spacing: 11) {
                // Header - different for trial vs non-trial
                if purchaseManager.isEligibleForTrial {
                    Text("FREE TRIAL")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(themeManager.accentColor)
                        .tracking(1)
                } else {
                    Text("PREMIUM")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(themeManager.accentColor)
                        .tracking(1)
                }
                
                // Plan selector
                HStack {
                    // Radio button
                    ZStack {
                        Circle()
                            .stroke(themeManager.accentColor, lineWidth: 2)
                            .frame(width: 23, height: 23)
                        
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 13, height: 13)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(purchaseManager.isEligibleForTrial ? "Try it Free" : "Subscribe Now")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text(selectedPlan == "monthly" ? "Best value - save \(purchaseManager.monthlySavingsPercentage)%" : "Cancel anytime")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Price from RevenueCat
                    Text(selectedPlan == "monthly" ? purchaseManager.monthlyPriceString + "/mo" : purchaseManager.weeklyPriceString + "/wk")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(themeManager.accentColor, lineWidth: 2)
                        .background(RoundedRectangle(cornerRadius: 15).fill(themeManager.cardBackgroundColor))
                )
                
                // Plan toggle
                HStack(spacing: 11) {
                    Button(action: { selectedPlan = "weekly" }) {
                        Text("Weekly")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(selectedPlan == "weekly" ? .white : themeManager.secondaryTextColor)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selectedPlan == "weekly" ? themeManager.accentColor : Color.clear)
                            )
                    }
                    
                    Button(action: { selectedPlan = "monthly" }) {
                        HStack(spacing: 4) {
                            Text("Monthly")
                            if purchaseManager.monthlySavingsPercentage > 0 {
                                Text("(\(purchaseManager.monthlySavingsPercentage)% off)")
                                    .font(.system(size: 10, weight: .bold))
                            }
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(selectedPlan == "monthly" ? .white : themeManager.secondaryTextColor)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(selectedPlan == "monthly" ? themeManager.accentColor : Color.clear)
                        )
                    }
                }
                .padding(4)
                .background(Capsule().fill(themeManager.secondaryTextColor.opacity(0.1)))
                
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(0.2), radius: 18, y: 9)
            )
            .padding(.horizontal, 18)
            
            // No commitment text with price after trial
            VStack(spacing: 3) {
                Text("No commitment. Cancel anytime.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
                
                if purchaseManager.isEligibleForTrial {
                    Text(selectedPlan == "monthly" ? "Then \(purchaseManager.monthlyPriceString)/month after trial" : "Then \(purchaseManager.weeklyPriceString)/week after trial")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.tertiaryTextColor)
                }
            }
            .padding(.top, 10)
            
            // CTA Button - different text for trial eligible vs returning users
            Button(action: {
                HapticFeedback.medium.trigger()
                Task {
                    await handlePurchase()
                }
            }) {
                HStack {
                    if purchaseManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(purchaseManager.isLoading ? "Processing..." : (purchaseManager.isEligibleForTrial ? "Start Free Trial" : "Subscribe Now"))
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(purchaseManager.isLoading ? Color.gray : themeManager.accentColor)
                        .shadow(color: themeManager.accentColor.opacity(0.4), radius: 9, y: 4)
                )
            }
            .buttonStyle(ResponsiveButtonStyle())
            .disabled(purchaseManager.isLoading)
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 26)
        }
    }
    
    private func handlePurchase() async {
        var packageToPurchase: Package?
        
        switch selectedPlan {
        case "weekly":
            packageToPurchase = purchaseManager.weeklyProduct
        case "monthly":
            packageToPurchase = purchaseManager.monthlyProduct
        default:
            packageToPurchase = purchaseManager.monthlyProduct
        }
        
        guard let package = packageToPurchase else {
            // Fallback if no package available - close anyway
            dismissPaywall()
            return
        }
        
        let success = await purchaseManager.purchase(package: package, petName: userSettings.pet.name)
        if success {
            dismissPaywall()
        }
    }
}

// MARK: - Timeline Item
struct TimelineItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isFirst: Bool
    let isLast: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Timeline line and dot
            VStack(spacing: 0) {
                // Line above (hidden for first item)
                Rectangle()
                    .fill(isFirst ? Color.clear : Color.gray.opacity(0.3))
                    .frame(width: 2, height: 9)
                
                // Icon circle
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                // Line below (hidden for last item)
                Rectangle()
                    .fill(isLast ? Color.clear : Color.gray.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 42)
            
            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineSpacing(1.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 9)
            .padding(.bottom, isLast ? 0 : 15)
            
            Spacer()
        }
    }
}

// MARK: - Paywall Feature Card
struct PaywallFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

// MARK: - Paywall Plan Button
struct PaywallPlanButton: View {
    let title: String
    let price: String
    let period: String
    let subtitle: String
    let isSelected: Bool
    var isBestValue: Bool = false
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Radio button
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
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.orange, .red],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isBestValue && !isSelected ? Color.green : themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Price
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    Text(period)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? themeManager.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: isSelected ? themeManager.accentColor.opacity(0.15) : Color.clear, radius: 8, y: 4)
            )
        }
    }
}

// MARK: - Accent Color Picker View
struct AccentColorPickerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header description
                    VStack(spacing: 8) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: themeManager.accentColorTheme.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Choose Your Theme")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("Personalize your app with a color that matches your style")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Color grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(AccentColorTheme.allCases, id: \.self) { theme in
                            AccentColorButton(
                                theme: theme,
                                isSelected: themeManager.accentColorTheme == theme,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        themeManager.accentColorTheme = theme
                                        userSettings.accentColorTheme = theme.rawValue
                                    }
                                    HapticFeedback.light.trigger()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Preview section
                    VStack(spacing: 12) {
                        Text("Preview")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 16) {
                            // Sample button
                            Text("Sample Button")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: themeManager.accentColorTheme.gradientColors,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                            
                            // Sample progress
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(themeManager.primaryColor.opacity(0.2))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: themeManager.accentColorTheme.gradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 80, height: 12)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Sample text
                        HStack(spacing: 12) {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 24))
                                .foregroundColor(themeManager.primaryColor)
                            
                            Text("8,547")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryColor)
                            
                            Text("steps")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(themeManager.cardBackgroundColor)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("App Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
    }
}

// MARK: - Accent Color Button
struct AccentColorButton: View {
    let theme: AccentColorTheme
    let isSelected: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Color preview circle
                ZStack {
                    // Outer ring when selected
                    if isSelected {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: theme.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 64, height: 64)
                    }
                    
                    // Main color circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: Color(hex: theme.primaryHex).opacity(0.4), radius: 8, y: 4)
                    
                    // Icon
                    Image(systemName: theme.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Checkmark when selected
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: theme.primaryHex))
                            )
                            .offset(x: 20, y: -20)
                    }
                }
                .frame(width: 68, height: 68)
                
                // Theme name
                Text(theme.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isSelected ? themeManager.primaryColor : themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color(hex: theme.primaryHex).opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

