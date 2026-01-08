//
//  VirtuPetApp.swift
//  VirtuPet
//
//  Care for your VirtuPet by caring for yourself
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct VirtuPetApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var userSettings = UserSettings()
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var stepDataManager = StepDataManager()
    @StateObject private var purchaseManager = PurchaseManager.shared
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
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
            .environmentObject(purchaseManager)
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            .onAppear {
                setupApp()
            }
            .onChange(of: purchaseManager.isPremium) { _, isPremium in
                // Sync premium status with UserSettings
                userSettings.isPremium = isPremium
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
        }
    }
    
    private func setupApp() {
        // Configure RevenueCat
        purchaseManager.configure()
        
        // Only request authorization if onboarding is complete
        if userSettings.hasCompletedOnboarding {
            healthKitManager.requestAuthorization()
        }
        
        // Load saved data
        stepDataManager.loadData()
        achievementManager.loadAchievements()
        
        // Setup notification categories
        NotificationManager.shared.setupNotificationCategories()
        
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
        
        // Sync data to widget on app launch
        let todaySteps = stepDataManager.todayRecord?.steps ?? 0
        WidgetDataManager.shared.syncFromUserSettings(userSettings, todaySteps: todaySteps)
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
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App came to foreground - refresh data and update widgets
            if userSettings.hasCompletedOnboarding {
                healthKitManager.fetchTodaySteps()
                
                // Sync latest data to widget
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let todaySteps = healthKitManager.todaySteps
                    WidgetDataManager.shared.syncFromUserSettings(userSettings, todaySteps: todaySteps)
                }
            }
            
        case .background:
            // App went to background - ensure widgets are updated with latest data
            let todaySteps = healthKitManager.todaySteps
            WidgetDataManager.shared.syncFromUserSettings(userSettings, todaySteps: todaySteps)
            
            // Force reload all widget timelines
            WidgetCenter.shared.reloadAllTimelines()
            
        case .inactive:
            break
            
        @unknown default:
            break
        }
    }
}
