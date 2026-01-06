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
    
    // Game & Activity tracking properties
    @Published var totalMinigamesPlayed: Int {
        didSet { save() }
    }
    @Published var totalPetActivitiesPlayed: Int {
        didSet { save() }
    }
    @Published var moodCatchPlayed: Int {
        didSet { save() }
    }
    @Published var memoryMatchPlayed: Int {
        didSet { save() }
    }
    @Published var skyDashPlayed: Int {
        didSet { save() }
    }
    @Published var patternMatchPlayed: Int {
        didSet { save() }
    }
    @Published var feedActivityCount: Int {
        didSet { save() }
    }
    @Published var playBallActivityCount: Int {
        didSet { save() }
    }
    @Published var watchTVActivityCount: Int {
        didSet { save() }
    }
    @Published var totalCreditsUsed: Int {
        didSet { save() }
    }
    @Published var consecutiveGameDays: Int {
        didSet { save() }
    }
    @Published var lastGamePlayDate: Date? {
        didSet { save() }
    }
    @Published var todayFedPet: Bool {
        didSet { save() }
    }
    @Published var todayPlayedBall: Bool {
        didSet { save() }
    }
    @Published var todayWatchedTV: Bool {
        didSet { save() }
    }
    @Published var lastActivityDate: Date? {
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
            
            // Game & Activity tracking properties
            self.totalMinigamesPlayed = savedSettings.totalMinigamesPlayed ?? 0
            self.totalPetActivitiesPlayed = savedSettings.totalPetActivitiesPlayed ?? 0
            self.moodCatchPlayed = savedSettings.moodCatchPlayed ?? 0
            self.memoryMatchPlayed = savedSettings.memoryMatchPlayed ?? 0
            self.skyDashPlayed = savedSettings.skyDashPlayed ?? 0
            self.patternMatchPlayed = savedSettings.patternMatchPlayed ?? 0
            self.feedActivityCount = savedSettings.feedActivityCount ?? 0
            self.playBallActivityCount = savedSettings.playBallActivityCount ?? 0
            self.watchTVActivityCount = savedSettings.watchTVActivityCount ?? 0
            self.totalCreditsUsed = savedSettings.totalCreditsUsed ?? 0
            self.consecutiveGameDays = savedSettings.consecutiveGameDays ?? 0
            self.lastGamePlayDate = savedSettings.lastGamePlayDate
            self.todayFedPet = savedSettings.todayFedPet ?? false
            self.todayPlayedBall = savedSettings.todayPlayedBall ?? false
            self.todayWatchedTV = savedSettings.todayWatchedTV ?? false
            self.lastActivityDate = savedSettings.lastActivityDate
            
            // Reset daily activity tracking if it's a new day
            if let lastActDate = lastActivityDate, !Calendar.current.isDateInToday(lastActDate) {
                self.todayFedPet = false
                self.todayPlayedBall = false
                self.todayWatchedTV = false
            }
            
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
            
            // Game & Activity tracking properties - defaults
            self.totalMinigamesPlayed = 0
            self.totalPetActivitiesPlayed = 0
            self.moodCatchPlayed = 0
            self.memoryMatchPlayed = 0
            self.skyDashPlayed = 0
            self.patternMatchPlayed = 0
            self.feedActivityCount = 0
            self.playBallActivityCount = 0
            self.watchTVActivityCount = 0
            self.totalCreditsUsed = 0
            self.consecutiveGameDays = 0
            self.lastGamePlayDate = nil
            self.todayFedPet = false
            self.todayPlayedBall = false
            self.todayWatchedTV = false
            self.lastActivityDate = nil
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
            lastHealthCheckDate: lastHealthCheckDate,
            totalMinigamesPlayed: totalMinigamesPlayed,
            totalPetActivitiesPlayed: totalPetActivitiesPlayed,
            moodCatchPlayed: moodCatchPlayed,
            memoryMatchPlayed: memoryMatchPlayed,
            skyDashPlayed: skyDashPlayed,
            patternMatchPlayed: patternMatchPlayed,
            feedActivityCount: feedActivityCount,
            playBallActivityCount: playBallActivityCount,
            watchTVActivityCount: watchTVActivityCount,
            totalCreditsUsed: totalCreditsUsed,
            consecutiveGameDays: consecutiveGameDays,
            lastGamePlayDate: lastGamePlayDate,
            todayFedPet: todayFedPet,
            todayPlayedBall: todayPlayedBall,
            todayWatchedTV: todayWatchedTV,
            lastActivityDate: lastActivityDate
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
    
    // MARK: - Game & Activity Tracking Methods
    
    enum MinigameType: String {
        case moodCatch = "mood_catch"
        case memoryMatch = "memory_match"
        case skyDash = "sky_dash"
        case patternMatch = "pattern_match"
    }
    
    enum PetActivityType: String {
        case feed = "feed"
        case playBall = "play_ball"
        case watchTV = "watch_tv"
    }
    
    func recordMinigamePlayed(type: MinigameType) {
        totalMinigamesPlayed += 1
        totalCreditsUsed += 1
        
        // Track specific game
        switch type {
        case .moodCatch:
            moodCatchPlayed += 1
        case .memoryMatch:
            memoryMatchPlayed += 1
        case .skyDash:
            skyDashPlayed += 1
        case .patternMatch:
            patternMatchPlayed += 1
        }
        
        // Track consecutive game days
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = lastGamePlayDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                // Consecutive day
                consecutiveGameDays += 1
            } else if daysDiff > 1 {
                // Streak broken
                consecutiveGameDays = 1
            }
            // daysDiff == 0 means same day, don't increment
        } else {
            consecutiveGameDays = 1
        }
        lastGamePlayDate = Date()
        
        save()
    }
    
    func recordPetActivity(type: PetActivityType) {
        totalPetActivitiesPlayed += 1
        totalCreditsUsed += 1
        
        // Track specific activity
        switch type {
        case .feed:
            feedActivityCount += 1
            todayFedPet = true
        case .playBall:
            playBallActivityCount += 1
            todayPlayedBall = true
        case .watchTV:
            watchTVActivityCount += 1
            todayWatchedTV = true
        }
        
        lastActivityDate = Date()
        save()
    }
    
    // Check if all 3 activities were done today
    var didAllActivitiesToday: Bool {
        return todayFedPet && todayPlayedBall && todayWatchedTV
    }
    
    // Reset daily activity tracking
    func checkAndResetDailyActivityTracking() {
        if let lastDate = lastActivityDate, !Calendar.current.isDateInToday(lastDate) {
            todayFedPet = false
            todayPlayedBall = false
            todayWatchedTV = false
            save()
        }
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
    
    // Game & Activity tracking
    var totalMinigamesPlayed: Int?
    var totalPetActivitiesPlayed: Int?
    var moodCatchPlayed: Int?
    var memoryMatchPlayed: Int?
    var skyDashPlayed: Int?
    var patternMatchPlayed: Int?
    var feedActivityCount: Int?
    var playBallActivityCount: Int?
    var watchTVActivityCount: Int?
    var totalCreditsUsed: Int?
    var consecutiveGameDays: Int?
    var lastGamePlayDate: Date?
    var todayFedPet: Bool?
    var todayPlayedBall: Bool?
    var todayWatchedTV: Bool?
    var lastActivityDate: Date?
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

