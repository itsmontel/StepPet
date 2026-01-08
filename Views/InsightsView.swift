//
//  InsightsView.swift
//  VirtuPet
//
//  Premium Analytics Dashboard

import SwiftUI

// MARK: - Time Period Enum
enum TimePeriod: String, CaseIterable {
    case week = "7D"
    case month = "30D"
    case threeMonths = "3M"
    case year = "1Y"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }
    
    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .threeMonths: return "3 Months"
        case .year: return "This Year"
        }
    }
}

// MARK: - Main Insights View
struct InsightsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var stepDataManager: StepDataManager
    
    @State private var selectedPeriod: TimePeriod = .week
    @State private var historicalData: [Date: Int] = [:]
    @State private var lastWeekData: [Date: Int] = [:]
    @State private var isLoading = false
    @State private var selectedTab: Int = 0
    @State private var animateCharts = false
    @State private var showPremiumSheet = false
    
    // MARK: - Computed Properties
    private var currentPeriodData: [Date: Int] {
        selectedPeriod == .week ? healthKitManager.weeklySteps : historicalData
    }
    
    private var totalSteps: Int {
        if selectedPeriod == .week {
            return healthKitManager.totalWeeklySteps
        }
        return historicalData.values.reduce(0, +)
    }
    
    private var averageSteps: Int {
        let data = currentPeriodData
        guard !data.isEmpty else { return 0 }
        return data.values.reduce(0, +) / max(1, data.count)
    }
    
    private var bestDay: (date: Date, steps: Int)? {
        let data = currentPeriodData
        guard let best = data.max(by: { $0.value < $1.value }) else { return nil }
        return (best.key, best.value)
    }
    
    private var worstDay: (date: Date, steps: Int)? {
        let data = currentPeriodData
        let filtered = data.filter { $0.value > 0 }
        guard let worst = filtered.min(by: { $0.value < $1.value }) else { return nil }
        return (worst.key, worst.value)
    }
    
    private var goalsAchieved: Int {
        currentPeriodData.values.filter { $0 >= userSettings.dailyStepGoal }.count
    }
    
    private var goalCompletionRate: Double {
        guard !currentPeriodData.isEmpty else { return 0 }
        return Double(goalsAchieved) / Double(currentPeriodData.count) * 100
    }
    
    private var lifetimeSteps: Int {
        stepDataManager.totalStepsAllTime + healthKitManager.todaySteps
    }
    
    private var lifetimeMiles: Double {
        Double(lifetimeSteps) * 2.5 / 5280
    }
    
    private var weekOverWeekChange: Double {
        let thisWeekTotal = healthKitManager.totalWeeklySteps
        let lastWeekTotal = lastWeekData.values.reduce(0, +)
        guard lastWeekTotal > 0 else { return 0 }
        return Double(thisWeekTotal - lastWeekTotal) / Double(lastWeekTotal) * 100
    }
    
    private var currentStreak: Int {
        userSettings.streakData.currentStreak
    }
    
    private var bestStreak: Int {
        userSettings.streakData.longestStreak
    }
    
    // Day of week analysis
    private var dayOfWeekAverages: [(String, Int)] {
        let calendar = Calendar.current
        var dayTotals: [Int: [Int]] = [:]
        
        for (date, steps) in currentPeriodData {
            let weekday = calendar.component(.weekday, from: date)
            if dayTotals[weekday] == nil {
                dayTotals[weekday] = []
            }
            dayTotals[weekday]?.append(steps)
        }
        
        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return (1...7).map { weekday in
            let steps = dayTotals[weekday] ?? []
            let avg = steps.isEmpty ? 0 : steps.reduce(0, +) / steps.count
            return (dayNames[weekday], avg)
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            if !userSettings.isPremium {
                premiumGateView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        timePeriodPicker
                        
                        // Main Stats Cards
                        mainStatsGrid
                        
                        // Goal Completion Ring
                        goalCompletionSection
                        
                        // Weekly Chart
                        if selectedPeriod == .week {
                            enhancedWeeklyChart
                            weekComparisonSection
                        }
                        
                        // Day of Week Analysis
                        dayOfWeekSection
                        
                        // Personal Records
                        personalRecordsSection
                        
                        // Streak Section
                        streakSection
                        
                        // Detailed Stats
                        detailedStatsSection
                        
                        // Lifetime Stats with Milestones
                        lifetimeSection
                        
                        // Activity Insights
                        activityInsightsSection
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .onAppear {
            if userSettings.isPremium {
                healthKitManager.fetchWeeklySteps()
                loadDataForPeriod()
                loadLastWeekData()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        animateCharts = true
                    }
                }
            }
        }
        .onChange(of: selectedPeriod) { _, _ in
            if userSettings.isPremium {
                animateCharts = false
                loadDataForPeriod()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        animateCharts = true
                    }
                }
            }
        }
    }
    
    // MARK: - Premium Gate View
    private var premiumGateView: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 20)
                
                // Animated pet with decorative circles (matching Activity page)
                ZStack {
                    // Outer decorative ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [themeManager.accentColor.opacity(0.3), themeManager.accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 160, height: 160)
                    
                    // Middle glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [themeManager.accentColor.opacity(0.15), themeManager.accentColor.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    // Inner circle with pet
                    ZStack {
                        Circle()
                            .fill(themeManager.cardBackgroundColor)
                            .frame(width: 110, height: 110)
                            .shadow(color: themeManager.accentColor.opacity(0.2), radius: 20, y: 5)
                        
                        // Pet animation (thinking pose)
                        AnimatedPetVideoView(
                            petType: userSettings.pet.type,
                            moodState: .content
                        )
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    }
                    
                    // Insights chart icon badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(themeManager.accentColor)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: themeManager.accentColor.opacity(0.5), radius: 8, y: 3)
                                
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 10, y: 10)
                        }
                    }
                    .frame(width: 130, height: 130)
                }
                
                VStack(spacing: 8) {
                    Text("Deep Insights")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("Premium Analytics")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(themeManager.accentColor)
                    
                    Text("Unlock powerful analytics to understand your fitness journey")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                
                // Features list - more compact
                VStack(alignment: .leading, spacing: 10) {
                    InsightFeatureRow(icon: "chart.xyaxis.line", text: "Interactive trend charts", color: .blue)
                    InsightFeatureRow(icon: "calendar.badge.clock", text: "Day-of-week patterns", color: .orange)
                    InsightFeatureRow(icon: "trophy.fill", text: "Personal records tracking", color: .yellow)
                    InsightFeatureRow(icon: "flame.fill", text: "Streak analytics", color: .red)
                    InsightFeatureRow(icon: "arrow.triangle.2.circlepath", text: "Week-over-week comparison", color: .green)
                    InsightFeatureRow(icon: "figure.walk.motion", text: "Lifetime milestones", color: .purple)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                
                // Upgrade button - matching Activity page style
                Button(action: {
                    HapticFeedback.medium.trigger()
                    showPremiumSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Upgrade to Premium")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                            .shadow(color: themeManager.accentColor.opacity(0.4), radius: 10, y: 5)
                    )
                }
                
                Spacer()
            }
        .sheet(isPresented: $showPremiumSheet) {
            PremiumView()
                .environmentObject(themeManager)
                .environmentObject(userSettings)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Insights")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Your step journey")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Pet mascot
            AnimatedPetVideoView(
                petType: userSettings.pet.type,
                moodState: .fullHealth
            )
            .frame(width: 50, height: 50)
            .clipShape(Circle())
        }
        .padding(.top, 16)
    }
    
    // MARK: - Time Period Picker
    private var timePeriodPicker: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedPeriod = period
                    }
                    HapticFeedback.light.trigger()
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: selectedPeriod == period ? .bold : .semibold))
                        .foregroundColor(selectedPeriod == period ? .white : themeManager.secondaryTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedPeriod == period ? themeManager.accentColor : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Main Stats Grid
    private var mainStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            // Average Steps
            EnhancedStatCard(
                title: "Daily Average",
                value: formatSteps(averageSteps),
                subtitle: "steps/day",
                icon: "chart.line.uptrend.xyaxis",
                color: themeManager.accentColor,
                isHighlighted: averageSteps >= userSettings.dailyStepGoal
            )
            
            // Total Steps
            EnhancedStatCard(
                title: "Total Steps",
                value: formatSteps(totalSteps),
                subtitle: selectedPeriod.displayName.lowercased(),
                icon: "figure.walk",
                color: .purple,
                isHighlighted: false
            )
            
            // Goals Hit
            EnhancedStatCard(
                title: "Goals Hit",
                value: "\(goalsAchieved)/\(currentPeriodData.count)",
                subtitle: "days",
                icon: "target",
                color: .green,
                isHighlighted: goalCompletionRate >= 70
            )
            
            // Active Days
            let activeDays = currentPeriodData.values.filter { $0 > 1000 }.count
            EnhancedStatCard(
                title: "Active Days",
                value: "\(activeDays)",
                subtitle: "days",
                icon: "bolt.fill",
                color: .orange,
                isHighlighted: false
            )
        }
    }
    
    // MARK: - Goal Completion Section
    private var goalCompletionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Goal Completion")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Text("\(Int(goalCompletionRate))%")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: goalCompletionRate >= 70 ? [Color.green, Color.mint] : [themeManager.accentColor, themeManager.accentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(themeManager.accentColor.opacity(0.15), lineWidth: 20)
                    .frame(width: 160, height: 160)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: animateCharts ? CGFloat(goalCompletionRate / 100) : 0)
                    .stroke(
                        LinearGradient(
                            colors: goalCompletionRate >= 70 ? [Color.green, Color.mint] : [themeManager.accentColor, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(goalsAchieved)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("of \(currentPeriodData.count) days")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .padding(.vertical, 10)
            
            // Goal insight
            HStack(spacing: 8) {
                Image(systemName: goalCompletionRate >= 70 ? "sparkles" : "lightbulb.fill")
                    .foregroundColor(goalCompletionRate >= 70 ? .yellow : .orange)
                
                Text(goalInsightText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(goalCompletionRate >= 70 ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    private var goalInsightText: String {
        if goalCompletionRate >= 90 {
            return "Outstanding! You're crushing your goals! 🎉"
        } else if goalCompletionRate >= 70 {
            return "Great work! Keep up the momentum! 💪"
        } else if goalCompletionRate >= 50 {
            return "You're halfway there! Push a little more! 🚀"
        } else if goalCompletionRate >= 30 {
            return "Room to improve - try setting reminders! ⏰"
        } else {
            return "Start small - even 5 min walks help! 🌱"
        }
    }
    
    // MARK: - Enhanced Weekly Chart
    private var enhancedWeeklyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weekly Overview")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                // Legend
                HStack(spacing: 12) {
                    LegendItem(color: .green, text: "Goal met")
                    LegendItem(color: themeManager.accentColor, text: "Below goal")
                }
            }
            
            EnhancedBarChart(
                weeklySteps: healthKitManager.weeklySteps,
                todaySteps: healthKitManager.todaySteps,
                goalSteps: userSettings.dailyStepGoal,
                animate: animateCharts
            )
            .frame(height: 200)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Week Comparison Section
    private var weekComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("vs Last Week")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            HStack(spacing: 16) {
                // This Week
                VStack(spacing: 8) {
                    Text("This Week")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text(formatSteps(healthKitManager.totalWeeklySteps))
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.accentColor.opacity(0.1))
                )
                
                // Change indicator
                VStack(spacing: 4) {
                    Image(systemName: weekOverWeekChange >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(weekOverWeekChange >= 0 ? .green : .orange)
                    
                    Text(String(format: "%+.1f%%", weekOverWeekChange))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(weekOverWeekChange >= 0 ? .green : .orange)
                }
                .frame(width: 80)
                
                // Last Week
                VStack(spacing: 8) {
                    Text("Last Week")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text(formatSteps(lastWeekData.values.reduce(0, +)))
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Day of Week Section
    private var dayOfWeekSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Activity by Day")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Image(systemName: "calendar")
                    .foregroundColor(themeManager.accentColor)
            }
            
            Text("Your most active days")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
            
            HStack(spacing: 8) {
                ForEach(Array(dayOfWeekAverages.enumerated()), id: \.offset) { index, data in
                    let maxAvg = dayOfWeekAverages.map { $0.1 }.max() ?? 1
                    let height = maxAvg > 0 ? CGFloat(data.1) / CGFloat(maxAvg) : 0
                    let isTopDay = data.1 == maxAvg && data.1 > 0
                    
                    VStack(spacing: 6) {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                isTopDay
                                    ? LinearGradient(colors: [Color.green, Color.mint], startPoint: .bottom, endPoint: .top)
                                    : LinearGradient(colors: [themeManager.accentColor.opacity(0.8), themeManager.accentColor.opacity(0.4)], startPoint: .bottom, endPoint: .top)
                            )
                            .frame(height: animateCharts ? max(8, height * 80) : 8)
                        
                        Text(data.0)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isTopDay ? .green : themeManager.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
            
            // Best day callout
            if let bestDayOfWeek = dayOfWeekAverages.max(by: { $0.1 < $1.1 }), bestDayOfWeek.1 > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                    
                    Text("You're most active on **\(bestDayOfWeek.0)s** with \(formatSteps(bestDayOfWeek.1)) avg steps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Personal Records Section
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Personal Records")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
            }
            
            VStack(spacing: 12) {
                // Best Day
                if let best = bestDay {
                    RecordRow(
                        icon: "crown.fill",
                        iconColor: .yellow,
                        title: "Best Day",
                        value: formatSteps(best.steps),
                        subtitle: formatDate(best.date),
                        isBest: true
                    )
                }
                
                // Worst Day
                if let worst = worstDay {
                    RecordRow(
                        icon: "arrow.down.circle.fill",
                        iconColor: .orange,
                        title: "Lowest Day",
                        value: formatSteps(worst.steps),
                        subtitle: formatDate(worst.date),
                        isBest: false
                    )
                }
                
                // Lifetime Best (from step data manager if available)
                RecordRow(
                    icon: "star.circle.fill",
                    iconColor: .purple,
                    title: "Lifetime Steps",
                    value: formatSteps(lifetimeSteps),
                    subtitle: "all time",
                    isBest: false
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.08), Color.orange.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Streak Section
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Streaks")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 16) {
                // Current Streak
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                        
                        VStack(spacing: 0) {
                            Text("\(currentStreak)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("days")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Text("Current")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(themeManager.secondaryTextColor.opacity(0.2))
                    .frame(width: 1, height: 80)
                
                // Best Streak
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                        
                        VStack(spacing: 0) {
                            Text("\(bestStreak)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("days")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Text("Best")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
            
            // Streak tip
            HStack(spacing: 8) {
                Image(systemName: currentStreak > 0 ? "flame.fill" : "lightbulb.fill")
                    .foregroundColor(currentStreak > 0 ? .orange : .yellow)
                
                Text(currentStreak > 0 ? "Keep going! Don't break the chain! 🔥" : "Start a streak by hitting your daily goal!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Detailed Stats Section
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Stats")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            // Distance
            let distance = Double(totalSteps) * 2.5 / 5280
            DetailedStatRow(
                icon: "map.fill",
                iconColor: .blue,
                title: "Distance",
                value: String(format: "%.1f", distance),
                unit: "miles"
            )
            
            // Calories
            let calories = Int(Double(totalSteps) * 0.04)
            DetailedStatRow(
                icon: "flame.fill",
                iconColor: .red,
                title: "Calories",
                value: formatNumber(calories),
                unit: "kcal"
            )
            
            // Time Walking (estimate: 100 steps/min average)
            let minutesWalking = totalSteps / 100
            DetailedStatRow(
                icon: "clock.fill",
                iconColor: .purple,
                title: "Time Active",
                value: formatTime(minutes: minutesWalking),
                unit: ""
            )
            
            // Floors (estimate: 16 steps per floor)
            let floors = totalSteps / 16
            DetailedStatRow(
                icon: "building.2.fill",
                iconColor: .green,
                title: "Floors Climbed",
                value: formatNumber(floors),
                unit: "floors"
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    // MARK: - Lifetime Section
    private var lifetimeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with gradient accent
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "infinity")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(colors: [Color.purple, Color.pink], startPoint: .leading, endPoint: .trailing)
                            )
                        
                        Text("Lifetime Journey")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                    
                    Text("Since you started with VirtuPet")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 50, height: 50)
                    
                    AnimatedPetVideoView(
                        petType: userSettings.pet.type,
                        moodState: .fullHealth
                    )
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                }
            }
            
            // Big stats with beautiful gradient cards
            HStack(spacing: 14) {
                LifetimeStatBox(
                    value: formatSteps(lifetimeSteps),
                    label: "Total Steps",
                    icon: "figure.walk",
                    gradient: [Color(hex: "667eea"), Color(hex: "764ba2")]
                )
                
                LifetimeStatBox(
                    value: String(format: "%.1f", lifetimeMiles),
                    label: "Total Miles",
                    icon: "map.fill",
                    gradient: [Color(hex: "f093fb"), Color(hex: "f5576c")]
                )
            }
            
            // Milestones with enhanced design
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "flag.checkered")
                        .foregroundStyle(
                            LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .top, endPoint: .bottom)
                        )
                    
                    Text("Milestones")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                
                MilestoneRow(steps: 10000, current: lifetimeSteps, label: "First 10K", emoji: "🌱")
                MilestoneRow(steps: 100000, current: lifetimeSteps, label: "100K Club", emoji: "⭐")
                MilestoneRow(steps: 500000, current: lifetimeSteps, label: "Half Million", emoji: "🔥")
                MilestoneRow(steps: 1000000, current: lifetimeSteps, label: "Millionaire", emoji: "💎")
                MilestoneRow(steps: 5000000, current: lifetimeSteps, label: "5M Legend", emoji: "👑")
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [themeManager.accentColor.opacity(0.08), themeManager.accentColor.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(themeManager.accentColor.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // Fun fact with enhanced style
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Text("💡")
                        .font(.system(size: 18))
                }
                
                Text(lifetimeFunFact)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.primaryTextColor)
                    .lineSpacing(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.12), Color.orange.opacity(0.08)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(themeManager.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.06), Color.pink.opacity(0.04), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.purple.opacity(themeManager.isDarkMode ? 0.15 : 0.12), radius: 20, x: 0, y: 10)
        )
    }
    
    private var lifetimeFunFact: String {
        if lifetimeMiles > 2500 {
            return "That's further than walking across the USA! 🇺🇸"
        } else if lifetimeMiles > 1000 {
            return "You've walked the length of California! 🌴"
        } else if lifetimeMiles > 500 {
            return "Like walking from LA to San Francisco and back! 🌉"
        } else if lifetimeMiles > 100 {
            return "You've walked \(Int(lifetimeMiles / 26.2)) marathon distances! 🏃"
        } else if lifetimeMiles > 26.2 {
            return "You've completed a marathon distance! 🎉"
        } else {
            return "Keep going! Great habits are forming! 💪"
        }
    }
    
    // MARK: - Activity Insights Section
    private var activityInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Insights")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 12) {
                // Consistency score
                let consistencyScore = calculateConsistencyScore()
                InsightCard(
                    icon: "chart.bar.fill",
                    iconColor: .blue,
                    title: "Consistency Score",
                    value: "\(consistencyScore)%",
                    description: consistencyDescription(score: consistencyScore)
                )
                
                // Projected monthly
                let projectedMonthly = averageSteps * 30
                InsightCard(
                    icon: "calendar.badge.plus",
                    iconColor: .green,
                    title: "Projected Monthly",
                    value: formatSteps(projectedMonthly),
                    description: "Based on your current average"
                )
                
                // Improvement suggestion
                InsightCard(
                    icon: "lightbulb.fill",
                    iconColor: .yellow,
                    title: "Pro Tip",
                    value: "",
                    description: improvementTip
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    private func calculateConsistencyScore() -> Int {
        let data = currentPeriodData
        guard data.count >= 3 else { return 0 }
        
        let values = data.values.sorted()
        let median = values[values.count / 2]
        guard median > 0 else { return 0 }
        
        var withinRange = 0
        for value in values {
            let deviation = abs(Double(value - median)) / Double(median)
            if deviation <= 0.3 { // Within 30% of median
                withinRange += 1
            }
        }
        
        return Int(Double(withinRange) / Double(values.count) * 100)
    }
    
    private func consistencyDescription(score: Int) -> String {
        if score >= 80 { return "Excellent! Very consistent activity" }
        if score >= 60 { return "Good consistency - keep it steady" }
        if score >= 40 { return "Moderate - try walking every day" }
        return "Variable - aim for consistent daily walks"
    }
    
    private var improvementTip: String {
        if averageSteps < 5000 {
            return "Try parking farther away or taking stairs to add more steps naturally"
        } else if averageSteps < 8000 {
            return "A 15-min walk after meals can boost your daily steps significantly"
        } else if averageSteps < 10000 {
            return "You're close! A morning or evening walk will get you to 10K"
        } else {
            return "Amazing! Consider adding interval walks for extra fitness benefits"
        }
    }
    
    // MARK: - Helper Methods
    private func loadDataForPeriod() {
        guard selectedPeriod != .week else { return }
        
        isLoading = true
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) else { return }
        
        healthKitManager.fetchSteps(from: startDate, to: endDate) { data in
            historicalData = data
            isLoading = false
        }
    }
    
    private func loadLastWeekData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let lastWeekStart = calendar.date(byAdding: .day, value: -14, to: today),
              let lastWeekEnd = calendar.date(byAdding: .day, value: -8, to: today) else { return }
        
        healthKitManager.fetchSteps(from: lastWeekStart, to: lastWeekEnd) { data in
            lastWeekData = data
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000000 {
            return String(format: "%.1fM", Double(steps) / 1_000_000)
        } else if steps >= 10000 {
            return String(format: "%.1fK", Double(steps) / 1000)
        } else if steps >= 1000 {
            return String(format: "%.1fK", Double(steps) / 1000)
        }
        return "\(steps)"
    }
    
    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTime(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Supporting Views

struct EnhancedStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let isHighlighted: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        )
                }
                
                Spacer()
                
                if isHighlighted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                        Text("Goal")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(colors: [Color.green, Color.mint], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                }
            }
            
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(0.3)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(themeManager.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.05), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(color.opacity(isHighlighted ? 0.3 : 0.1), lineWidth: 1)
                )
                .shadow(color: color.opacity(isHighlighted ? 0.15 : 0.08), radius: 12, x: 0, y: 6)
        )
    }
}

