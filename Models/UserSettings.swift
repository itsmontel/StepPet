//
//  UserSettings.swift
//  VirtuPet
//

import Foundation
import SwiftUI

class UserSettings: ObservableObject {
    @Published var userName: String {
        didSet { save() }
    }
    @Published var pet: Pet {
        didSet { save() }
    }
    @Published var dailyStepGoal: Int {
        didSet { save() }
    }
    @Published var isPremium: Bool {
        didSet { save() }
    }
    @Published var notificationsEnabled: Bool {
        didSet { save() }
    }
    @Published var hapticsEnabled: Bool {
        didSet {
            save()
            // Sync with global HapticFeedback setting
            HapticFeedback.isEnabled = hapticsEnabled
        }
    }
    @Published var reminderTime: Date {
        didSet { save() }
    }
    @Published var goalCelebrations: Bool {
        didSet { save() }
    }
    @Published var streakData: StreakData {
        didSet { save() }
    }
    @Published var firstLaunchDate: Date? {
        didSet { save() }
    }
    @Published var petsUsed: Set<String> {
        didSet { save() }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { save() }
    }
    @Published var playCredits: Int {
        didSet { save() }
    }
    @Published var dailyFreeCredits: Int {
        didSet { save() }
    }
    @Published var lastDailyCreditsDate: Date? {
        didSet { save() }
    }
    @Published var todayPlayHealthBoost: Int {
        didSet { save() }
    }
    @Published var lastPlayBoostDate: Date? {
        didSet { save() }
    }
    @Published var hasCompletedAppTutorial: Bool {
        didSet { save() }
    }
    @Published var hasSeenPaywall: Bool {
        didSet { save() }
    }
    @Published var accentColorTheme: String {
        didSet { save() }
    }
    
    // Achievement tracking properties
    @Published var previousHealthForAchievement: Int {
        didSet { save() }
    }
    @Published var consecutiveFullHealthDays: Int {
        didSet { save() }
    }
    @Published var consecutiveHealthyDays: Int {
        didSet { save() }
    }
    @Published var consecutiveNoSickDays: Int {
        didSet { save() }
    }
    @Published var rescueCount: Int {
        didSet { save() }
    }
    @Published var lastHealthCheckDate: Date? {
        didSet { save() }
    }
    
    private let userDefaultsKey = "StepPetUserSettings"
    
    init() {
        // Load saved settings or use defaults
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedSettings = try? JSONDecoder().decode(SavedUserSettings.self, from: data) {
            self.userName = savedSettings.userName
            self.pet = savedSettings.pet
            self.dailyStepGoal = savedSettings.dailyStepGoal
            self.isPremium = savedSettings.isPremium
            self.notificationsEnabled = savedSettings.notificationsEnabled
            self.hapticsEnabled = savedSettings.hapticsEnabled
            self.reminderTime = savedSettings.reminderTime
            self.goalCelebrations = savedSettings.goalCelebrations
            self.streakData = savedSettings.streakData
            self.firstLaunchDate = savedSettings.firstLaunchDate
            self.petsUsed = savedSettings.petsUsed
            self.hasCompletedOnboarding = savedSettings.hasCompletedOnboarding
            self.playCredits = savedSettings.playCredits
            self.dailyFreeCredits = savedSettings.dailyFreeCredits ?? (savedSettings.isPremium ? 10 : 5)
            self.lastDailyCreditsDate = savedSettings.lastDailyCreditsDate
            self.todayPlayHealthBoost = savedSettings.todayPlayHealthBoost
            self.lastPlayBoostDate = savedSettings.lastPlayBoostDate
            self.hasCompletedAppTutorial = savedSettings.hasCompletedAppTutorial ?? false
            self.hasSeenPaywall = savedSettings.hasSeenPaywall ?? false
            self.accentColorTheme = savedSettings.accentColorTheme ?? "Sunset Glow"
            
            // Achievement tracking properties
            self.previousHealthForAchievement = savedSettings.previousHealthForAchievement ?? 0
            self.consecutiveFullHealthDays = savedSettings.consecutiveFullHealthDays ?? 0
            self.consecutiveHealthyDays = savedSettings.consecutiveHealthyDays ?? 0
            self.consecutiveNoSickDays = savedSettings.consecutiveNoSickDays ?? 0
            self.rescueCount = savedSettings.rescueCount ?? 0
            self.lastHealthCheckDate = savedSettings.lastHealthCheckDate
            
            // Reset daily boost if it's a new day
            if let lastDate = lastPlayBoostDate, !Calendar.current.isDateInToday(lastDate) {
                self.todayPlayHealthBoost = 0
                self.lastPlayBoostDate = nil
            }
            
            // Reset daily free credits if it's a new day (5 for free, 10 for premium)
            if let lastCreditsDate = lastDailyCreditsDate, !Calendar.current.isDateInToday(lastCreditsDate) {
                self.dailyFreeCredits = self.isPremium ? 10 : 5
                self.lastDailyCreditsDate = Date()
            } else if lastDailyCreditsDate == nil {
                self.dailyFreeCredits = self.isPremium ? 10 : 5
                self.lastDailyCreditsDate = Date()
            }
        } else {
            // Default values
            self.userName = "Friend"
            self.pet = Pet(type: .dog, name: "Buddy") // Dog is the main free pet
            self.dailyStepGoal = 10000
            self.isPremium = false
            self.notificationsEnabled = true
            self.hapticsEnabled = true
            self.reminderTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
            self.goalCelebrations = true
            self.streakData = StreakData()
            self.firstLaunchDate = Date()
            self.petsUsed = Set([PetType.dog.rawValue]) // Dog is the main free pet
            self.hasCompletedOnboarding = false
            self.playCredits = 0 // Purchased credits start at 0
            self.dailyFreeCredits = 5 // 5 free credits daily for free users (10 for premium)
            self.lastDailyCreditsDate = Date()
            self.todayPlayHealthBoost = 0
            self.lastPlayBoostDate = nil
            self.hasCompletedAppTutorial = false
            self.hasSeenPaywall = false
            self.accentColorTheme = "Sunset Glow"
            
            // Achievement tracking properties - defaults
            self.previousHealthForAchievement = 0
            self.consecutiveFullHealthDays = 0
            self.consecutiveHealthyDays = 0
            self.consecutiveNoSickDays = 0
            self.rescueCount = 0
            self.lastHealthCheckDate = nil
        }
        
        // Sync haptics setting with global HapticFeedback
        HapticFeedback.isEnabled = self.hapticsEnabled
    }
    
