//
//  HistoryView.swift
//  StepPet
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var stepDataManager: StepDataManager
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday
        guard let startOfWeek = calendar.date(from: components) else { return [] }
        
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private var weeklyAverage: Int {
        let steps = healthKitManager.weeklySteps.values
        guard !steps.isEmpty else { return 0 }
        return steps.reduce(0, +) / steps.count
    }
    
    private var bestDayThisWeek: (day: String, steps: Int)? {
        guard let best = healthKitManager.weeklySteps.max(by: { $0.value < $1.value }) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return (formatter.string(from: best.key), best.value)
    }
    
    private var dateRangeString: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday
        guard let startOfWeek = calendar.date(from: components) else { return "" }
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else { return "" }
        
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = ", yyyy"
        
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))\(yearFormatter.string(from: endOfWeek))"
    }
    
    private var focusScore: String {
        let goalsHit = healthKitManager.weeklySteps.values.filter { $0 >= userSettings.dailyStepGoal }.count
        let total = healthKitManager.weeklySteps.count
        guard total > 0 else { return "N/A" }
        
        let percentage = Double(goalsHit) / Double(max(1, total))
        
        switch percentage {
        case 0.9...1.0: return "A"
        case 0.8..<0.9: return "B"
        case 0.7..<0.8: return "C"
        case 0.6..<0.7: return "D"
        default: return "F"
        }
    }
    
    private var goalsHitCount: Int {
        healthKitManager.weeklySteps.values.filter { $0 >= userSettings.dailyStepGoal }.count
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Weekly Discipline Banner
                weeklyDisciplineBanner
                
                // Weekly Highlights Section
                weeklyHighlightsSection
                
                // This Week's Activity Header
                thisWeekActivityHeader
                
                // This Week Calendar Section
                thisWeekSection
                
                // Summary Cards
                summaryCardsSection
                
                // Focus Score
                focusScoreSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .onAppear {
            healthKitManager.fetchWeeklySteps()
            healthKitManager.fetchMonthlySteps()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stats")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(dateRangeString)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.primaryTextColor)
            
            Text("This week")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }
    
    // MARK: - Weekly Discipline Banner
    private var weeklyDisciplineBanner: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Weekly Discipline")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Track your step count and focus habits.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Pet Image
            let imageName = userSettings.pet.type.imageName(for: .content)
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 85, height: 85)
            } else {
                AnimatedPetView(petType: userSettings.pet.type, moodState: .content)
                    .frame(width: 85, height: 85)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Weekly Highlights Section
    private var weeklyHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Highlights")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("Your achievements this week")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text("✨")
                        .font(.system(size: 18))
                }
            }
            
            // Highlight Cards Row
            HStack(spacing: 12) {
                // Total Steps Card
                HighlightCard(
                    value: formatStepsShort(healthKitManager.totalWeeklySteps),
                    title: "Total Steps",
                    subtitle: "This week",
                    iconName: "figure.walk",
                    iconColor: .pink
                )
                
                // Goals Hit Card
                HighlightCard(
                    value: "\(goalsHitCount)",
                    title: "Goals Hit",
                    subtitle: "Out of 7 days",
                    iconName: "target",
                    iconColor: .purple
                )
            }
            
            // Streak Banner
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Text("💪")
                        .font(.system(size: 18))
                }
                
                Text("Keep going! You're building a \(userSettings.streakData.currentStreak) day streak.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.08))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - This Week's Activity Header
    private var thisWeekActivityHeader: some View {
        Text("This Week's Activity")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(themeManager.primaryTextColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
    
    // MARK: - This Week Section
    private var thisWeekSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("This Week")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("Daily step count overview")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
            }
            
            // Week Days Scrollable
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(weekDates, id: \.self) { date in
                        WeekDayCard(
                            date: date,
                            steps: healthKitManager.weeklySteps[Calendar.current.startOfDay(for: date)] ?? 0,
                            goalSteps: userSettings.dailyStepGoal,
                            petType: userSettings.pet.type,
                            isToday: Calendar.current.isDateInToday(date),
                            isFuture: date > Date()
                        )
                        .frame(width: 140) // Double the width for better visibility
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Summary Cards Section
    private var summaryCardsSection: some View {
        HStack(spacing: 12) {
            // Best Day
            SummaryCard(
                iconName: "star.fill",
                iconColor: .yellow,
                label: "Best Day",
                value: bestDayThisWeek?.day ?? "N/A",
                subtitle: bestDayThisWeek != nil ? formatStepsShort(bestDayThisWeek!.steps) : "-"
            )
            
            // Average Steps
            SummaryCard(
                iconName: "chart.line.uptrend.xyaxis",
                iconColor: .blue,
                label: "Avg Steps",
                value: formatStepsShort(weeklyAverage),
                subtitle: "This week"
            )
        }
    }
    
    // MARK: - Focus Score Section
    private var focusScoreSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Score")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Based on your habits this week")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Score Circle
            ZStack {
                Circle()
                    .fill(focusScoreColor)
                    .frame(width: 56, height: 56)
                
                Text(focusScore)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private var focusScoreColor: Color {
        switch focusScore {
        case "A": return .green
        case "B": return .orange
        case "C": return .yellow
        case "D": return .orange
        default: return .red
        }
    }
    
    private func formatStepsShort(_ steps: Int) -> String {
        if steps >= 1000 {
            let thousands = Double(steps) / 1000.0
            if thousands == Double(Int(thousands)) {
                return "\(Int(thousands))k"
            } else {
                return String(format: "%.1fk", thousands)
            }
        }
        return "\(steps)"
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let iconName: String
    let iconColor: Color
    let label: String
    let value: String
    let subtitle: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Week Day Card
struct WeekDayCard: View {
    let date: Date
    let steps: Int
    let goalSteps: Int
    let petType: PetType
    let isToday: Bool
    let isFuture: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var health: Int {
        guard goalSteps > 0 else { return 0 }
        return min(100, Int((Double(steps) / Double(goalSteps)) * 100))
    }
    
    private var moodState: PetMoodState {
        PetMoodState.from(health: health)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(dayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isToday ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
            
            Text(dayNumber)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeManager.primaryTextColor)
            
            // Pet Image
            if isFuture {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.tertiaryTextColor)
                    .frame(width: 40, height: 40)
            } else {
                let imageName = petType.imageName(for: moodState)
                if let _ = UIImage(named: imageName) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .grayscale(steps == 0 ? 1.0 : 0)
                        .opacity(steps == 0 ? 0.5 : 1.0)
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .frame(width: 40, height: 40)
                }
            }
            
            // Steps
            Text(isFuture ? "-" : formatSteps(steps))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(steps >= goalSteps ? themeManager.successColor : themeManager.primaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isToday ? themeManager.successColor.opacity(0.12) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isToday ? themeManager.successColor.opacity(0.25) : themeManager.isDarkMode ? Color.white.opacity(0.05) : Color.gray.opacity(0.08), lineWidth: 1.5)
                )
        )
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            let thousands = Double(steps) / 1000.0
            return String(format: "%.0fk", thousands)
        }
        return "\(steps)"
    }
}

// MARK: - Highlight Card
struct HighlightCard: View {
    let value: String
    let title: String
    let subtitle: String
    let iconName: String
    let iconColor: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(iconColor.opacity(0.25), lineWidth: 1.5)
        )
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
        .environmentObject(UserSettings())
        .environmentObject(StepDataManager())
}
