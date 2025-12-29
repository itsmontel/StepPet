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
    
    @State private var isAnimating = true
    @State private var showCalendar = false
    
    private var stepBasedHealth: Int {
        guard userSettings.dailyStepGoal > 0 else { return 0 }
        return Int((Double(healthKitManager.todaySteps) / Double(userSettings.dailyStepGoal)) * 100)
    }
    
    private var currentHealth: Int {
        // Step-based health + any play activity boosts (capped at 100)
        return min(100, stepBasedHealth + userSettings.todayPlayHealthBoost)
    }
    
    private var moodState: PetMoodState {
        PetMoodState.from(health: currentHealth)
    }
    
    private var stepsRemaining: Int {
        max(0, userSettings.dailyStepGoal - healthKitManager.todaySteps)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                // Pet Display Section
                petDisplaySection
                
                // Today's Dashboard
                dashboardSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .onAppear {
            refreshData()
        }
        .onChange(of: healthKitManager.todaySteps) { _, newValue in
            updateData(steps: newValue)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            // Date Row
            HStack {
                Button(action: { showCalendar.toggle() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? .white : themeManager.accentColor)
                        
                        Text(formattedDate)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : themeManager.cardBackgroundColor)
                    )
                }
                
                Spacer()
            }
            .padding(.top, 8)
            
            // Greeting
            Text("\(userSettings.greeting), \(userSettings.userName)")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
            
            // Pet Name and Streak
            HStack(alignment: .center) {
                Text(userSettings.pet.name)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                // Streak Badge
                streakBadge
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Streak Badge
    private var streakBadge: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text("🔥")
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(userSettings.streakData.currentStreak)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Day Streak")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Pet Display Section
    private var petDisplaySection: some View {
        VStack(spacing: 16) {
            // Pet Animation
            ZStack {
                AnimatedPetView(petType: userSettings.pet.type, moodState: moodState)
                    .frame(height: 180)
            }
            .padding(.top, 16)
            
            // Health Score
            VStack(spacing: 12) {
                Text("\(currentHealth)")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
                
                // Health Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.15))
                            .frame(height: 14)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.healthColor(for: currentHealth))
                            .frame(width: geometry.size.width * CGFloat(currentHealth) / 100, height: 14)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentHealth)
                    }
                }
                .frame(height: 14)
                .padding(.horizontal, 40)
                
                Text("Health")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Dashboard Section
    private var dashboardSection: some View {
        VStack(spacing: 16) {
            // Divider
            Rectangle()
                .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.15))
                .frame(height: 1)
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
            
            // Title
            HStack {
                Text("Today's Dashboard")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Spacer()
            }
            
            // Stats Grid
            HStack(spacing: 16) {
                // Steps Today
                DashboardCard(
                    title: "Today's Steps",
                    value: formatSteps(healthKitManager.todaySteps),
                    icon: "figure.walk",
                    iconColor: themeManager.accentColor
                )
                
                // Steps Remaining
                DashboardCard(
                    title: "Steps Left",
                    value: formatSteps(stepsRemaining),
                    icon: "flag.fill",
                    iconColor: themeManager.warningColor
                )
            }
            
            HStack(spacing: 16) {
                // Goal Progress
                DashboardCard(
                    title: "Goal Progress",
                    value: "\(min(100, Int((Double(healthKitManager.todaySteps) / Double(userSettings.dailyStepGoal)) * 100)))%",
                    icon: "target",
                    iconColor: themeManager.successColor
                )
                
                // Daily Goal
                DashboardCard(
                    title: "Daily Goal",
                    value: formatSteps(userSettings.dailyStepGoal),
                    icon: "star.fill",
                    iconColor: Color.yellow
                )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private func formatSteps(_ steps: Int) -> String {
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
    
    private func refreshData() {
        healthKitManager.fetchTodaySteps()
        healthKitManager.fetchWeeklySteps()
    }
    
    private func updateData(steps: Int) {
        userSettings.updatePetHealth(steps: steps)
        stepDataManager.updateTodayRecord(steps: steps, goalSteps: userSettings.dailyStepGoal)
        
        // Check if goal achieved
        if steps >= userSettings.dailyStepGoal {
            userSettings.streakData.updateStreak(goalAchieved: true, date: Date())
            
            // Check achievements
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
        }
    }
}

// MARK: - Dashboard Card
struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Spacer()
            }
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(1)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(themeManager.primaryTextColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.05), radius: 8, x: 0, y: 4)
        )
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

