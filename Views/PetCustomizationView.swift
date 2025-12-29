//
//  PetCustomizationView.swift
//  StepPet
//

import SwiftUI
import StoreKit

// MARK: - Pet Activity Type
enum PetActivity: String, CaseIterable, Identifiable {
    case feed = "Feed"
    case playBall = "Play Ball"
    case watchTV = "Watch TV"
    
    var id: String { rawValue }
    
    func displayName(for petType: PetType) -> String {
        switch self {
        case .feed: return "Feed \(petType.displayName)"
        case .playBall: return "Play Ball"
        case .watchTV: return "Watch TV"
        }
    }
    
    var icon: String {
        switch self {
        case .feed: return "fork.knife"
        case .playBall: return "tennisball.fill"
        case .watchTV: return "tv.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .feed: return Color.orange
        case .playBall: return Color.green
        case .watchTV: return Color.purple
        }
    }
    
    var description: String {
        switch self {
        case .feed: return "A tasty meal to boost energy"
        case .playBall: return "Fun exercise time together"
        case .watchTV: return "Relaxing entertainment"
        }
    }
    
    func gifName(for petType: PetType) -> String {
        switch self {
        case .feed: return "Feed\(petType.rawValue)"
        case .playBall: return "\(petType.rawValue)PlayBall"
        case .watchTV: return "\(petType.rawValue)TV"
        }
    }
}
struct CreditPackage: Identifiable {
    let id = UUID()
    let credits: Int
    let price: String
    let productId: String
    let savings: String?
    let isPopular: Bool
    
    static let packages: [CreditPackage] = [
        CreditPackage(credits: 3, price: "$1.99", productId: "com.steppet.credits.3", savings: nil, isPopular: false),
        CreditPackage(credits: 5, price: "$2.99", productId: "com.steppet.credits.5", savings: "10% off", isPopular: true),
        CreditPackage(credits: 10, price: "$4.99", productId: "com.steppet.credits.10", savings: "17% off", isPopular: false)
    ]
}

