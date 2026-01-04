//
//  ContentView.swift
//  VirtuPet
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var userSettings: UserSettings
    @StateObject private var tutorialManager = TutorialManager()
    @State private var selectedTab = 2 // Start on Today (center)
    @State private var visitedTabs: Set<Int> = [2] // Start with Today visited
    @State private var showPaywall = false // Show paywall after tutorial
    
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
            .disabled(tutorialManager.isActive) // Disable swiping during tutorial
            
            // Custom Tab Bar with Center Highlight
            CenteredTabBar(selectedTab: $selectedTab, tutorialManager: tutorialManager)
                .allowsHitTesting(!tutorialManager.isActive) // Disable tab bar during tutorial
        }
        .onChange(of: selectedTab) { _, newValue in
            visitedTabs.insert(newValue)
            achievementManager.updateProgress(achievementId: "explorer", progress: visitedTabs.count)
            HapticFeedback.light.trigger()
        }
        .onReceive(navigateToChallengesNotification) { _ in
            if !tutorialManager.isActive {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 3 // Navigate to Challenges tab
                }
            }
        }
        .overlay {
            if achievementManager.showUnlockAnimation, let achievement = achievementManager.recentlyUnlocked {
                AchievementUnlockOverlay(achievement: achievement)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .overlayPreferenceValue(TutorialHighlightKey.self) { anchors in
            if tutorialManager.isActive {
                TutorialOverlay(highlightAnchors: anchors)
                    .environmentObject(tutorialManager)
                    .environmentObject(themeManager)
                    .environmentObject(userSettings)
                    .zIndex(200)
            }
        }
        .environmentObject(tutorialManager)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: achievementManager.showUnlockAnimation)
        .onAppear {
            // Check if tutorial should start - wait 0.5s after app loads, then show tutorial
            // First-time tutorial cannot be skipped
            if userSettings.hasCompletedOnboarding && !userSettings.hasCompletedAppTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        tutorialManager.start(allowSkip: false, isFirstTime: true)
                    }
                }
            }
        }
        .onChange(of: tutorialManager.currentStep) { _, newStep in
            // Automatically switch tabs based on tutorial step
            let targetTab = newStep.tabIndex
            if selectedTab != targetTab {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = targetTab
                }
            }
        }
        .onChange(of: tutorialManager.isActive) { oldValue, newValue in
            // When tutorial ends (becomes inactive) and it was a first-time tutorial
            // and user hasn't seen paywall yet, show it
            if oldValue && !newValue && tutorialManager.isFirstTimeTutorial && !userSettings.hasSeenPaywall {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showPaywall = true
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            OnboardingPaywallView(isPresented: $showPaywall)
                .environmentObject(themeManager)
                .environmentObject(userSettings)
        }
    }
}

// MARK: - Centered Tab Bar (Today in middle, prominent) 🎨
struct CenteredTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: ThemeManager
    var tutorialManager: TutorialManager? = nil
    
    // Tab order: Activity, Insights, TODAY (center), Challenges, Settings
    // Each tab gets its own cute color! 🌈
    var tabs: [(icon: String, selectedIcon: String, title: String, tutorialID: String, color: Color)] {
        [
            ("figure.walk.motion", "figure.walk.motion", "Activity", "tutorial_tab_activity", themeManager.activityTabColor),
            ("chart.line.uptrend.xyaxis", "chart.line.uptrend.xyaxis", "Insights", "tutorial_tab_insights", themeManager.insightsTabColor),
            ("house", "house.fill", "Today", "tutorial_tab_today", themeManager.todayTabColor),
            ("trophy", "trophy.fill", "Challenges", "tutorial_tab_challenges", themeManager.challengesTabColor),
            ("gearshape", "gearshape.fill", "Settings", "tutorial_tab_settings", themeManager.settingsTabColor)
        ]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                if index == 2 {
                    // Center tab (Today) - Prominent with gradient!
                    CenterTabButton(
                        icon: tabs[index].selectedIcon,
                        title: tabs[index].title,
                        isSelected: selectedTab == index,
                        tabColor: tabs[index].color
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                        HapticFeedback.light.trigger()
                    }
                    .tutorialHighlight(tabs[index].tutorialID)
                } else {
                    // Regular tabs with colorful accents
                    ColorfulTabBarButton(
                        icon: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon,
                        title: tabs[index].title,
                        isSelected: selectedTab == index,
                        tabColor: tabs[index].color
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                        HapticFeedback.light.trigger()
                    }
                    .tutorialHighlight(tabs[index].tutorialID)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(
            ZStack {
                // Glass morphism effect
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        themeManager.primaryColor.opacity(0.03),
                                        Color.clear,
                                        themeManager.primaryColor.opacity(0.02)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0.3 : 0.08), radius: 20, x: 0, y: -5)
                    .shadow(color: themeManager.primaryColor.opacity(0.05), radius: 15, x: 0, y: -3)
            }
            .padding(.horizontal, 8)
        )
        .padding(.bottom, 0)
    }
}

// MARK: - Center Tab Button (Prominent) 🏠
struct CenterTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var tabColor: Color = .orange
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    // Enhanced glowing background with multiple layers
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tabColor, tabColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: tabColor.opacity(isSelected ? 0.7 : 0.5), radius: isSelected ? 16 : 12, x: 0, y: 4)
                        .shadow(color: tabColor.opacity(isSelected ? 0.4 : 0.2), radius: isSelected ? 24 : 18, x: 0, y: 8)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.5
                                )
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(y: -8)
                .scaleEffect(isSelected ? 1.08 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
                
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? tabColor : themeManager.secondaryTextColor)
                    .offset(y: -4)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Colorful Tab Bar Button 🎨
struct ColorfulTabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var tabColor: Color = .blue
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    // Enhanced background when selected
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [tabColor.opacity(0.18), tabColor.opacity(0.12)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(tabColor.opacity(0.2), lineWidth: 1.5)
                            )
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 21, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(isSelected ? tabColor : themeManager.secondaryTextColor)
                }
                .frame(height: 40)
                .scaleEffect(isSelected ? 1.12 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isSelected ? tabColor : themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legacy Tab Bar Button (for compatibility)
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ColorfulTabBarButton(
            icon: icon,
            title: title,
            isSelected: isSelected,
            tabColor: themeManager.accentColor,
            action: action
        )
        .environmentObject(themeManager)
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
