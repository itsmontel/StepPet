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
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .onAppear {
            refreshData()
            animateValues()
        }
        .onChange(of: healthKitManager.todaySteps) { _, newValue in
            updateData(steps: newValue)
            animateValues()
        }
        .onChange(of: currentHealth) { oldValue, newValue in
            if newValue >= 100 && oldValue < 100 {
                triggerCelebration()
            }
        }
        .overlay {
            if showCelebration {
                CelebrationOverlay(petName: userSettings.pet.name) {
                    withAnimation { showCelebration = false }
                }
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
    }
    
    // MARK: - Header Section (Compact)
    private var headerSection: some View {
        HStack(alignment: .center) {
            // Date (smaller)
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .semibold))
                
                Text(formattedDate)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(themeManager.primaryTextColor)
            
            Spacer()
            
            // Credits (clickable - navigates to Pet section)
            Button(action: {
                HapticFeedback.light.trigger()
                // Set target section to Pet (1) and navigate to Challenges
                UserDefaults.standard.set(1, forKey: "challengesTargetSegment")
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToChallenges"), object: nil, userInfo: ["segment": 1])
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text("\(userSettings.playCredits)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.yellow.opacity(0.15))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .tutorialHighlight("tutorial_credits_badge")
            
            // Streak (small) with animation target (clickable - navigates to Awards section)
            ZStack {
                Button(action: {
                    HapticFeedback.light.trigger()
                    // Set target section to Awards (2) and navigate to Challenges
                    UserDefaults.standard.set(2, forKey: "challengesTargetSegment")
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToChallenges"), object: nil, userInfo: ["segment": 2])
                }) {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 12))
                        
                        Text("\(userSettings.streakData.currentStreak)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                    )
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
        VStack(spacing: 16) {
            // Pet Name
            Text(userSettings.pet.name)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
                .padding(.top, 16)
            
            // Pet with Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 10)
                    .frame(width: 200, height: 200)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: isViewingToday ? goalProgress : Double(selectedDayHealth) / 100)
                    .stroke(
                        AngularGradient(
                            colors: [healthColor(for: isViewingToday ? currentHealth : selectedDayHealth), 
                                    healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.6)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: goalProgress)
                
                // Pet Animation
                AnimatedPetVideoView(
                    petType: userSettings.pet.type,
                    moodState: isViewingToday ? moodState : selectedDayMood
                )
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .tutorialHighlight("tutorial_pet_hero")
            
            // Steps Display
            VStack(spacing: 6) {
                if isViewingToday {
                    Text("\(healthKitManager.todaySteps)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.accentColor)
                        .contentTransition(.numericText())
                    
                    Text("steps today")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                } else {
                    Text("\(selectedDaySteps)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.accentColor)
                    
                    Text(selectedDayFormatted)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .tutorialHighlight("tutorial_step_count")
            
            // Health Bar (no number)
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 12)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [healthColor(for: isViewingToday ? currentHealth : selectedDayHealth), 
                                            healthColor(for: isViewingToday ? currentHealth : selectedDayHealth).opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(isViewingToday ? currentHealth : selectedDayHealth) / 100, height: 12)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentHealth)
                    }
                }
                .frame(height: 12)
                .padding(.horizontal, 30)
                
                Text("Pet Health")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            // Steps to Goal / Next Mood (only for today)
            if isViewingToday {
                stepsToGoalSection
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(themeManager.backgroundColor)
        )
        .padding(.top, 16)
    }
    
    // MARK: - Steps to Goal Section
    private var stepsToGoalSection: some View {
        VStack(spacing: 12) {
            // Steps to reach goal
            if stepsToGoal > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.accentColor)
                    
                    Text("\(stepsToGoal) steps to reach goal")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(themeManager.accentColor.opacity(0.1))
                )
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    Text("Goal reached! 🎉")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.1))
                )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Weekly Graph Section
    private var weeklyGraphSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Last 7 Days")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                if selectedDay != nil && !Calendar.current.isDateInToday(selectedDay!) {
                    Button(action: { 
                        withAnimation(.spring(response: 0.3)) {
                            selectedDay = nil 
                        }
                    }) {
                        Text("Back to Today")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.accentColor)
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.accentColor.opacity(0.08))
        )
        .padding(.top, 16)
    }
    
    // MARK: - Encouragement Section
    private var encouragementSection: some View {
        HStack(spacing: 8) {
            Text(encouragementMessage)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(healthColor(for: currentHealth).opacity(0.1))
        )
        .padding(.top, 16)
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
                Text("Quick Stats")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
            }
            
            // Stats Row
            HStack(spacing: 12) {
                QuickStatCard(
                    title: "Calories",
                    value: "\(Int(Double(healthKitManager.todaySteps) * 0.04))",
                    icon: "flame.fill",
                    color: .orange
                )
                
                QuickStatCard(
                    title: "Miles",
                    value: String(format: "%.1f", Double(healthKitManager.todaySteps) * 2.5 / 5280),
                    icon: "map.fill",
                    color: .purple
                )
                
                QuickStatCard(
                    title: "Goal",
                    value: "\(Int(goalProgress * 100))%",
                    icon: "target",
                    color: .green
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.purple.opacity(0.08))
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
        achievementManager.checkAchievements(
            todaySteps: steps,
            totalSteps: stepDataManager.totalStepsAllTime,
            streak: userSettings.streakData.currentStreak,
            health: currentHealth,
            goalSteps: userSettings.dailyStepGoal,
            goalsAchieved: stepDataManager.totalGoalsAchieved,
            daysUsed: daysUsed,
            petsUsed: userSettings.petsUsed.count
        )
        
        // Update streak only when goal achieved
        if currentHealth >= 100 {
            let previousStreak = userSettings.streakData.currentStreak
            userSettings.streakData.updateStreak(goalAchieved: true, date: Date())
            let newStreak = userSettings.streakData.currentStreak
            
            // Check for milestone celebration (only if streak actually increased)
            if newStreak > previousStreak && StreakMilestoneCelebrationView.shouldShowCelebration(for: newStreak) {
                // Delay to show after regular celebration
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    milestoneStreakValue = newStreak
                    withAnimation {
                        showMilestoneCelebration = true
                    }
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

// MARK: - Celebration Overlay
struct CelebrationOverlay: View {
    let petName: String
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var confettiActive = true
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    ForEach(0..<5) { i in
                        Text(["🎉", "⭐", "🌟", "✨", "🎊"][i])
                            .font(.system(size: 30))
                            .offset(y: confettiActive ? -20 : 0)
                            .animation(
                                .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1),
                                value: confettiActive
                            )
                    }
                }
                
                Text("🏆")
                    .font(.system(size: 80))
                    .scaleEffect(showContent ? 1.0 : 0.5)
                
                Text("Goal Achieved!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(petName) is at full health!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Streak maintained! 🔥")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                        )
                }
                .padding(.top, 10)
            }
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
}

// MARK: - Streak Badge Position Key
struct StreakBadgePositionKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
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