    // Total available credits (daily free + purchased)
    var totalCredits: Int {
        return dailyFreeCredits + playCredits
    }
    
    // Use a credit for playing a minigame (+3 health)
    func useGameCredit() -> Bool {
        guard totalCredits > 0 else { return false }
        
        // Use daily free credits first, then purchased
        if dailyFreeCredits > 0 {
            dailyFreeCredits -= 1
        } else {
            playCredits -= 1
        }
        
        todayPlayHealthBoost += 3
        lastPlayBoostDate = Date()
        pet.health = min(100, pet.health + 3)
        save()
        return true
    }
    
    // Use a credit for pet activity (+5 health)
    func useActivityCredit() -> Bool {
        guard totalCredits > 0 else { return false }
        
        // Use daily free credits first, then purchased
        if dailyFreeCredits > 0 {
            dailyFreeCredits -= 1
        } else {
            playCredits -= 1
        }
        
        todayPlayHealthBoost += 5
        lastPlayBoostDate = Date()
        pet.health = min(100, pet.health + 5)
        save()
        return true
    }
    
    // Legacy method - kept for compatibility, uses activity credit
    func usePlayCredit() -> Bool {
        return useActivityCredit()
    }
    
    // Daily credits based on premium status
    var dailyCreditsAllowance: Int {
        return isPremium ? 10 : 5
    }
    
    // Check if it's a new day and reset daily boost and credits
    func checkAndResetDailyBoost() {
        var needsSave = false
        
        if let lastDate = lastPlayBoostDate, !Calendar.current.isDateInToday(lastDate) {
            todayPlayHealthBoost = 0
            lastPlayBoostDate = nil
            needsSave = true
        }
        
        // Reset daily free credits at midnight (5 for free, 10 for premium)
        if let lastCreditsDate = lastDailyCreditsDate, !Calendar.current.isDateInToday(lastCreditsDate) {
            dailyFreeCredits = dailyCreditsAllowance
            lastDailyCreditsDate = Date()
            needsSave = true
        }
        
        if needsSave {
            save()
        }
    }
    