struct EnhancedBarChart: View {
    let weeklySteps: [Date: Int]
    let todaySteps: Int
    let goalSteps: Int
    let animate: Bool
    
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
    
    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height - 60
            let barWidth = (width - 48) / 7
            
            VStack(spacing: 0) {
                // Goal line
                ZStack(alignment: .top) {
                    // Goal indicator line
                    let goalHeight = height * CGFloat(goalSteps) / CGFloat(maxSteps)
                    
                    HStack {
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(height: 2)
                        
                        Text("Goal")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 4)
                    }
                    .offset(y: height - goalHeight)
                    
                    // Bars
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                            let steps = stepsForDay(day)
                            let barHeight = maxSteps > 0 ? CGFloat(steps) / CGFloat(maxSteps) * height : 0
                            let reachedGoal = steps >= goalSteps
                            
                            VStack(spacing: 6) {
                                // Step count
                                Text(formatSteps(steps))
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(reachedGoal ? .green : themeManager.accentColor)
                                    .opacity(animate ? 1 : 0)
                                
                                // Bar
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: reachedGoal
                                                ? [.green, .mint.opacity(0.8)]
                                                : [themeManager.accentColor, themeManager.accentColor.opacity(0.5)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: barWidth - 6, height: animate ? max(8, barHeight) : 8)
                                    .shadow(color: (reachedGoal ? .green : themeManager.accentColor).opacity(0.3), radius: 4, y: 2)
                            }
                        }
                    }
                }
                .frame(height: height + 20)
                
                // Day labels
                HStack(spacing: 6) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                        let isToday = Calendar.current.isDateInToday(day)
                        
                        Text(dayLabel(day))
                            .font(.system(size: 11, weight: isToday ? .bold : .medium))
                            .foregroundColor(isToday ? themeManager.accentColor : themeManager.secondaryTextColor)
                            .frame(width: barWidth - 6)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 10000 {
            return String(format: "%.0fK", Double(steps) / 1000.0)
        } else if steps >= 1000 {
            return String(format: "%.1fK", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct RecordRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    let isBest: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.2), iconColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [iconColor, iconColor.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .textCase(.uppercase)
                    .tracking(0.3)
                
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
            
            if isBest {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom)
                        )
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(iconColor.opacity(0.04))
        )
    }
}

