//
//  TodayView.swift
//  VirtuPet
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var stepDataManager: StepDataManager
    @EnvironmentObject var achievementManager: AchievementManager
    
    @State private var animatedSteps: Int = 0
    @State private var showCelebration = false
    @State private var selectedDay: Date? = nil
    
    // Streak animation states
    @State private var showStreakAnimation = false
    @State private var streakFlamePosition: CGPoint = .zero
    @State private var streakFlameScale: CGFloat = 0
    @State private var streakFlameOpacity: Double = 0
    @State private var streakBadgeScale: CGFloat = 1.0
    @State private var showStreakPlusOne = false
    @State private var plusOneOffset: CGFloat = 0
    @State private var plusOneOpacity: Double = 0
    @State private var streakFlameRotation: Double = 0
    
    // Milestone celebration states
    @State private var showMilestoneCelebration = false
    @State private var milestoneStreakValue: Int = 0
    
    // Trigger for streak animation (set to true to animate, view handles geometry)
    @State private var pendingStreakAnimation = false
    
    // Streak calendar popup
    @State private var showStreakCalendar = false
    
    // Test paywall popup
    @State private var showTestPaywall = false
    
    // Widget intro popup
    @State private var showWidgetPopup = false
    
    // App usage tracking timer
    @State private var usageTimer: Timer? = nil
    
    // Tutorial manager
    @EnvironmentObject var tutorialManager: TutorialManager
    
    private var stepBasedHealth: Int {
        guard userSettings.dailyStepGoal > 0 else { return 0 }
        return Int((Double(healthKitManager.todaySteps) / Double(userSettings.dailyStepGoal)) * 100)
    }
    
    private var currentHealth: Int {
        min(100, stepBasedHealth + userSettings.todayPlayHealthBoost)
    }
    
    private var moodState: PetMoodState {
        PetMoodState.from(health: currentHealth)
    }
    
    private var stepsToGoal: Int {
        max(0, userSettings.dailyStepGoal - healthKitManager.todaySteps)
    }
    
    private var goalProgress: Double {
        guard userSettings.dailyStepGoal > 0 else { return 0 }
        return min(1.0, Double(healthKitManager.todaySteps) / Double(userSettings.dailyStepGoal))
    }
    
    // Selected day's data (for historical view)
    private var selectedDaySteps: Int {
        guard let day = selectedDay else { return healthKitManager.todaySteps }
        let startOfDay = Calendar.current.startOfDay(for: day)
        return healthKitManager.weeklySteps[startOfDay] ?? 0
    }
    
    private var selectedDayHealth: Int {
        guard userSettings.dailyStepGoal > 0 else { return 0 }
        return min(100, Int((Double(selectedDaySteps) / Double(userSettings.dailyStepGoal)) * 100))
    }
    
    private var selectedDayMood: PetMoodState {
        PetMoodState.from(health: selectedDayHealth)
    }
    
    private var isViewingToday: Bool {
        selectedDay == nil || Calendar.current.isDateInToday(selectedDay!)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean background
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollViewReader { scrollProxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            headerSection
                            heroCardSection
                            weeklyGraphSection
                                .tutorialHighlight("tutorial_weekly_graph")
                                .id("weeklyGraph")
                            encouragementSection
                            dashboardSection
                            Spacer(minLength: 120)
                        }
                        .padding(.horizontal, 20)
                    }
                    .onChange(of: tutorialManager.scrollToWeekly) { _, shouldScroll in
                        if shouldScroll {
                            withAnimation {
                                scrollProxy.scrollTo("weeklyGraph", anchor: .top)
                            }
                        }
                    }
                }
                
                // Streak animation overlay
                streakAnimationOverlay(in: geometry)
            }
            .onChange(of: pendingStreakAnimation) { _, shouldAnimate in
                if shouldAnimate {
                    pendingStreakAnimation = false
                    triggerStreakAnimation(in: geometry)
                }
            }
        }
        .onAppear {
            refreshData()
            animateValues()
            startUsageTracking()
        }
        .onDisappear {
            stopUsageTracking()
        }
        .onChange(of: healthKitManager.todaySteps) { _, newValue in
            updateData(steps: newValue)
            animateValues()
        }
        .onChange(of: currentHealth) { oldValue, newValue in
            // Only show celebration if:
            // 1. Health reached 100% (from below 100%)
            // 2. We haven't shown the celebration today yet
            // 3. Goal celebrations are enabled
            if newValue >= 100 && oldValue < 100 && !userSettings.hasShownGoalCelebrationToday && userSettings.goalCelebrations {
                triggerCelebration()
                // Mark celebration as shown for today
                userSettings.hasShownGoalCelebrationToday = true
                userSettings.lastGoalCelebrationDate = Date()
            }
        }
        .overlay {
            if showCelebration {
                CelebrationOverlay(petName: userSettings.pet.name) {
                    withAnimation { showCelebration = false }
                    
                    // Trigger streak animation after celebration is dismissed (if streak increased)
                    if userSettings.streakDidIncreaseToday {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            pendingStreakAnimation = true
                        }
                        
                        // Show milestone celebration after streak animation completes
                        if milestoneStreakValue > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                                withAnimation {
                                    showMilestoneCelebration = true
                                }
                            }
                        }
                        
                        // Reset the flag
                        userSettings.streakDidIncreaseToday = false
                    }
                }
                .environmentObject(themeManager)
            }
        }
        .overlay {
            if showMilestoneCelebration {
                StreakMilestoneCelebrationView(
                    streak: milestoneStreakValue,
                    petType: userSettings.pet.type,
                    petName: userSettings.pet.name,
                    onDismiss: {
                        withAnimation {
                            showMilestoneCelebration = false
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showStreakCalendar) {
            StreakCalendarView()
                .environmentObject(themeManager)
                .environmentObject(userSettings)
                .environmentObject(stepDataManager)
                .environmentObject(healthKitManager)
        }
        .sheet(isPresented: $showTestPaywall) {
            OnboardingPaywallView(isPresented: $showTestPaywall)
                .environmentObject(themeManager)
                .environmentObject(userSettings)
        }
        .overlay {
            if showWidgetPopup {
                WidgetIntroPopup(isPresented: $showWidgetPopup)
                    .environmentObject(themeManager)
            }
        }
    }
    
    // MARK: - Header Section (Compact)
    private var headerSection: some View {
        HStack(alignment: .center) {
            // Date badge
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Text(formattedDate)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(themeManager.secondaryCardColor)
            )
            
            Spacer()
            
            // Test Buttons (for testing)
            #if DEBUG
            HStack(spacing: 8) {
                // Test Widget Popup Button
                Button(action: {
                    showWidgetPopupForTesting()
                }) {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Test Paywall Button
                Button(action: {
                    HapticFeedback.light.trigger()
                    showTestPaywall = true
                }) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [themeManager.primaryColor, themeManager.primaryLightColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            #endif
            
            // Credits (clickable - navigates to Pet section) with gradient
            Button(action: {
                HapticFeedback.light.trigger()
                // Set target section to Pet (1) and navigate to Challenges
                UserDefaults.standard.set(1, forKey: "challengesTargetSegment")
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToChallenges"), object: nil, userInfo: ["segment": 1])
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("\(userSettings.totalCredits)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.12)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.yellow.opacity(0.25), lineWidth: 1)
                        )
                )
                .shadow(color: Color.yellow.opacity(0.15), radius: 4, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .tutorialHighlight("tutorial_credits_badge")
            
            // Streak (small) with animation target (clickable - opens streak calendar)
            ZStack {
                Button(action: {
                    HapticFeedback.light.trigger()
                    showStreakCalendar = true
                }) {
                    HStack(spacing: 5) {
                        Text("🔥")
                            .font(.system(size: 14))
                        
                        Text("\(userSettings.streakData.currentStreak)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.2), Color.red.opacity(0.12)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.orange.opacity(0.15), radius: 4, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(streakBadgeScale)
                .tutorialHighlight("tutorial_streak_badge")
                .overlay(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: StreakBadgePositionKey.self, value: geo.frame(in: .global))
                    }
                )
                
                // +1 floating text
                if showStreakPlusOne {
                    Text("+1")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.orange)
                        .shadow(color: .orange.opacity(0.5), radius: 4)
                        .offset(x: 30, y: plusOneOffset)
                        .opacity(plusOneOpacity)
                }
            }
        }
        .padding(.top, 12)
    }
    
    // MARK: - Hero Card Section
    private var heroCardSection: some View {
        VStack(spacing: 12) {
            // Pet Name with sparkles
            HStack(spacing: 8) {
                Text("✨")
                    .font(.system(size: 20))
                Text(userSettings.pet.name)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                Text("✨")
                    .font(.system(size: 20))
            }
            .padding(.top, 8)
            
            // Pet with Progress Ring
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 80,
                            endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)
                
                // Background ring with gradient
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 14
                    )
                    .frame(width: 290, height: 290)
                
                // Progress ring with animated gradient
                Circle()
                    .trim(from: 0, to: isViewingToday ? goalProgress : Double(selectedDayHealth) / 100)
                    .stroke(
                        AngularGradient(
                            colors: [
                                healthColor(for: isViewingToday ? currentHealth : selectedDayHealth),
                                healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.8),
                                healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.6),
                                healthColor(for: isViewingToday ? currentHealth : selectedDayHealth)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 290, height: 290)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.5), radius: 10)
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: goalProgress)
                
                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [themeManager.cardBackgroundColor, themeManager.cardBackgroundColor.opacity(0.95)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 130
                        )
                    )
                    .frame(width: 270, height: 270)
                
                // Pet Animation with border
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(themeManager.cardBackgroundColor)
                        .frame(width: 238, height: 238)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(
                                    healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.4),
                                    lineWidth: 2
                                )
                                .shadow(
                                    color: healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.5),
                                    radius: 12
                                )
                                .shadow(
                                    color: healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.3),
                                    radius: 20
                                )
                        )
                    
                    AnimatedPetVideoView(
                        petType: userSettings.pet.type,
                        moodState: isViewingToday ? moodState : selectedDayMood
                    )
                    .frame(width: 230, height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                }
            }
            .tutorialHighlight("tutorial_pet_hero")
            
            // Steps Display with gradient
            VStack(spacing: 6) {
                if isViewingToday {
                    Text("\(healthKitManager.todaySteps)")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.primaryColor)
                        .contentTransition(.numericText())
                    
                    HStack(spacing: 6) {
                        Image(systemName: "shoeprints.fill")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.secondaryTextColor)
                        Text("steps today")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                } else {
                    Text("\(selectedDaySteps)")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.primaryColor)
                    
                    Text(selectedDayFormatted)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .tutorialHighlight("tutorial_step_count")
            
            // Health Bar with enhanced styling
            VStack(spacing: 10) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background with subtle gradient
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.12), Color.gray.opacity(0.18)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 14)
                        
                        // Health fill with glow
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        healthColor(for: isViewingToday ? currentHealth : selectedDayHealth),
                                        healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.8),
                                        healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.9)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(isViewingToday ? currentHealth : selectedDayHealth) / 100, height: 14)
                            .shadow(color: healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.5), radius: 6, y: 2)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentHealth)
                        
                        // Shimmer overlay
                        if currentHealth > 0 {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0), Color.white.opacity(0.3), Color.white.opacity(0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 40, height: 14)
                                .offset(x: min(geometry.size.width * CGFloat(isViewingToday ? currentHealth : selectedDayHealth) / 100 - 20, geometry.size.width - 40))
                        }
                    }
                }
                .frame(height: 14)
                .padding(.horizontal, 24)
                
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(healthColor(for: currentHealth))
                    Text("Pet Health")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(themeManager.secondaryTextColor)
                    Text("•")
                        .foregroundColor(themeManager.tertiaryTextColor)
                    Text("\(isViewingToday ? currentHealth : selectedDayHealth)%")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(healthColor(for: isViewingToday ? currentHealth : selectedDayHealth))
                }
            }
            
            // Steps to Goal / Next Mood (only for today)
            if isViewingToday {
                stepsToGoalSection
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 10, y: 4)
        )
        .padding(.top, 16)
    }
    
    // MARK: - Steps to Goal Section
    private var stepsToGoalSection: some View {
        VStack(spacing: 12) {
            // Steps to reach goal
            if stepsToGoal > 0 {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(themeManager.primaryColor)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "flag.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("\(stepsToGoal.formatted()) steps to reach goal")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(themeManager.primaryColor.opacity(0.1))
                )
            } else {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "22C55E"), Color(hex: "5CD9C5")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Goal reached!")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "22C55E"), Color(hex: "5CD9C5")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("🎉")
                        .font(.system(size: 16))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.15), Color(hex: "5CD9C5").opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.green.opacity(0.25), lineWidth: 1)
                        )
                )
                .shadow(color: Color.green.opacity(0.15), radius: 6, y: 3)
            }
        }
        .padding(.top, 12)
    }
    
    // MARK: - Weekly Graph Section
    private var weeklyGraphSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [themeManager.primaryColor, themeManager.primaryLightColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Last 7 Days")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                
                Spacer()
                
                if selectedDay != nil && !Calendar.current.isDateInToday(selectedDay!) {
                    Button(action: { 
                        withAnimation(.spring(response: 0.3)) {
                            selectedDay = nil 
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 10, weight: .bold))
                            Text("Today")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(themeManager.accentColor)
                        )
                    }
                }
            }
            
            // Week Graph
            WeeklyStepsGraph(
                weeklySteps: healthKitManager.weeklySteps,
                todaySteps: healthKitManager.todaySteps,
                goalSteps: userSettings.dailyStepGoal,
                selectedDay: $selectedDay
            )
            .frame(height: 140)
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.cardBackgroundColor)
                
                // Decorative gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.primaryColor.opacity(0.06),
                                themeManager.primaryLightColor.opacity(0.04),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [themeManager.primaryColor.opacity(0.2), themeManager.primaryLightColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: themeManager.accentBlue.opacity(0.1), radius: 12, y: 6)
        )
        .padding(.top, 16)
    }
    
    // MARK: - Encouragement Section
    private var encouragementSection: some View {
        HStack(spacing: 12) {
            // Animated pet emoji based on health
            Text(healthEmoji)
                .font(.system(size: 28))
            
            Text(encouragementMessage)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                healthColor(for: currentHealth).opacity(0.15),
                                healthColor(for: currentHealth).opacity(0.08)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(healthColor(for: currentHealth).opacity(0.25), lineWidth: 1)
            }
        )
        .padding(.top, 16)
    }
    
    private var healthEmoji: String {
        switch currentHealth {
        case 0...20: return "😰"
        case 21...40: return "🙂"
        case 41...60: return "😊"
        case 61...80: return "😄"
        case 81...99: return "🤩"
        default: return "🌟"
        }
    }
    
    private var encouragementMessage: String {
        switch currentHealth {
        case 0...20:
            return "Let's get moving! \(userSettings.pet.name) needs you! 🐾"
        case 21...40:
            return "Good start! Keep those steps coming! 💪"
        case 41...60:
            return "You're doing great! Halfway there! ⭐"
        case 61...80:
            return "Amazing progress! \(userSettings.pet.name) is getting happier! 🎉"
        case 81...99:
            return "Almost there! Just a little more! 🔥"
        default:
            return "Perfect! \(userSettings.pet.name) is thriving! 🌟"
        }
    }
    
    // MARK: - Dashboard Section
    private var dashboardSection: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Text("⚡")
                        .font(.system(size: 18))
                    Text("Quick Stats")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                
                Spacer()
                
                Text("Today")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(themeManager.secondaryCardColor)
                    )
            }
            
            // Stats Row with enhanced cards
            HStack(spacing: 12) {
                TodayEnhancedStatCard(
                    title: "Calories",
                    value: "\(Int(Double(healthKitManager.todaySteps) * 0.04))",
                    icon: "flame.fill",
                    gradient: [Color(hex: "FF6B4A"), Color(hex: "FFD93D")]
                )
                
                TodayEnhancedStatCard(
                    title: "Miles",
                    value: String(format: "%.1f", Double(healthKitManager.todaySteps) * 2.5 / 5280),
                    icon: "map.fill",
                    gradient: [Color(hex: "A855F7"), Color(hex: "EC4899")]
                )
                
                TodayEnhancedStatCard(
                    title: "Goal",
                    value: "\(Int(goalProgress * 100))%",
                    icon: "target",
                    gradient: [Color(hex: "22C55E"), Color(hex: "5CD9C5")]
                )
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.cardBackgroundColor)
                
                // Multi-color gradient overlay
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.04),
                                Color.purple.opacity(0.03),
                                Color.green.opacity(0.04)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.15),
                                Color.purple.opacity(0.1),
                                Color.green.opacity(0.15)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.purple.opacity(0.08), radius: 12, y: 6)
        )
        .padding(.top, 16)
    }
    
    // MARK: - Helper Methods
    
    private func healthColor(for health: Int) -> Color {
        switch health {
        case 0...20: return .red
        case 21...39: return .orange
        case 40...59: return .yellow
        default: return .green
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private var selectedDayFormatted: String {
        guard let day = selectedDay else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: day)
    }
    
    private func animateValues() {
        withAnimation(.easeOut(duration: 1.0)) {
            animatedSteps = healthKitManager.todaySteps
        }
    }
    
    private func triggerCelebration() {
        HapticFeedback.success.trigger()
        withAnimation(.spring(response: 0.5)) {
            showCelebration = true
        }
    }
    
    private func refreshData() {
        healthKitManager.fetchTodaySteps()
        healthKitManager.fetchWeeklySteps()
        
        // Check if it's a new day and reset daily achievements
        let lastCheckDate = UserDefaults.standard.object(forKey: "lastAchievementResetDate") as? Date ?? Date.distantPast
        let calendar = Calendar.current
        
        if !calendar.isDate(lastCheckDate, inSameDayAs: Date()) {
            achievementManager.resetDailyAchievements()
            UserDefaults.standard.set(Date(), forKey: "lastAchievementResetDate")
        }
    }
    
    // MARK: - App Usage Tracking
    private func startUsageTracking() {
        // Track usage every second
        usageTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            userSettings.totalAppUsageSeconds += 1
            
            // Check if 15 minutes (900 seconds) reached and popup not shown yet
            if userSettings.totalAppUsageSeconds >= 900 && !userSettings.hasShownWidgetPopup {
                userSettings.hasShownWidgetPopup = true
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showWidgetPopup = true
                    }
                }
            }
        }
    }
    
    private func stopUsageTracking() {
        usageTimer?.invalidate()
        usageTimer = nil
    }
    
    // Test function to show widget popup
    private func showWidgetPopupForTesting() {
        HapticFeedback.medium.trigger()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showWidgetPopup = true
        }
    }
    
    // MARK: - Streak Animation Overlay
    @ViewBuilder
    private func streakAnimationOverlay(in geometry: GeometryProxy) -> some View {
        if showStreakAnimation {
            ZStack {
                // Flying flame
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.orange.opacity(0.6), .red.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 10)
                    
                    // Flame emoji with effects
                    Text("🔥")
                        .font(.system(size: 50))
                        .shadow(color: .orange, radius: 10)
                        .shadow(color: .red.opacity(0.8), radius: 20)
                }
                .scaleEffect(streakFlameScale)
                .rotationEffect(.degrees(streakFlameRotation))
                .position(streakFlamePosition)
                .opacity(streakFlameOpacity)
                
                // Particle trail effect
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .yellow, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 8...16))
                        .position(
                            x: streakFlamePosition.x + CGFloat.random(in: -30...30),
                            y: streakFlamePosition.y + CGFloat.random(in: -30...30)
                        )
                        .opacity(streakFlameOpacity * 0.6)
                        .blur(radius: 2)
                }
            }
            .allowsHitTesting(false)
        }
    }
    
    // MARK: - Trigger Streak Animation
    private func triggerStreakAnimation(in geometry: GeometryProxy) {
        // Reset states
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        let targetX = geometry.size.width - 50 // Top right area
        let targetY: CGFloat = 70 // Near the top
        
        streakFlamePosition = CGPoint(x: centerX, y: centerY)
        streakFlameScale = 0
        streakFlameOpacity = 0
        streakFlameRotation = -30
        showStreakPlusOne = false
        plusOneOffset = 10 // Start at safe position below badge
        plusOneOpacity = 0
        streakBadgeScale = 1.0
        
        showStreakAnimation = true
        HapticFeedback.medium.trigger()
        
        // Phase 1: Appear with scale and glow (slower)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            streakFlameScale = 1.3
            streakFlameOpacity = 1.0
            streakFlameRotation = 0
        }
        
        // Phase 2: Fly to target with curved path (slower - 0.8s delay, 1.1s duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            HapticFeedback.light.trigger()
            
            withAnimation(.easeInOut(duration: 1.1)) {
                streakFlamePosition = CGPoint(x: targetX, y: targetY)
                streakFlameScale = 0.6
                streakFlameRotation = 360
            }
        }
        
        // Phase 3: Impact - shrink and fade, badge pulse (2.0s delay - slower)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            HapticFeedback.success.trigger()
            
            withAnimation(.easeOut(duration: 0.3)) {
                streakFlameScale = 0.1
                streakFlameOpacity = 0
            }
            
            // Badge pulse
            withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                streakBadgeScale = 1.4
            }
            
            // Show +1 (start at positive offset to avoid being cut off)
            showStreakPlusOne = true
            plusOneOffset = 10 // Start below the badge
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                plusOneOffset = -10 // Move up slightly, but not too much
                plusOneOpacity = 1.0
            }
        }
        
        // Phase 4: Badge settle (2.5s delay - slower)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                streakBadgeScale = 1.0
            }
        }
        
        // Phase 5: +1 float up and fade (3.0s delay - slower)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.7)) {
                plusOneOffset = -25 // Less upward movement to avoid cutoff
                plusOneOpacity = 0
            }
        }
        
        // Phase 6: Cleanup (4.0s delay - slower)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            showStreakAnimation = false
            showStreakPlusOne = false
        }
    }
    
    private func updateData(steps: Int) {
        userSettings.updatePetHealth(steps: steps)
        stepDataManager.updateTodayRecord(steps: steps, goalSteps: userSettings.dailyStepGoal)
        
        // Sync data to widget
        WidgetDataManager.shared.syncFromUserSettings(userSettings, todaySteps: steps)
        
        // Always check achievements, not just when at 100% health
        let daysUsed = Calendar.current.dateComponents([.day], from: userSettings.firstLaunchDate ?? Date(), to: Date()).day ?? 0
        let previousHealth = userSettings.previousHealthForAchievement
        
        // Calculate weekly steps
        let weeklySteps = healthKitManager.weeklySteps.values.reduce(0, +)
        
        achievementManager.checkAchievements(
            todaySteps: steps,
            totalSteps: stepDataManager.totalStepsAllTime,
            streak: userSettings.streakData.currentStreak,
            health: currentHealth,
            goalSteps: userSettings.dailyStepGoal,
            goalsAchieved: stepDataManager.totalGoalsAchieved,
            daysUsed: daysUsed,
            petsUsed: userSettings.petsUsed.count,
            weeklySteps: weeklySteps,
            previousHealth: previousHealth,
            consecutiveFullHealthDays: userSettings.consecutiveFullHealthDays,
            consecutiveHealthyDays: userSettings.consecutiveHealthyDays,
            consecutiveNoSickDays: userSettings.consecutiveNoSickDays,
            rescueCount: userSettings.rescueCount,
            consecutiveGoalDays: userSettings.streakData.currentStreak
        )
        
        // Check daily walker achievement
        achievementManager.checkDailyWalkerAchievement(todaySteps: steps)
        
        // Check day-specific achievements (weekend warrior, never miss Monday)
        achievementManager.checkDaySpecificAchievements(todaySteps: steps, goalSteps: userSettings.dailyStepGoal)
        
        // Update previous health for next check
        userSettings.previousHealthForAchievement = currentHealth
        
        // Update streak only when goal achieved
        if currentHealth >= 100 {
            let previousStreak = userSettings.streakData.currentStreak
            userSettings.streakData.updateStreak(goalAchieved: true, date: Date())
            let newStreak = userSettings.streakData.currentStreak
            
            // Track if streak increased (for animation after celebration dismissal)
            // Using persisted flag so it survives view re-renders
            if newStreak > previousStreak {
                userSettings.streakDidIncreaseToday = true
                
                // Check for milestone celebration
                // This will show after the streak animation which is triggered when celebration is dismissed
                if StreakMilestoneCelebrationView.shouldShowCelebration(for: newStreak) {
                    milestoneStreakValue = newStreak
                }
            }
        }
    }
}

