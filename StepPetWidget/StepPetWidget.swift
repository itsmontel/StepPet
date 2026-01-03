//
//  StepPetWidget.swift
//  StepPetWidget
//
//  Beautiful iOS Widget for StepPet - Matching VirtuPet Design
//

import WidgetKit
import SwiftUI

// MARK: - Theme Colors
struct StepPetTheme {
    // Warm cream background like VirtuPet
    static let background = Color(red: 1.0, green: 0.98, blue: 0.92)
    static let backgroundAccent = Color(red: 0.99, green: 0.96, blue: 0.88)
    
    // Teal/Green accent colors
    static let accent = Color(red: 0.15, green: 0.68, blue: 0.55) // Teal green
    static let accentLight = Color(red: 0.2, green: 0.75, blue: 0.6)
    
    // Text colors
    static let textPrimary = Color(red: 0.15, green: 0.15, blue: 0.2)
    static let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.5)
    
    // Mood badge colors
    static let moodGreen = Color(red: 0.2, green: 0.7, blue: 0.5)
    static let moodYellow = Color(red: 0.95, green: 0.75, blue: 0.3)
    static let moodOrange = Color(red: 0.95, green: 0.55, blue: 0.3)
    static let moodRed = Color(red: 0.9, green: 0.35, blue: 0.35)
    
    // Streak orange
    static let streak = Color(red: 0.95, green: 0.5, blue: 0.2)
}

// MARK: - Mood Display Helper
struct MoodDisplay {
    let text: String
    let color: Color
    
    static func from(mood: String, health: Int) -> MoodDisplay {
        switch mood.lowercased() {
        case "fullhealth":
            return MoodDisplay(text: "Full Health", color: StepPetTheme.moodGreen)
        case "happy":
            return MoodDisplay(text: "Happy", color: StepPetTheme.moodGreen)
        case "content":
            return MoodDisplay(text: "Content", color: StepPetTheme.moodYellow)
        case "sad":
            return MoodDisplay(text: "Sad", color: StepPetTheme.moodOrange)
        case "sick":
            return MoodDisplay(text: "Sick", color: StepPetTheme.moodRed)
        default:
            return MoodDisplay(text: "Full Health", color: StepPetTheme.moodGreen)
        }
    }
}

// MARK: - Pet Image View (Uses actual assets with fallback)
struct WidgetPetImageView: View {
    let petType: String
    let petMood: String
    let size: CGFloat
    
    private var imageName: String {
        // Asset name format: "doghappy", "catfullhealth", etc.
        let type = petType.lowercased()
        let mood = petMood.lowercased()
        return "\(type)\(mood)"
    }
    
    private var emoji: String {
        switch petType.lowercased() {
        case "dog": return "🐕"
        case "cat": return "🐱"
        case "bunny": return "🐰"
        case "hamster": return "🐹"
        case "horse": return "🐴"
        default: return "🐾"
        }
    }
    
