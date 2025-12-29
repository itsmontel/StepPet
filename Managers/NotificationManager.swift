//
//  NotificationManager.swift
//  StepPet
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Request Authorization
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Request Authorization with Completion
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            completion(granted)
        }
    }
    
    // MARK: - Schedule Morning Motivation
    func scheduleMorningMotivation(petName: String, at hour: Int = 8) {
        let content = UNMutableNotificationContent()
        content.title = "Good Morning! ☀️"
        content.body = "\(petName) is ready for an adventure! Let's get those steps in."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_motivation", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Mid-day Check-in
    func scheduleMidDayCheckIn(petName: String, at hour: Int = 13) {
        let content = UNMutableNotificationContent()
        content.title = "Halfway There! 🌤️"
        content.body = "How's your step count? \(petName) is cheering you on!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "midday_checkin", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Evening Reminder
    func scheduleEveningReminder(petName: String, at hour: Int = 18) {
        let content = UNMutableNotificationContent()
        content.title = "Evening Walk Time! 🌅"
        content.body = "\(petName) would love a walk. Time to hit your step goal!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "evening_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Send Goal Achievement Notification
    func sendGoalAchievedNotification(petName: String) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Goal Achieved!"
        content.body = "\(petName) is thriving! Amazing work hitting your step goal today!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "goal_achieved_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Streak at Risk
    func scheduleStreakAtRisk(petName: String, streak: Int, at hour: Int = 21) {
        let content = UNMutableNotificationContent()
        content.title = "Streak at Risk! ⚠️"
        content.body = "\(petName) doesn't want to break your \(streak)-day streak... Time for a quick walk!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_at_risk", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Send Pet Status Notification
    func sendPetStatusNotification(petName: String, health: Int) {
        let content = UNMutableNotificationContent()
        
        switch health {
        case 0...20:
            content.title = "\(petName) is feeling unwell 😢"
            content.body = "Your pet needs you! Get moving to help them feel better."
        case 21...40:
            content.title = "\(petName) is a bit sad 😔"
            content.body = "A few more steps would cheer them up!"
        case 41...60:
            content.title = "\(petName) is doing okay 😊"
            content.body = "Keep going! You're making progress."
        case 61...80:
            content.title = "\(petName) is happy! 😄"
            content.body = "Almost there! Just a bit more to full health."
        default:
            content.title = "\(petName) is thriving! 🌟"
            content.body = "Amazing! Your pet is at full health!"
        }
        
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "pet_status_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Cancel All Notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Cancel Specific Notification
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Update All Scheduled Notifications
    func updateScheduledNotifications(petName: String, enabled: Bool, reminderTime: Date) {
        cancelAllNotifications()
        
        guard enabled else { return }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        
        scheduleMorningMotivation(petName: petName)
        scheduleMidDayCheckIn(petName: petName)
        scheduleEveningReminder(petName: petName, at: hour)
    }
}