struct DetailedStatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.15), iconColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [iconColor, iconColor.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
            }
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Spacer()
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [themeManager.primaryTextColor, themeManager.primaryTextColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.cardBackgroundColor.opacity(0.5))
        )
    }
}

struct LifetimeStatBox: View {
    let value: String
    let label: String
    let icon: String
    let gradient: [Color]
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 10) {
            // Icon badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: gradient.map { $0.opacity(0.2) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                )
            
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(colors: [gradient[0].opacity(0.1), gradient[1].opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(colors: [gradient[0].opacity(0.3), gradient[1].opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: gradient[0].opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

struct MilestoneRow: View {
    let steps: Int
    let current: Int
    let label: String
    let emoji: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    private var progress: Double {
        min(1.0, Double(current) / Double(steps))
    }
    
    private var isCompleted: Bool {
        current >= steps
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon with emoji
            ZStack {
                Circle()
                    .fill(
                        isCompleted
                            ? LinearGradient(colors: [Color.green.opacity(0.2), Color.mint.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 38, height: 38)
                
                if isCompleted {
                    Text(emoji)
                        .font(.system(size: 18))
                } else {
                    Text(emoji)
                        .font(.system(size: 18))
                        .grayscale(0.8)
                        .opacity(0.5)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isCompleted ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
                    
                    if isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Text(formatMilestone(steps))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(isCompleted ? .green : themeManager.secondaryTextColor)
                }
                
                // Progress bar with animation
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray.opacity(0.12))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                isCompleted
                                    ? LinearGradient(colors: [Color.green, Color.mint], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: max(0, geometry.size.width * progress), height: 8)
                        
                        // Shimmer effect for completed
                        if isCompleted {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0), Color.white.opacity(0.4), Color.white.opacity(0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * 0.3, height: 8)
                        }
                    }
                }
                .frame(height: 8)
                
                // Progress text
                if !isCompleted {
                    Text("\(formatMilestone(current)) / \(formatMilestone(steps)) (\(Int(progress * 100))%)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor.opacity(0.8))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatMilestone(_ steps: Int) -> String {
        if steps >= 1000000 {
            return String(format: "%.1fM", Double(steps) / 1_000_000)
        } else if steps >= 1000 {
            return String(format: "%.0fK", Double(steps) / 1000)
        }
        return "\(steps)"
    }
}

struct InsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let description: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.2), iconColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [iconColor, iconColor.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    if !value.isEmpty {
                        Text(value)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [iconColor, iconColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                            )
                    }
                }
                
                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
                    .lineSpacing(1)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [iconColor.opacity(0.08), iconColor.opacity(0.04)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(iconColor.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

struct InsightFeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.green)
        }
    }
}

// MARK: - Preview
#Preview {
    InsightsView()
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
        .environmentObject(UserSettings())
        .environmentObject(StepDataManager())
}
