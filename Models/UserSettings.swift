//
//  UserSettings.swift
//  StepPet
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
        didSet { save() }
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
    @Published var todayPlayHealthBoost: Int {
        didSet { save() }
    }
    @Published var lastPlayBoostDate: Date? {
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
            self.todayPlayHealthBoost = savedSettings.todayPlayHealthBoost
            self.lastPlayBoostDate = savedSettings.lastPlayBoostDate
            
            // Reset daily boost if it's a new day
            if let lastDate = lastPlayBoostDate, !Calendar.current.isDateInToday(lastDate) {
                self.todayPlayHealthBoost = 0
                self.lastPlayBoostDate = nil
            }
        } else {
            // Default values
            self.userName = "Friend"
            self.pet = Pet(type: .cat, name: "Whiskers") // Cat is the main free pet
            self.dailyStepGoal = 10000
            self.isPremium = false
            self.notificationsEnabled = true
            self.hapticsEnabled = true
            self.reminderTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
            self.goalCelebrations = true
            self.streakData = StreakData()
            self.firstLaunchDate = Date()
            self.petsUsed = Set([PetType.cat.rawValue]) // Cat is the main free pet
            self.hasCompletedOnboarding = false
            self.playCredits = 3 // Welcome bonus!
            self.todayPlayHealthBoost = 0
            self.lastPlayBoostDate = nil
        }
    }
    
    // Use a play credit and boost health
    func usePlayCredit() -> Bool {
        guard playCredits > 0 else { return false }
        playCredits -= 1
        todayPlayHealthBoost += 20
        lastPlayBoostDate = Date()
        pet.health = min(100, pet.health + 20)
        save()
        return true
    }
    
    // Check if it's a new day and reset daily boost
    func checkAndResetDailyBoost() {
        if let lastDate = lastPlayBoostDate, !Calendar.current.isDateInToday(lastDate) {
            todayPlayHealthBoost = 0
            lastPlayBoostDate = nil
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
            todayPlayHealthBoost: todayPlayHealthBoost,
            lastPlayBoostDate: lastPlayBoostDate
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
        // Calculate step-based health
        let stepHealth = dailyStepGoal > 0 ? Int((Double(steps) / Double(dailyStepGoal)) * 100) : 0
        // Add play activity boosts (capped at 100)
        pet.health = min(100, stepHealth + todayPlayHealthBoost)
        save()
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
    var todayPlayHealthBoost: Int
    var lastPlayBoostDate: Date?
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