// MARK: - Weekly Steps Graph
struct WeeklyStepsGraph: View {
    let weeklySteps: [Date: Int]
    let todaySteps: Int
    let goalSteps: Int
    @Binding var selectedDay: Date?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -(6 - offset), to: today)
        }.map { calendar.startOfDay(for: $0) }
    }
    
    private var maxSteps: Int {
        let allSteps = weekDays.map { stepsForDay($0) }
        return max(allSteps.max() ?? goalSteps, goalSteps)
    }
    
    private func stepsForDay(_ date: Date) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: date)
        if Calendar.current.isDateInToday(date) {
            return todaySteps
        }
        return weeklySteps[startOfDay] ?? 0
    }
    
    private func dayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height - 30 // Leave space for labels
            let spacing = width / CGFloat(weekDays.count)
            let goalY = height - (CGFloat(goalSteps) / CGFloat(maxSteps) * height)
            
            ZStack {
                // Goal line with gradient glow
                ZStack {
                    // Glow effect
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: width, y: goalY))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.0),
                                Color.green.opacity(0.3),
                                Color.green.opacity(0.3),
                                Color.green.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6)
                    )
                    .blur(radius: 3)
                    
                    // Main dashed line
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: width, y: goalY))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color.green.opacity(0.4), Color.green.opacity(0.7), Color.green.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                    )
                    
                    // Goal label on right side
                    HStack(spacing: 3) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 8))
                        Text("Goal")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.green.opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                    )
                    .position(x: width - 28, y: goalY - 12)
                }
                
                // Area fill with smooth curve
                Path { path in
                    path.move(to: CGPoint(x: spacing / 2, y: height))
                    
                    let points = weekDays.enumerated().map { (index, day) -> CGPoint in
                        let x = spacing / 2 + CGFloat(index) * spacing
                        let steps = stepsForDay(day)
                        let y = height - (CGFloat(steps) / CGFloat(maxSteps) * height)
                        return CGPoint(x: x, y: y)
                    }
                    
                    // First point
                    path.addLine(to: points[0])
                    
                    // Smooth curve through points
                    for i in 1..<points.count {
                        let prev = points[i - 1]
                        let curr = points[i]
                        let controlX = (prev.x + curr.x) / 2
                        path.addCurve(
                            to: curr,
                            control1: CGPoint(x: controlX, y: prev.y),
                            control2: CGPoint(x: controlX, y: curr.y)
                        )
                    }
                    
                    path.addLine(to: CGPoint(x: spacing / 2 + CGFloat(weekDays.count - 1) * spacing, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.accentColor.opacity(0.35),
                            themeManager.accentColor.opacity(0.15),
                            themeManager.accentColor.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Line glow effect
                Path { path in
                    let points = weekDays.enumerated().map { (index, day) -> CGPoint in
                        let x = spacing / 2 + CGFloat(index) * spacing
                        let steps = stepsForDay(day)
                        let y = height - (CGFloat(steps) / CGFloat(maxSteps) * height)
                        return CGPoint(x: x, y: y)
                    }
                    
                    path.move(to: points[0])
                    
                    for i in 1..<points.count {
                        let prev = points[i - 1]
                        let curr = points[i]
                        let controlX = (prev.x + curr.x) / 2
                        path.addCurve(
                            to: curr,
                            control1: CGPoint(x: controlX, y: prev.y),
                            control2: CGPoint(x: controlX, y: curr.y)
                        )
                    }
                }
                .stroke(themeManager.accentColor.opacity(0.4), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .blur(radius: 4)
                
                // Main line with smooth curve
                Path { path in
                    let points = weekDays.enumerated().map { (index, day) -> CGPoint in
                        let x = spacing / 2 + CGFloat(index) * spacing
                        let steps = stepsForDay(day)
                        let y = height - (CGFloat(steps) / CGFloat(maxSteps) * height)
                        return CGPoint(x: x, y: y)
                    }
                    
                    path.move(to: points[0])
                    
                    for i in 1..<points.count {
                        let prev = points[i - 1]
                        let curr = points[i]
                        let controlX = (prev.x + curr.x) / 2
                        path.addCurve(
                            to: curr,
                            control1: CGPoint(x: controlX, y: prev.y),
                            control2: CGPoint(x: controlX, y: curr.y)
                        )
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [themeManager.accentColor.opacity(0.8), themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
                // Interactive dots with improved styling
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                    let x = spacing / 2 + CGFloat(index) * spacing
                    let steps = stepsForDay(day)
                    let y = height - (CGFloat(steps) / CGFloat(maxSteps) * height)
                    let isSelected = selectedDay != nil && Calendar.current.isDate(selectedDay!, inSameDayAs: day)
                    let isToday = Calendar.current.isDateInToday(day)
                    let metGoal = steps >= goalSteps
                    
                    VStack(spacing: 4) {
                        // Dot
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isToday {
                                    selectedDay = nil
                                } else {
                                    selectedDay = day
                                }
                            }
                            HapticFeedback.light.trigger()
                        }) {
                            ZStack {
                                // Outer glow for selected/today
                                if isSelected || isToday {
                                    Circle()
                                        .fill(themeManager.accentColor.opacity(0.3))
                                        .frame(width: 22, height: 22)
                                        .blur(radius: 4)
                                }
                                
                                // Achievement indicator (met goal)
                                if metGoal && !isSelected {
                                    Circle()
                                        .fill(Color.green.opacity(0.2))
                                        .frame(width: 18, height: 18)
                                }
                                
                                // Main dot
                                Circle()
                                    .fill(
                                        isSelected || isToday 
                                            ? themeManager.accentColor 
                                            : (metGoal ? Color.green.opacity(0.8) : themeManager.cardBackgroundColor)
                                    )
                                    .frame(width: isSelected ? 14 : 10, height: isSelected ? 14 : 10)
                                    .shadow(color: (isSelected || isToday ? themeManager.accentColor : (metGoal ? Color.green : Color.clear)).opacity(0.5), radius: 4)
                                
                                // Border for non-selected, non-today dots
                                if !isSelected && !isToday && !metGoal {
                                    Circle()
                                        .stroke(themeManager.accentColor.opacity(0.6), lineWidth: 2)
                                        .frame(width: 10, height: 10)
                                }
                                
                                // Checkmark for goal achieved
                                if metGoal && !isSelected && !isToday {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 6, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .position(x: x, y: y)
                    }
                }
                
                // Day labels
                HStack(spacing: 0) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                        let isToday = Calendar.current.isDateInToday(day)
                        let isSelected = selectedDay != nil && Calendar.current.isDate(selectedDay!, inSameDayAs: day)
                        
                        Text(dayName(day))
                            .font(.system(size: 10, weight: isToday || isSelected ? .bold : .medium))
                            .foregroundColor(isToday || isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
                            .frame(width: spacing)
                    }
                }
                .position(x: width / 2, y: height + 15)
            }
        }
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Enhanced Stat Card (More Colorful)
struct TodayEnhancedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 10) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: gradient[0].opacity(0.4), radius: 6, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(themeManager.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(themeManager.secondaryCardColor)
                
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [gradient[0].opacity(0.08), gradient[1].opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [gradient[0].opacity(0.3), gradient[1].opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
}

// MARK: - Celebration Overlay
struct CelebrationOverlay: View {
    let petName: String
    let onDismiss: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var sparkleRotation: Double = 0
    @State private var confettiParticles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            // Gradient background overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.85),
                    Color(hex: "1a1a2e").opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .onTapGesture { onDismiss() }
            
            // Floating confetti particles
            ForEach(confettiParticles) { particle in
                Text(particle.emoji)
                    .font(.system(size: particle.size))
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
            
            // Main content card
            VStack(spacing: 0) {
                // Top glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.yellow.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 25)
                    .offset(y: 30)
                
                VStack(spacing: 16) {
                    // Sparkle ring around trophy
                    ZStack {
                        // Rotating sparkles
                        ForEach(0..<8, id: \.self) { i in
                            Image(systemName: "sparkle")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .offset(x: 55 * cos(Double(i) * .pi / 4 + sparkleRotation),
                                        y: 55 * sin(Double(i) * .pi / 4 + sparkleRotation))
                                .opacity(0.8)
                        }
                        
                        // Trophy with glow
                        ZStack {
                            Text("🏆")
                                .font(.system(size: 70))
                                .shadow(color: .yellow.opacity(0.6), radius: 15)
                            
                            // Pulse ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.5), .orange.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.5
                                )
                                .frame(width: 100, height: 100)
                                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                .opacity(pulseAnimation ? 0 : 0.8)
                        }
                    }
                    .scaleEffect(showContent ? 1.0 : 0.3)
                    
                    // Title with gradient
                    Text("Goal Achieved!")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "FFD700")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .yellow.opacity(0.3), radius: 8)
                    
                    // Pet status
                    VStack(spacing: 6) {
                        Text("\(petName) is thriving!")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 5) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.pink)
                            Text("100% Health")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.pink)
                        }
                    }
                    
                    // Streak badge
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Streak Maintained!")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                            )
                    )
                    
                    // Continue button
                    Button(action: onDismiss) {
                        HStack(spacing: 8) {
                            Text("Continue")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .orange.opacity(0.5), radius: 12, y: 4)
                        )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "2d2d44"),
                                    Color(hex: "1a1a2e")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.2), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.5), radius: 30, y: 20)
                )
                .padding(.horizontal, 24)
            }
            .offset(y: -60)
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            // Generate confetti particles
            generateConfetti()
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
            
            // Start pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulseAnimation = true
            }
            
            // Start sparkle rotation
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                sparkleRotation = .pi * 2
            }
            
            // Animate confetti
            animateConfetti()
        }
    }
    
    private func generateConfetti() {
        let emojis = ["🎉", "⭐", "✨", "🌟", "🎊", "💫", "🏆", "❤️"]
        confettiParticles = (0..<20).map { _ in
            ConfettiParticle(
                emoji: emojis.randomElement()!,
                position: CGPoint(
                    x: CGFloat.random(in: 50...350),
                    y: CGFloat.random(in: -100...0)
                ),
                size: CGFloat.random(in: 20...35),
                opacity: 0
            )
        }
    }
    
    private func animateConfetti() {
        for i in confettiParticles.indices {
            let delay = Double(i) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 2.5)) {
                    confettiParticles[i].position.y += CGFloat.random(in: 600...900)
                    confettiParticles[i].opacity = 1
                }
                withAnimation(.easeIn(duration: 2.5).delay(1.5)) {
                    confettiParticles[i].opacity = 0
                }
            }
        }
    }
}

