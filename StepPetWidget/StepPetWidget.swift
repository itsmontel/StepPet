//
//  StepPetWidget.swift
//  StepPetWidget
//
//  Premium Home Screen Widget for StepPet
//

import WidgetKit
import SwiftUI

// MARK: - Theme
struct StepPetWidgetTheme {
    static let background = Color(red: 1.0, green: 0.98, blue: 0.89)
    static let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    static let accentDark = Color(red: 0.3, green: 0.7, blue: 0.5)
    static let textPrimary = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let textSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StepPetEntry {
        StepPetEntry(
            date: Date(),
            petType: "cat",
            petMood: "fullhealth",
            petName: "Whiskers",
            todaySteps: 5432,
            goalSteps: 10000,
            health: 75,
            streak: 7
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StepPetEntry) -> ()) {
        let entry = StepPetEntry(
            date: Date(),
            petType: "cat",
            petMood: "fullhealth",
            petName: "Whiskers",
            todaySteps: 5432,
            goalSteps: 10000,
            health: 75,
            streak: 7
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Read from shared UserDefaults (App Group)
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.StepPet")
        
        let petType = sharedDefaults?.string(forKey: "widgetPetType") ?? "cat"
        let petMood = sharedDefaults?.string(forKey: "widgetPetMood") ?? "fullhealth"
        let petName = sharedDefaults?.string(forKey: "widgetPetName") ?? "Pet"
        let todaySteps = sharedDefaults?.integer(forKey: "widgetTodaySteps") ?? 0
        let goalSteps = sharedDefaults?.integer(forKey: "widgetGoalSteps") ?? 10000
        let health = sharedDefaults?.integer(forKey: "widgetHealth") ?? 50
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

// MARK: - Widget View
struct StepPetWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    private var progress: Double {
        guard entry.goalSteps > 0 else { return 0 }
        return min(Double(entry.todaySteps) / Double(entry.goalSteps), 1.0)
    }
    
    private var healthColor: Color {
        switch entry.health {
        case 0...20: return .red
        case 21...39: return .orange
        case 40...59: return .yellow
        default: return StepPetWidgetTheme.accent
        }
    }
    
    private var petImageName: String {
        "\(entry.petType)\(entry.petMood)"
    }
    
    private var petSymbol: String {
        switch entry.petType.lowercased() {
        case "cat": return "cat.fill"
        case "dog": return "dog.fill"
        case "bunny", "rabbit": return "hare.fill"
        case "hamster": return "lizard.fill" // closest match
        case "horse": return "🐴"
        default: return "pawprint.fill"
        }
    }
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry, progress: progress, healthColor: healthColor, petImageName: petImageName, petSymbol: petSymbol)
        case .systemMedium:
            MediumWidgetView(entry: entry, progress: progress, healthColor: healthColor, petImageName: petImageName, petSymbol: petSymbol)
        default:
            SmallWidgetView(entry: entry, progress: progress, healthColor: healthColor, petImageName: petImageName, petSymbol: petSymbol)
        }
    }
}

