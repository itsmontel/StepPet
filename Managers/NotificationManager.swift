//
//  NotificationManager.swift
//  VirtuPet
//
//  Enhanced Notification System with Personalized Messages
//

import Foundation
import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        // Pre-save the app logo for notifications
        saveAppLogoForNotifications()
    }
    
    // MARK: - Notification Logo
    
    /// URL for the saved notification logo
    private var notificationLogoURL: URL? {
        let fileManager = FileManager.default
        guard let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return cachesDir.appendingPathComponent("notification_logo.png")
    }
    
    /// Save the app logo to a location accessible by notifications
    private func saveAppLogoForNotifications() {
        guard let logoURL = notificationLogoURL else { return }
        
        // Check if already saved
        if FileManager.default.fileExists(atPath: logoURL.path) {
            return
        }
        
        // Try to load the app logo from assets
        if let logoImage = UIImage(named: "SplashLogo") ?? UIImage(named: "FocusPetlogo") ?? UIImage(named: "Virtupet180") {
            if let pngData = logoImage.pngData() {
                try? pngData.write(to: logoURL)
            }
        }
    }
    
    /// Create a notification attachment with the app logo
    private func createLogoAttachment() -> UNNotificationAttachment? {
        guard let logoURL = notificationLogoURL,
              FileManager.default.fileExists(atPath: logoURL.path) else {
            return nil
        }
        
        // Copy to a unique temp file (required by iOS)
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("\(UUID().uuidString).png")
        
        do {
            try FileManager.default.copyItem(at: logoURL, to: tempURL)
            let attachment = try UNNotificationAttachment(identifier: "logo", url: tempURL, options: nil)
            return attachment
        } catch {
            print("Failed to create notification attachment: \(error)")
            return nil
        }
    }
    
    /// Add logo attachment to notification content
    /// NOTE: Disabled - iOS shows app icon on left automatically, attachment creates duplicate icon on right
    private func addLogoToContent(_ content: UNMutableNotificationContent) {
        // Removed attachment - the app icon shows automatically on the left side of notifications
        // Adding an attachment was causing a duplicate pet image to appear on the right side
    }
    
    // MARK: - Message Templates
    
    private let morningMessages: [(title: String, body: String)] = [
        ("Good Morning! ☀️", "{pet} is ready for an adventure! Let's get those steps in."),
        ("Rise and Shine! 🌅", "{pet} woke up excited to walk with you today!"),
        ("New Day, New Steps! 🐾", "{pet} can't wait to explore with you today."),
        ("Morning Walk Time! 🌸", "{pet} is stretching and ready to go!"),
        ("Hello Sunshine! ✨", "{pet} dreamed about walking with you. Make it real!"),
        ("Wake Up Call! 🎵", "{pet} is doing their happy dance waiting for you!"),
        ("Fresh Start! 🌿", "A new day means new adventures with {pet}!"),
        ("Morning Energy! ⚡", "{pet} has breakfast ready... just kidding! But they're ready to walk!"),
    ]
    
    private let middayMessages: [(title: String, body: String)] = [
        ("Halfway There! 🌤️", "How's your step count? {pet} is cheering you on!"),
        ("Midday Check-In! 🕐", "{pet} wants to know: have you stretched your legs?"),
        ("Afternoon Motivation! 💪", "Keep it up! {pet} believes in you!"),
        ("Quick Walk? 🚶", "{pet} thinks a quick walk would be nice right about now."),
        ("Step Check! 📊", "How are those steps looking? {pet} is curious!"),
        ("Lunch Walk? 🥗", "{pet} suggests a post-lunch stroll!"),
        ("Energy Boost! ⚡", "Feeling sluggish? {pet} knows a walk always helps!"),
        ("Progress Report! 📈", "{pet} is tracking your steps with excitement!"),
    ]
    
    private let eveningMessages: [(title: String, body: String)] = [
        ("Evening Walk Time! 🌅", "{pet} would love a walk. Time to hit your step goal!"),
        ("Sunset Stroll? 🌇", "Perfect weather for an evening walk with {pet}!"),
        ("Almost There! 🏃", "{pet} is rooting for you to reach today's goal!"),
        ("Wind Down Walk! 🌙", "{pet} thinks an evening walk would be lovely."),
        ("Golden Hour! ✨", "Beautiful time for a walk! {pet} is ready when you are."),
        ("End of Day Push! 💪", "{pet} knows you can finish strong today!"),
        ("Twilight Time! 🌆", "{pet} loves evening walks. Join them?"),
        ("Last Chance! ⏰", "Still time to hit your goal! {pet} is hopeful!"),
    ]
    
    private let streakMessages: [(title: String, body: String)] = [
        ("Streak at Risk! 🔥", "{pet} doesn't want to break your {streak}-day streak!"),
        ("Don't Break the Chain! ⛓️", "Your {streak}-day streak is on the line! {pet} believes in you!"),
        ("Save Your Streak! 💪", "{pet} worked hard for this {streak}-day streak. Quick walk?"),
        ("Urgent: Streak Alert! ⚠️", "{streak} days of progress! Don't let {pet} down now!"),
        ("Keep It Going! 🏆", "Your {streak}-day streak makes {pet} so proud. Don't stop!"),
    ]
    
    private let goalAchievedMessages: [(title: String, body: String)] = [
        ("🎉 Goal Achieved!", "{pet} is thriving! Amazing work hitting your step goal today!"),
        ("🏆 You Did It!", "{pet} is doing a happy dance! Goal reached!"),
        ("⭐ Champion!", "You crushed it today! {pet} is so proud of you!"),
        ("🎊 Celebration Time!", "{pet} is throwing confetti! You hit your goal!"),
        ("🌟 Superstar!", "Goal achieved! {pet} knew you could do it!"),
        ("💪 Mission Complete!", "Another successful day! {pet} is impressed!"),
        ("🥇 Winner!", "You're on fire! {pet} loves seeing you succeed!"),
        ("✨ Incredible!", "{pet} can't believe how awesome you are! Goal smashed!"),
    ]
    
    private let encouragementMessages: [(title: String, body: String)] = [
        ("You've Got This! 💪", "{pet} believes in you. Every step counts!"),
        ("Keep Going! 🌟", "{pet} is proud of every step you take."),
        ("Small Steps, Big Impact! 👣", "{pet} knows consistency beats perfection."),
        ("Progress Not Perfection! 📈", "{pet} celebrates your effort, not just results."),
        ("You're Doing Great! ⭐", "{pet} sees how hard you're trying!"),
        ("One Step at a Time! 🚶", "{pet} is with you every step of the way."),
    ]
    
    private let achievementMessages: [(title: String, body: String)] = [
        ("🏅 Achievement Unlocked!", "You just earned '{achievement}'! {pet} is amazed!"),
        ("🎖️ New Badge!", "Congrats! You unlocked '{achievement}'! {pet} is celebrating!"),
        ("🏆 Trophy Time!", "'{achievement}' is yours! {pet} knew you could do it!"),
        ("⭐ Level Up!", "You earned '{achievement}'! {pet} is so proud!"),
    ]
    
    private let milestoneMessages: [(title: String, body: String)] = [
        ("🎯 Milestone Reached!", "You've walked {steps} steps total! {pet} is impressed!"),
        ("📊 New Record!", "Amazing! {steps} lifetime steps! {pet} can't believe it!"),
        ("🎊 Huge Achievement!", "{steps} steps and counting! {pet} is cheering!"),
    ]
    
    private let weeklyMessages: [(title: String, body: String)] = [
        ("📊 Weekly Recap!", "You walked {steps} steps this week! {pet} averaged {health}% health!"),
        ("🗓️ Week Complete!", "Great week! {steps} steps total. {pet} loved every moment!"),
        ("📈 Weekly Stats!", "This week: {steps} steps, {streak} day streak. {pet} is proud!"),
    ]
    
    private let petMoodMessages: [String: [(title: String, body: String)]] = [
        "sick": [
            ("😢 {pet} Needs You!", "Your pet is feeling unwell. A walk could help!"),
            ("🏥 Pet Alert!", "{pet} isn't feeling great. Some steps would cheer them up!"),
            ("💔 Help {pet}!", "Your pet needs attention. Get moving to help them feel better!"),
        ],
        "sad": [
            ("😔 {pet} Misses You!", "Your pet is a bit sad. A quick walk would help!"),
            ("🥺 Cheer Up {pet}!", "{pet} would love some activity with you!"),
            ("💙 {pet} Needs Love!", "A few more steps would make {pet} happier!"),
        ],
        "content": [
            ("😊 {pet} is Content!", "Your pet is doing okay. Keep up the good work!"),
            ("👍 Good Progress!", "{pet} is feeling content. A bit more to full health!"),
        ],
        "happy": [
            ("😄 {pet} is Happy!", "Your pet is in great spirits! Almost at full health!"),
            ("🎉 Great Job!", "{pet} is happy thanks to you! Keep it up!"),
        ],
        "fullhealth": [
            ("🌟 {pet} is Thriving!", "Your pet is at full health! Amazing work!"),
            ("✨ Perfect Health!", "{pet} couldn't be happier! You're the best!"),
            ("💖 {pet} Loves You!", "Full health achieved! {pet} is so grateful!"),
        ],
    ]
    
    // MARK: - Helper Functions
    
    private func randomMessage(from messages: [(title: String, body: String)]) -> (title: String, body: String) {
        return messages.randomElement() ?? messages[0]
    }
    
    private func formatMessage(_ template: String, petName: String, streak: Int = 0, achievement: String = "", steps: Int = 0, health: Int = 0) -> String {
        var result = template
        result = result.replacingOccurrences(of: "{pet}", with: petName)
        result = result.replacingOccurrences(of: "{streak}", with: "\(streak)")
        result = result.replacingOccurrences(of: "{achievement}", with: achievement)
        result = result.replacingOccurrences(of: "{steps}", with: formatNumber(steps))
        result = result.replacingOccurrences(of: "{health}", with: "\(health)")
        return result
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
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
        let message = randomMessage(from: morningMessages)
        
        let content = UNMutableNotificationContent()
        content.title = formatMessage(message.title, petName: petName)
        content.body = formatMessage(message.body, petName: petName)
        content.sound = .default
        content.categoryIdentifier = "MORNING_MOTIVATION"
        addLogoToContent(content)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_motivation", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Mid-day Check-in
    func scheduleMidDayCheckIn(petName: String, at hour: Int = 13) {
        let message = randomMessage(from: middayMessages)
        
        let content = UNMutableNotificationContent()
        content.title = formatMessage(message.title, petName: petName)
        content.body = formatMessage(message.body, petName: petName)
        content.sound = .default
        content.categoryIdentifier = "MIDDAY_CHECKIN"
        addLogoToContent(content)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "midday_checkin", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Evening Reminder
    func scheduleEveningReminder(petName: String, at hour: Int = 18) {
        let message = randomMessage(from: eveningMessages)
        
        let content = UNMutableNotificationContent()
        content.title = formatMessage(message.title, petName: petName)
        content.body = formatMessage(message.body, petName: petName)
        content.sound = .default
        content.categoryIdentifier = "EVENING_REMINDER"
        addLogoToContent(content)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "evening_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Send Goal Achievement Notification
    func sendGoalAchievedNotification(petName: String) {
        let message = randomMessage(from: goalAchievedMessages)
        
        let content = UNMutableNotificationContent()
        content.title = formatMessage(message.title, petName: petName)
        content.body = formatMessage(message.body, petName: petName)
        content.sound = .default
        content.categoryIdentifier = "GOAL_ACHIEVED"
        addLogoToContent(content)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "goal_achieved_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Streak at Risk
    func scheduleStreakAtRisk(petName: String, streak: Int, at hour: Int = 21) {
        let message = randomMessage(from: streakMessages)
        
        let content = UNMutableNotificationContent()
        content.title = formatMessage(message.title, petName: petName, streak: streak)
        content.body = formatMessage(message.body, petName: petName, streak: streak)
        content.sound = .default
        content.categoryIdentifier = "STREAK_AT_RISK"
        content.interruptionLevel = .timeSensitive
        addLogoToContent(content)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_at_risk", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Send Pet Status Notification
    func sendPetStatusNotification(petName: String, health: Int) {
        let mood: String
        switch health {
        case 0...20:
            mood = "sick"
        case 21...40:
            mood = "sad"
        case 41...60:
            mood = "content"
        case 61...80:
            mood = "happy"
        default:
            mood = "fullhealth"
        }
        
        guard let messages = petMoodMessages[mood], let message = messages.randomElement() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = formatMessage(message.title, petName: petName)
        content.body = formatMessage(message.body, petName: petName)
        content.sound = .default
        content.categoryIdentifier = "PET_STATUS"
        addLogoToContent(content)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "pet_status_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Send Achievement Notification
    func sendAchievementNotification(petName: String, achievementTitle: String) {
        let message = randomMessage(from: achievementMessages)
        
        let content = UNMutableNotificationContent()
        content.title = formatMessage(message.title, petName: petName, achievement: achievementTitle)
        content.body = formatMessage(message.body, petName: petName, achievement: achievementTitle)
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"
        addLogoToContent(content)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "achievement_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Send Milestone Notification
    func sendMilestoneNotification(petName: String, totalSteps: Int) {
        let message = randomMessage(from: milestoneMessages)
        
        let content = UNMutableNotificationContent()
        content.title = formatMessage(message.title, petName: petName, steps: totalSteps)
        content.body = formatMessage(message.body, petName: petName, steps: totalSteps)
        content.sound = .default
        content.categoryIdentifier = "MILESTONE"
        addLogoToContent(content)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "milestone_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Send Encouragement Notification
    func sendEncouragementNotification(petName: String) {
        let message = randomMessage(from: encouragementMessages)
        
        let content = UNMutableNotificationContent()
        content.title = formatMessage(message.title, petName: petName)
        content.body = formatMessage(message.body, petName: petName)
        content.sound = .default
        content.categoryIdentifier = "ENCOURAGEMENT"
        addLogoToContent(content)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "encouragement_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Weekly Summary
    func scheduleWeeklySummary(petName: String) {
        let message = randomMessage(from: weeklyMessages)
        
        let content = UNMutableNotificationContent()
        content.title = formatMessage(message.title, petName: petName)
        content.body = "Check the app for your detailed weekly stats! 📊"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"
        addLogoToContent(content)
        
        // Schedule for Sunday at 7pm
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_summary", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Send Streak Milestone Notification
    func sendStreakMilestoneNotification(petName: String, streak: Int) {
        let content = UNMutableNotificationContent()
        
        switch streak {
        case 7:
            content.title = "🔥 One Week Streak!"
            content.body = "\(petName) is amazed! 7 days in a row!"
        case 14:
            content.title = "🔥🔥 Two Week Streak!"
            content.body = "\(petName) can't believe it! 14 days strong!"
        case 30:
            content.title = "🔥🔥🔥 Monthly Streak!"
            content.body = "INCREDIBLE! 30 days! \(petName) is so proud!"
        case 50:
            content.title = "🏆 50 Day Streak!"
            content.body = "\(petName) is speechless! You're a legend!"
        case 100:
            content.title = "💯 100 DAY STREAK!"
            content.body = "\(petName) is throwing a party! 100 days of dedication!"
        case 365:
            content.title = "👑 ONE YEAR STREAK!"
            content.body = "\(petName) has never been happier! A full year of consistency!"
        default:
            content.title = "🔥 \(streak) Day Streak!"
            content.body = "\(petName) celebrates your \(streak) day streak!"
        }
        
        content.sound = .default
        content.categoryIdentifier = "STREAK_MILESTONE"
        addLogoToContent(content)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_milestone_\(streak)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Send Inactivity Reminder
    func sendInactivityReminder(petName: String, daysMissed: Int) {
        let content = UNMutableNotificationContent()
        
        switch daysMissed {
        case 1:
            content.title = "👋 Missing You!"
            content.body = "\(petName) missed you yesterday. Ready for a walk today?"
        case 2:
            content.title = "🥺 \(petName) Misses You!"
            content.body = "It's been 2 days! \(petName) is waiting for your return."
        case 3...6:
            content.title = "💔 Come Back!"
            content.body = "\(petName) hasn't seen you in \(daysMissed) days. They really miss you!"
        default:
            content.title = "🐾 Welcome Back?"
            content.body = "\(petName) has been waiting. Even one walk would make their day!"
        }
        
        content.sound = .default
        content.categoryIdentifier = "INACTIVITY"
        addLogoToContent(content)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "inactivity_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Random Encouragement
    func scheduleRandomEncouragement(petName: String, at hour: Int = 15) {
        let message = randomMessage(from: encouragementMessages)
        
        let content = UNMutableNotificationContent()
        content.title = formatMessage(message.title, petName: petName)
        content.body = formatMessage(message.body, petName: petName)
        content.sound = .default
        content.categoryIdentifier = "ENCOURAGEMENT"
        addLogoToContent(content)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = Int.random(in: 0...59)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "random_encouragement", content: content, trigger: trigger)
        
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
        scheduleWeeklySummary(petName: petName)
        scheduleRandomEncouragement(petName: petName)
    }
    
    // MARK: - Setup Notification Categories
    func setupNotificationCategories() {
        let openAction = UNNotificationAction(identifier: "OPEN_APP", title: "Open VirtuPet", options: .foreground)
        let dismissAction = UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: .destructive)
        
        let categories = [
            UNNotificationCategory(identifier: "MORNING_MOTIVATION", actions: [openAction, dismissAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "MIDDAY_CHECKIN", actions: [openAction, dismissAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "EVENING_REMINDER", actions: [openAction, dismissAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "GOAL_ACHIEVED", actions: [openAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "STREAK_AT_RISK", actions: [openAction, dismissAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "PET_STATUS", actions: [openAction, dismissAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "ACHIEVEMENT", actions: [openAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "MILESTONE", actions: [openAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "ENCOURAGEMENT", actions: [openAction, dismissAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "WEEKLY_SUMMARY", actions: [openAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "STREAK_MILESTONE", actions: [openAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "INACTIVITY", actions: [openAction, dismissAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: "TRIAL_REMINDER", actions: [openAction], intentIdentifiers: []),
        ]
        
        UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
    }
    
    // MARK: - Get Pending Notifications Count
    func getPendingNotificationsCount(completion: @escaping (Int) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            completion(requests.count)
        }
    }
    
    // MARK: - Schedule Trial Reminder
    /// Schedules a notification to remind users 1 day before their 3-day trial ends (on day 2)
    func scheduleTrialReminder(petName: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(petName) is loving Premium with you! 💖"
        content.body = "You've unlocked so much together already! Your premium features are set to continue tomorrow—keep making \(petName) happy with your daily steps!"
        content.sound = .default
        content.categoryIdentifier = "TRIAL_REMINDER"
        
        // Schedule for 2 days from now (1 day before trial ends)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60 * 24 * 2, repeats: false)
        let request = UNNotificationRequest(identifier: "trial_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule trial reminder: \(error)")
            } else {
                print("✅ Trial reminder scheduled for 2 days from now")
            }
        }
    }
    
    // MARK: - Cancel Trial Reminder
    /// Cancels the trial reminder notification (e.g., if user cancels trial or subscribes)
    func cancelTrialReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["trial_reminder"])
        print("✅ Trial reminder cancelled")
    }
}
