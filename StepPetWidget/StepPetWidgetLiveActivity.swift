//
//  StepPetWidgetLiveActivity.swift
//  StepPetWidget
//
//  Premium Live Activity for workout tracking on Lock Screen and Dynamic Island
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Workout Activity Attributes (Shared with main app)
struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedTime: TimeInterval
        var distance: Double // in meters
        var pace: String
        var calories: Int
        var steps: Int
        var isActive: Bool
    }
    
    var workoutType: String
    var petName: String
    var petType: String // "cat", "dog", "bunny", "hamster", "horse"
    var petMood: String // "fullhealth", "happy", "content", "sad", "sick"
    var startTime: Date
}

// MARK: - Theme Colors
struct WidgetTheme {
    static let background = Color(red: 1.0, green: 0.98, blue: 0.89)
    static let cardBackground = Color.white
    static let accent = Color(red: 0.4, green: 0.8, blue: 0.6)
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.4, green: 0.85, blue: 0.65), Color(red: 0.3, green: 0.7, blue: 0.5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let textPrimary = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let textSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)
}

// MARK: - Pet Image Helper for Live Activity
struct LiveActivityPetImage: View {
    let petType: String
    let size: CGFloat
    
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
        ZStack {
            // Background
            Circle()
                .fill(WidgetTheme.accent.opacity(0.2))
                .frame(width: size, height: size)
            
            // Emoji fallback that always shows
            Text(emoji)
                .font(.system(size: size * 0.55))
        }
    }
}

// MARK: - Live Activity Widget
struct StepPetWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen UI - Premium Design
            PremiumLockScreenView(context: context)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island UI
                DynamicIslandExpandedRegion(.leading) {
                    PremiumExpandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    PremiumExpandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    PremiumExpandedCenter(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    PremiumExpandedBottom(context: context)
                }
            } compactLeading: {
                PremiumCompactLeading(context: context)
            } compactTrailing: {
                PremiumCompactTrailing(context: context)
            } minimal: {
                PremiumMinimal(context: context)
            }
            .widgetURL(URL(string: "steppet://activity"))
            .keylineTint(WidgetTheme.accent)
        }
    }
}

// MARK: - Premium Lock Screen View
struct PremiumLockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    private var distanceInMiles: Double {
        context.state.distance * 0.000621371
    }
    
    private var formattedTime: String {
        let time = context.state.elapsedTime
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Pet Hero Section
            ZStack {
                // Glowing background for pet
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [WidgetTheme.accent.opacity(0.3), WidgetTheme.accent.opacity(0.05)],
                            center: .center,
                            startRadius: 5,
                            endRadius: 45
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // Pet image
                LiveActivityPetImage(
                    petType: context.attributes.petType,
                    size: 60
                )
            }
            .padding(.leading, 12)
            
            // Center: Pet name + Time
            VStack(alignment: .leading, spacing: 4) {
                // Pet name with activity indicator
                HStack(spacing: 6) {
                    Text(context.attributes.petName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(WidgetTheme.textPrimary)
                    
                    // Live indicator
                    HStack(spacing: 3) {
                        Circle()
                            .fill(WidgetTheme.accent)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(WidgetTheme.accent)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(WidgetTheme.accent.opacity(0.15))
                    )
                }
                
                // Large time display
                Text(formattedTime)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(WidgetTheme.textPrimary)
                    .contentTransition(.numericText())
                
                // Workout type
                Text(context.attributes.workoutType)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(WidgetTheme.textSecondary)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Right: Stats Column
            VStack(alignment: .trailing, spacing: 6) {
                PremiumStatBadge(
                    icon: "location.fill",
                    value: String(format: "%.2f", distanceInMiles),
                    unit: "mi",
                    color: .blue
                )
                
                PremiumStatBadge(
                    icon: "speedometer",
                    value: context.state.pace,
                    unit: "/mi",
                    color: .orange
                )
                
                PremiumStatBadge(
                    icon: "flame.fill",
                    value: "\(context.state.calories)",
                    unit: "cal",
                    color: .red
                )
            }
            .padding(.trailing, 14)
        }
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [WidgetTheme.background, WidgetTheme.background.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Premium Stat Badge
struct PremiumStatBadge: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(
                    Circle()
                        .fill(color)
                )
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(WidgetTheme.textPrimary)
                .contentTransition(.numericText())
            
            Text(unit)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(WidgetTheme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: color.opacity(0.15), radius: 4, y: 2)
        )
    }
}

