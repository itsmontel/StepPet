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
        todaySteps: Int,
        goalSteps: Int,
        health: Int,
        streak: Int
    ) {
        guard let defaults = sharedDefaults else {
            print("⚠️ WidgetDataManager: Could not access App Group UserDefaults")
            return
        }
        
        defaults.set(petType, forKey: "widgetPetType")
        defaults.set(petMood, forKey: "widgetPetMood")
        defaults.set(petName, forKey: "widgetPetName")
        defaults.set(todaySteps, forKey: "widgetTodaySteps")
        defaults.set(goalSteps, forKey: "widgetGoalSteps")
        defaults.set(health, forKey: "widgetHealth")
        defaults.set(streak, forKey: "widgetStreak")
        
        // Force synchronize
        defaults.synchronize()
        
        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()
        
        print("✅ Widget data updated: \(petName) the \(petType), \(todaySteps)/\(goalSteps) steps, \(health)% health")
    }
    
    /// Convenience method using UserSettings
    func syncFromUserSettings(_ userSettings: UserSettings, todaySteps: Int) {
        let petType = userSettings.pet.type.rawValue.lowercased()
        let petMood = userSettings.pet.moodState.rawValue.lowercased()
        let petName = userSettings.pet.name
        let goalSteps = userSettings.dailyStepGoal
        let health = userSettings.pet.health
        let streak = userSettings.streakData.currentStreak
        
        updateWidgetData(
            petType: petType,
            petMood: petMood,
            petName: petName,
            todaySteps: todaySteps,
            goalSteps: goalSteps,
            health: health,
            streak: streak
        )
    }
}


