//
//  InsightsView.swift
//  StepPet
//

import SwiftUI

enum TimePeriod: String, CaseIterable {
    case week = "7 days"
    case month = "30 days"
    case sixMonths = "6 months"
    case year = "1 year"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .sixMonths: return 180
        case .year: return 365
        }
    }
}

struct InsightsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var stepDataManager: StepDataManager
    
    @State private var selectedPeriod: TimePeriod = .week
    @State private var historicalData: [Date: Int] = [:]
    @State private var isLoading = false
    
    private var totalSteps: Int {
        if selectedPeriod == .week {
            return healthKitManager.totalWeeklySteps
        }
        return historicalData.values.reduce(0, +)
    }
    
    private var averageSteps: Int {
        let data = selectedPeriod == .week ? healthKitManager.weeklySteps : historicalData
        guard !data.isEmpty else { return 0 }
        return data.values.reduce(0, +) / max(1, data.count)
    }
    
    private var bestDay: (date: Date, steps: Int)? {
        let data = selectedPeriod == .week ? healthKitManager.weeklySteps : historicalData
        guard let best = data.max(by: { $0.value < $1.value }) else { return nil }
        return (best.key, best.value)
    }
    
    private var goalsAchieved: Int {
        let data = selectedPeriod == .week ? healthKitManager.weeklySteps : historicalData
        return data.values.filter { $0 >= userSettings.dailyStepGoal }.count
    }
    
    private var lifetimeSteps: Int {
        stepDataManager.totalStepsAllTime + healthKitManager.todaySteps
    }
    
    private var lifetimeMiles: Double {
        Double(lifetimeSteps) * 2.5 / 5280
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerSection
                timePeriodPicker
                mainStatsSection
                
                if selectedPeriod == .week {
                    weeklyBarChart
                }
                
                detailedStatsSection
                lifetimeStatsSection
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .onAppear {
            healthKitManager.fetchWeeklySteps()
            loadDataForPeriod()
        }
        .onChange(of: selectedPeriod) { _, _ in
            loadDataForPeriod()
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Insights")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Your step journey")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Pet mascot - using actual pet animation
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
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                    HapticFeedback.light.trigger()
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: selectedPeriod == period ? .bold : .medium))
                        .foregroundColor(selectedPeriod == period ? .white : themeManager.primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedPeriod == period ? themeManager.accentColor : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Main Stats Section
    private var mainStatsSection: some View {
        HStack(spacing: 12) {
            // Average Steps
            InsightStatCard(
                title: "Average",
                value: formatSteps(averageSteps),
                subtitle: "steps/day",
                icon: "chart.line.uptrend.xyaxis",
                color: themeManager.accentColor,
                trend: averageSteps >= userSettings.dailyStepGoal ? .up : .neutral
            )
            
            // Total Steps
            InsightStatCard(
                title: "Total",
                value: formatSteps(totalSteps),
                subtitle: "steps",
                icon: "figure.walk",
                color: .purple,
                trend: .neutral
            )
        }
    }
    
    // MARK: - Weekly Bar Chart
    private var weeklyBarChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 7 Days")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            WeeklyInsightChart(
                weeklySteps: healthKitManager.weeklySteps,
                todaySteps: healthKitManager.todaySteps,
                goalSteps: userSettings.dailyStepGoal
            )
            .frame(height: 160)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.accentColor.opacity(0.08))
        )
    }
    
    // MARK: - Detailed Stats Section
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            // Best Day
            if let best = bestDay {
                DetailRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Best Day",
                    value: formatSteps(best.steps),
                    subtitle: formatDate(best.date)
                )
            }
            
            // Goals Achieved
            DetailRow(
                icon: "target",
                iconColor: .green,
                title: "Goals Achieved",
                value: "\(goalsAchieved)",
                subtitle: "out of \(selectedPeriod.days) days"
            )
            
            // Distance
            let distance = Double(totalSteps) * 2.5 / 5280
            DetailRow(
                icon: "map.fill",
                iconColor: .orange,
                title: "Distance Walked",
                value: String(format: "%.1f", distance),
                subtitle: "miles"
            )
            
            // Calories
            let calories = Int(Double(totalSteps) * 0.04)
            DetailRow(
                icon: "flame.fill",
                iconColor: .red,
                title: "Calories Burned",
                value: formatNumber(calories),
                subtitle: "estimated"
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.orange.opacity(0.08))
        )
    }
    
    // MARK: - Lifetime Stats Section
    private var lifetimeStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Lifetime")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                AnimatedPetVideoView(
                    petType: userSettings.pet.type,
                    moodState: .fullHealth
                )
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            }
            
            HStack(spacing: 12) {
                // Lifetime Steps
                VStack(spacing: 8) {
                    Text(formatSteps(lifetimeSteps))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.accentColor)
                    
                    Text("Total Steps")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.accentColor.opacity(0.08))
                )
                
                // Lifetime Miles
                VStack(spacing: 8) {
                    Text(String(format: "%.0f", lifetimeMiles))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.purple)
                    
                    Text("Total Miles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.08))
                )
            }
            
            // Fun fact
            if lifetimeMiles > 10 {
                HStack(spacing: 8) {
                    Text("💡")
                        .font(.system(size: 16))
                    
                    Text(funFact)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.primaryTextColor)
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
                .fill(Color.purple.opacity(0.08))
        )
    }
    
    private var funFact: String {
        if lifetimeMiles > 2500 {
            return "That's further than walking across the USA! 🇺🇸"
        } else if lifetimeMiles > 1000 {
            return "You've walked the length of California! 🌴"
        } else if lifetimeMiles > 500 {
            return "That's like walking from LA to San Francisco! 🌉"
        } else if lifetimeMiles > 100 {
            return "You've walked a marathon distance \(Int(lifetimeMiles / 26)) times! 🏃"
        } else if lifetimeMiles > 26 {
            return "You've walked more than a marathon! 🎉"
        } else {
            return "Keep going! You're building great habits! 💪"
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
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000000 {
            return String(format: "%.1fM", Double(steps) / 1_000_000)
        } else if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000)
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
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Insight Stat Card
struct InsightStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: Trend
    
    enum Trend {
        case up, down, neutral
    }
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                if trend != .neutral {
                    Image(systemName: trend == .up ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(trend == .up ? .green : .orange)
                }
            }
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Weekly Insight Chart
struct WeeklyInsightChart: View {
    let weeklySteps: [Date: Int]
    let todaySteps: Int
    let goalSteps: Int
    
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
    
    private func dayLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height - 30
            let barWidth: CGFloat = (width - 60) / CGFloat(weekDays.count)
            let spacing: CGFloat = 8
            
            VStack(spacing: 0) {
                // Bars
                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                        let steps = stepsForDay(day)
                        let barHeight = maxSteps > 0 ? CGFloat(steps) / CGFloat(maxSteps) * height : 0
                        let reachedGoal = steps >= goalSteps
                        let isToday = Calendar.current.isDateInToday(day)
                        
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    reachedGoal
                                        ? LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: barWidth - spacing, height: max(4, barHeight))
                                .animation(.spring(response: 0.5), value: steps)
                            
                            Text(dayLetter(day))
                                .font(.system(size: 11, weight: isToday ? .bold : .medium))
                                .foregroundColor(isToday ? themeManager.accentColor : themeManager.secondaryTextColor)
                        }
                    }
                }
                .frame(height: height + 20)
            }
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