// MARK: - Dynamic Island Views

struct PremiumExpandedLeading: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    var body: some View {
        HStack(spacing: 8) {
            // Pet image
            LiveActivityPetImage(
                petType: context.attributes.petType,
                size: 36
            )
            
            VStack(alignment: .leading, spacing: 1) {
                Text(context.attributes.petName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(context.attributes.workoutType)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

struct PremiumExpandedTrailing: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    private var formattedTime: String {
        let time = context.state.elapsedTime
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(formattedTime)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
            
            HStack(spacing: 4) {
                Circle()
                    .fill(WidgetTheme.accent)
                    .frame(width: 5, height: 5)
                Text("tracking")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

struct PremiumExpandedCenter: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    var body: some View {
        Image(systemName: "figure.walk")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(WidgetTheme.accent)
            .symbolEffect(.pulse.byLayer, options: .repeating)
    }
}

struct PremiumExpandedBottom: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    private var distanceInMiles: Double {
        context.state.distance * 0.000621371
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Distance
            ExpandedStatItem(
                icon: "location.fill",
                value: String(format: "%.2f", distanceInMiles),
                label: "miles",
                color: .blue
            )
            
            Spacer()
            
            // Pace
            ExpandedStatItem(
                icon: "speedometer",
                value: context.state.pace,
                label: "pace",
                color: .orange
            )
            
            Spacer()
            
            // Calories
            ExpandedStatItem(
                icon: "flame.fill",
                value: "\(context.state.calories)",
                label: "cal",
                color: .red
            )
            
            Spacer()
            
            // Steps
            ExpandedStatItem(
                icon: "shoeprints.fill",
                value: "\(context.state.steps)",
                label: "steps",
                color: .purple
            )
        }
        .padding(.horizontal, 4)
    }
}

struct ExpandedStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
            
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

struct PremiumCompactLeading: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    var body: some View {
        LiveActivityPetImage(
            petType: context.attributes.petType,
            size: 24
        )
    }
}

struct PremiumCompactTrailing: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    private var formattedTime: String {
        let time = context.state.elapsedTime
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.walk")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(WidgetTheme.accent)
            
            Text(formattedTime)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
    }
}

struct PremiumMinimal: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    var body: some View {
        LiveActivityPetImage(
            petType: context.attributes.petType,
            size: 20
        )
    }
}

// MARK: - Previews
extension WorkoutActivityAttributes {
    fileprivate static var preview: WorkoutActivityAttributes {
        WorkoutActivityAttributes(
            workoutType: "Activity",
            petName: "Whiskers",
            petType: "cat",
            petMood: "fullhealth",
            startTime: Date()
        )
    }
}

extension WorkoutActivityAttributes.ContentState {
    fileprivate static var active: WorkoutActivityAttributes.ContentState {
        WorkoutActivityAttributes.ContentState(
            elapsedTime: 754,
            distance: 2414,
            pace: "9:45",
            calories: 156,
            steps: 3200,
            isActive: true
        )
    }
    
    fileprivate static var starting: WorkoutActivityAttributes.ContentState {
        WorkoutActivityAttributes.ContentState(
            elapsedTime: 0,
            distance: 0,
            pace: "--:--",
            calories: 0,
            steps: 0,
            isActive: true
        )
    }
}

#Preview("Lock Screen", as: .content, using: WorkoutActivityAttributes.preview) {
    StepPetWidgetLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState.starting
    WorkoutActivityAttributes.ContentState.active
}
