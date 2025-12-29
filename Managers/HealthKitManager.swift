//
//  HealthKitManager.swift
//  StepPet
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private var stepQuery: HKObserverQuery?
    
    @Published var todaySteps: Int = 0
    @Published var isAuthorized: Bool = false
    @Published var weeklySteps: [Date: Int] = [:]
    @Published var monthlySteps: [Date: Int] = [:]
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let typesToRead: Set<HKObjectType> = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.startObservingSteps()
                    self?.fetchTodaySteps()
                    self?.fetchWeeklySteps()
                    self?.fetchMonthlySteps()
                } else if let error = error {
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepType)
        
        DispatchQueue.main.async {
            self.isAuthorized = status == .sharingAuthorized
            if self.isAuthorized {
                self.startObservingSteps()
                self.fetchTodaySteps()
            }
        }
    }
    
    // MARK: - Fetch Today's Steps
    func fetchTodaySteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    if let error = error {
                        print("Error fetching today's steps: \(error.localizedDescription)")
                    }
                    return
                }
                
                self?.todaySteps = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Last 7 Days Steps
    func fetchWeeklySteps() {
        isLoading = true
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        
        // Get the last 7 days (including today)
        let today = calendar.startOfDay(for: Date())
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return }
        
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: sevenDaysAgo,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { [weak self] _, results, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let results = results else { return }
                
                var weeklyData: [Date: Int] = [:]
                let now = Date()
                
                results.enumerateStatistics(from: sevenDaysAgo, to: now) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    let startOfDay = calendar.startOfDay(for: statistics.startDate)
                    weeklyData[startOfDay] = Int(steps)
                }
                
                self?.weeklySteps = weeklyData
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Monthly Steps
    func fetchMonthlySteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        
        // Get start of month
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let startOfMonth = calendar.date(from: components) else { return }
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else { return }
        
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: startOfMonth,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { [weak self] _, results, error in
            DispatchQueue.main.async {
                guard let results = results else { return }
                
                var monthlyData: [Date: Int] = [:]
                
                results.enumerateStatistics(from: startOfMonth, to: endOfMonth) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    monthlyData[statistics.startDate] = Int(steps)
                }
                
                self?.monthlySteps = monthlyData
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Steps for Date Range
    func fetchSteps(from startDate: Date, to endDate: Date, completion: @escaping ([Date: Int]) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { _, results, error in
            DispatchQueue.main.async {
                guard let results = results else {
                    completion([:])
                    return
                }
                
                var stepData: [Date: Int] = [:]
                
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    stepData[statistics.startDate] = Int(steps)
                }
                
                completion(stepData)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Observe Steps (Real-time Updates)
    private func startObservingSteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        stepQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                return
            }
            
            self?.fetchTodaySteps()
        }
        
        if let query = stepQuery {
            healthStore.execute(query)
        }
    }
    
    // MARK: - Stop Observing
    func stopObservingSteps() {
        if let query = stepQuery {
            healthStore.stop(query)
            stepQuery = nil
        }
    }
    
    // MARK: - Historical Data
    func fetchHistoricalSteps(days: Int, completion: @escaping ([DailyStepRecord]) -> Void) {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            completion([])
            return
        }
        
        fetchSteps(from: startDate, to: endDate) { stepData in
            var records: [DailyStepRecord] = []
            
            for (date, steps) in stepData.sorted(by: { $0.key < $1.key }) {
                let record = DailyStepRecord(date: date, steps: steps, goalSteps: 10000)
                records.append(record)
            }
            
            completion(records)
        }
    }
    
    // MARK: - Weekly Summary
    func getWeeklySummary(goalSteps: Int) -> WeeklySummary {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday
        let startOfWeek = calendar.date(from: components) ?? Date()
        
        var records: [DailyStepRecord] = []
        
        for (date, steps) in weeklySteps.sorted(by: { $0.key < $1.key }) {
            let record = DailyStepRecord(date: date, steps: steps, goalSteps: goalSteps)
            records.append(record)
        }
        
        return WeeklySummary(weekStartDate: startOfWeek, dailyRecords: records)
    }
    
    // MARK: - Total Steps for Period
    var totalWeeklySteps: Int {
        weeklySteps.values.reduce(0, +)
    }
    
    var averageWeeklySteps: Int {
        guard !weeklySteps.isEmpty else { return 0 }
        return totalWeeklySteps / weeklySteps.count
    }
    
    var totalMonthlySteps: Int {
        monthlySteps.values.reduce(0, +)
    }
    
    var averageMonthlySteps: Int {
        guard !monthlySteps.isEmpty else { return 0 }
        return totalMonthlySteps / monthlySteps.count
    }
}