    func save() {
        let settings = SavedUserSettings(
            userName: userName,
            pet: pet,
            dailyStepGoal: dailyStepGoal,
            isPremium: isPremium,
            notificationsEnabled: notificationsEnabled,
            hapticsEnabled: hapticsEnabled,
            reminderTime: reminderTime,
            goalCelebrations: goalCelebrations,
            streakData: streakData,
            firstLaunchDate: firstLaunchDate,
            petsUsed: petsUsed,
            hasCompletedOnboarding: hasCompletedOnboarding,
            playCredits: playCredits,
            dailyFreeCredits: dailyFreeCredits,
            lastDailyCreditsDate: lastDailyCreditsDate,
            todayPlayHealthBoost: todayPlayHealthBoost,
            lastPlayBoostDate: lastPlayBoostDate,
            hasCompletedAppTutorial: hasCompletedAppTutorial,
            hasSeenPaywall: hasSeenPaywall,
            accentColorTheme: accentColorTheme,
            previousHealthForAchievement: previousHealthForAchievement,
            consecutiveFullHealthDays: consecutiveFullHealthDays,
            consecutiveHealthyDays: consecutiveHealthyDays,
            consecutiveNoSickDays: consecutiveNoSickDays,
            rescueCount: rescueCount,
            lastHealthCheckDate: lastHealthCheckDate
        )
        
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func changePet(to type: PetType, newName: String? = nil) {
        pet.type = type
        if let name = newName {
            pet.name = name
        }
        petsUsed.insert(type.rawValue)
        save()
    }
    
    func updatePetHealth(steps: Int) {
        // Track previous health for achievement checks
        let oldHealth = pet.health
        
        // Calculate step-based health
        let stepHealth = dailyStepGoal > 0 ? Int((Double(steps) / Double(dailyStepGoal)) * 100) : 0
        // Add play activity boosts (capped at 100)
        let newHealth = min(100, stepHealth + todayPlayHealthBoost)
        pet.health = newHealth
        
        // Update achievement tracking on new day
        updateHealthAchievementTracking(oldHealth: oldHealth, newHealth: newHealth)
        
        save()
    }
    
    // MARK: - Update Health Achievement Tracking
    func updateHealthAchievementTracking(oldHealth: Int, newHealth: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if it's a new day
        let isNewDay: Bool
        if let lastCheck = lastHealthCheckDate {
            isNewDay = !calendar.isDate(lastCheck, inSameDayAs: today)
        } else {
            isNewDay = true
        }
        
        // Only update daily tracking once per day
        if isNewDay {
            // Check if we had full health yesterday
            if previousHealthForAchievement == 100 {
                consecutiveFullHealthDays += 1
            } else {
                consecutiveFullHealthDays = 0
            }
            
            // Check if we had healthy (60%+) status yesterday
            if previousHealthForAchievement >= 60 {
                consecutiveHealthyDays += 1
            } else {
                consecutiveHealthyDays = 0
            }
            
            // Check if we were NOT sick (>20%) yesterday
            if previousHealthForAchievement > 20 {
                consecutiveNoSickDays += 1
            } else {
                consecutiveNoSickDays = 0
            }
            
            lastHealthCheckDate = Date()
        }
        
        // Track rescue count - recovered from sick to healthy
        if oldHealth <= 20 && newHealth >= 60 {
            rescueCount += 1
        }
        
        // Update previous health for next check
        previousHealthForAchievement = newHealth
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }
    
    var activityLevel: ActivityLevel {
        switch dailyStepGoal {
        case 0..<6000: return .sedentary
        case 6000..<8500: return .lightlyActive
        case 8500..<11000: return .active
        default: return .veryActive
        }
    }
}

// MARK: - Saved Settings Structure
struct SavedUserSettings: Codable {
    var userName: String
    var pet: Pet
    var dailyStepGoal: Int
    var isPremium: Bool
    var notificationsEnabled: Bool
    var hapticsEnabled: Bool
    var reminderTime: Date
    var goalCelebrations: Bool
    var streakData: StreakData
    var firstLaunchDate: Date?
    var petsUsed: Set<String>
    var hasCompletedOnboarding: Bool
    var playCredits: Int
    var dailyFreeCredits: Int?
    var lastDailyCreditsDate: Date?
    var todayPlayHealthBoost: Int
    var lastPlayBoostDate: Date?
    var hasCompletedAppTutorial: Bool?
    var hasSeenPaywall: Bool?
    var accentColorTheme: String?
    
    // Achievement tracking
    var previousHealthForAchievement: Int?
    var consecutiveFullHealthDays: Int?
    var consecutiveHealthyDays: Int?
    var consecutiveNoSickDays: Int?
    var rescueCount: Int?
    var lastHealthCheckDate: Date?
}

// MARK: - Activity Level
enum ActivityLevel: String, CaseIterable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case active = "Active"
    case veryActive = "Very Active"
    
    var recommendedGoal: Int {
        switch self {
        case .sedentary: return 5000
        case .lightlyActive: return 7500
        case .active: return 10000
        case .veryActive: return 12500
        }
    }
}

