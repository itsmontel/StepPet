//
//  StepPetWidget.swift
//  StepPetWidget
//
//  ✨ Cute & Colorful iOS Widgets for VirtuPet ✨
//

import WidgetKit
import SwiftUI
import UIKit

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Bundle Helper (ensures assets load in widgets + previews)
private final class WidgetBundleToken: NSObject {}
private enum WidgetResources {
    static let bundle = Bundle(for: WidgetBundleToken.self)
}

// MARK: - 🎨 Cute Widget Theme
struct CuteTheme {
    // Warm backgrounds
    static let warmCream = Color(red: 1.0, green: 0.98, blue: 0.92)
    static let softPeach = Color(red: 1.0, green: 0.95, blue: 0.90)
    static let lightLavender = Color(red: 0.96, green: 0.94, blue: 1.0)
    static let mintFresh = Color(red: 0.93, green: 0.99, blue: 0.96)
    
    // Accent colors
    static let tealPrimary = Color(red: 0.15, green: 0.72, blue: 0.65)
    static let tealLight = Color(red: 0.3, green: 0.82, blue: 0.75)
    static let coralPink = Color(red: 1.0, green: 0.55, blue: 0.55)
    static let sunnyYellow = Color(red: 1.0, green: 0.85, blue: 0.35)
    static let lavenderPurple = Color(red: 0.68, green: 0.55, blue: 0.95)
    static let skyBlue = Color(red: 0.55, green: 0.78, blue: 1.0)
    
    // Text colors
    static let textDark = Color(red: 0.2, green: 0.2, blue: 0.25)
    static let textMuted = Color(red: 0.5, green: 0.5, blue: 0.55)
    
    // Mood colors - cute pastel versions
    static let moodExcellent = Color(red: 0.4, green: 0.85, blue: 0.6)  // Minty green
    static let moodHappy = Color(red: 0.55, green: 0.85, blue: 0.5)      // Spring green
    static let moodContent = Color(red: 1.0, green: 0.82, blue: 0.4)     // Warm yellow
    static let moodSad = Color(red: 1.0, green: 0.65, blue: 0.45)        // Soft orange
    static let moodSick = Color(red: 1.0, green: 0.5, blue: 0.55)        // Coral red
    
    // Streak fire gradient
    static let fireOrange = Color(red: 1.0, green: 0.55, blue: 0.25)
    static let fireYellow = Color(red: 1.0, green: 0.85, blue: 0.35)
}

// MARK: - 🌈 Mood Display Helper
struct CuteMoodDisplay {
    let text: String
    let emoji: String
    let color: Color
    let gradient: [Color]
    
    static func from(mood: String, health: Int) -> CuteMoodDisplay {
        switch mood.lowercased() {
        case "fullhealth":
            return CuteMoodDisplay(
                text: "Amazing!",
                emoji: "✨",
                color: CuteTheme.moodExcellent,
                gradient: [Color(red: 0.4, green: 0.9, blue: 0.65), Color(red: 0.3, green: 0.8, blue: 0.55)]
            )
        case "happy":
            return CuteMoodDisplay(
                text: "Happy",
                emoji: "😊",
                color: CuteTheme.moodHappy,
                gradient: [Color(red: 0.55, green: 0.9, blue: 0.55), Color(red: 0.45, green: 0.8, blue: 0.45)]
            )
        case "content":
            return CuteMoodDisplay(
                text: "Content",
                emoji: "😌",
                color: CuteTheme.moodContent,
                gradient: [Color(red: 1.0, green: 0.85, blue: 0.45), Color(red: 1.0, green: 0.75, blue: 0.35)]
            )
        case "sad":
            return CuteMoodDisplay(
                text: "Sad",
                emoji: "😢",
                color: CuteTheme.moodSad,
                gradient: [Color(red: 1.0, green: 0.7, blue: 0.5), Color(red: 1.0, green: 0.6, blue: 0.4)]
            )
        case "sick":
            return CuteMoodDisplay(
                text: "Sick",
                emoji: "🤒",
                color: CuteTheme.moodSick,
                gradient: [Color(red: 1.0, green: 0.55, blue: 0.6), Color(red: 1.0, green: 0.45, blue: 0.5)]
            )
        default:
            return CuteMoodDisplay(
                text: "Happy",
                emoji: "💖",
                color: CuteTheme.moodHappy,
                gradient: [CuteTheme.tealPrimary, CuteTheme.tealLight]
            )
        }
    }
}

