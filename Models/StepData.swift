//
//  StepData.swift
//  VirtuPet
//

import Foundation

// MARK: - Daily Step Record
struct DailyStepRecord: Codable, Identifiable {
    var id = UUID()
    let date: Date
    var steps: Int
    var goalSteps: Int
    var healthScore: Int
    
    var goalAchieved: Bool {
        steps >= goalSteps
    }
    
    var progressPercentage: Double {
        guard goalSteps > 0 else { return 0 }
        return min(1.0, Double(steps) / Double(goalSteps))
    }
    
    var moodState: PetMoodState {
        PetMoodState.from(health: healthScore)
    }
    
    init(date: Date = Date(), steps: Int = 0, goalSteps: Int = 10000) {
        self.date = date
        self.steps = steps
        self.goalSteps = goalSteps
        self.healthScore = min(100, Int((Double(steps) / Double(goalSteps)) * 100))
    }
}

// MARK: - Weekly Summary
struct WeeklySummary {
    let weekStartDate: Date
    let dailyRecords: [DailyStepRecord]
    
    var totalSteps: Int {
        dailyRecords.reduce(0) { $0 + $1.steps }
    }
    
    var averageSteps: Int {
        guard !dailyRecords.isEmpty else { return 0 }
        return totalSteps / dailyRecords.count
    }
    
    var goalsAchieved: Int {
        dailyRecords.filter { $0.goalAchieved }.count
    }
    
    var bestDay: DailyStepRecord? {
        dailyRecords.max(by: { $0.steps < $1.steps })
    }
    
    var averageHealth: Int {
        guard !dailyRecords.isEmpty else { return 0 }
        return dailyRecords.reduce(0) { $0 + $1.healthScore } / dailyRecords.count
    }
}

// MARK: - Monthly Summary
struct MonthlySummary {
    let month: Date
    let dailyRecords: [DailyStepRecord]
    
    var totalSteps: Int {
        dailyRecords.reduce(0) { $0 + $1.steps }
    }
    
    var averageSteps: Int {
        guard !dailyRecords.isEmpty else { return 0 }
        return totalSteps / dailyRecords.count
    }
    
    var goalsAchieved: Int {
        dailyRecords.filter { $0.goalAchieved }.count
    }
    
    var totalDays: Int {
        dailyRecords.count
    }
    
    var bestDay: DailyStepRecord? {
        dailyRecords.max(by: { $0.steps < $1.steps })
    }
    
    var longestStreak: Int {
        var maxStreak = 0
        var currentStreak = 0
        
        let sortedRecords = dailyRecords.sorted { $0.date < $1.date }
        
        for record in sortedRecords {
            if record.goalAchieved {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
}

// MARK: - Streak Data
struct StreakData: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastGoalAchievedDate: Date?
    
    var streakBadge: StreakBadge {
        switch currentStreak {
        case 0..<3: return .none
        case 3..<7: return .bronze
        case 7..<14: return .silver
        case 14..<30: return .gold
        case 30..<100: return .platinum
        default: return .diamond
        }
    }
    
    mutating func updateStreak(goalAchieved: Bool, date: Date) {
        let calendar = Calendar.current
        // Normalize to start of day for accurate day comparison
        let today = calendar.startOfDay(for: date)
        
        if goalAchieved {
            if let lastDate = lastGoalAchievedDate {
                // Normalize last date to start of day for comparison
                let lastDay = calendar.startOfDay(for: lastDate)
                let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
                
                if daysDifference == 1 {
                    // Consecutive day - increment streak
                    currentStreak += 1
                } else if daysDifference == 0 {
                    // Same day, don't increment (already counted today)
                    // But ensure streak is at least 1 if it was 0
                    if currentStreak == 0 {
                        currentStreak = 1
                    }
                } else {
                    // Streak broken (more than 1 day gap), start new streak
                    currentStreak = 1
                }
            } else {
                // First goal achieved ever - start streak at 1
                currentStreak = 1
            }
            
            lastGoalAchievedDate = date
            longestStreak = max(longestStreak, currentStreak)
        } else {
            // Check if it's a new day and goal not achieved - reset streak
            if let lastDate = lastGoalAchievedDate {
                let lastDay = calendar.startOfDay(for: lastDate)
                let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
                if daysDifference > 1 {
                    currentStreak = 0
                }
            }
        }
    }
}

// MARK: - Streak Badge
enum StreakBadge: String, Codable {
    case none = "No Badge"
    case bronze = "Bronze Paw"
    case silver = "Silver Paw"
    case gold = "Gold Paw"
    case platinum = "Platinum Paw"
    case diamond = "Diamond Paw"
    
    var color: String {
        switch self {
        case .none: return "gray"
        case .bronze: return "orange"
        case .silver: return "gray"
        case .gold: return "yellow"
        case .platinum: return "purple"
        case .diamond: return "cyan"
        }
    }
    
    var requiredDays: Int {
        switch self {
        case .none: return 0
        case .bronze: return 3
        case .silver: return 7
        case .gold: return 14
        case .platinum: return 30
        case .diamond: return 100
        }
    }
}