// MARK: - Main View
struct PetCustomizationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var achievementManager: AchievementManager
    
    @State private var selectedPetType: PetType = .dog
    @State private var showRenameSheet = false
    @State private var newPetName = ""
    @State private var showPremiumAlert = false
    @State private var showCreditsSheet = false
    @State private var showActivitySheet = false
    @State private var selectedActivity: PetActivity?
    @State private var showHealthBoostAnimation = false
    @State private var healthBoostAmount = 0
    @State private var showMinigames = false
    
    // Preview slider - continuous for smooth video transitions
    @State private var previewSliderValue: Double = 50
    
    private let moodStates: [PetMoodState] = [.sick, .sad, .content, .happy, .fullHealth]
    
    private var previewMoodState: PetMoodState {
        PetMoodState.from(health: Int(previewSliderValue))
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
        .sheet(isPresented: $showActivitySheet) {
            if let activity = selectedActivity {
                ActivityPlaySheet(
                    activity: activity,
                    petType: selectedPetType,
                    onComplete: { handleActivityComplete() }
                )
            }
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
            previewSliderValue = Double(userSettings.pet.health)
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
                .frame(width: UIScreen.main.bounds.width - 64, height: UIScreen.main.bounds.width - 64)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .id("\(selectedPetType.rawValue)-\(previewMoodState.rawValue)")
            
            // Health Percentage Display
            VStack(spacing: 4) {
                Text("\(Int(previewSliderValue))%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(sliderColor)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: Int(previewSliderValue))
                
                Text("health")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            // Mood Badge
            HStack(spacing: 4) {
                Text(previewMoodState.emoji)
                    .font(.system(size: 14))
                
                Text(previewMoodState.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(sliderColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(sliderColor.opacity(0.12))
            )
            
            // Native SwiftUI Slider (Onboarding Style)
            VStack(spacing: 10) {
                Slider(value: $previewSliderValue, in: 0...100, step: 1)
                    .tint(sliderColor)
                    .onChange(of: previewSliderValue) {
                        if userSettings.hapticsEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                
                HStack {
                    Text("Sick")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Text("Full Health")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
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
                VStack(alignment: .leading, spacing: 1) {
                    Text("🎮 Minigames")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("Play games with \(userSettings.pet.name)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Games count badge
                Text("3 games")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.purple.opacity(0.12)))
            }
            
            // Minigames preview row
            Button(action: { showMinigames = true }) {
                HStack(spacing: 12) {
                    // Game icons preview
                    HStack(spacing: -8) {
                        ForEach(["🦴", "🃏", "🫧"], id: \.self) { emoji in
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                
                                Text(emoji)
                                    .font(.system(size: 20))
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Earn bonus health!")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.pink)
                            
                            Text("+10-30 per game")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.pink)
                        }
                    }
                    
                    Spacer()
                    
                    // Play button
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.08),
                                    Color.blue.opacity(0.08)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(userSettings.playCredits > 0 ? 1.0 : 0.5)
            
            if userSettings.playCredits == 0 {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    
                    Text("Get credits to play minigames")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Spacer()
                    
                    Button(action: { showCreditsSheet = true }) {
                        Text("Get Credits")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.04), radius: 6, x: 0, y: 3)
        )
    }
    
    // MARK: - Play Activities Section
    private var playActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Play with \(userSettings.pet.name)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("+20 health per activity")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                if userSettings.todayPlayHealthBoost > 0 {
                    Text("+\(userSettings.todayPlayHealthBoost)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                }
            }
            
            // Activity Buttons
            HStack(spacing: 8) {
                ForEach(PetActivity.allCases) { activity in
                    Button(action: {
                        selectedActivity = activity
                        showActivitySheet = true
                    }) {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(activity.color.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: activity.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(activity.color)
                            }
                            
                            Text(activity.rawValue)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.isDarkMode ? Color.white.opacity(0.03) : Color.gray.opacity(0.03))
                        )
                        .opacity(userSettings.playCredits > 0 ? 1 : 0.4)
                    }
                    .disabled(userSettings.playCredits <= 0)
                }
            }
            
            if userSettings.playCredits == 0 {
                Button(action: { showCreditsSheet = true }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        
                        Text("Get credits to play")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.04), radius: 6, x: 0, y: 3)
        )
    }
    
    // MARK: - Pet Selection Section
    private var petSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Choose Pet")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                if !userSettings.isPremium {
                    HStack(spacing: 2) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                        Text("4 locked")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(themeManager.tertiaryTextColor)
                }
            }
            
            // Compact Pet Row
            HStack(spacing: 6) {
                ForEach(PetType.allCases, id: \.self) { petType in
                    Button(action: { selectPet(petType) }) {
                        VStack(spacing: 3) {
                            ZStack {
                                // Use actual pet image from assets
                                let imageName = petType.imageName(for: .fullHealth)
                                if let _ = UIImage(named: imageName) {
                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)
                                        .grayscale(petType.isPremium && !userSettings.isPremium ? 1.0 : 0)
                                        .opacity(petType.isPremium && !userSettings.isPremium ? 0.4 : 1)
                                } else {
                                    // Fallback to emoji
                                    Text(petType.emoji)
                                        .font(.system(size: 22))
                                        .grayscale(petType.isPremium && !userSettings.isPremium ? 1.0 : 0)
                                        .opacity(petType.isPremium && !userSettings.isPremium ? 0.4 : 1)
                                }
                                
                                if petType.isPremium && !userSettings.isPremium {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(2)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                        .offset(x: 10, y: 10)
                                }
                            }
                            
                            Text(petType.displayName)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedPetType == petType ?
                                      themeManager.accentColor.opacity(0.1) :
                                      Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedPetType == petType ? themeManager.accentColor : Color.clear, lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Selected Pet Info
            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.accentColor)
                
                Text(selectedPetType.personality)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(1)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.04), radius: 6, x: 0, y: 3)
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
            VStack(spacing: 16) {
                // Current Credits
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                        
                        Text("\(userSettings.playCredits)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                    
                    Text("Play Credits")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(.top, 12)
                
                // Info
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.pink)
                    
                    Text("Each activity or minigame gives health!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.pink.opacity(0.08)))
                .padding(.horizontal, 16)
                
                // Packages
                VStack(spacing: 8) {
                    ForEach(CreditPackage.packages) { package in
                        Button(action: { purchaseCredits(package: package) }) {
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.yellow)
                                    
                                    Text("\(package.credits)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.primaryTextColor)
                                }
                                .frame(width: 50)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(package.credits) Credits")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(themeManager.primaryTextColor)
                                    
                                    if let savings = package.savings {
                                        Text(savings)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(package.price)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(themeManager.accentColor))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.cardBackgroundColor)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(package.isPopular ? themeManager.accentColor : Color.clear, lineWidth: 1.5)
                                    )
                            )
                            .overlay(alignment: .topTrailing) {
                                if package.isPopular {
                                    Text("BEST")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(themeManager.accentColor))
                                        .offset(x: -4, y: -4)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showCreditsSheet = false }
                        .font(.system(size: 14))
                }
            }
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
        
        if userSettings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func handleActivityComplete() {
        showActivitySheet = false
        
        if userSettings.usePlayCredit() {
            healthBoostAmount = 20
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showHealthBoostAnimation = true
            }
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showHealthBoostAnimation = false
                }
            }
        }
    }
    
    private func purchaseCredits(package: CreditPackage) {
        userSettings.playCredits += package.credits
        if userSettings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

// MARK: - Activity Play Sheet
struct ActivityPlaySheet: View {
    let activity: PetActivity
    let petType: PetType
    let onComplete: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    
    @State private var showAnimation = false
    @State private var animationComplete = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer()
                
                if showAnimation {
                    VStack(spacing: 14) {
                        // GIF Animation for activity (Square and larger)
                        let size = min(UIScreen.main.bounds.width - 48, 320)
                        GIFImage(activity.gifName(for: petType))
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        if animationComplete {
                            VStack(spacing: 8) {
                                Text("🎉")
                                    .font(.system(size: 36))
                                
                                Text("\(userSettings.pet.name) loved it!")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                Text("+20 Health")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("Playing...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(activity.color.opacity(0.12))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: activity.icon)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(activity.color)
                        }
                        
                        VStack(spacing: 4) {
                            Text(activity.displayName(for: petType))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                            
                            Text(activity.description)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                            
                            Text("1 Credit (\(userSettings.playCredits) left)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(themeManager.cardBackgroundColor))
                    }
                }
                
                Spacer()
                
                if animationComplete {
                    Button(action: {
                        dismiss()
                        onComplete()
                    }) {
                        Text("Done!")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.green))
                    }
                    .padding(.horizontal, 16)
                } else if !showAnimation {
                    Button(action: startActivity) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .bold))
                            
                            Text("Start")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(activity.color))
                    }
                    .padding(.horizontal, 16)
                    .disabled(userSettings.playCredits <= 0)
                    .opacity(userSettings.playCredits > 0 ? 1 : 0.5)
                }
                
                Spacer().frame(height: 16)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle(activity.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 14))
                }
            }
        }
    }
    
    private func startActivity() {
        withAnimation(.spring(response: 0.5)) {
            showAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring(response: 0.5)) {
                animationComplete = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
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