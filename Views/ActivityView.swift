//
//  ActivityView.swift
//  StepPet
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Walk Record Model
struct WalkRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let workoutType: String // "walk" or "run"
    let distance: Double // in meters
    let duration: TimeInterval
    let routeCoordinates: [CodableCoordinate]
    let calories: Int
    
    var distanceInMiles: Double {
        distance * 0.000621371
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var pace: String {
        guard distanceInMiles > 0.01 else { return "--:--" }
        let paceMinutes = duration / 60 / distanceInMiles
        let mins = Int(paceMinutes)
        let secs = Int((paceMinutes - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
    
    init(id: UUID = UUID(), date: Date = Date(), workoutType: String, distance: Double, duration: TimeInterval, routeCoordinates: [CLLocationCoordinate2D], calories: Int) {
        self.id = id
        self.date = date
        self.workoutType = workoutType
        self.distance = distance
        self.duration = duration
        self.routeCoordinates = routeCoordinates.map { CodableCoordinate(coordinate: $0) }
        self.calories = calories
    }
    
    var coordinates: [CLLocationCoordinate2D] {
        routeCoordinates.map { $0.coordinate }
    }
}

struct CodableCoordinate: Codable {
    let latitude: Double
    let longitude: Double
    
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Walk History Manager
class WalkHistoryManager: ObservableObject {
    @Published var walkHistory: [WalkRecord] = []
    
    private let userDefaultsKey = "walkHistory"
    
    init() {
        loadHistory()
    }
    
    func saveWalk(_ record: WalkRecord) {
        walkHistory.insert(record, at: 0)
        saveHistory()
    }
    
    func deleteWalk(at offsets: IndexSet) {
        walkHistory.remove(atOffsets: offsets)
        saveHistory()
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([WalkRecord].self, from: data) {
            walkHistory = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(walkHistory) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    var thisWeekWalks: [WalkRecord] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return walkHistory.filter { $0.date >= weekAgo }
    }
    
    var thisMonthWalks: [WalkRecord] {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return walkHistory.filter { $0.date >= monthAgo }
    }
    
    var totalDistanceThisWeek: Double {
        thisWeekWalks.reduce(0) { $0 + $1.distanceInMiles }
    }
    
    var totalTimeThisWeek: TimeInterval {
        thisWeekWalks.reduce(0) { $0 + $1.duration }
    }
}

// MARK: - Location Manager
class ActivityLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    @Published var isTracking = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var totalDistance: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    private var lastLocation: CLLocation?
    private var startTime: Date?
    private var timer: Timer?
    private var hasSetInitialRegion = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.activityType = .fitness
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
    }
    
    func requestPermission() {
        manager.requestAlwaysAuthorization()
    }
    
    func startTracking() {
        manager.startUpdatingLocation()
        isTracking = true
        startTime = Date()
        routeCoordinates = []
        totalDistance = 0
        elapsedTime = 0
        lastLocation = nil
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            DispatchQueue.main.async {
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }
    
    func stopTracking() -> (distance: Double, duration: TimeInterval, route: [CLLocationCoordinate2D]) {
        isTracking = false
        timer?.invalidate()
        timer = nil
        
        let result = (totalDistance, elapsedTime, routeCoordinates)
        return result
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        DispatchQueue.main.async {
            self.location = newLocation.coordinate
            
            // Update region to follow user
            self.region = MKCoordinateRegion(
                center: newLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
            self.hasSetInitialRegion = true
            
            if self.isTracking {
                self.routeCoordinates.append(newLocation.coordinate)
                
                if let last = self.lastLocation {
                    self.totalDistance += newLocation.distance(from: last)
                }
                self.lastLocation = newLocation
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }
}

// MARK: - Activity Type
enum ActivityType: String, CaseIterable {
    case walk = "Walk"
    case run = "Run"
    
    var icon: String {
        switch self {
        case .walk: return "figure.walk"
        case .run: return "figure.run"
        }
    }
    
    var color: Color {
        switch self {
        case .walk: return .green
        case .run: return .orange
        }
    }
    
    var encouragements: [String] {
        switch self {
        case .walk:
            return [
                "Great pace! 🐾",
                "Your pet loves this!",
                "Keep moving! 💪",
                "Fresh air feels good!",
                "You're doing amazing!"
            ]
        case .run:
            return [
                "You're on fire! 🔥",
                "Crush it!",
                "Feel the speed! 💨",
                "Amazing energy!",
                "Keep going strong!"
            ]
        }
    }
}

// MARK: - Main Activity View
struct ActivityView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    
    @StateObject private var locationManager = ActivityLocationManager()
    @StateObject private var walkHistory = WalkHistoryManager()
    
    @State private var selectedActivity: ActivityType = .walk
    @State private var isWorkoutActive = false
    @State private var showHistory = false
    @State private var showPermissionAlert = false
    @State private var currentEncouragement = ""
    @State private var showWorkoutComplete = false
    @State private var lastCompletedWorkout: WalkRecord?
    @State private var encouragementTimer: Timer?
    
    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor.ignoresSafeArea()
            
            if isWorkoutActive {
                // Active Workout View
                activeWorkoutView
            } else {
                // Main Activity View
                mainActivityView
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .sheet(isPresented: $showHistory) {
            ActivityHistoryView(walkHistory: walkHistory)
        }
        .sheet(isPresented: $showWorkoutComplete) {
            if let workout = lastCompletedWorkout {
                WorkoutCompleteSheet(workout: workout)
            }
        }
        .alert("Location Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("StepPet needs location access to track your activities. Please enable it in Settings.")
        }
    }
    
    // MARK: - Main Activity View
    private var mainActivityView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Weekly Stats Card
                weeklyStatsCard
                
                // Start Activity Section
                startActivitySection
                
                // Recent Activities
                recentActivitiesSection
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Track your walks with \(userSettings.pet.name)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // History Button - More Prominent
            Button(action: { 
                HapticFeedback.light.trigger()
                showHistory = true 
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if !walkHistory.walkHistory.isEmpty {
                        Text("\(walkHistory.walkHistory.count)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    
                    Text("History")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: themeManager.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Weekly Stats Card (Compact)
    private var weeklyStatsCard: some View {
        HStack(spacing: 12) {
            // Activities count
            CompactStatPill(
                icon: "figure.walk",
                value: "\(walkHistory.thisWeekWalks.count)",
                label: "activities",
                color: .blue
            )
            
            // Distance
            CompactStatPill(
                icon: "map.fill",
                value: String(format: "%.1f", walkHistory.totalDistanceThisWeek),
                label: "mi",
                color: .green
            )
            
            // Time
            CompactStatPill(
                icon: "clock.fill",
                value: formatTimeCompact(walkHistory.totalTimeThisWeek),
                label: "",
                color: .purple
            )
            
            // Calories
            CompactStatPill(
                icon: "flame.fill",
                value: "\(walkHistory.thisWeekWalks.reduce(0) { $0 + $1.calories })",
                label: "cal",
                color: .orange
            )
        }
    }
    
    private func formatTimeCompact(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
    
    // MARK: - Start Activity Section
    private var startActivitySection: some View {
        VStack(spacing: 16) {
            // Activity Type Selector (more compact)
            HStack(spacing: 10) {
                ForEach(ActivityType.allCases, id: \.self) { activity in
                    CompactActivityButton(
                        activity: activity,
                        isSelected: selectedActivity == activity,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedActivity = activity
                            }
                            HapticFeedback.light.trigger()
                        }
                    )
                }
            }
            
            // Map Preview with Pet Location - BIGGER
            ZStack {
                Map(initialPosition: .region(locationManager.region)) {
                    if let location = locationManager.location {
                        Annotation("", coordinate: location) {
                            PetMapMarker(petType: userSettings.pet.type, color: selectedActivity.color)
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .onAppear {
                    // Keep requesting location updates
                    locationManager.requestPermission()
                }
                
                // Pet location indicator if no permission yet
                if locationManager.location == nil {
                    VStack {
                        Image(systemName: "location.slash.fill")
                            .font(.system(size: 28))
                            .foregroundColor(themeManager.secondaryTextColor)
                        Text("Enable location to see your position")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            
            // Start Button
            Button(action: startWorkout) {
                HStack(spacing: 12) {
                    Image(systemName: selectedActivity.icon)
                        .font(.system(size: 22, weight: .bold))
                    
                    Text("Start \(selectedActivity.rawValue)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [selectedActivity.color, selectedActivity.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: selectedActivity.color.opacity(0.4), radius: 15, x: 0, y: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(selectedActivity.color.opacity(0.06))
        )
    }
    
    // MARK: - Recent Activities Section
    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                if !walkHistory.walkHistory.isEmpty {
                    Button(action: { showHistory = true }) {
                        Text("See All")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            
            if walkHistory.walkHistory.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    AnimatedPetVideoView(petType: userSettings.pet.type, moodState: .content)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    
                    Text("No activities yet")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("Start a walk to track your first activity!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeManager.secondaryTextColor.opacity(0.05))
                )
            } else {
                // Recent Activities List
                VStack(spacing: 12) {
                    ForEach(Array(walkHistory.walkHistory.prefix(3))) { walk in
                        RecentActivityCard(walk: walk)
                    }
                }
            }
        }
    }
    
    // MARK: - Active Workout View
    private var activeWorkoutView: some View {
        ZStack {
            // Map - follows user location
            Map(initialPosition: .region(locationManager.region)) {
                if let location = locationManager.location {
                    Annotation("", coordinate: location) {
                        PetMapMarker(petType: userSettings.pet.type, color: selectedActivity.color)
                    }
                }
                
                if !locationManager.routeCoordinates.isEmpty {
                    MapPolyline(coordinates: locationManager.routeCoordinates)
                        .stroke(selectedActivity.color, lineWidth: 5)
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            // Stats Overlay
            VStack {
                // Top Stats Bar
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        WorkoutStatPill(title: "Distance", value: String(format: "%.2f mi", locationManager.totalDistance * 0.000621371), color: selectedActivity.color)
                        WorkoutStatPill(title: "Time", value: formatTime(locationManager.elapsedTime), color: .blue)
                        WorkoutStatPill(title: "Pace", value: calculatePace(), color: .purple)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Encouragement Bubble
                if !currentEncouragement.isEmpty {
                    HStack(spacing: 10) {
                        AnimatedPetVideoView(petType: userSettings.pet.type, moodState: .happy)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        
                        Text(currentEncouragement)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(themeManager.cardBackgroundColor)
                            .shadow(color: Color.black.opacity(0.1), radius: 10)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
                }
                
                // STOP BUTTON - Positioned above tab bar
                Button {
                    stopWorkout()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 22, weight: .bold))
                        
                        Text("End \(selectedActivity.rawValue)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: Color.red.opacity(0.5), radius: 20, x: 0, y: 10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 90) // Positioned above tab bar (tab bar is now ~70px + safe area)
            }
        }
        .onAppear {
            startEncouragementTimer()
        }
        .onDisappear {
            encouragementTimer?.invalidate()
            encouragementTimer = nil
        }
    }
    
    // MARK: - Helper Methods
    private func startWorkout() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            showPermissionAlert = true
            return
        }
        
        locationManager.startTracking()
        withAnimation(.spring(response: 0.4)) {
            isWorkoutActive = true
        }
        HapticFeedback.success.trigger()
    }
    
    private func stopWorkout() {
        // Stop tracking and get results
        let result = locationManager.stopTracking()
        
        // Invalidate encouragement timer
        encouragementTimer?.invalidate()
        encouragementTimer = nil
        
        // Calculate calories (rough estimate)
        let calories = Int(result.distance * 0.000621371 * (selectedActivity == .run ? 120 : 80))
        
        // Save the walk
        let record = WalkRecord(
            workoutType: selectedActivity.rawValue.lowercased(),
            distance: result.distance,
            duration: result.duration,
            routeCoordinates: result.route,
            calories: calories
        )
        
        walkHistory.saveWalk(record)
        lastCompletedWorkout = record
        
        // Update UI
        withAnimation(.spring(response: 0.4)) {
            isWorkoutActive = false
            currentEncouragement = ""
        }
        HapticFeedback.success.trigger()
        
        // Show completion sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showWorkoutComplete = true
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func calculatePace() -> String {
        let miles = locationManager.totalDistance * 0.000621371
        guard miles > 0.01 else { return "--:--" }
        let paceMinutes = locationManager.elapsedTime / 60 / miles
        let mins = Int(paceMinutes)
        let secs = Int((paceMinutes - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func startEncouragementTimer() {
        // First encouragement after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard isWorkoutActive else { return }
            withAnimation(.spring(response: 0.5)) {
                currentEncouragement = selectedActivity.encouragements.randomElement() ?? ""
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { currentEncouragement = "" }
            }
        }
        
        // Recurring encouragement
        encouragementTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [self] _ in
            guard isWorkoutActive else { return }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.5)) {
                    currentEncouragement = selectedActivity.encouragements.randomElement() ?? ""
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation { currentEncouragement = "" }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CompactStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

struct CompactActivityButton: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: activity.icon)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(activity.rawValue)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : activity.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? activity.color : activity.color.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(activity.color, lineWidth: isSelected ? 0 : 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PetMapMarker: View {
    let petType: PetType
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 50, height: 50)
            
            Circle()
                .fill(color)
                .frame(width: 38, height: 38)
            
            let imageName = petType.imageName(for: .fullHealth)
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            } else {
                Text(petType.emoji)
                    .font(.system(size: 20))
            }
        }
    }
}

struct WorkoutStatPill: View {
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 8)
        )
    }
}

struct RecentActivityCard: View {
    let walk: WalkRecord
    @EnvironmentObject var themeManager: ThemeManager
    
    private var activityColor: Color {
        walk.workoutType == "run" ? .orange : .green
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Mini Map
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(activityColor.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                if !walk.coordinates.isEmpty {
                    // Simple route preview
                    MiniRoutePreview(coordinates: walk.coordinates, color: activityColor)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: walk.workoutType == "run" ? "figure.run" : "figure.walk")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(activityColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(walk.date))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                HStack(spacing: 12) {
                    Label(String(format: "%.2f mi", walk.distanceInMiles), systemImage: "location.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Label(walk.formattedDuration, systemImage: "clock.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Activity Type Badge
            Text(walk.workoutType.capitalized)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(activityColor))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(activityColor.opacity(0.06))
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct MiniRoutePreview: View {
    let coordinates: [CLLocationCoordinate2D]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            if coordinates.count >= 2 {
                Path { path in
                    let normalized = normalizeCoordinates(coordinates, in: geometry.size)
                    
                    path.move(to: normalized[0])
                    for point in normalized.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(color, lineWidth: 2)
            }
        }
    }
    
    private func normalizeCoordinates(_ coords: [CLLocationCoordinate2D], in size: CGSize) -> [CGPoint] {
        guard !coords.isEmpty else { return [] }
        
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0
        
        let latRange = max(maxLat - minLat, 0.0001)
        let lonRange = max(maxLon - minLon, 0.0001)
        
        return coords.map { coord in
            let x = (coord.longitude - minLon) / lonRange * (size.width - 8) + 4
            let y = (1 - (coord.latitude - minLat) / latRange) * (size.height - 8) + 4
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Activity History View
struct ActivityHistoryView: View {
    @ObservedObject var walkHistory: WalkHistoryManager
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedPeriod = 0 // 0 = Week, 1 = Month, 2 = All
    
    private var filteredWalks: [WalkRecord] {
        switch selectedPeriod {
        case 0: return walkHistory.thisWeekWalks
        case 1: return walkHistory.thisMonthWalks
        default: return walkHistory.walkHistory
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Period Picker
                    Picker("Period", selection: $selectedPeriod) {
                        Text("Week").tag(0)
                        Text("Month").tag(1)
                        Text("All").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                    
                    // Combined Routes Map
                    if !filteredWalks.isEmpty {
                        CombinedRoutesMap(walks: filteredWalks)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 20)
                    }
                    
                    // Stats Summary
                    HStack(spacing: 16) {
                        HistoryStatCard(title: "Activities", value: "\(filteredWalks.count)", color: .blue)
                        HistoryStatCard(title: "Distance", value: String(format: "%.1f mi", filteredWalks.reduce(0) { $0 + $1.distanceInMiles }), color: .green)
                        HistoryStatCard(title: "Calories", value: "\(filteredWalks.reduce(0) { $0 + $1.calories })", color: .orange)
                    }
                    .padding(.horizontal, 20)
                    
                    // Activity List
                    VStack(spacing: 12) {
                        ForEach(filteredWalks) { walk in
                            HistoryActivityCard(walk: walk)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Activity History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

struct CombinedRoutesMap: View {
    let walks: [WalkRecord]
    
    var body: some View {
        Map {
            ForEach(walks) { walk in
                if !walk.coordinates.isEmpty {
                    MapPolyline(coordinates: walk.coordinates)
                        .stroke(walk.workoutType == "run" ? Color.orange : Color.green, lineWidth: 3)
                }
            }
        }
        .mapStyle(.standard)
    }
}

struct HistoryStatCard: View {
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.1))
        )
    }
}

struct HistoryActivityCard: View {
    let walk: WalkRecord
    @EnvironmentObject var themeManager: ThemeManager
    
    private var activityColor: Color {
        walk.workoutType == "run" ? .orange : .green
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(walk.date))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(walk.workoutType.capitalized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(activityColor)
                }
                
                Spacer()
                
                Image(systemName: walk.workoutType == "run" ? "figure.run" : "figure.walk")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(activityColor)
            }
            
            HStack(spacing: 20) {
                Label(String(format: "%.2f mi", walk.distanceInMiles), systemImage: "location.fill")
                Label(walk.formattedDuration, systemImage: "clock.fill")
                Label("\(walk.calories) cal", systemImage: "flame.fill")
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(themeManager.secondaryTextColor)
            
            if !walk.coordinates.isEmpty {
                MiniRoutePreview(coordinates: walk.coordinates, color: activityColor)
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(activityColor.opacity(0.08))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(activityColor.opacity(0.06))
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Workout Complete Sheet
struct WorkoutCompleteSheet: View {
    let workout: WalkRecord
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    
    private var activityColor: Color {
        workout.workoutType == "run" ? .orange : .green
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pet Celebration
                    VStack(spacing: 12) {
                        AnimatedPetVideoView(petType: userSettings.pet.type, moodState: .fullHealth)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                        
                        Text("Great \(workout.workoutType.capitalized)!")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("\(userSettings.pet.name) is so proud of you!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.top, 20)
                    
                    // Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        CompletionStatCard(title: "Distance", value: String(format: "%.2f", workout.distanceInMiles), unit: "miles", icon: "map.fill", color: activityColor)
                        CompletionStatCard(title: "Time", value: workout.formattedDuration, unit: "", icon: "clock.fill", color: .blue)
                        CompletionStatCard(title: "Pace", value: workout.pace, unit: "min/mi", icon: "speedometer", color: .purple)
                        CompletionStatCard(title: "Calories", value: "\(workout.calories)", unit: "kcal", icon: "flame.fill", color: .orange)
                    }
                    .padding(.horizontal, 20)
                    
                    // Route Map
                    if !workout.coordinates.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Route")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryTextColor)
                                .padding(.horizontal, 20)
                            
                            Map {
                                MapPolyline(coordinates: workout.coordinates)
                                    .stroke(activityColor, lineWidth: 4)
                            }
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("\(workout.workoutType.capitalized) Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

struct CompletionStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Preview
#Preview {
    ActivityView()
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
