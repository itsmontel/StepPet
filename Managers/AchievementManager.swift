//
//  AchievementManager.swift
//  VirtuPet
//

import Foundation
import SwiftUI

class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: Achievement?
    @Published var showUnlockAnimation: Bool = false
    
    private let userDefaultsKey = "StepPetAchievements"
    
    init() {
        loadAchievements()
    }
    
    // MARK: - Load Achievements
    func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            // Merge saved with all achievements to handle new additions
            var mergedAchievements: [Achievement] = []
            
            for achievement in Achievement.allAchievements {
                if let savedAchievement = saved.first(where: { $0.id == achievement.id }) {
                    mergedAchievements.append(savedAchievement)
                } else {
                    mergedAchievements.append(achievement)
                }
            }
            
            achievements = mergedAchievements
        } else {
            achievements = Achievement.allAchievements
        }
    }
    
    // MARK: - Save Achievements
    func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Unlock Achievement
    func unlock(achievementId: String) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId && !$0.isUnlocked }) else {
            return
        }
        
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        achievements[index].progress = achievements[index].targetProgress
        
        recentlyUnlocked = achievements[index]
        showUnlockAnimation = true
        
        saveAchievements()
        
        // Trigger haptic feedback
        HapticFeedback.success.trigger()
        
        // Hide animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUnlockAnimation = false
        }
    }
    
    // MARK: - Update Progress
    func updateProgress(achievementId: String, progress: Int) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else {
            return
        }
        
        achievements[index].progress = min(progress, achievements[index].targetProgress)
        
        // Check if achievement should be unlocked
        if achievements[index].progress >= achievements[index].targetProgress && !achievements[index].isUnlocked {
            unlock(achievementId: achievementId)
        } else {
            saveAchievements()
        }
    }
    
    // MARK: - Reset Daily Progress
    // For achievements that require completion within a single day
    func resetDailyProgress(achievementId: String) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId && !$0.isUnlocked }) else {
            return
        }
        
        achievements[index].progress = 0
        saveAchievements()
    }
    
    // MARK: - Check Achievements
    func checkAchievements(
        todaySteps: Int,
        totalSteps: Int,
        streak: Int,
        health: Int,
        goalSteps: Int,
        goalsAchieved: Int,
        daysUsed: Int,
        petsUsed: Int
    ) {
        // First Step - Complete first day
        if daysUsed >= 1 {
            updateProgress(achievementId: "first_step", progress: 1)
        }
        
        // DAILY step achievements - progress updates only for current day
        // These show X/target but reset at midnight if not achieved
        updateProgress(achievementId: "step_up", progress: todaySteps)
        updateProgress(achievementId: "getting_started", progress: todaySteps)
        updateProgress(achievementId: "ten_thousand", progress: todaySteps)
        updateProgress(achievementId: "fifteen_k", progress: todaySteps)
        updateProgress(achievementId: "twenty_k", progress: todaySteps)
        updateProgress(achievementId: "marathon_day", progress: todaySteps)
        updateProgress(achievementId: "ultra_walker", progress: todaySteps)
        
        // Total steps achievements (cumulative, never reset)
        updateProgress(achievementId: "hundred_k_total", progress: totalSteps)
        updateProgress(achievementId: "half_million", progress: totalSteps)
        updateProgress(achievementId: "millionaire", progress: totalSteps)
        updateProgress(achievementId: "five_million", progress: totalSteps)
        updateProgress(achievementId: "ten_million", progress: totalSteps)
        
        // Streak achievements (cumulative)
        updateProgress(achievementId: "on_fire", progress: streak)
        updateProgress(achievementId: "week_warrior", progress: streak)
        updateProgress(achievementId: "two_week_titan", progress: streak)
        updateProgress(achievementId: "monthly_master", progress: streak)
        updateProgress(achievementId: "dedication", progress: streak)
        updateProgress(achievementId: "streak_legend", progress: streak)
        
        // Health achievements
        if health == 100 {
            updateProgress(achievementId: "full_health_first", progress: 1)
        }
        
        // First goal (trigger when goal is reached)
        if todaySteps >= goalSteps {
            updateProgress(achievementId: "first_goal", progress: 1)
        }
        
        // Milestone achievements (cumulative)
        updateProgress(achievementId: "one_week_user", progress: daysUsed)
        updateProgress(achievementId: "one_month_user", progress: daysUsed)
        updateProgress(achievementId: "three_month_user", progress: daysUsed)
        updateProgress(achievementId: "six_month_user", progress: daysUsed)
        updateProgress(achievementId: "one_year_user", progress: daysUsed)
        updateProgress(achievementId: "hundred_goals", progress: goalsAchieved)
        
        // Special achievements
        updateProgress(achievementId: "pet_lover", progress: petsUsed)
        
        // Double goal (daily achievement)
        if todaySteps >= goalSteps * 2 {
            updateProgress(achievementId: "double_trouble", progress: 1)
        }
        
        // Triple goal (daily achievement)
        if todaySteps >= goalSteps * 3 {
            updateProgress(achievementId: "triple_threat", progress: 1)
        }
        
        // Lucky seven (daily achievement)
        if todaySteps == 7777 {
            updateProgress(achievementId: "lucky_seven", progress: 1)
        }
        
        // Check special date achievements
        checkSpecialDateAchievements(todaySteps: todaySteps, goalSteps: goalSteps)
    }
    
    // MARK: - Reset Daily Achievements
    // Call this at the start of each new day for achievements that must be completed in a single day
    func resetDailyAchievements() {
        let dailyAchievementIds = [
            "step_up", "getting_started", "ten_thousand", "fifteen_k",
            "twenty_k", "marathon_day", "ultra_walker",
            "double_trouble", "triple_threat", "lucky_seven"
        ]
        
        for id in dailyAchievementIds {
            resetDailyProgress(achievementId: id)
        }
    }
    
    private func checkSpecialDateAchievements(todaySteps: Int, goalSteps: Int) {
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        // New Year's Day
        if month == 1 && day == 1 && todaySteps >= goalSteps {
            updateProgress(achievementId: "new_years_walk", progress: 1)
        }
        
        // Christmas
        if month == 12 && day == 25 && todaySteps >= goalSteps {
            updateProgress(achievementId: "holiday_spirit", progress: 1)
        }
    }
    
    // MARK: - Filtered Achievements
    func achievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }
    
    func unlockedAchievements() -> [Achievement] {
        achievements.filter { $0.isUnlocked }
    }
    
    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var totalCount: Int {
        achievements.count
    }
    
    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
}


