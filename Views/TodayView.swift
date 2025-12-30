//
//  TodayView.swift
//  StepPet
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
    
    private var stepsToNextMood: (steps: Int, nextMood: PetMoodState)? {
        let currentMood = moodState
        let currentSteps = healthKitManager.todaySteps
        let goal = userSettings.dailyStepGoal
        
        // Calculate thresholds based on goal
        let moodThresholds: [(mood: PetMoodState, threshold: Int)] = [
            (.sick, Int(Double(goal) * 0.2)),
            (.sad, Int(Double(goal) * 0.4)),
            (.content, Int(Double(goal) * 0.6)),
            (.happy, Int(Double(goal) * 0.8)),
            (.fullHealth, goal)
        ]
        
        for (mood, threshold) in moodThresholds {
            if currentSteps < threshold {
                return (threshold - currentSteps, mood)
            }
        }
        return nil
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                heroCardSection
                weeklyGraphSection
                encouragementSection
                dashboardSection
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
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
            
            // Credits
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
            
            // Streak (small)
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
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.accentColor.opacity(0.12),
                            themeManager.accentColor.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
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
            
            // Steps to next mood
            if let nextMoodInfo = stepsToNextMood, stepsToGoal > 0 {
                HStack(spacing: 8) {
                    Text(nextMoodInfo.nextMood.emoji)
                        .font(.system(size: 14))
                    
                    Text("\(nextMoodInfo.steps) more to \(nextMoodInfo.nextMood.displayName.lowercased())")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
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
    
    private func updateData(steps: Int) {
        userSettings.updatePetHealth(steps: steps)
        stepDataManager.updateTodayRecord(steps: steps, goalSteps: userSettings.dailyStepGoal)
        
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
            userSettings.streakData.updateStreak(goalAchieved: true, date: Date())
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
            
            ZStack {
                // Goal line
                Path { path in
                    let goalY = height - (CGFloat(goalSteps) / CGFloat(maxSteps) * height)
                    path.move(to: CGPoint(x: 0, y: goalY))
                    path.addLine(to: CGPoint(x: width, y: goalY))
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.3))
                
                // Area fill
                Path { path in
                    path.move(to: CGPoint(x: spacing / 2, y: height))
                    
                    for (index, day) in weekDays.enumerated() {
                        let x = spacing / 2 + CGFloat(index) * spacing
                        let steps = stepsForDay(day)
                        let y = height - (CGFloat(steps) / CGFloat(maxSteps) * height)
                        
                        if index == 0 {
                            path.addLine(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                    path.addLine(to: CGPoint(x: spacing / 2 + CGFloat(weekDays.count - 1) * spacing, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [themeManager.accentColor.opacity(0.3), themeManager.accentColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Line
                Path { path in
                    for (index, day) in weekDays.enumerated() {
                        let x = spacing / 2 + CGFloat(index) * spacing
                        let steps = stepsForDay(day)
                        let y = height - (CGFloat(steps) / CGFloat(maxSteps) * height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(themeManager.accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                
                // Interactive dots
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                    let x = spacing / 2 + CGFloat(index) * spacing
                    let steps = stepsForDay(day)
                    let y = height - (CGFloat(steps) / CGFloat(maxSteps) * height)
                    let isSelected = selectedDay != nil && Calendar.current.isDate(selectedDay!, inSameDayAs: day)
                    let isToday = Calendar.current.isDateInToday(day)
                    
                    VStack(spacing: 4) {
                        // Dot
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                if isToday {
                                    selectedDay = nil
                                } else {
                                    selectedDay = day
                                }
                            }
                            HapticFeedback.light.trigger()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isSelected || isToday ? themeManager.accentColor : themeManager.cardBackgroundColor)
                                    .frame(width: isSelected ? 16 : 12, height: isSelected ? 16 : 12)
                                    .shadow(color: themeManager.accentColor.opacity(0.3), radius: isSelected ? 6 : 0)
                                
                                if !isSelected && !isToday {
                                    Circle()
                                        .stroke(themeManager.accentColor, lineWidth: 2)
                                        .frame(width: 12, height: 12)
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

// MARK: - Preview
#Preview {
    TodayView()
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
        .environmentObject(UserSettings())
        .environmentObject(StepDataManager())
        .environmentObject(AchievementManager())
}