// MARK: - 🐾 Pet Image View
struct WidgetPetImageView: View {
    let petType: String
    let petMood: String
    let size: CGFloat
    
    private var imageName: String {
        let type = petType.lowercased()
        let mood = petMood.lowercased()
        return "\(type)\(mood)"
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

// MARK: - ⭐️ Decorative Elements
struct SparkleView: View {
    let size: CGFloat
    let color: Color
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

struct FloatingHeartsView: View {
    var body: some View {
        ZStack() {
            Text("💕")
                .font(.system(size: 10))
                .offset(x: -30, y: -25)
                .opacity(0.6)
            Text("✨")
                .font(.system(size: 8))
                .offset(x: 25, y: -30)
                .opacity(0.7)
            Text("💖")
                .font(.system(size: 8))
                .offset(x: 30, y: 10)
                .opacity(0.5)
        }
    }
}

// MARK: - 📊 Cute Progress Bar
struct CuteProgressBar: View {
    let progress: Double
    let height: CGFloat
    let colors: [Color]
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Color.white.opacity(0.5))
                
                // Progress fill with gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(height, geo.size.width * progress))
                
                // Shine effect
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(height, geo.size.width * progress), height: height * 0.5)
                    .offset(y: -height * 0.15)
            }
        }
        .frame(height: height)
    }
}

// MARK: - 🔢 Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StepPetEntry {
        StepPetEntry(
            date: Date(),
            petType: "dog",
            petMood: "fullhealth",
            petName: "Buddy",
            userName: "Friend",
            todaySteps: 7500,
            goalSteps: 10000,
            health: 85,
            streak: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StepPetEntry) -> ()) {
        let entry = StepPetEntry(
            date: Date(),
            petType: "dog",
            petMood: "fullhealth",
            petName: "Buddy",
            userName: "Friend",
            todaySteps: 7500,
            goalSteps: 10000,
            health: 85,
            streak: 5
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.VirtuPet")
        
        let petType = sharedDefaults?.string(forKey: "widgetPetType") ?? "dog"
        let petMood = sharedDefaults?.string(forKey: "widgetPetMood") ?? "fullhealth"
        let petName = sharedDefaults?.string(forKey: "widgetPetName") ?? "Buddy"
        let userName = sharedDefaults?.string(forKey: "widgetUserName") ?? "Friend"
        let todaySteps = sharedDefaults?.integer(forKey: "widgetTodaySteps") ?? 0
        let goalSteps = sharedDefaults?.integer(forKey: "widgetGoalSteps") ?? 10000
        let health = sharedDefaults?.integer(forKey: "widgetHealth") ?? 100
        let streak = sharedDefaults?.integer(forKey: "widgetStreak") ?? 0
        
        // Create multiple timeline entries for more frequent updates
        // This gives iOS more "scheduled" times to refresh the widget
        var entries: [StepPetEntry] = []
        let currentDate = Date()
        
        // Create entries every 5 minutes for the next hour
        // This ensures the widget has regular refresh points
        for minuteOffset in stride(from: 0, through: 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            
            let entry = StepPetEntry(
                date: entryDate,
                petType: petType,
                petMood: petMood,
                petName: petName,
                userName: userName,
                todaySteps: todaySteps,
                goalSteps: goalSteps,
                health: health,
                streak: streak
            )
            entries.append(entry)
        }
        
        // Request refresh after the last entry (in about 1 hour)
        // Use .atEnd to tell iOS to refresh as soon as the last entry is displayed
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - 📋 Timeline Entry
struct StepPetEntry: TimelineEntry {
    let date: Date
    let petType: String
    let petMood: String
    let petName: String
    let userName: String
    let todaySteps: Int
    let goalSteps: Int
    let health: Int
    let streak: Int
}

// MARK: - 🎯 Main Entry View
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
    
    private var moodDisplay: CuteMoodDisplay {
        CuteMoodDisplay.from(mood: entry.petMood, health: entry.health)
    }
    
    var body: some View {
        switch family {
        case .systemSmall:
            CuteSmallWidget(entry: entry, progress: progress, moodDisplay: moodDisplay)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        case .systemMedium:
            CuteMediumWidget(entry: entry, progress: progress, remainingSteps: remainingSteps, moodDisplay: moodDisplay)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        case .systemLarge:
            CuteLargeWidget(entry: entry, progress: progress, remainingSteps: remainingSteps, moodDisplay: moodDisplay)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        default:
            CuteMediumWidget(entry: entry, progress: progress, remainingSteps: remainingSteps, moodDisplay: moodDisplay)
        }
    }
}

// MARK: - Widget Background (PNG)
struct VirtuPetWidgetBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Fallback background color
                CuteTheme.warmCream
                
                // TEST: Try dogfullhealth which we know works
                // If this shows, then the issue is with Virtupetwidget asset specifically
                Image("dogfullhealth")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }
}