// Confetti particle model
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let emoji: String
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
}

// MARK: - Streak Badge Position Key
struct StreakBadgePositionKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Streak Calendar View
struct StreakCalendarView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var stepDataManager: StepDataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentMonth: Date = Date()
    @State private var animateFlame = false
    @State private var historicalSteps: [Date: Int] = [:]
    @State private var isLoadingData = false
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text("Streak Calendar")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(themeManager.cardBackgroundColor)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Streak Display Section
                VStack(spacing: 12) {
                    // Flame with streak number
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.orange.opacity(0.3),
                                        Color.orange.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(animateFlame ? 1.1 : 1.0)
                        
                        // Flame emoji and number
                        VStack(spacing: 0) {
                            Text("🔥")
                                .font(.system(size: 40))
                                .scaleEffect(animateFlame ? 1.05 : 1.0)
                            
                            Text("\(userSettings.streakData.currentStreak)")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange, Color.red],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    }
                    
                    Text("day streak")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    // Highest streak
                    HStack(spacing: 4) {
                        Text("Highest streak")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.tertiaryTextColor)
                        
                        Text("⭐")
                            .font(.system(size: 11))
                        
                        Text("\(userSettings.streakData.longestStreak)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                }
                .padding(.bottom, 20)
                
                // Calendar Card
                VStack(spacing: 12) {
                    // Month Navigation
                    HStack {
                        Button(action: { previousMonth() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.primaryTextColor)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(themeManager.secondaryCardColor)
                                )
                        }
                        
                        Spacer()
                        
                        Text(monthYearString)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Spacer()
                        
                        Button(action: { nextMonth() }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.primaryTextColor)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(themeManager.secondaryCardColor)
                                )
                        }
                        .opacity(canGoToNextMonth ? 1.0 : 0.3)
                        .disabled(!canGoToNextMonth)
                    }
                    .padding(.horizontal, 4)
                    
                    // Days of week header
                    HStack(spacing: 0) {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(themeManager.tertiaryTextColor)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // Calendar grid with step counts
                    if isLoadingData {
                        ProgressView()
                            .frame(height: 300)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                            ForEach(daysInMonth, id: \.self) { date in
                                if let date = date {
                                    EnhancedDayCell(
                                        date: date,
                                        steps: stepsForDate(date),
                                        goalSteps: userSettings.dailyStepGoal,
                                        isToday: calendar.isDateInToday(date),
                                        isFuture: date > Date()
                                    )
                                } else {
                                    Color.clear
                                        .frame(height: 54)
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    
                    // Legend
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: "34C759"))
                                .frame(width: 10, height: 10)
                            Text("Goal achieved")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: "FF3B30"))
                                .frame(width: 10, height: 10)
                            Text("Goal missed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(themeManager.cardBackgroundColor)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                )
                .padding(.horizontal, 16)
                
                Spacer()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateFlame = true
            }
            fetchMonthData()
        }
        .onChange(of: currentMonth) { _, _ in
            fetchMonthData()
        }
    }
    
    // MARK: - Helper Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var canGoToNextMonth: Bool {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        return nextMonth <= Date()
    }
    
    private var daysInMonth: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        
        // Get the weekday of the first day (0 = Sunday)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // MARK: - Helper Methods
    
    private func fetchMonthData() {
        isLoadingData = true
        
        // Calculate start and end of current displayed month
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let endOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth)!
        
        // Fetch historical data from HealthKit
        healthKitManager.fetchSteps(from: startOfMonth, to: min(endOfMonth, Date())) { data in
            DispatchQueue.main.async {
                // Merge with existing data
                for (date, steps) in data {
                    let normalizedDate = calendar.startOfDay(for: date)
                    historicalSteps[normalizedDate] = steps
                }
                isLoadingData = false
            }
        }
    }
    
    private func stepsForDate(_ date: Date) -> Int {
        let normalizedDate = calendar.startOfDay(for: date)
        
        // First check HealthKit data
        if let steps = historicalSteps[normalizedDate] {
            return steps
        }
        
        // Fallback to app's daily records
        if let record = stepDataManager.dailyRecords.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            return record.steps
        }
        
        return 0
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        guard canGoToNextMonth else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

