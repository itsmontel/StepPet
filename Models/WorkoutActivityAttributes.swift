//
//  WorkoutActivityAttributes.swift
//  StepPet
//
//  Activity Attributes for Live Activities during workouts
//

import ActivityKit
import Foundation

// MARK: - Workout Live Activity Attributes
struct WorkoutActivityAttributes: ActivityAttributes {
    // Static context that doesn't change during the activity
    public struct ContentState: Codable, Hashable {
        // Dynamic values that update during the activity
        var elapsedTime: TimeInterval
        var distance: Double // in meters
        var pace: String
        var calories: Int
        var steps: Int
        var isActive: Bool
    }
    
    // Static values set when activity starts
    var workoutType: String
    var petName: String
    var petType: String // "cat", "dog", "bunny", "hamster", "horse"
    var petMood: String // "fullhealth", "happy", "content", "sad", "sick"
    var startTime: Date
}

// MARK: - Live Activity Manager
@available(iOS 16.2, *)
class WorkoutLiveActivityManager: ObservableObject {
    static let shared = WorkoutLiveActivityManager()
    
    @Published var currentActivity: Activity<WorkoutActivityAttributes>?
    
    private init() {}
    
    /// Start a new live activity for workout
    func startActivity(workoutType: String, petName: String, petType: String, petMood: String) {
        // Check if Live Activities are enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // End any existing activity first
        endActivity()
        
        // Create initial content state
        let initialState = WorkoutActivityAttributes.ContentState(
            elapsedTime: 0,
            distance: 0,
            pace: "--:--",
            calories: 0,
            steps: 0,
            isActive: true
        )
        
        // Create activity attributes
        let attributes = WorkoutActivityAttributes(
            workoutType: workoutType,
            petName: petName,
            petType: petType,
            petMood: petMood,
            startTime: Date()
        )
        
        // Start the activity
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    /// Update the live activity with new workout data
    func updateActivity(elapsedTime: TimeInterval, distance: Double, pace: String, calories: Int, steps: Int) {
        guard let activity = currentActivity else { return }
        
        let updatedState = WorkoutActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            distance: distance,
            pace: pace,
            calories: calories,
            steps: steps,
            isActive: true
        )
        
        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }
    
    /// End the live activity
    func endActivity() {
        guard let activity = currentActivity else { return }
        
        let finalState = WorkoutActivityAttributes.ContentState(
            elapsedTime: 0,
            distance: 0,
            pace: "--:--",
            calories: 0,
            steps: 0,
            isActive: false
        )
        
        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            await MainActor.run {
                currentActivity = nil
            }
        }
    }
    
    /// Check if live activities are available
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
}

// MARK: - Backward Compatibility Wrapper
class WorkoutLiveActivityWrapper {
    static let shared = WorkoutLiveActivityWrapper()
    
    private init() {}
    
    func startActivity(workoutType: String, petName: String, petType: String, petMood: String) {
        if #available(iOS 16.2, *) {
            WorkoutLiveActivityManager.shared.startActivity(
                workoutType: workoutType,
                petName: petName,
                petType: petType,
                petMood: petMood
            )
        }
    }
    
    func updateActivity(elapsedTime: TimeInterval, distance: Double, pace: String, calories: Int, steps: Int) {
        if #available(iOS 16.2, *) {
            WorkoutLiveActivityManager.shared.updateActivity(
                elapsedTime: elapsedTime,
                distance: distance,
                pace: pace,
                calories: calories,
                steps: steps
            )
        }
    }
    
    func endActivity() {
        if #available(iOS 16.2, *) {
            WorkoutLiveActivityManager.shared.endActivity()
        }
    }
}
