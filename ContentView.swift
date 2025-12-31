//
//  ContentView.swift
//  StepPet
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var userSettings: UserSettings
    @State private var selectedTab = 2 // Start on Today (center)
    @State private var visitedTabs: Set<Int> = [2] // Start with Today visited
    
    // Listen for navigation to Challenges
    private let navigateToChallengesNotification = NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToChallenges"))
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            // Tab Content
            TabView(selection: $selectedTab) {
                ActivityView()
                    .tag(0)
                
                InsightsView()
                    .tag(1)
                
                TodayView()
                    .tag(2)
                
                ChallengesView()
                    .tag(3)
                
                SettingsView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar with Center Highlight
            CenteredTabBar(selectedTab: $selectedTab)
        }
        .onChange(of: selectedTab) { _, newValue in
            visitedTabs.insert(newValue)
            achievementManager.updateProgress(achievementId: "explorer", progress: visitedTabs.count)
            HapticFeedback.light.trigger()
        }
        .onReceive(navigateToChallengesNotification) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = 3 // Navigate to Challenges tab
            }
        }
        .overlay {
            if achievementManager.showUnlockAnimation, let achievement = achievementManager.recentlyUnlocked {
                AchievementUnlockOverlay(achievement: achievement)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: achievementManager.showUnlockAnimation)
    }
}

// MARK: - Centered Tab Bar (Today in middle, prominent)
struct CenteredTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    // Tab order: Activity, Insights, TODAY (center), Challenges, Settings
    let tabs: [(icon: String, selectedIcon: String, title: String)] = [
        ("figure.walk.motion", "figure.walk.motion", "Activity"),
        ("chart.line.uptrend.xyaxis", "chart.line.uptrend.xyaxis", "Insights"),
        ("house", "house.fill", "Today"),
        ("trophy", "trophy.fill", "Challenges"),
        ("gearshape", "gearshape.fill", "Settings")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                if index == 2 {
                    // Center tab (Today) - Prominent
                    CenterTabButton(
                        icon: tabs[index].selectedIcon,
                        title: tabs[index].title,
                        isSelected: selectedTab == index
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                } else {
                    // Regular tabs
                    TabBarButton(
                        icon: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon,
                        title: tabs[index].title,
                        isSelected: selectedTab == index
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .padding(.bottom, 20)
        .background(
            themeManager.cardBackgroundColor
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Center Tab Button (Prominent)
struct CenterTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack {
                    // Glowing background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: themeManager.accentColor.opacity(isSelected ? 0.5 : 0.3), radius: isSelected ? 10 : 6, x: 0, y: 3)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(y: -6) // Reduced offset
                
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tab Bar Button (Regular)
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3), value: isSelected)
                
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Achievement Unlock Overlay
struct AchievementUnlockOverlay: View {
    let achievement: Achievement
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(themeManager.categoryColor(for: achievement.category).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(themeManager.categoryColor(for: achievement.category))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Challenge Complete!")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.successColor)
                    
                    Text(achievement.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(themeManager.primaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.successColor)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
        .environmentObject(UserSettings())
        .environmentObject(AchievementManager())
        .environmentObject(StepDataManager())
}