// MARK: - Steps Remaining Badge
struct StepsRemainingBadge: View {
    let remainingSteps: Int
    
    private var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: remainingSteps)) ?? "\(remainingSteps)"
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(formatted)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [CuteTheme.tealPrimary, CuteTheme.tealLight],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            
            Text("steps remaining")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(CuteTheme.textMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.65), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 🟡 Small Widget (Ultra Simple!)
struct CuteSmallWidget: View {
    let entry: StepPetEntry
    let progress: Double
    let moodDisplay: CuteMoodDisplay
    
    var body: some View {
        Image("SmallWidget")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

// MARK: - 🟠 Medium Widget (Cute & Informative!)
struct CuteMediumWidget: View {
    let entry: StepPetEntry
    let progress: Double
    let remainingSteps: Int
    let moodDisplay: CuteMoodDisplay
    
    private var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: remainingSteps)) ?? "\(remainingSteps)"
    }
    
    private var petImageName: String {
        "\(entry.petType.lowercased())\(entry.petMood.lowercased())"
    }
    
    var body: some View {
            ZStack {
            // Background PNG - fills entire widget
            Image("MiddleWidget")
                .resizable()
                .scaledToFill()
            
            // Data overlay
            VStack {
                // Top right - VirtuPet title
                HStack {
                    Spacer()
                    Text("VirtuPet")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "FF8E53"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.85))
                        )
                }
                .padding(.top, 10)
                .padding(.trailing, 12)
                
                Spacer()
                
                // Bottom right - Stats
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        // Steps remaining
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(formattedSteps)
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "FF6B4A"))
                            
                            Text("steps left")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "8B7355"))
                        }
                        
                        // Pet health with mini pet image
                        HStack(spacing: 6) {
                            // Mini pet image
                            Image(petImageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text(entry.petName)
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "8B7355"))
                                
                                HStack(spacing: 3) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(moodDisplay.color)
                                    
                                    Text("\(entry.health)%")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .foregroundColor(moodDisplay.color)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.9))
                        )
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

// MARK: - 🔴 Large Widget (Full Featured!)
struct CuteLargeWidget: View {
    let entry: StepPetEntry
    let progress: Double
    let remainingSteps: Int
    let moodDisplay: CuteMoodDisplay
    