// MARK: - Small Widget (Completely Redesigned)
struct SmallWidgetView: View {
    let entry: StepPetEntry
    let progress: Double
    let healthColor: Color
    let petImageName: String
    let petSymbol: String
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    StepPetWidgetTheme.background,
                    StepPetWidgetTheme.background.opacity(0.95),
                    healthColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 6) {
                // Top: Pet name + streak
                HStack {
                    Text(entry.petName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(StepPetWidgetTheme.textPrimary)
                    
                    Spacer()
                    
                    if entry.streak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                            Text("\(entry.streak)")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                
                // Center: Pet with health ring - HERO
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [healthColor.opacity(0.3), healthColor.opacity(0.0)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 50
                            )
                        )
                        .frame(width: 85, height: 85)
                    
                    // Health ring background
                    Circle()
                        .stroke(healthColor.opacity(0.15), lineWidth: 5)
                        .frame(width: 65, height: 65)
                    
                    // Health ring progress
                    Circle()
                        .trim(from: 0, to: Double(entry.health) / 100)
                        .stroke(
                            LinearGradient(
                                colors: [healthColor, healthColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 65, height: 65)
                        .rotationEffect(.degrees(-90))
                    
                    // Pet image - THE HERO
                    if let _ = UIImage(named: petImageName, in: Bundle.main, with: nil) {
                        Image(petImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 45, height: 45)
                    } else {
                        // Fallback to SF Symbol
                        Image(systemName: petSymbol)
                            .font(.system(size: 35, weight: .medium))
                            .foregroundColor(healthColor)
                            .frame(width: 45, height: 45)
                    }
                }
                
                // Bottom: Steps + Progress
                VStack(spacing: 4) {
                    // Steps count - big and bold
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(entry.todaySteps)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(StepPetWidgetTheme.textPrimary)
                        
                        Text("steps")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(StepPetWidgetTheme.textSecondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            Capsule()
                                .fill(Color.gray.opacity(0.15))
                            
                            // Progress
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [StepPetWidgetTheme.accent, StepPetWidgetTheme.accentDark],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(5, geo.size.width * progress))
                        }
                    }
                    .frame(height: 5)
                    .padding(.horizontal, 14)
                    
                    // Percentage
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(StepPetWidgetTheme.accent)
                }
                .padding(.bottom, 10)
            }
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: StepPetEntry
    let progress: Double
    let healthColor: Color
    let petImageName: String
    let petSymbol: String
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    StepPetWidgetTheme.background,
                    StepPetWidgetTheme.background.opacity(0.95),
                    healthColor.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 0) {
                // Left: Pet Hero
                VStack(spacing: 6) {
                    ZStack {
                        // Glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [healthColor.opacity(0.35), healthColor.opacity(0.0)],
                                    center: .center,
                                    startRadius: 15,
                                    endRadius: 55
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        // Health ring background
                        Circle()
                            .stroke(healthColor.opacity(0.15), lineWidth: 6)
                            .frame(width: 80, height: 80)
                        
                        // Health ring progress
                        Circle()
                            .trim(from: 0, to: Double(entry.health) / 100)
                            .stroke(
                                LinearGradient(
                                    colors: [healthColor, healthColor.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        // Pet - HERO
                        if let _ = UIImage(named: petImageName, in: Bundle.main, with: nil) {
                            Image(petImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 52, height: 52)
                        } else {
                            // Fallback to SF Symbol
                            Image(systemName: petSymbol)
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(healthColor)
                                .frame(width: 52, height: 52)
                        }
                    }
                    
                    // Pet name
                    Text(entry.petName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(StepPetWidgetTheme.textPrimary)
                        .lineLimit(1)
                    
                    // Health badge
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                        Text("\(entry.health)%")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(healthColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(healthColor.opacity(0.12))
                    )
                }
                .frame(width: 130)
                
                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.gray.opacity(0.2), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
                    .padding(.vertical, 20)
                
                // Right: Stats
                VStack(alignment: .leading, spacing: 10) {
                    // Header with streak
                    HStack {
                        Text("Today")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(StepPetWidgetTheme.textSecondary)
                        
                        Spacer()
                        
                        // Streak badge
                        if entry.streak > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                Text("\(entry.streak)")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.12))
                            )
                        }
                    }
                    
                    // Steps - Big number
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(entry.todaySteps)")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(StepPetWidgetTheme.textPrimary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        
                        Text("/ \(entry.goalSteps)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(StepPetWidgetTheme.textSecondary)
                    }
                    
                    // Progress section
                    VStack(alignment: .leading, spacing: 5) {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.12))
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [StepPetWidgetTheme.accent, StepPetWidgetTheme.accentDark],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(8, geo.size.width * progress))
                                    .shadow(color: StepPetWidgetTheme.accent.opacity(0.3), radius: 2, y: 1)
                            }
                        }
                        .frame(height: 8)
                        
                        // Progress text
                        HStack {
                            Text("\(Int(progress * 100))% complete")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(StepPetWidgetTheme.accent)
                            
                            Spacer()
                            
                            if progress >= 1.0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                    Text("Done!")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(StepPetWidgetTheme.accent)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Widget Configuration
struct StepPetWidget: Widget {
    let kind: String = "StepPetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                StepPetWidgetEntryView(entry: entry)
                    .containerBackground(StepPetWidgetTheme.background, for: .widget)
            } else {
                StepPetWidgetEntryView(entry: entry)
                    .background(StepPetWidgetTheme.background)
            }
        }
        .configurationDisplayName("StepPet")
        .description("See your pet and track daily steps at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    StepPetWidget()
} timeline: {
    StepPetEntry(date: .now, petType: "cat", petMood: "fullhealth", petName: "Whiskers", todaySteps: 5432, goalSteps: 10000, health: 75, streak: 7)
    StepPetEntry(date: .now, petType: "dog", petMood: "happy", petName: "Buddy", todaySteps: 10000, goalSteps: 10000, health: 100, streak: 30)
}

#Preview(as: .systemMedium) {
    StepPetWidget()
} timeline: {
    StepPetEntry(date: .now, petType: "cat", petMood: "fullhealth", petName: "Whiskers", todaySteps: 5432, goalSteps: 10000, health: 75, streak: 7)
    StepPetEntry(date: .now, petType: "bunny", petMood: "content", petName: "Fluffy", todaySteps: 12500, goalSteps: 10000, health: 100, streak: 14)
}