    var body: some View {
        Image(imageName)
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipped()
    }
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StepPetEntry {
        StepPetEntry(
            date: Date(),
            petType: "dog",
            petMood: "fullhealth",
            petName: "Buddy",
            todaySteps: 7500,
            goalSteps: 10000,
            health: 75,
            streak: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StepPetEntry) -> ()) {
        let entry = StepPetEntry(
            date: Date(),
            petType: "dog",
            petMood: "fullhealth",
            petName: "Buddy",
            todaySteps: 7500,
            goalSteps: 10000,
            health: 75,
            streak: 5
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Read from shared UserDefaults (App Group)
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.VirtuPet")
        
        let petType = sharedDefaults?.string(forKey: "widgetPetType") ?? "dog"
        let petMood = sharedDefaults?.string(forKey: "widgetPetMood") ?? "fullhealth"
        let petName = sharedDefaults?.string(forKey: "widgetPetName") ?? "Buddy"
        let todaySteps = sharedDefaults?.integer(forKey: "widgetTodaySteps") ?? 0
        let goalSteps = sharedDefaults?.integer(forKey: "widgetGoalSteps") ?? 10000
        let health = sharedDefaults?.integer(forKey: "widgetHealth") ?? 100
        let streak = sharedDefaults?.integer(forKey: "widgetStreak") ?? 0
        
        let entry = StepPetEntry(
            date: Date(),
            petType: petType,
            petMood: petMood,
            petName: petName,
            todaySteps: todaySteps,
            goalSteps: goalSteps,
            health: health,
            streak: streak
        )
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry
struct StepPetEntry: TimelineEntry {
    let date: Date
    let petType: String
    let petMood: String
    let petName: String
    let todaySteps: Int
    let goalSteps: Int
    let health: Int
    let streak: Int
}

// MARK: - Main Widget Entry View
struct StepPetWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    private var progress: Double {
        guard entry.goalSteps > 0 else { return 0 }
        return min(Double(entry.todaySteps) / Double(entry.goalSteps), 1.0)
    }
    
    private var remainingSteps: Int {
        max(0, entry.goalSteps - entry.todaySteps)
    }
    
    private var moodDisplay: MoodDisplay {
        MoodDisplay.from(mood: entry.petMood, health: entry.health)
    }
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry, progress: progress, moodDisplay: moodDisplay)
        case .systemMedium:
            MediumWidgetView(entry: entry, progress: progress, remainingSteps: remainingSteps, moodDisplay: moodDisplay)
        case .systemLarge:
            LargeWidgetView(entry: entry, progress: progress, remainingSteps: remainingSteps, moodDisplay: moodDisplay)
        default:
            MediumWidgetView(entry: entry, progress: progress, remainingSteps: remainingSteps, moodDisplay: moodDisplay)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: StepPetEntry
    let progress: Double
    let moodDisplay: MoodDisplay
    
    var body: some View {
        VStack(spacing: 8) {
            // Mood text
            Text(moodDisplay.text)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(moodDisplay.color)
            
            // Health bar
            VStack(spacing: 2) {
                Text("Health")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(StepPetTheme.textSecondary)
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(StepPetTheme.accent)
                        .frame(width: max(6, 70 * (Double(entry.health) / 100)), height: 6)
                }
                .frame(width: 70)
                
                Text("\(entry.health)%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(StepPetTheme.accent)
            }
            
            // Steps
            VStack(spacing: 2) {
                Text("\(entry.todaySteps)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(StepPetTheme.textPrimary)
                
                Text("steps")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(StepPetTheme.textSecondary)
            }
        }
    }
}

// MARK: - Medium Widget (VirtuPet Style)
struct MediumWidgetView: View {
    let entry: StepPetEntry
    let progress: Double
    let remainingSteps: Int
    let moodDisplay: MoodDisplay
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                StepPetTheme.background
                
                HStack(spacing: 0) {
                    // Left side - Pet section
                    VStack(spacing: 6) {
                        // Pet image
                        WidgetPetImageView(
                            petType: entry.petType,
                            petMood: entry.petMood,
                            size: min(geometry.size.height * 0.55, 80)
                        )
                        
                        // Pet name
                        Text(entry.petName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(StepPetTheme.textPrimary)
                            .lineLimit(1)
                        
                        // Mood badge
                        Text(moodDisplay.text)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(moodDisplay.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(moodDisplay.color.opacity(0.12))
                            )
                    }
                    .frame(width: geometry.size.width * 0.42)
                    
                    // Right side - Stats section
                    VStack(alignment: .leading, spacing: 10) {
                        // Health section
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("❤️")
                                    .font(.system(size: 11))
                                Text("Health")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(StepPetTheme.textSecondary)
                            }
                            
                            HStack(spacing: 8) {
                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.gray.opacity(0.15))
                                        Capsule()
                                            .fill(StepPetTheme.accent)
                                            .frame(width: max(4, geo.size.width * (Double(entry.health) / 100)))
                                    }
                                }
                                .frame(height: 8)
                                
                                Text("\(entry.health)%")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(StepPetTheme.accent)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                        
                        // Today's steps section
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("⏳")
                                    .font(.system(size: 11))
                                Text("Today")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(StepPetTheme.textSecondary)
                            }
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text(formatStepsCompact(entry.todaySteps))
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(StepPetTheme.textPrimary)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                                
                                Text("steps")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(StepPetTheme.textSecondary)
                            }
                        }
                        
                        // Streak badge at bottom right
                        HStack {
                            Spacer()
                            if entry.streak > 0 {
                                HStack(spacing: 4) {
                                    Text("🔥")
                                        .font(.system(size: 12))
                                    Text("\(entry.streak) day streak")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(StepPetTheme.streak)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func formatStepsCompact(_ steps: Int) -> String {
        if steps >= 100000 {
            return String(format: "%.0fk", Double(steps) / 1000)
        } else if steps >= 10000 {
            return String(format: "%.1fk", Double(steps) / 1000)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

// MARK: - Large Widget (Full Featured)
struct LargeWidgetView: View {
    let entry: StepPetEntry
    let progress: Double
    let remainingSteps: Int
    let moodDisplay: MoodDisplay
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                StepPetTheme.background
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("StepPet")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(StepPetTheme.accent)
                        
                        Spacer()
                        
                        if entry.streak > 0 {
                            HStack(spacing: 4) {
                                Text("🔥")
                                    .font(.system(size: 14))
                                Text("\(entry.streak)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(StepPetTheme.streak)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(StepPetTheme.streak.opacity(0.12))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Pet section - prominent
                    VStack(spacing: 8) {
                        // Large pet image
                        WidgetPetImageView(
                            petType: entry.petType,
                            petMood: entry.petMood,
                            size: min(geometry.size.width * 0.4, 130)
                        )
                        
                        // Pet name
                        Text(entry.petName)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(StepPetTheme.textPrimary)
                        
                        // Mood badge
                        Text(moodDisplay.text)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(moodDisplay.color)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(moodDisplay.color.opacity(0.12))
                            )
                    }
                    .padding(.vertical, 12)
                    
                    // Stats cards
                    HStack(spacing: 12) {
                        // Health card
                        StatCard(
                            icon: "❤️",
                            title: "Pet Health",
                            value: "\(entry.health)%",
                            progress: Double(entry.health) / 100,
                            accentColor: StepPetTheme.accent
                        )
                        
                        // Steps card
                        StatCard(
                            icon: "👟",
                            title: "Steps Today",
                            value: formatStepsLarge(entry.todaySteps),
                            progress: progress,
                            accentColor: StepPetTheme.accent
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Bottom section - Goal progress
                    VStack(spacing: 8) {
                        // Full-width progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.12))
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [StepPetTheme.accent, StepPetTheme.accentLight],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(8, geo.size.width * progress))
                            }
                        }
                        .frame(height: 10)
                        .padding(.horizontal, 20)
                        
                        // Progress text
                        HStack {
                            Text("\(Int(progress * 100))% of daily goal")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(StepPetTheme.accent)
                            
                            Spacer()
                            
                            if remainingSteps > 0 {
                                Text("\(formatStepsLarge(remainingSteps)) to go")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(StepPetTheme.textSecondary)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("Goal reached!")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(StepPetTheme.accent)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    private func formatStepsLarge(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

// MARK: - Stat Card Component (for Large Widget)
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let progress: Double
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(StepPetTheme.textSecondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(StepPetTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.12))
                    Capsule()
                        .fill(accentColor)
                        .frame(width: max(4, geo.size.width * progress))
                }
            }
            .frame(height: 5)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.5))
        )
    }
}

// MARK: - Widget Configuration
struct StepPetWidget: Widget {
    let kind: String = "StepPetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                StepPetWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        StepPetTheme.background
                    }
            } else {
                StepPetWidgetEntryView(entry: entry)
                    .padding()
                    .background(StepPetTheme.background)
            }
        }
        .configurationDisplayName("StepPet")
        .description("Track your steps and care for your pet!")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Keep old name for backward compatibility
typealias VirtuPetWidget = StepPetWidget
typealias VirtuPetEntry = StepPetEntry

// MARK: - Previews
#Preview(as: .systemSmall) {
    StepPetWidget()
} timeline: {
    StepPetEntry(date: .now, petType: "dog", petMood: "fullhealth", petName: "Buddy", todaySteps: 7500, goalSteps: 10000, health: 100, streak: 5)
    StepPetEntry(date: .now, petType: "cat", petMood: "happy", petName: "Whiskers", todaySteps: 3200, goalSteps: 10000, health: 65, streak: 0)
}

#Preview(as: .systemMedium) {
    StepPetWidget()
} timeline: {
    StepPetEntry(date: .now, petType: "dog", petMood: "fullhealth", petName: "Buddy", todaySteps: 7500, goalSteps: 10000, health: 100, streak: 1)
    StepPetEntry(date: .now, petType: "bunny", petMood: "content", petName: "Fluffy", todaySteps: 12500, goalSteps: 10000, health: 100, streak: 14)
}

#Preview(as: .systemLarge) {
    StepPetWidget()
} timeline: {
    StepPetEntry(date: .now, petType: "dog", petMood: "fullhealth", petName: "Buddy", todaySteps: 7500, goalSteps: 10000, health: 100, streak: 5)
    StepPetEntry(date: .now, petType: "hamster", petMood: "happy", petName: "Nibbles", todaySteps: 15000, goalSteps: 10000, health: 100, streak: 30)
}
