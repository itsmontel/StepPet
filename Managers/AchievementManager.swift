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
        petsUsed: Int,
        weeklySteps: Int = 0,
        previousHealth: Int = 0,
        consecutiveFullHealthDays: Int = 0,
        consecutiveHealthyDays: Int = 0,
        consecutiveNoSickDays: Int = 0,
        rescueCount: Int = 0,
        consecutiveGoalDays: Int = 0
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
        
        // Weekly step achievements
        if weeklySteps > 0 {
            updateProgress(achievementId: "weekly_75k", progress: weeklySteps)
            updateProgress(achievementId: "weekly_100k", progress: weeklySteps)
        }
        
        // Streak achievements (cumulative)
        updateProgress(achievementId: "on_fire", progress: streak)
        updateProgress(achievementId: "week_warrior", progress: streak)
        updateProgress(achievementId: "two_week_titan", progress: streak)
        updateProgress(achievementId: "monthly_master", progress: streak)
        updateProgress(achievementId: "dedication", progress: streak)
        updateProgress(achievementId: "streak_legend", progress: streak)
        updateProgress(achievementId: "consistent_walker", progress: consecutiveGoalDays)
        
        // Health achievements
        if health == 100 {
            updateProgress(achievementId: "full_health_first", progress: 1)
        }
        
        // Perfect health streak achievements
        updateProgress(achievementId: "perfect_week", progress: consecutiveFullHealthDays)
        updateProgress(achievementId: "perfect_month", progress: consecutiveFullHealthDays)
        
        // Never sick achievement (tracks days without falling to sick status)
        updateProgress(achievementId: "never_sick", progress: consecutiveNoSickDays)
        
        // Health recovery - recovered from <50% to 100% in one day
        if previousHealth < 50 && health == 100 {
            updateProgress(achievementId: "health_recovery", progress: 1)
        }
        
        // Comeback kid - recover from sick to full health
        if previousHealth <= 20 && health == 100 {
            updateProgress(achievementId: "comeback_kid", progress: 1)
        }
        
        // Stable health - above 60% for consecutive days
        updateProgress(achievementId: "stable_health", progress: consecutiveHealthyDays)
        
        // Always happy - happy or full health (60%+) for 5 days
        if health >= 60 {
            updateProgress(achievementId: "always_happy", progress: consecutiveHealthyDays)
        }
        
        // Guardian - never below 40% for 30 days
        if health >= 40 {
            // This needs tracking in UserSettings
        }
        
        // Rescue mission - recover from sick 5 times
        updateProgress(achievementId: "rescue_mission", progress: rescueCount)
        
        // First goal (trigger when goal is reached)
        if todaySteps >= goalSteps && goalSteps > 0 {
            updateProgress(achievementId: "first_goal", progress: 1)
        }
        
        // Milestone achievements (cumulative)
        updateProgress(achievementId: "one_week_user", progress: daysUsed)
        updateProgress(achievementId: "one_month_user", progress: daysUsed)
        updateProgress(achievementId: "three_month_user", progress: daysUsed)
        updateProgress(achievementId: "six_month_user", progress: daysUsed)
        updateProgress(achievementId: "one_year_user", progress: daysUsed)
        updateProgress(achievementId: "two_year_user", progress: daysUsed)
        updateProgress(achievementId: "hundred_goals", progress: goalsAchieved)
        updateProgress(achievementId: "five_hundred_goals", progress: goalsAchieved)
        updateProgress(achievementId: "thousand_goals", progress: goalsAchieved)
        
        // Special achievements
        updateProgress(achievementId: "pet_lover", progress: petsUsed)
        
        // Double goal (daily achievement)
        if todaySteps >= goalSteps * 2 && goalSteps > 0 {
            updateProgress(achievementId: "double_trouble", progress: 1)
        }
        
        // Triple goal (daily achievement)
        if todaySteps >= goalSteps * 3 && goalSteps > 0 {
            updateProgress(achievementId: "triple_threat", progress: 1)
        }
        
        // Lucky seven - walk exactly 7,777 steps (with small tolerance)
        if todaySteps >= 7770 && todaySteps <= 7784 {
            updateProgress(achievementId: "lucky_seven", progress: 1)
        }
        
        // Photo finish - complete goal with exactly 0 steps remaining
        if todaySteps == goalSteps && goalSteps > 0 {
            updateProgress(achievementId: "photo_finish", progress: 1)
        }
        
        // Close call - complete goal in the last hour of the day (11 PM - midnight)
        let hour = Calendar.current.component(.hour, from: Date())
        if todaySteps >= goalSteps && hour >= 23 && goalSteps > 0 {
            // Check if goal was just reached (within tolerance)
            if previousHealth < 100 {
                updateProgress(achievementId: "close_call", progress: 1)
            }
        }
        
        // Overachiever - exceed weekly goal by 25%
        let weeklyGoal = goalSteps * 7
        if weeklySteps > 0 && weeklySteps >= Int(Double(weeklyGoal) * 1.25) {
            updateProgress(achievementId: "overachiever", progress: 1)
        }
        
        // Goal crusher - exceed daily goal by 50% for 5 days
        if todaySteps >= Int(Double(goalSteps) * 1.5) && goalSteps > 0 {
            incrementStreakProgress(achievementId: "goal_crusher", maxProgress: 5)
        }
        
        // Steady pace - hit exactly 10,000 ±500 steps for 3 days
        if todaySteps >= 9500 && todaySteps <= 10500 {
            incrementStreakProgress(achievementId: "steady_pace", maxProgress: 3)
        }
        
        // Check special date achievements
        checkSpecialDateAchievements(todaySteps: todaySteps, goalSteps: goalSteps)
    }
    
    // MARK: - Increment Streak Progress
    // Helper for achievements that require consecutive days
    func incrementStreakProgress(achievementId: String, maxProgress: Int) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId && !$0.isUnlocked }) else {
            return
        }
        
        let newProgress = min(achievements[index].progress + 1, maxProgress)
        achievements[index].progress = newProgress
        
        if newProgress >= maxProgress {
            unlock(achievementId: achievementId)
        } else {
            saveAchievements()
        }
    }
    
    // MARK: - Check Time-Based Achievements
    func checkTimeBasedAchievements(
        stepsBeforeNoon: Int,
        goalSteps: Int,
        goalAchievedAfter8PM: Bool,
        stepsBeforeWorkday: Int,
        stepsAtLunch: Int,
        stepsAfterEvening: Int
    ) {
        // Early bird - reach 50% of goal before noon for 7 days
        if stepsBeforeNoon >= goalSteps / 2 {
            incrementStreakProgress(achievementId: "early_bird", maxProgress: 7)
        }
        
        // Night owl - complete goal after 8 PM for 5 days
        if goalAchievedAfter8PM {
            incrementStreakProgress(achievementId: "night_owl", maxProgress: 5)
        }
        
        // Morning routine - 3000 steps before 9 AM for 7 days
        if stepsBeforeWorkday >= 3000 {
            incrementStreakProgress(achievementId: "morning_routine", maxProgress: 7)
        }
        
        // Lunch walker - 2000 steps during lunch hours for 5 days
        if stepsAtLunch >= 2000 {
            incrementStreakProgress(achievementId: "lunch_walker", maxProgress: 5)
        }
        
        // Evening stroll - 3000 steps after 6 PM for 7 days
        if stepsAfterEvening >= 3000 {
            incrementStreakProgress(achievementId: "evening_stroll", maxProgress: 7)
        }
    }
    
    // MARK: - Check All-Day Active Achievement
    func checkAllDayActiveAchievement(stepsPerBlock: [Int]) {
        // All day active - walk steps in every 4-hour block for 3 days
        // 6 blocks: 0-4, 4-8, 8-12, 12-16, 16-20, 20-24
        let allBlocksActive = stepsPerBlock.allSatisfy { $0 > 0 }
        if allBlocksActive {
            incrementStreakProgress(achievementId: "all_day_active", maxProgress: 3)
        }
    }
    
    // MARK: - Check Daily Walker Achievement
    func checkDailyWalkerAchievement(todaySteps: Int) {
        // Daily walker - at least 1000 steps every day for a week
        if todaySteps >= 1000 {
            incrementStreakProgress(achievementId: "daily_walker", maxProgress: 7)
        }
        
        // Monthly active - at least 1000 steps every day for a month
        if todaySteps >= 1000 {
            incrementStreakProgress(achievementId: "monthly_active", maxProgress: 30)
        }
    }
    
    // MARK: - Check Weekend/Weekday Achievements
    func checkDaySpecificAchievements(todaySteps: Int, goalSteps: Int) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let isWeekend = weekday == 1 || weekday == 7 // Sunday or Saturday
        let isMonday = weekday == 2
        
        if todaySteps >= goalSteps {
            // Weekend warrior - hit goal on 8 consecutive weekend days
            if isWeekend {
                incrementStreakProgress(achievementId: "weekend_warrior", maxProgress: 8)
            }
            
            // Never miss Monday - hit goal on 4 consecutive Mondays
            if isMonday {
                incrementStreakProgress(achievementId: "never_miss", maxProgress: 4)
            }
        }
    }
    
    // MARK: - Unlock Premium Supporter
    func unlockPremiumSupporter() {
        updateProgress(achievementId: "premium_supporter", progress: 1)
    }
    
    // MARK: - Check Game & Activity Achievements
    func checkGameAchievements(
        totalMinigamesPlayed: Int,
        totalPetActivitiesPlayed: Int,
        moodCatchPlayed: Int,
        memoryMatchPlayed: Int,
        skyDashPlayed: Int,
        patternMatchPlayed: Int,
        feedActivityCount: Int,
        playBallActivityCount: Int,
        watchTVActivityCount: Int,
        totalCreditsUsed: Int,
        consecutiveGameDays: Int,
        didAllActivitiesToday: Bool
    ) {
        // Mini-game achievements
        updateProgress(achievementId: "first_minigame", progress: min(totalMinigamesPlayed, 1))
        updateProgress(achievementId: "game_enthusiast", progress: totalMinigamesPlayed)
        updateProgress(achievementId: "arcade_regular", progress: totalMinigamesPlayed)
        updateProgress(achievementId: "gaming_pro", progress: totalMinigamesPlayed)
        updateProgress(achievementId: "minigame_master", progress: totalMinigamesPlayed)
        updateProgress(achievementId: "minigame_legend", progress: totalMinigamesPlayed)
        
        // Pet activity achievements
        updateProgress(achievementId: "first_activity", progress: min(totalPetActivitiesPlayed, 1))
        updateProgress(achievementId: "pet_carer", progress: totalPetActivitiesPlayed)
        updateProgress(achievementId: "devoted_owner", progress: totalPetActivitiesPlayed)
        updateProgress(achievementId: "best_friend", progress: totalPetActivitiesPlayed)
        updateProgress(achievementId: "pet_activity_pro", progress: totalPetActivitiesPlayed)
        updateProgress(achievementId: "ultimate_pet_parent", progress: totalPetActivitiesPlayed)
        
        // Specific game achievements
        updateProgress(achievementId: "mood_master", progress: moodCatchPlayed)
        updateProgress(achievementId: "memory_champion", progress: memoryMatchPlayed)
        updateProgress(achievementId: "sky_legend", progress: skyDashPlayed)
        updateProgress(achievementId: "pattern_expert", progress: patternMatchPlayed)
        
        // Specific activity achievements
        updateProgress(achievementId: "feeding_time", progress: feedActivityCount)
        updateProgress(achievementId: "playful_spirit", progress: playBallActivityCount)
        updateProgress(achievementId: "couch_buddies", progress: watchTVActivityCount)
        
        // Credit achievements
        updateProgress(achievementId: "credit_spender", progress: totalCreditsUsed)
        updateProgress(achievementId: "credit_collector", progress: totalCreditsUsed)
        updateProgress(achievementId: "credit_master", progress: totalCreditsUsed)
        updateProgress(achievementId: "credit_goat", progress: totalCreditsUsed)
        
        // Gaming streak achievements
        updateProgress(achievementId: "weekly_gamer", progress: consecutiveGameDays)
        updateProgress(achievementId: "monthly_gamer", progress: consecutiveGameDays)
        updateProgress(achievementId: "gaming_devotee", progress: consecutiveGameDays)
        
        // Social butterfly - all 3 activities in one day
        if didAllActivitiesToday {
            updateProgress(achievementId: "social_butterfly", progress: 1)
        }
    }
    
    // MARK: - Reset Daily Achievements
    // Call this at the start of each new day for achievements that must be completed in a single day
    // Note: resetDailyProgress only resets progress if the achievement is NOT yet unlocked
    func resetDailyAchievements() {
        // Daily step achievements - must be achieved in a single day
        let dailyStepAchievementIds = [
            "step_up", "getting_started", "ten_thousand", "fifteen_k",
            "twenty_k", "marathon_day", "ultra_walker"
        ]
        
        // Daily special achievements
        let dailySpecialAchievementIds = [
            "double_trouble", "triple_threat", "lucky_seven",
            "photo_finish", "close_call", "health_recovery"
        ]
        
        // Multi-day streak achievements that track consecutive days
        // These reset their "day count" if the streak breaks
        let streakTrackingIds = [
            "early_bird", "night_owl", "morning_routine", "lunch_walker",
            "evening_stroll", "all_day_active", "goal_crusher", "steady_pace",
            "daily_walker", "monthly_active", "perfect_week", "perfect_month",
            "never_sick", "stable_health", "always_happy", "guardian",
            "consistent_walker", "never_miss", "weekend_warrior"
        ]
        
        for id in dailyStepAchievementIds {
            resetDailyProgress(achievementId: id)
        }
        
        for id in dailySpecialAchievementIds {
            resetDailyProgress(achievementId: id)
        }
        
        // Note: streak tracking achievements are handled separately
        // They should only reset when the streak condition is broken
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


