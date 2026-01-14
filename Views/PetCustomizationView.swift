//
//  PetCustomizationView.swift
//  VirtuPet
//

import SwiftUI
import StoreKit
import RevenueCat

// MARK: - Main View
struct PetCustomizationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var achievementManager: AchievementManager
    @ObservedObject var purchaseManager = PurchaseManager.shared
    
    @State private var selectedPetType: PetType = .dog
    @State private var showRenameSheet = false
    @State private var newPetName = ""
    @State private var showPremiumAlert = false
    @State private var showCreditsSheet = false
    @State private var selectedActivity: PetActivity?
    @State private var showHealthBoostAnimation = false
    @State private var healthBoostAmount = 0
    @State private var showMinigames = false
    
    // Preview slider - discrete steps for 5 moods
    @State private var previewStep: Double = 2 // Start at Content (index 2)
    
    private let moodStates: [PetMoodState] = [.sick, .sad, .content, .happy, .fullHealth]
    
    private var previewMoodState: PetMoodState {
        moodStates[Int(previewStep)]
    }
    
    private var sliderColor: Color {
        switch previewMoodState {
        case .sick: return .red
        case .sad: return .orange
        case .content: return .yellow
        case .happy: return Color(hex: "8BC34A")
        case .fullHealth: return .green
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                headerSection
                petPreviewSection
                minigamesSection // NEW: Minigames section
                playActivitiesSection
                petSelectionSection
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .sheet(isPresented: $showRenameSheet) { renameSheet }
        .sheet(isPresented: $showCreditsSheet) { creditsSheet }
        .sheet(isPresented: $showMinigames) {
            MinigamesView()
        }
        .sheet(item: $selectedActivity) { activity in
                ActivityPlaySheet(
                    activity: activity,
                    petType: selectedPetType,
                    onComplete: { handleActivityComplete() }
                )
        }
        .alert("Premium Required", isPresented: $showPremiumAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Upgrade") {}
        } message: {
            Text("This pet is only available for premium members.")
        }
        .onAppear {
            selectedPetType = userSettings.pet.type
            newPetName = userSettings.pet.name
            userSettings.checkAndResetDailyBoost()
            
            // Trigger health_check achievement for viewing pet status
            achievementManager.updateProgress(achievementId: "health_check", progress: 1)
            
            // Set initial slider based on current health
            let currentHealth = userSettings.pet.health
            if currentHealth <= 20 { previewStep = 0 }
            else if currentHealth <= 40 { previewStep = 1 }
            else if currentHealth <= 60 { previewStep = 2 }
            else if currentHealth <= 80 { previewStep = 3 }
            else { previewStep = 4 }
        }
        .overlay {
            if showHealthBoostAnimation {
                healthBoostOverlay
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Text("Pets")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            Spacer()
            
            Button(action: { showCreditsSheet = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text("\(userSettings.playCredits)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(themeManager.cardBackgroundColor)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Pet Preview Section (with MP4 Video and Slider)
    private var petPreviewSection: some View {
        VStack(spacing: 20) {
            // Pet Name with Edit
            HStack {
                Text(userSettings.pet.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Button(action: {
                    newPetName = userSettings.pet.name
                    showRenameSheet = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.accentColor.opacity(0.7))
                }
            }
            
            // MP4 Video Preview (Square aspect ratio)
            AnimatedPetVideoView(petType: selectedPetType, moodState: previewMoodState)
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: themeManager.accentColor.opacity(0.15), radius: 20, x: 0, y: 10)
                .id("\(selectedPetType.rawValue)-\(previewMoodState.rawValue)")
            
            // Mood Display
            Text(previewMoodState.displayName)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(sliderColor)
                .padding(.top, 4)
            
            // Native SwiftUI Slider
            VStack(spacing: 12) {
                Slider(value: $previewStep, in: 0...4, step: 1)
                    .tint(sliderColor)
                    .onChange(of: previewStep) {
                        HapticFeedback.light.trigger()
                    }
                
                // Labels
                HStack {
                    ForEach(moodStates, id: \.self) { mood in
                        Text(mood.displayName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(previewMoodState == mood ? sliderColor : themeManager.secondaryTextColor)
                            .frame(maxWidth: .infinity)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Minigames Section (NEW!)
    private var minigamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Minigames", systemImage: "gamecontroller.fill")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                if userSettings.playCredits == 0 {
                    Button(action: { showCreditsSheet = true }) {
                        Text("Get Credits")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(themeManager.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(themeManager.accentColor.opacity(0.1)))
                    }
                }
            }
            
            // Minigames Entry Card
            Button(action: { showMinigames = true }) {
                HStack(spacing: 16) {
                    // Game icons preview
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                            .opacity(0.1)
                        
                        Text("🎮")
                            .font(.system(size: 28))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Play Games")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("Earn health & have fun!")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.tertiaryTextColor)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeManager.cardBackgroundColor)
                        .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.03), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(userSettings.playCredits > 0 ? 1.0 : 0.8)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Play Activities Section
    private var playActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Activities", systemImage: "figure.play")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                if userSettings.todayPlayHealthBoost > 0 {
                    Text("+\(userSettings.todayPlayHealthBoost) Health")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                }
            }
            
            // Activity Buttons Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PetActivity.allCases) { activity in
                        Button(action: {
                            selectedActivity = activity
                        }) {
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(activity.color.opacity(0.12))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: activity.icon)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(activity.color)
                                }
                                
                                Text(activity.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(themeManager.primaryTextColor)
                            }
                            .frame(width: 90, height: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(themeManager.cardBackgroundColor)
                                    .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.03), radius: 6, x: 0, y: 3)
                            )
                        }
                        .disabled(userSettings.playCredits <= 0)
                        .opacity(userSettings.playCredits > 0 ? 1 : 0.6)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Pet Selection Section
    private var petSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Choose Pet")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                if !userSettings.isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("4 locked")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(themeManager.tertiaryTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(themeManager.cardBackgroundColor))
                }
            }
            
            // Horizontal Scrollable Selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PetType.allCases, id: \.self) { petType in
                        Button(action: { selectPet(petType) }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(selectedPetType == petType ? themeManager.accentColor.opacity(0.15) : themeManager.cardBackgroundColor)
                                        .frame(width: 70, height: 70)
                                    
                                    // Use actual pet image from assets
                                    let imageName = petType.imageName(for: .fullHealth)
                                    if let _ = UIImage(named: imageName) {
                                        Image(imageName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                            .grayscale(petType.isPremium && !userSettings.isPremium ? 1.0 : 0)
                                            .opacity(petType.isPremium && !userSettings.isPremium ? 0.5 : 1)
                                    } else {
                                        Text(petType.emoji)
                                            .font(.system(size: 36))
                                            .grayscale(petType.isPremium && !userSettings.isPremium ? 1.0 : 0)
                                            .opacity(petType.isPremium && !userSettings.isPremium ? 0.5 : 1)
                                    }
                                    
                                    if petType.isPremium && !userSettings.isPremium {
                                        ZStack {
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                                .frame(width: 20, height: 20)
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .offset(x: 24, y: -24)
                                    }
                                    
                                    if selectedPetType == petType {
                                        Circle()
                                            .stroke(themeManager.accentColor, lineWidth: 2)
                                            .frame(width: 70, height: 70)
                                    }
                                }
                                
                                Text(petType.displayName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(selectedPetType == petType ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.cardBackgroundColor) // Lighter background for the container
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.03), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Rename Sheet
    private var renameSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                AnimatedPetView(petType: selectedPetType, moodState: .happy)
                    .frame(height: 80)
                    .padding(.top, 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pet name")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    TextField("Enter name", text: $newPetName)
                        .font(.system(size: 16, weight: .medium))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(themeManager.cardBackgroundColor)
                        )
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                Button(action: {
                    if !newPetName.isEmpty {
                        userSettings.pet.name = newPetName
                        achievementManager.updateProgress(achievementId: "pet_parent", progress: 1)
                    }
                    showRenameSheet = false
                }) {
                    Text("Save")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(themeManager.accentColor))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showRenameSheet = false }
                        .font(.system(size: 14))
                }
            }
        }
        .presentationDetents([.height(280)])
    }
    
    // MARK: - Credits Sheet
    private var creditsSheet: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero Section with Credit Balance
                    VStack(spacing: 14) {
                        // Credit count
                        VStack(spacing: 3) {
                            Text("\(userSettings.totalCredits)")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [themeManager.primaryDarkColor, themeManager.primaryColor, themeManager.primaryLightColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Credits Available")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        // Credit breakdown pills with theme colors
                        HStack(spacing: 10) {
                            HStack(spacing: 5) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 11))
                                Text("\(userSettings.dailyFreeCredits) free")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(themeManager.successColor)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(themeManager.successColor.opacity(0.12))
                            )
                            
                            HStack(spacing: 5) {
                                Image(systemName: "bag.fill")
                                    .font(.system(size: 11))
                                Text("\(userSettings.playCredits) bought")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(themeManager.primaryColor)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(themeManager.primaryColor.opacity(0.12))
                            )
                        }
                    }
                    .padding(.top, 8)
                    
                    // Credit Packages Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(themeManager.primaryColor)
                            
                            Text("Get More Credits")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(spacing: 10) {
                            ForEach(Array(CreditPackage.packages.enumerated()), id: \.element.id) { index, package in
                                petCreditPackageCard(package: package, index: index)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        purchaseCredits(package: package)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Quick Info (COMPACT) with theme colors
                    HStack(spacing: 14) {
                        VStack(spacing: 4) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.infoColor)
                            Text("+3 ❤️")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                            Text("Games")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(themeManager.infoColor.opacity(0.12))
                        )
                        
                        VStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.accentPink)
                            Text("+5 ❤️")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                            Text("Activities")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(themeManager.accentPink.opacity(0.12))
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Footer
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.successColor)
                            Text("Secure purchase via App Store")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Text("Credits never expire!")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(themeManager.successColor)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showCreditsSheet = false }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    // MARK: - Credit Package Card (Pet View)
    @ViewBuilder
    private func petCreditPackageCard(package: CreditPackage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 14) {
                // Credit coin stack with theme colors
                ZStack {
                    ForEach(0..<min(3, max(1, package.credits / 8)), id: \.self) { i in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [themeManager.primaryColor, themeManager.primaryLightColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40 - CGFloat(i * 4), height: 40 - CGFloat(i * 4))
                            .offset(x: CGFloat(i * 3), y: CGFloat(i * -3))
                            .shadow(color: themeManager.primaryColor.opacity(0.2), radius: 2, y: 1)
                    }
                    
                    Text("\(package.credits)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 1, y: 1)
                }
                .frame(width: 50, height: 50)
                
                // Package info
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(package.credits) Credits")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    if let savings = package.savings {
                        Text(savings)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.successColor)
                    } else {
                        Text("Perfect for trying out!")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                // Price button with theme gradient
                Text(package.price)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: package.isPopular ? 
                                        [themeManager.primaryDarkColor, themeManager.primaryColor, themeManager.primaryLightColor] :
                                        [themeManager.primaryColor, themeManager.primaryLightColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: themeManager.primaryColor.opacity(0.35), radius: 8, y: 4)
                    )
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                package.isPopular ?
                                LinearGradient(
                                    colors: [themeManager.primaryDarkColor, themeManager.primaryColor, themeManager.primaryLightColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing),
                                lineWidth: package.isPopular ? 2.5 : 0
                            )
                    )
                    .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: package.isPopular ? 12 : 8, y: package.isPopular ? 6 : 3)
            )
        }
    }
    
    // MARK: - Health Boost Overlay
    private var healthBoostOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Text("+\(healthBoostAmount)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                
                Text("Health Boost!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(userSettings.pet.name) feels happier!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .scaleEffect(showHealthBoostAnimation ? 1 : 0.5)
            .opacity(showHealthBoostAnimation ? 1 : 0)
        }
    }
    
    // MARK: - Helper Methods
    private func selectPet(_ petType: PetType) {
        if petType.isPremium && !userSettings.isPremium {
            showPremiumAlert = true
            return
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPetType = petType
            userSettings.changePet(to: petType)
            achievementManager.updateProgress(achievementId: "customizer", progress: 1)
            achievementManager.updateProgress(achievementId: "pet_lover", progress: userSettings.petsUsed.count)
        }
        
        HapticFeedback.light.trigger()
    }
    
    private func handleActivityComplete() {
        selectedActivity = nil
        
        if userSettings.usePlayCredit() {
            healthBoostAmount = 20
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showHealthBoostAnimation = true
            }
            
            HapticFeedback.success.trigger()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showHealthBoostAnimation = false
                }
            }
        }
    }
    
    private func purchaseCredits(package: CreditPackage) {
        // Find matching RevenueCat package by product ID
        Task {
            if let rcPackage = purchaseManager.creditProducts.first(where: { 
                $0.storeProduct.productIdentifier == package.productId
            }) {
                let success = await purchaseManager.purchaseCredits(package: rcPackage, userSettings: userSettings)
                if success {
                    HapticFeedback.success.trigger()
                    showCreditsSheet = false
                }
            } else {
                // Products not loaded from RevenueCat - show error
                HapticFeedback.error.trigger()
                purchaseManager.errorMessage = "Unable to load credit packages. Please try again later."
                print("❌ Credit package not found: \(package.productId). Available: \(purchaseManager.creditProducts.map { $0.storeProduct.productIdentifier })")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PetCustomizationView()
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
        .environmentObject(AchievementManager())
}