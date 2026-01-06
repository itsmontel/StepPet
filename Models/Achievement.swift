//
//  Achievement.swift
//  VirtuPet
//

import Foundation
import SwiftUI

// MARK: - Achievement Category
enum AchievementCategory: String, CaseIterable, Codable {
    case gettingStarted = "Getting Started"
    case streak = "Streak"
    case steps = "Steps"
    case health = "Health"
    case consistency = "Consistency"
    case milestones = "Milestones"
    case games = "Games & Activities"
    case special = "Special"
    
    var icon: String {
        switch self {
        case .gettingStarted: return "star.fill"
        case .streak: return "flame.fill"
        case .steps: return "figure.walk"
        case .health: return "heart.fill"
        case .consistency: return "calendar"
        case .milestones: return "flag.fill"
        case .games: return "gamecontroller.fill"
        case .special: return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .gettingStarted: return .green
        case .streak: return .orange
        case .steps: return .blue
        case .health: return .red
        case .consistency: return .purple
        case .milestones: return .yellow
        case .games: return .cyan
        case .special: return .pink
        }
    }
}

// MARK: - Achievement Rarity
enum AchievementRarity: String, Codable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: AchievementCategory
    let rarity: AchievementRarity
    let icon: String
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    var progress: Int = 0
    let targetProgress: Int
    
    var progressPercentage: Double {
        guard targetProgress > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(targetProgress))
    }
    
    static let allAchievements: [Achievement] = [
        // MARK: - Getting Started (10 achievements)
        Achievement(id: "first_step", title: "First Step", description: "Complete your first day of step tracking", category: .gettingStarted, rarity: .common, icon: "star.fill", targetProgress: 1),
        Achievement(id: "step_up", title: "Step Up", description: "Reach 1,000 steps in a single day", category: .gettingStarted, rarity: .common, icon: "shoe.fill", targetProgress: 1000),
        Achievement(id: "getting_started", title: "Getting Started", description: "Reach 5,000 steps in a single day", category: .gettingStarted, rarity: .common, icon: "figure.walk", targetProgress: 5000),
        Achievement(id: "goal_setter", title: "Goal Setter", description: "Set your first daily step goal", category: .gettingStarted, rarity: .common, icon: "target", targetProgress: 1),
        Achievement(id: "pet_parent", title: "Pet Parent", description: "Name your pet for the first time", category: .gettingStarted, rarity: .common, icon: "heart.fill", targetProgress: 1),
        Achievement(id: "health_check", title: "Health Check", description: "View your pet's health status", category: .gettingStarted, rarity: .common, icon: "waveform.path.ecg", targetProgress: 1),
        Achievement(id: "explorer", title: "Explorer", description: "Visit all app sections", category: .gettingStarted, rarity: .common, icon: "map.fill", targetProgress: 5),
        Achievement(id: "first_goal", title: "First Goal", description: "Achieve your daily step goal for the first time", category: .gettingStarted, rarity: .common, icon: "checkmark.circle.fill", targetProgress: 1),
        Achievement(id: "customizer", title: "Customizer", description: "Change your pet's appearance", category: .gettingStarted, rarity: .common, icon: "paintbrush.fill", targetProgress: 1),
        Achievement(id: "notifications_on", title: "Stay Connected", description: "Enable notifications", category: .gettingStarted, rarity: .common, icon: "bell.fill", targetProgress: 1),
        
        // MARK: - Streak Achievements (12 achievements)
        Achievement(id: "on_fire", title: "On Fire", description: "Maintain a 3-day goal streak", category: .streak, rarity: .common, icon: "flame.fill", targetProgress: 3),
        Achievement(id: "week_warrior", title: "Week Warrior", description: "Maintain a 7-day goal streak", category: .streak, rarity: .uncommon, icon: "flame.fill", targetProgress: 7),
        Achievement(id: "two_week_titan", title: "Two Week Titan", description: "Maintain a 14-day goal streak", category: .streak, rarity: .rare, icon: "flame.fill", targetProgress: 14),
        Achievement(id: "monthly_master", title: "Monthly Master", description: "Maintain a 30-day goal streak", category: .streak, rarity: .epic, icon: "flame.fill", targetProgress: 30),
        Achievement(id: "streak_legend", title: "Streak Legend", description: "Maintain a 100-day goal streak", category: .streak, rarity: .legendary, icon: "flame.fill", targetProgress: 100),
        Achievement(id: "comeback_kid", title: "Comeback Kid", description: "Recover your pet's health from sick to full health", category: .streak, rarity: .uncommon, icon: "arrow.up.heart.fill", targetProgress: 1),
        Achievement(id: "never_miss", title: "Never Miss Monday", description: "Hit your goal on 4 consecutive Mondays", category: .streak, rarity: .rare, icon: "calendar", targetProgress: 4),
        Achievement(id: "weekend_warrior", title: "Weekend Warrior", description: "Hit your goal on 8 consecutive weekend days", category: .streak, rarity: .rare, icon: "sun.max.fill", targetProgress: 8),
        Achievement(id: "early_bird", title: "Early Bird", description: "Reach 50% of your goal before noon for 7 days", category: .streak, rarity: .uncommon, icon: "sunrise.fill", targetProgress: 7),
        Achievement(id: "night_owl", title: "Night Owl", description: "Complete your goal after 8 PM for 5 days", category: .streak, rarity: .uncommon, icon: "moon.stars.fill", targetProgress: 5),
        Achievement(id: "consistent_walker", title: "Consistent Walker", description: "Hit your goal 5 days in a row", category: .streak, rarity: .uncommon, icon: "repeat", targetProgress: 5),
        Achievement(id: "dedication", title: "Pure Dedication", description: "Maintain a 60-day goal streak", category: .streak, rarity: .epic, icon: "star.circle.fill", targetProgress: 60),
        
        // MARK: - Steps Achievements (12 achievements)
        Achievement(id: "ten_thousand", title: "10K Club", description: "Walk 10,000 steps in a single day", category: .steps, rarity: .common, icon: "figure.walk", targetProgress: 10000),
        Achievement(id: "fifteen_k", title: "15K Achiever", description: "Walk 15,000 steps in a single day", category: .steps, rarity: .uncommon, icon: "figure.walk", targetProgress: 15000),
        Achievement(id: "twenty_k", title: "20K Champion", description: "Walk 20,000 steps in a single day", category: .steps, rarity: .rare, icon: "figure.walk", targetProgress: 20000),
        Achievement(id: "marathon_day", title: "Marathon Day", description: "Walk 30,000 steps in a single day", category: .steps, rarity: .epic, icon: "figure.run", targetProgress: 30000),
        Achievement(id: "ultra_walker", title: "Ultra Walker", description: "Walk 50,000 steps in a single day", category: .steps, rarity: .legendary, icon: "bolt.fill", targetProgress: 50000),
        Achievement(id: "hundred_k_total", title: "100K Total", description: "Accumulate 100,000 total steps", category: .steps, rarity: .common, icon: "sum", targetProgress: 100000),
        Achievement(id: "half_million", title: "Half Million", description: "Accumulate 500,000 total steps", category: .steps, rarity: .uncommon, icon: "sum", targetProgress: 500000),
        Achievement(id: "millionaire", title: "Step Millionaire", description: "Accumulate 1,000,000 total steps", category: .steps, rarity: .rare, icon: "dollarsign.circle.fill", targetProgress: 1000000),
        Achievement(id: "five_million", title: "Five Million Steps", description: "Accumulate 5,000,000 total steps", category: .steps, rarity: .epic, icon: "star.fill", targetProgress: 5000000),
        Achievement(id: "ten_million", title: "Ten Million Steps", description: "Accumulate 10,000,000 total steps", category: .steps, rarity: .legendary, icon: "crown.fill", targetProgress: 10000000),
        Achievement(id: "weekly_75k", title: "Weekly 75K", description: "Walk 75,000 steps in a single week", category: .steps, rarity: .uncommon, icon: "calendar.badge.plus", targetProgress: 75000),
        Achievement(id: "weekly_100k", title: "Weekly 100K", description: "Walk 100,000 steps in a single week", category: .steps, rarity: .rare, icon: "calendar.badge.exclamationmark", targetProgress: 100000),
        
        // MARK: - Health Achievements (10 achievements)
        Achievement(id: "full_health_first", title: "Thriving", description: "Reach 100% pet health for the first time", category: .health, rarity: .common, icon: "heart.fill", targetProgress: 1),
        Achievement(id: "perfect_week", title: "Perfect Week", description: "Keep pet at 100% health for 7 consecutive days", category: .health, rarity: .rare, icon: "heart.circle.fill", targetProgress: 7),
        Achievement(id: "perfect_month", title: "Perfect Month", description: "Keep pet at 100% health for 30 consecutive days", category: .health, rarity: .legendary, icon: "heart.text.square.fill", targetProgress: 30),
        Achievement(id: "never_sick", title: "Never Sick", description: "Never let pet fall to sick status for 14 days", category: .health, rarity: .rare, icon: "cross.case.fill", targetProgress: 14),
        Achievement(id: "health_recovery", title: "Health Recovery", description: "Recover from below 50% to 100% in one day", category: .health, rarity: .uncommon, icon: "arrow.up.heart", targetProgress: 1),
        Achievement(id: "stable_health", title: "Stable Health", description: "Keep pet above 60% health for 10 days", category: .health, rarity: .uncommon, icon: "waveform.path.ecg", targetProgress: 10),
        Achievement(id: "always_happy", title: "Always Happy", description: "Keep pet at happy or full health for 5 days", category: .health, rarity: .uncommon, icon: "face.smiling.fill", targetProgress: 5),
        Achievement(id: "health_champion", title: "Health Champion", description: "Average 90%+ health for a month", category: .health, rarity: .epic, icon: "trophy.fill", targetProgress: 1),
        Achievement(id: "rescue_mission", title: "Rescue Mission", description: "Recover pet from sick status 5 times", category: .health, rarity: .uncommon, icon: "bandage.fill", targetProgress: 5),
        Achievement(id: "guardian", title: "Guardian", description: "Never let pet fall below 40% health for 30 days", category: .health, rarity: .epic, icon: "shield.fill", targetProgress: 30),
        
        // MARK: - Consistency Achievements (8 achievements)
        Achievement(id: "daily_walker", title: "Daily Walker", description: "Walk at least 1,000 steps every day for a week", category: .consistency, rarity: .common, icon: "calendar.badge.clock", targetProgress: 7),
        Achievement(id: "monthly_active", title: "Monthly Active", description: "Walk at least 1,000 steps every day for a month", category: .consistency, rarity: .rare, icon: "calendar", targetProgress: 30),
        Achievement(id: "morning_routine", title: "Morning Routine", description: "Walk 3,000 steps before 9 AM for 7 days", category: .consistency, rarity: .uncommon, icon: "alarm.fill", targetProgress: 7),
        Achievement(id: "lunch_walker", title: "Lunch Walker", description: "Walk 2,000 steps during lunch hours for 5 days", category: .consistency, rarity: .uncommon, icon: "takeoutbag.and.cup.and.straw.fill", targetProgress: 5),
        Achievement(id: "evening_stroll", title: "Evening Stroll", description: "Walk 3,000 steps after 6 PM for 7 days", category: .consistency, rarity: .uncommon, icon: "sunset.fill", targetProgress: 7),
        Achievement(id: "all_day_active", title: "All Day Active", description: "Walk steps in every 4-hour block for 3 days", category: .consistency, rarity: .rare, icon: "clock.fill", targetProgress: 3),
        Achievement(id: "goal_crusher", title: "Goal Crusher", description: "Exceed your daily goal by 50% for 5 days", category: .consistency, rarity: .rare, icon: "bolt.heart.fill", targetProgress: 5),
        Achievement(id: "steady_pace", title: "Steady Pace", description: "Hit exactly 10,000 steps (±500) for 3 days", category: .consistency, rarity: .uncommon, icon: "speedometer", targetProgress: 3),
        
        // MARK: - Milestone Achievements (9 achievements)
        Achievement(id: "one_week_user", title: "One Week User", description: "Use VirtuPet for 7 days", category: .milestones, rarity: .common, icon: "7.circle.fill", targetProgress: 7),
        Achievement(id: "one_month_user", title: "One Month User", description: "Use VirtuPet for 30 days", category: .milestones, rarity: .uncommon, icon: "calendar", targetProgress: 30),
        Achievement(id: "three_month_user", title: "Three Month User", description: "Use VirtuPet for 90 days", category: .milestones, rarity: .rare, icon: "calendar.badge.plus", targetProgress: 90),
        Achievement(id: "six_month_user", title: "Six Month User", description: "Use VirtuPet for 180 days", category: .milestones, rarity: .epic, icon: "calendar.badge.exclamationmark", targetProgress: 180),
        Achievement(id: "one_year_user", title: "One Year User", description: "Use VirtuPet for 365 days", category: .milestones, rarity: .legendary, icon: "calendar.circle.fill", targetProgress: 365),
        Achievement(id: "hundred_goals", title: "100 Goals", description: "Achieve your daily goal 100 times", category: .milestones, rarity: .rare, icon: "100.circle.fill", targetProgress: 100),
        Achievement(id: "five_hundred_goals", title: "500 Goals", description: "Achieve your daily goal 500 times", category: .milestones, rarity: .epic, icon: "checkmark.seal.fill", targetProgress: 500),
        Achievement(id: "thousand_goals", title: "1000 Goals", description: "Achieve your daily goal 1000 times", category: .milestones, rarity: .legendary, icon: "rosette", targetProgress: 1000),
        Achievement(id: "two_year_user", title: "Two Year Veteran", description: "Use VirtuPet for 730 days", category: .milestones, rarity: .legendary, icon: "gift.fill", targetProgress: 730),
        
        // MARK: - Special Achievements (10 achievements)
        Achievement(id: "new_years_walk", title: "New Year's Walk", description: "Hit your goal on January 1st", category: .special, rarity: .rare, icon: "party.popper.fill", targetProgress: 1),
        Achievement(id: "holiday_spirit", title: "Holiday Spirit", description: "Hit your goal on December 25th", category: .special, rarity: .rare, icon: "gift.fill", targetProgress: 1),
        Achievement(id: "lucky_seven", title: "Lucky Seven", description: "Walk exactly 7,777 steps in a day", category: .special, rarity: .rare, icon: "7.circle.fill", targetProgress: 1),
        Achievement(id: "double_trouble", title: "Double Trouble", description: "Walk double your daily goal", category: .special, rarity: .uncommon, icon: "2.circle.fill", targetProgress: 1),
        Achievement(id: "triple_threat", title: "Triple Threat", description: "Walk triple your daily goal", category: .special, rarity: .rare, icon: "3.circle.fill", targetProgress: 1),
        Achievement(id: "photo_finish", title: "Photo Finish", description: "Complete your goal with exactly 0 steps remaining", category: .special, rarity: .epic, icon: "camera.fill", targetProgress: 1),
        Achievement(id: "close_call", title: "Close Call", description: "Complete your goal in the last hour of the day", category: .special, rarity: .uncommon, icon: "clock.badge.exclamationmark.fill", targetProgress: 1),
        Achievement(id: "overachiever", title: "Overachiever", description: "Exceed your weekly goal by 25%", category: .special, rarity: .uncommon, icon: "arrow.up.right.circle.fill", targetProgress: 1),
        Achievement(id: "pet_lover", title: "Pet Lover", description: "Try all 5 different pets", category: .special, rarity: .rare, icon: "pawprint.fill", targetProgress: 5),
        Achievement(id: "premium_supporter", title: "Premium Supporter", description: "Upgrade to VirtuPet Premium", category: .special, rarity: .epic, icon: "crown.fill", targetProgress: 1),
        
        // MARK: - Games & Activities Achievements (26 achievements)
        // Mini-game achievements
        Achievement(id: "first_minigame", title: "Game On!", description: "Play your first mini-game", category: .games, rarity: .common, icon: "gamecontroller.fill", targetProgress: 1),
        Achievement(id: "game_enthusiast", title: "Game Enthusiast", description: "Play 25 mini-games", category: .games, rarity: .common, icon: "arcade.stick", targetProgress: 25),
        Achievement(id: "arcade_regular", title: "Arcade Regular", description: "Play 100 mini-games", category: .games, rarity: .uncommon, icon: "arcade.stick.console.fill", targetProgress: 100),
        Achievement(id: "gaming_pro", title: "Gaming Pro", description: "Play 250 mini-games", category: .games, rarity: .rare, icon: "trophy.fill", targetProgress: 250),
        Achievement(id: "minigame_master", title: "Mini-Game Master", description: "Play 500 mini-games", category: .games, rarity: .epic, icon: "medal.fill", targetProgress: 500),
        Achievement(id: "minigame_legend", title: "Mini-Game Legend", description: "Play 1,000 mini-games", category: .games, rarity: .legendary, icon: "crown.fill", targetProgress: 1000),
        
        // Pet activity achievements
        Achievement(id: "first_activity", title: "Caring Owner", description: "Do your first pet activity", category: .games, rarity: .common, icon: "heart.circle.fill", targetProgress: 1),
        Achievement(id: "pet_carer", title: "Pet Carer", description: "Do 25 pet activities", category: .games, rarity: .common, icon: "hands.sparkles.fill", targetProgress: 25),
        Achievement(id: "devoted_owner", title: "Devoted Owner", description: "Do 100 pet activities", category: .games, rarity: .uncommon, icon: "star.circle.fill", targetProgress: 100),
        Achievement(id: "best_friend", title: "Best Friend", description: "Do 250 pet activities with your pet", category: .games, rarity: .rare, icon: "person.2.fill", targetProgress: 250),
        Achievement(id: "pet_activity_pro", title: "Pet Activity Pro", description: "Do 500 pet activities", category: .games, rarity: .epic, icon: "medal.star.fill", targetProgress: 500),
        Achievement(id: "ultimate_pet_parent", title: "Ultimate Pet Parent", description: "Do 1,000 pet activities", category: .games, rarity: .legendary, icon: "sparkles", targetProgress: 1000),
        
        // Specific game achievements
        Achievement(id: "bubble_master", title: "Bubble Master", description: "Play Bubble Pop 50 times", category: .games, rarity: .rare, icon: "bubble.left.fill", targetProgress: 50),
        Achievement(id: "memory_champion", title: "Memory Champion", description: "Play Memory Match 50 times", category: .games, rarity: .rare, icon: "brain.head.profile", targetProgress: 50),
        Achievement(id: "pattern_expert", title: "Pattern Expert", description: "Play Pattern Match 50 times", category: .games, rarity: .rare, icon: "square.grid.3x3.fill", targetProgress: 50),
        
        // Specific activity achievements
        Achievement(id: "feeding_time", title: "Feeding Time", description: "Feed your pet 25 times", category: .games, rarity: .uncommon, icon: "fork.knife", targetProgress: 25),
        Achievement(id: "playful_spirit", title: "Playful Spirit", description: "Play ball with your pet 25 times", category: .games, rarity: .uncommon, icon: "tennisball.fill", targetProgress: 25),
        Achievement(id: "couch_buddies", title: "Couch Buddies", description: "Watch TV with your pet 25 times", category: .games, rarity: .uncommon, icon: "tv.fill", targetProgress: 25),
        
        // Combined achievements - Daily gaming streaks
        Achievement(id: "weekly_gamer", title: "Weekly Gamer", description: "Play at least one game 7 days in a row", category: .games, rarity: .uncommon, icon: "calendar.badge.clock", targetProgress: 7),
        Achievement(id: "monthly_gamer", title: "Monthly Gamer", description: "Play at least one game 30 days in a row", category: .games, rarity: .epic, icon: "calendar.badge.checkmark", targetProgress: 30),
        Achievement(id: "gaming_devotee", title: "Gaming Devotee", description: "Play at least one game 100 days in a row", category: .games, rarity: .legendary, icon: "infinity.circle.fill", targetProgress: 100),
        
        // Other combined achievements
        Achievement(id: "social_butterfly", title: "Social Butterfly", description: "Do all 3 pet activities in one day", category: .games, rarity: .uncommon, icon: "sparkle", targetProgress: 1),
        Achievement(id: "credit_spender", title: "Credit Spender", description: "Use 100 credits total", category: .games, rarity: .uncommon, icon: "creditcard.fill", targetProgress: 100),
        Achievement(id: "credit_collector", title: "Credit Collector", description: "Use 500 credits total", category: .games, rarity: .epic, icon: "banknote.fill", targetProgress: 500),
        Achievement(id: "credit_master", title: "Credit Master", description: "Use 1,000 credits total", category: .games, rarity: .legendary, icon: "dollarsign.circle.fill", targetProgress: 1000),
        Achievement(id: "credit_goat", title: "Credit GOAT", description: "Use 2,000 credits total", category: .games, rarity: .legendary, icon: "bolt.circle.fill", targetProgress: 2000)
    ]
}

