//
//  ContentView.swift
//  StepPet
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var achievementManager: AchievementManager
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            // Tab Content
            TabView(selection: $selectedTab) {
                TodayView()
                    .tag(0)
                
                HistoryView()
                    .tag(1)
                
                PetCustomizationView()
                    .tag(2)
                
                AchievementsView()
                    .tag(3)
                
                SettingsView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .onChange(of: selectedTab) { _, newValue in
            // Track visited sections for explorer achievement
            achievementManager.updateProgress(achievementId: "explorer", progress: min(newValue + 1, 5))
            
            // Trigger haptic
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        .overlay {
            // Achievement Unlock Animation
            if achievementManager.showUnlockAnimation, let achievement = achievementManager.recentlyUnlocked {
                AchievementUnlockOverlay(achievement: achievement)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: achievementManager.showUnlockAnimation)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    let tabs: [(icon: String, selectedIcon: String, title: String)] = [
        ("house", "house.fill", "Today"),
        ("chart.bar", "chart.bar.fill", "History"),
        ("pawprint", "pawprint.fill", "Pets"),
        ("trophy", "trophy.fill", "Achievements"),
        ("gearshape", "gearshape.fill", "Settings")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
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
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            themeManager.cardBackgroundColor
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isSelected)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
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
                // Icon
                ZStack {
                    Circle()
                        .fill(themeManager.categoryColor(for: achievement.category).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(themeManager.categoryColor(for: achievement.category))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Achievement Unlocked!")
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
