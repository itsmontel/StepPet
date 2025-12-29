//
//  StepDataManager.swift
//  StepPet
//

import Foundation
import SwiftUI

class StepDataManager: ObservableObject {
    @Published var dailyRecords: [DailyStepRecord] = []
    @Published var todayRecord: DailyStepRecord?
    
    private let userDefaultsKey = "StepPetDailyRecords"
    
    init() {
        loadData()
    }
    
    // MARK: - Load Data
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let records = try? JSONDecoder().decode([DailyStepRecord].self, from: data) {
            dailyRecords = records
            
            // Check if today's record exists
            let today = Calendar.current.startOfDay(for: Date())
            todayRecord = records.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        }
    }
    
    // MARK: - Save Data
    func saveData() {
        if let data = try? JSONEncoder().encode(dailyRecords) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Update Today's Record
    func updateTodayRecord(steps: Int, goalSteps: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let index = dailyRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            dailyRecords[index].steps = steps
            dailyRecords[index].goalSteps = goalSteps
            dailyRecords[index].healthScore = min(100, Int((Double(steps) / Double(goalSteps)) * 100))
            todayRecord = dailyRecords[index]
        } else {
            let newRecord = DailyStepRecord(date: today, steps: steps, goalSteps: goalSteps)
            dailyRecords.append(newRecord)
            todayRecord = newRecord
        }
        
        saveData()
    }
    
    // MARK: - Get Records for Date Range
    func getRecords(from startDate: Date, to endDate: Date) -> [DailyStepRecord] {
        dailyRecords.filter { record in
            record.date >= startDate && record.date <= endDate
        }.sorted { $0.date < $1.date }
    }
    
    // MARK: - Weekly Records
    func getWeeklyRecords() -> [DailyStepRecord] {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday
        guard let startOfWeek = calendar.date(from: components) else { return [] }
        
        return getRecords(from: startOfWeek, to: Date())
    }
    
    // MARK: - Monthly Records
    func getMonthlyRecords() -> [DailyStepRecord] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let startOfMonth = calendar.date(from: components) else { return [] }
        
        return getRecords(from: startOfMonth, to: Date())
    }
    
    // MARK: - Weekly Summary
    func getWeeklySummary() -> WeeklySummary {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday
        let startOfWeek = calendar.date(from: components) ?? Date()
        
        return WeeklySummary(weekStartDate: startOfWeek, dailyRecords: getWeeklyRecords())
    }
    
    // MARK: - Monthly Summary
    func getMonthlySummary() -> MonthlySummary {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        let startOfMonth = calendar.date(from: components) ?? Date()
        
        return MonthlySummary(month: startOfMonth, dailyRecords: getMonthlyRecords())
    }
    
    // MARK: - Statistics
    var totalStepsAllTime: Int {
        dailyRecords.reduce(0) { $0 + $1.steps }
    }
    
    var totalGoalsAchieved: Int {
        dailyRecords.filter { $0.goalAchieved }.count
    }
    
    var bestDay: DailyStepRecord? {
        dailyRecords.max { $0.steps < $1.steps }
    }
    
    // MARK: - Clean Old Data (keep last 365 days)
    func cleanOldData() {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -365, to: Date()) else { return }
        
        dailyRecords = dailyRecords.filter { $0.date >= cutoffDate }
        saveData()
    }
}

