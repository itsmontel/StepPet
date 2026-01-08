//
//  WidgetDataManager.swift
//  VirtuPet
//
//  Manages data sharing between the main app and widgets via App Groups
//

import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // App Group identifier - must match in both targets
    private let appGroupIdentifier = "group.com.yourcompany.VirtuPet"
    
    // Throttling to prevent too many widget reloads
    private var lastReloadTime: Date = .distantPast
    private let minimumReloadInterval: TimeInterval = 30 // Minimum 30 seconds between reloads
    private var pendingReload = false
    
    // Track last synced values to avoid unnecessary updates
    private var lastSyncedSteps: Int = -1
    private var lastSyncedHealth: Int = -1
    private var lastSyncedStreak: Int = -1
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    private init() {}
    
    // MARK: - Update Widget Data
    
    /// Call this whenever pet, steps, or health data changes
    func updateWidgetData(
        petType: String,
        petMood: String,
        petName: String,
        userName: String,
        todaySteps: Int,
        goalSteps: Int,
        health: Int,
        streak: Int
    ) {
        guard let defaults = sharedDefaults else {
            print("⚠️ WidgetDataManager: Could not access App Group UserDefaults")
            return
        }
        
        // Always update the shared defaults
        defaults.set(petType, forKey: "widgetPetType")
        defaults.set(petMood, forKey: "widgetPetMood")
        defaults.set(petName, forKey: "widgetPetName")
        defaults.set(userName, forKey: "widgetUserName")
        defaults.set(todaySteps, forKey: "widgetTodaySteps")
        defaults.set(goalSteps, forKey: "widgetGoalSteps")
        defaults.set(health, forKey: "widgetHealth")
        defaults.set(streak, forKey: "widgetStreak")
        defaults.set(Date(), forKey: "widgetLastUpdated")
        
        // Force synchronize
        defaults.synchronize()
        
        // Check if significant data changed (to prioritize important updates)
        let significantChange = (todaySteps != lastSyncedSteps) || 
                               (health != lastSyncedHealth) || 
                               (streak != lastSyncedStreak)
        
        if significantChange {
            lastSyncedSteps = todaySteps
            lastSyncedHealth = health
            lastSyncedStreak = streak
        }
        
        // Throttle widget reloads to prevent battery drain
        let now = Date()
        let timeSinceLastReload = now.timeIntervalSince(lastReloadTime)
        
        // Force immediate reload for significant changes, otherwise throttle
        if significantChange && timeSinceLastReload >= minimumReloadInterval {
            performWidgetReload()
        } else if !pendingReload && timeSinceLastReload < minimumReloadInterval {
            // Schedule a pending reload
            pendingReload = true
            let delay = minimumReloadInterval - timeSinceLastReload + 1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.performWidgetReload()
                self?.pendingReload = false
            }
        }
        
        print("✅ Widget data updated: \(petName) the \(petType), \(todaySteps)/\(goalSteps) steps, \(health)% health")
    }
    
    private func performWidgetReload() {
        lastReloadTime = Date()
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 Widget timelines reloaded")
    }
    
    /// Force an immediate widget reload (use sparingly)
    func forceReload() {
        performWidgetReload()
    }
    
    /// Convenience method using UserSettings
    func syncFromUserSettings(_ userSettings: UserSettings, todaySteps: Int) {
        let petType = userSettings.pet.type.rawValue.lowercased()
        let petMood = userSettings.pet.moodState.rawValue.lowercased()
        let petName = userSettings.pet.name
        let userName = userSettings.userName
        let goalSteps = userSettings.dailyStepGoal
        let health = userSettings.pet.health
        let streak = userSettings.streakData.currentStreak
        
        updateWidgetData(
            petType: petType,
            petMood: petMood,
            petName: petName,
            userName: userName,
            todaySteps: todaySteps,
            goalSteps: goalSteps,
            health: health,
            streak: streak
        )
    }
}