    private var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: remainingSteps)) ?? "\(remainingSteps)"
    }
    
    private var petImageName: String {
        "\(entry.petType.lowercased())\(entry.petMood.lowercased())"
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background PNG - fills entire widget using GeometryReader
                Image("Virtupetwidget")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                // Data overlay
                VStack {
                    // Top row - Title left, Stats right
                    HStack(alignment: .top) {
                        // Top left - VirtuPet title
                            HStack(spacing: 4) {
                            Text("🐾")
                                .font(.system(size: 12))
                            Text("VirtuPet")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "FF8E53"))
                        }
                        .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                .fill(Color.white.opacity(0.9))
                        )
                        
                        Spacer()
                        
                        // Top right - Stats card
                        VStack(alignment: .trailing, spacing: 10) {
                            // Steps remaining
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formattedSteps)
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundColor(Color(hex: "FF6B4A"))
                                
                                Text("steps left")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "8B7355"))
                            }
                            
                            // Progress bar
                            VStack(alignment: .trailing, spacing: 2) {
                            ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color(hex: "E8DDD0"))
                                        .frame(width: 85, height: 5)
                                    
                                    Capsule()
                                    .fill(
                                        LinearGradient(
                                                colors: [Color(hex: "FF6B4A"), Color(hex: "FFD93D")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                        .frame(width: 85 * progress, height: 5)
                                }
                                
                                Text("\(Int(progress * 100))% complete")
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "8B7355"))
                            }
                            
                            // Pet health with mini pet image
                            HStack(spacing: 8) {
                                // Mini pet image
                                Image(petImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(moodDisplay.color, lineWidth: 2)
                                    )
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(entry.petName)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "8B7355"))
                                    
                                    HStack(spacing: 3) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(moodDisplay.color)
                                        
                                        Text("\(entry.health)%")
                                            .font(.system(size: 16, weight: .black, design: .rounded))
                                            .foregroundColor(moodDisplay.color)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.92))
                            )
                            
                            // Streak if active
                            if entry.streak > 0 {
                                HStack(spacing: 4) {
                                    Text("🔥")
                                        .font(.system(size: 11))
                                    Text("\(entry.streak) day streak!")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "FF6B4A"))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "FF6B4A").opacity(0.15))
                                )
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.85))
                        )
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 12)
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - ⚙️ Widget Configuration
struct StepPetWidget: Widget {
    let kind: String = "StepPetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
                StepPetWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("VirtuPet")
        .description("Your cute pet companion on your home screen! 🐾")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// Backward compatibility
typealias VirtuPetWidget = StepPetWidget
typealias VirtuPetEntry = StepPetEntry

// MARK: - 👀 Previews
#Preview(as: .systemSmall) {
    StepPetWidget()
} timeline: {
    StepPetEntry(date: .now, petType: "dog", petMood: "fullhealth", petName: "Buddy", userName: "Alex", todaySteps: 7500, goalSteps: 10000, health: 100, streak: 5)
    StepPetEntry(date: .now, petType: "cat", petMood: "happy", petName: "Whiskers", userName: "Sam", todaySteps: 3200, goalSteps: 10000, health: 65, streak: 0)
    StepPetEntry(date: .now, petType: "bunny", petMood: "sad", petName: "Fluffy", userName: "Jordan", todaySteps: 1500, goalSteps: 10000, health: 35, streak: 0)
}

#Preview(as: .systemMedium) {
    StepPetWidget()
} timeline: {
    StepPetEntry(date: .now, petType: "dog", petMood: "fullhealth", petName: "Buddy", userName: "Alex", todaySteps: 7500, goalSteps: 10000, health: 100, streak: 7)
    StepPetEntry(date: .now, petType: "bunny", petMood: "content", petName: "Fluffy", userName: "Sam", todaySteps: 12500, goalSteps: 10000, health: 80, streak: 14)
    StepPetEntry(date: .now, petType: "hamster", petMood: "sick", petName: "Nibbles", userName: "Jordan", todaySteps: 500, goalSteps: 10000, health: 20, streak: 0)
}

#Preview(as: .systemLarge) {
    StepPetWidget()
} timeline: {
    StepPetEntry(date: .now, petType: "dog", petMood: "fullhealth", petName: "Buddy", userName: "Alex", todaySteps: 8500, goalSteps: 10000, health: 95, streak: 12)
    StepPetEntry(date: .now, petType: "horse", petMood: "happy", petName: "Spirit", userName: "Sam", todaySteps: 15000, goalSteps: 10000, health: 100, streak: 30)
    StepPetEntry(date: .now, petType: "cat", petMood: "content", petName: "Luna", userName: "Jordan", todaySteps: 5000, goalSteps: 10000, health: 70, streak: 3)
}
