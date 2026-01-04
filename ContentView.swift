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

// MARK: - Ultra Premium Dock-Style Tab Bar ✨
struct CenteredTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: ThemeManager
    var tutorialManager: TutorialManager? = nil
    @State private var animationTrigger = false
    
    // Tab configuration
    var tabs: [(icon: String, selectedIcon: String, title: String, tutorialID: String)] {
        [
            ("figure.walk.motion", "figure.walk.motion", "Activity", "tutorial_tab_activity"),
            ("chart.line.uptrend.xyaxis", "chart.line.uptrend.xyaxis", "Insights", "tutorial_tab_insights"),
            ("pawprint.fill", "pawprint.fill", "Pet", "tutorial_tab_today"),
            ("trophy", "trophy.fill", "Games", "tutorial_tab_challenges"),
            ("gearshape", "gearshape.fill", "Settings", "tutorial_tab_settings")
        ]
    }
    
    var body: some View {
        ZStack {
            // Animated glow under selected tab
            GeometryReader { geo in
                let tabWidth = (geo.size.width - 32) / CGFloat(tabs.count)
                
                // Moving glow indicator
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                themeManager.primaryColor.opacity(0.6),
                                themeManager.primaryColor.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                    .offset(
                        x: tabWidth * CGFloat(selectedTab) + tabWidth / 2 - 40 + 16,
                        y: selectedTab == 2 ? -30 : 0
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedTab)
            }
            .frame(height: 60)
            
            // Main tab bar content
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    if index == 2 {
                        // Center tab - Premium floating orb
                        PremiumCenterOrb(
                            icon: tabs[index].selectedIcon,
                            isSelected: selectedTab == index
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                                selectedTab = index
                            }
                            HapticFeedback.medium.trigger()
                        }
                        .tutorialHighlight(tabs[index].tutorialID)
                    } else {
                        // Side tabs - Premium glass buttons
                        PremiumTabItem(
                            icon: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon,
                            title: tabs[index].title,
                            isSelected: selectedTab == index,
                            index: index,
                            selectedIndex: selectedTab
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                            HapticFeedback.light.trigger()
                        }
                        .tutorialHighlight(tabs[index].tutorialID)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 2)
            .padding(.bottom, 0)
            .background(
                // Full-width opaque dock
                ZStack {
                    // Base opaque layer - extends to edges and bottom
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 24
                    )
                    .fill(themeManager.cardBackgroundColor)
                    
                    // Inner highlight gradient
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 24
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(themeManager.isDarkMode ? 0.08 : 0.3),
                                Color.clear,
                                themeManager.primaryColor.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Top border line only
                    VStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        themeManager.primaryColor.opacity(0.1),
                                        Color.white.opacity(themeManager.isDarkMode ? 0.15 : 0.4),
                                        themeManager.primaryColor.opacity(0.1)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                        Spacer()
                    }
                }
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0.4 : 0.1), radius: 20, x: 0, y: -8)
                .shadow(color: themeManager.primaryColor.opacity(0.1), radius: 15, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Premium Center Orb (Floating Pet Button) 🐾
struct PremiumCenterOrb: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer pulsing ring (always visible, pulses when selected)
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                themeManager.primaryColor.opacity(0.4),
                                themeManager.primaryColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 74, height: 74)
                    .scaleEffect(isPulsing && isSelected ? 1.15 : 1.0)
                    .opacity(isPulsing && isSelected ? 0 : 0.8)
                    .animation(
                        isSelected ?
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: false) :
                            .default,
                        value: isPulsing
                    )
                
                // Glow backdrop
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                themeManager.primaryColor.opacity(0.5),
                                themeManager.primaryColor.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)
                    .blur(radius: 10)
                    .opacity(isSelected ? 1 : 0.5)
                
                // Main orb with 3D effect
                ZStack {
                    // Shadow layer
                    Circle()
                        .fill(themeManager.primaryColor.opacity(0.8))
                        .frame(width: 64, height: 64)
                        .offset(y: 2)
                        .blur(radius: 4)
                    
                    // Main gradient fill
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.primaryColor.opacity(1.0),
                                    themeManager.primaryColor.opacity(0.75),
                                    themeManager.primaryColor.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    // Inner shine (top-left highlight)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    // Glass reflection
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 40, height: 20)
                        .offset(y: -16)
                    
                    // Border ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1),
                                    themeManager.primaryColor.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 64, height: 64)
                }
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .offset(y: -14)
            .scaleEffect(isSelected ? 1.08 : 0.95)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .onAppear { isPulsing = true }
    }
}

// MARK: - Premium Tab Item (Side Buttons)
struct PremiumTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let index: Int
    let selectedIndex: Int
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    // Calculate if this tab is adjacent to center (for spacing)
    var isNearCenter: Bool {
        index == 1 || index == 3
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Selection background with animated reveal
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        themeManager.primaryColor.opacity(0.2),
                                        themeManager.primaryColor.opacity(0.08)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 44, height: 34)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeManager.primaryColor.opacity(0.3), lineWidth: 1)
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Icon with glow when selected
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [
                                            themeManager.primaryColor,
                                            themeManager.primaryColor.opacity(0.8)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                : AnyShapeStyle(themeManager.secondaryTextColor.opacity(0.6))
                        )
                        .shadow(
                            color: isSelected ? themeManager.primaryColor.opacity(0.4) : .clear,
                            radius: 6,
                            x: 0,
                            y: 2
                        )
                        .symbolEffect(.bounce.byLayer, value: isSelected)
                }
                .frame(height: 34)
                
                // Label
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(
                        isSelected
                            ? themeManager.primaryColor
                            : themeManager.secondaryTextColor.opacity(0.5)
                    )
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .opacity(isSelected ? 1.0 : 0.8)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legacy Support Wrappers
struct FloatingCenterTab: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        PremiumCenterOrb(icon: icon, isSelected: isSelected, action: action)
            .environmentObject(themeManager)
    }
}

struct ModernTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        PremiumTabItem(
            icon: icon,
            title: title,
            isSelected: isSelected,
            index: 0,
            selectedIndex: isSelected ? 0 : 1,
            action: action
        )
        .environmentObject(themeManager)
    }
}

struct ColorfulTabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var tabColor: Color = .blue
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        PremiumTabItem(
            icon: icon,
            title: title,
            isSelected: isSelected,
            index: 0,
            selectedIndex: isSelected ? 0 : 1,
            action: action
        )
        .environmentObject(themeManager)
    }
}

struct CenterTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var tabColor: Color = .orange
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        PremiumCenterOrb(icon: icon, isSelected: isSelected, action: action)
            .environmentObject(themeManager)
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        PremiumTabItem(
            icon: icon,
            title: title,
            isSelected: isSelected,
            index: 0,
            selectedIndex: isSelected ? 0 : 1,
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
