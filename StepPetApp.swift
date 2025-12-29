//
//  StepPetApp.swift
//  StepPet
//
//  Your steps keep your pet healthy.
//

import SwiftUI
import SwiftData

@main
struct StepPetApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var userSettings = UserSettings()
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var stepDataManager = StepDataManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if userSettings.hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(themeManager)
            .environmentObject(healthKitManager)
            .environmentObject(userSettings)
            .environmentObject(achievementManager)
            .environmentObject(stepDataManager)
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            .onAppear {
                setupApp()
            }
        }
    }
    
    private func setupApp() {
        // Only request authorization if onboarding is complete
        if userSettings.hasCompletedOnboarding {
            healthKitManager.requestAuthorization()
        }
        
        // Load saved data
        stepDataManager.loadData()
        achievementManager.loadAchievements()
        
        // Setup notifications if enabled
        if userSettings.notificationsEnabled {
            NotificationManager.shared.requestAuthorization()
            NotificationManager.shared.updateScheduledNotifications(
                petName: userSettings.pet.name,
                enabled: userSettings.notificationsEnabled,
                reminderTime: userSettings.reminderTime
            )
        }
        
        // Check for daily reset
        checkDailyReset()
        
        // Track app sections visited for achievement
        achievementManager.updateProgress(achievementId: "explorer", progress: 1)
    }
    
    private func checkDailyReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastGoalDate = userSettings.streakData.lastGoalAchievedDate {
            let lastGoalDay = calendar.startOfDay(for: lastGoalDate)
            let daysDifference = calendar.dateComponents([.day], from: lastGoalDay, to: today).day ?? 0
            
            // If more than 1 day has passed without achieving goal, reset streak
            if daysDifference > 1 {
                userSettings.streakData.currentStreak = 0
            }
        }
    }
}
