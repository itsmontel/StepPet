//
//  StepPetWidget.swift
//  StepPetWidget
//
//  ✨ Cute & Colorful iOS Widgets for VirtuPet ✨
//

import WidgetKit
import SwiftUI

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
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - 📋 Timeline Entry
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
        case .systemMedium:
            CuteMediumWidget(entry: entry, progress: progress, remainingSteps: remainingSteps, moodDisplay: moodDisplay)
        case .systemLarge:
            CuteLargeWidget(entry: entry, progress: progress, remainingSteps: remainingSteps, moodDisplay: moodDisplay)
        default:
            CuteMediumWidget(entry: entry, progress: progress, remainingSteps: remainingSteps, moodDisplay: moodDisplay)
        }
    }
}

// MARK: - 🟡 Small Widget (Ultra Simple!)
struct CuteSmallWidget: View {
    let entry: StepPetEntry
    let progress: Double
    let moodDisplay: CuteMoodDisplay
    
    private var remainingSteps: Int {
        max(0, entry.goalSteps - entry.todaySteps)
    }
    
    var body: some View {
        ZStack() {
            // VirtuPet logo as background
            Image("FocusPetlogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.95)
            
            // Steps remaining in top right
            VStack() {
                HStack() {
                    Spacer()
                    
                    VStack(spacing: 2) {
                        if remainingSteps > 0 {
                            Text("\(formatSteps(remainingSteps))")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(CuteTheme.textDark)
                            
                            Text("steps remaining")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundColor(CuteTheme.textMuted)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("✓")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(CuteTheme.moodExcellent)
                            
                            Text("goal reached!")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundColor(CuteTheme.moodExcellent)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                    )
                }
                
                Spacer()
            }
            .padding(12)
        }
        .background(
            LinearGradient(
                colors: [CuteTheme.warmCream, CuteTheme.softPeach.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 10000 {
            return String(format: "%.1fk", Double(steps) / 1000)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

// MARK: - 🟠 Medium Widget (Cute & Informative!)
struct CuteMediumWidget: View {
    let entry: StepPetEntry
    let progress: Double
    let remainingSteps: Int
    let moodDisplay: CuteMoodDisplay
    
    var body: some View {
        GeometryReader { geo in
            ZStack() {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        CuteTheme.warmCream,
                        CuteTheme.softPeach.opacity(0.5),
                        CuteTheme.mintFresh.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Decorative elements
                Circle()
                    .fill(moodDisplay.color.opacity(0.12))
                    .frame(width: 100, height: 100)
                    .offset(x: -geo.size.width * 0.35, y: -30)
                
                Circle()
                    .fill(CuteTheme.sunnyYellow.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .offset(x: geo.size.width * 0.35, y: 40)
                
                HStack(spacing: 0) {
                    // Left - Pet Section
                    VStack(spacing: 6) {
                        ZStack() {
                            // Mood-colored glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [moodDisplay.color.opacity(0.3), moodDisplay.color.opacity(0)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 90, height: 90)
                            
                            WidgetPetImageView(
                                petType: entry.petType,
                                petMood: entry.petMood,
                                size: min(geo.size.height * 0.5, 70)
                            )
                        }
                        
                        // Pet name
                        Text(entry.petName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(CuteTheme.textDark)
                        
                        // Mood badge with gradient
                        HStack(spacing: 4) {
                            Text(moodDisplay.emoji)
                                .font(.system(size: 11))
                            Text(moodDisplay.text)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: moodDisplay.gradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: moodDisplay.color.opacity(0.3), radius: 4, y: 2)
                        )
                    }
                    .frame(width: geo.size.width * 0.4)
                    
                    // Right - Stats Section
                    VStack(alignment: .leading, spacing: 10) {
                        // Health card
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("💖")
                                    .font(.system(size: 12))
                                Text("Health")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(CuteTheme.textMuted)
                                Spacer()
                                Text("\(entry.health)%")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(moodDisplay.color)
                            }
                            
                            CuteProgressBar(
                                progress: Double(entry.health) / 100,
                                height: 8,
                                colors: moodDisplay.gradient
                            )
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.7))
                                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                        )
                        
                        // Steps card
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("👟")
                                    .font(.system(size: 12))
                                Text("Steps")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(CuteTheme.textMuted)
                            }
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text(formatSteps(entry.todaySteps))
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(CuteTheme.textDark)
                                    .minimumScaleFactor(0.7)
                                
                                Text("/ \(formatSteps(entry.goalSteps))")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(CuteTheme.textMuted)
                            }
                            
                            CuteProgressBar(
                                progress: progress,
                                height: 8,
                                colors: [CuteTheme.tealPrimary, CuteTheme.tealLight]
                            )
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.7))
                                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                        )
                        
                        // Streak badge
                        if entry.streak > 0 {
                            HStack(spacing: 4) {
                                Text("🔥")
                                    .font(.system(size: 12))
                                Text("\(entry.streak) day streak!")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(CuteTheme.fireOrange)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [CuteTheme.fireYellow.opacity(0.3), CuteTheme.fireOrange.opacity(0.2)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
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

// MARK: - 🔴 Large Widget (Full Feature Cuteness!)
struct CuteLargeWidget: View {
    let entry: StepPetEntry
    let progress: Double
    let remainingSteps: Int
    let moodDisplay: CuteMoodDisplay
    
    var body: some View {
        GeometryReader { geo in
            ZStack() {
                // Multi-layer gradient background
                LinearGradient(
                    colors: [
                        CuteTheme.warmCream,
                        CuteTheme.softPeach.opacity(0.4),
                        CuteTheme.lightLavender.opacity(0.3),
                        CuteTheme.mintFresh.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Decorative circles
                Circle()
                    .fill(moodDisplay.color.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .offset(x: -geo.size.width * 0.4, y: -geo.size.height * 0.25)
                
                Circle()
                    .fill(CuteTheme.sunnyYellow.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.1)
                
                Circle()
                    .fill(CuteTheme.lavenderPurple.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.35)
                
                VStack(spacing: 0) {
                    // Header with app name and streak
                    HStack() {
                        HStack(spacing: 6) {
                            Text("🐾")
                                .font(.system(size: 16))
                            Text("VirtuPet")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundColor(CuteTheme.tealPrimary)
                        }
                        
                        Spacer()
                        
                        if entry.streak > 0 {
                            HStack(spacing: 4) {
                                Text("🔥")
                                    .font(.system(size: 14))
                                Text("\(entry.streak)")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundColor(CuteTheme.fireOrange)
                                Text("days")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(CuteTheme.fireOrange.opacity(0.8))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [CuteTheme.fireYellow.opacity(0.3), CuteTheme.fireOrange.opacity(0.2)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: CuteTheme.fireOrange.opacity(0.2), radius: 4, y: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Pet section - hero area
                    ZStack() {
                        // Large glow behind pet
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [moodDisplay.color.opacity(0.25), moodDisplay.color.opacity(0)],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                        
                        VStack(spacing: 8) {
                            WidgetPetImageView(
                                petType: entry.petType,
                                petMood: entry.petMood,
                                size: min(geo.size.width * 0.35, 120)
                            )
                            
                            // Pet name
                            Text(entry.petName)
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(CuteTheme.textDark)
                            
                            // Mood badge with emoji
                            HStack(spacing: 6) {
                                Text(moodDisplay.emoji)
                                    .font(.system(size: 14))
                                Text(moodDisplay.text)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: moodDisplay.gradient,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: moodDisplay.color.opacity(0.35), radius: 6, y: 3)
                            )
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Stats cards row
                    HStack(spacing: 12) {
                        // Health card
                        CuteStatCard(
                            emoji: "💖",
                            title: "Health",
                            value: "\(entry.health)%",
                            progress: Double(entry.health) / 100,
                            colors: moodDisplay.gradient,
                            bgColor: moodDisplay.color.opacity(0.08)
                        )
                        
                        // Steps card
                        CuteStatCard(
                            emoji: "👟",
                            title: "Steps",
                            value: formatSteps(entry.todaySteps),
                            progress: progress,
                            colors: [CuteTheme.tealPrimary, CuteTheme.tealLight],
                            bgColor: CuteTheme.tealPrimary.opacity(0.08)
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 8)
                    
                    // Bottom progress section
                    VStack(spacing: 8) {
                        // Goal progress bar
                        VStack(spacing: 6) {
                            HStack() {
                                Text("🎯 Daily Goal")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(CuteTheme.textDark)
                                
                                Spacer()
                                
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(CuteTheme.tealPrimary)
                            }
                            
                            CuteProgressBar(
                                progress: progress,
                                height: 12,
                                colors: [CuteTheme.tealPrimary, CuteTheme.tealLight, CuteTheme.skyBlue]
                            )
                            
                            HStack() {
                                if remainingSteps > 0 {
                                    Text("\(formatSteps(remainingSteps)) more to go!")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(CuteTheme.textMuted)
                                } else {
                                    HStack(spacing: 4) {
                                        Text("🎉")
                                            .font(.system(size: 12))
                                        Text("Goal reached! Amazing!")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(CuteTheme.moodExcellent)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("Goal: \(formatSteps(entry.goalSteps))")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(CuteTheme.textMuted)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.7))
                                .shadow(color: Color.black.opacity(0.05), radius: 6, y: 3)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

// MARK: - 📊 Cute Stat Card Component
struct CuteStatCard: View {
    let emoji: String
    let title: String
    let value: String
    let progress: Double
    let colors: [Color]
    let bgColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(CuteTheme.textMuted)
            }
            
            Text(value)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(CuteTheme.textDark)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            CuteProgressBar(
                progress: progress,
                height: 6,
                colors: colors
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(bgColor)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        )
    }
}

// MARK: - ⚙️ Widget Configuration
struct StepPetWidget: Widget {
    let kind: String = "StepPetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                StepPetWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        LinearGradient(
                            colors: [CuteTheme.warmCream, CuteTheme.softPeach.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
            } else {
                StepPetWidgetEntryView(entry: entry)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [CuteTheme.warmCream, CuteTheme.softPeach.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .configurationDisplayName("VirtuPet")
        .description("Your cute pet companion on your home screen! 🐾")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Backward compatibility
typealias VirtuPetWidget = StepPetWidget
typealias VirtuPetEntry = StepPetEntry

// MARK: - 👀 Previews
#Preview(as: .systemSmall) {
    StepPetWidget()
} timeline: {
    StepPetEntry(date: .now, petType: "dog", petMood: "fullhealth", petName: "Buddy", todaySteps: 7500, goalSteps: 10000, health: 100, streak: 5)
    StepPetEntry(date: .now, petType: "cat", petMood: "happy", petName: "Whiskers", todaySteps: 3200, goalSteps: 10000, health: 65, streak: 0)
    StepPetEntry(date: .now, petType: "bunny", petMood: "sad", petName: "Fluffy", todaySteps: 1500, goalSteps: 10000, health: 35, streak: 0)
}

#Preview(as: .systemMedium) {
    StepPetWidget()
} timeline: {
    StepPetEntry(date: .now, petType: "dog", petMood: "fullhealth", petName: "Buddy", todaySteps: 7500, goalSteps: 10000, health: 100, streak: 7)
    StepPetEntry(date: .now, petType: "bunny", petMood: "content", petName: "Fluffy", todaySteps: 12500, goalSteps: 10000, health: 80, streak: 14)
    StepPetEntry(date: .now, petType: "hamster", petMood: "sick", petName: "Nibbles", todaySteps: 500, goalSteps: 10000, health: 20, streak: 0)
}

#Preview(as: .systemLarge) {
    StepPetWidget()
} timeline: {
    StepPetEntry(date: .now, petType: "dog", petMood: "fullhealth", petName: "Buddy", todaySteps: 8500, goalSteps: 10000, health: 95, streak: 12)
    StepPetEntry(date: .now, petType: "horse", petMood: "happy", petName: "Spirit", todaySteps: 15000, goalSteps: 10000, health: 100, streak: 30)
    StepPetEntry(date: .now, petType: "cat", petMood: "content", petName: "Luna", todaySteps: 5000, goalSteps: 10000, health: 70, streak: 3)
}