// MARK: - Enhanced Day Cell (with step counts)
struct EnhancedDayCell: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let date: Date
    let steps: Int
    let goalSteps: Int
    let isToday: Bool
    let isFuture: Bool
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var goalAchieved: Bool {
        steps >= goalSteps && steps > 0
    }
    
    private var hasData: Bool {
        steps > 0
    }
    
    private var stepsText: String {
        if isFuture {
            return ""
        }
        if steps >= 1000 {
            return String(format: "%.1fK", Double(steps) / 1000.0)
        } else if steps > 0 {
            return "\(steps)"
        }
        return "0"
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Step count above the day
            if !isFuture {
                Text(stepsText)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(stepTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Text("")
                    .font(.system(size: 8))
            }
            
            ZStack {
                // Background circle based on status
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 32, height: 32)
                
                // Today indicator ring
                if isToday {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 36, height: 36)
                }
                
                Text(dayNumber)
                    .font(.system(size: 13, weight: isToday ? .bold : .medium, design: .rounded))
                    .foregroundColor(textColor)
            }
        }
        .frame(height: 54)
    }
    
    private var backgroundColor: Color {
        if isFuture {
            return Color.clear
        }
        
        if !hasData {
            return themeManager.secondaryCardColor.opacity(0.3)
        }
        
        return goalAchieved ? Color(hex: "34C759") : Color(hex: "FF3B30")
    }
    
    private var textColor: Color {
        if isFuture {
            return themeManager.tertiaryTextColor
        }
        
        if !hasData {
            return themeManager.secondaryTextColor
        }
        
        return .white
    }
    
    private var stepTextColor: Color {
        if !hasData {
            return themeManager.tertiaryTextColor
        }
        return goalAchieved ? Color(hex: "34C759") : Color(hex: "FF3B30")
    }
}

// MARK: - Preview
#Preview {
    TodayView()
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
        .environmentObject(UserSettings())
        .environmentObject(StepDataManager())
        .environmentObject(AchievementManager())
}
