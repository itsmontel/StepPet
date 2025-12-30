//
//  ActivityView.swift
//  StepPet
//

import SwiftUI
import MapKit
import CoreLocation
import PhotosUI

// MARK: - Activity Mood
enum ActivityMood: String, Codable, CaseIterable {
    case amazing = "Amazing"
    case good = "Good"
    case okay = "Okay"
    case tired = "Tired"
    case exhausted = "Exhausted"
    
    var emoji: String {
        switch self {
        case .amazing: return "🤩"
        case .good: return "😊"
        case .okay: return "😐"
        case .tired: return "😓"
        case .exhausted: return "😴"
        }
    }
    
    var color: Color {
        switch self {
        case .amazing: return .green
        case .good: return .blue
        case .okay: return .yellow
        case .tired: return .orange
        case .exhausted: return .red
        }
    }
}

// MARK: - Weather Data
struct WeatherData: Codable {
    let temperature: Double // Fahrenheit
    let condition: String
    let icon: String
    let humidity: Int
    
    var temperatureString: String {
        "\(Int(temperature))°F"
    }
    
    static var mock: WeatherData {
        WeatherData(temperature: 72, condition: "Sunny", icon: "sun.max.fill", humidity: 45)
    }
}

// MARK: - Weather Manager
class WeatherManager: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    
    func fetchWeather(for location: CLLocationCoordinate2D) {
        // Simulated weather - in production, use WeatherKit or OpenWeather API
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Generate realistic weather based on time of day
            let hour = Calendar.current.component(.hour, from: Date())
            let isNight = hour < 6 || hour > 20
            
            let conditions: [(String, String, Double)] = isNight ? [
                ("Clear Night", "moon.stars.fill", 65),
                ("Partly Cloudy", "cloud.moon.fill", 62),
                ("Cloudy", "cloud.fill", 60)
            ] : [
                ("Sunny", "sun.max.fill", 72),
                ("Partly Cloudy", "cloud.sun.fill", 68),
                ("Cloudy", "cloud.fill", 65),
                ("Light Rain", "cloud.drizzle.fill", 58)
            ]
            
            let selected = conditions.randomElement() ?? conditions[0]
            
            self.currentWeather = WeatherData(
                temperature: selected.2 + Double.random(in: -5...5),
                condition: selected.0,
                icon: selected.1,
                humidity: Int.random(in: 35...75)
            )
            self.isLoading = false
        }
    }
}

// MARK: - Photo Storage Manager
class PhotoStorageManager {
    static let shared = PhotoStorageManager()
    
    private var photosDirectory: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosDir = documentsDirectory.appendingPathComponent("ActivityPhotos")
        
        if !FileManager.default.fileExists(atPath: photosDir.path) {
            try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)
        }
        return photosDir
    }
    
    func savePhoto(_ image: UIImage, for workoutId: UUID) -> String? {
        let photoId = UUID().uuidString
        let fileName = "\(workoutId.uuidString)_\(photoId).jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Failed to save photo: \(error)")
            return nil
        }
    }
    
    func loadPhoto(identifier: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(identifier)
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else { return nil }
        return image
    }
    
    func deletePhotos(for workoutId: UUID) {
        let prefix = workoutId.uuidString
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: photosDirectory.path) else { return }
        
        for file in files where file.hasPrefix(prefix) {
            try? FileManager.default.removeItem(at: photosDirectory.appendingPathComponent(file))
        }
    }
}

// MARK: - Weather Effects Overlay
struct WeatherEffectsOverlay: View {
    let weather: WeatherData?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let weather = weather {
                    switch weather.condition.lowercased() {
                    case let condition where condition.contains("rain") || condition.contains("drizzle"):
                        RainEffectView(geometry: geometry)
                    case let condition where condition.contains("snow"):
                        SnowEffectView(geometry: geometry)
                    case let condition where condition.contains("sunny") || condition.contains("clear"):
                        SunEffectView()
                    case let condition where condition.contains("cloudy"):
                        CloudOverlayView()
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct RainEffectView: View {
    let geometry: GeometryProxy
    @State private var raindrops: [RainDrop] = []
    
    var body: some View {
        ZStack {
            // Slight dark overlay for rainy atmosphere
            Color.blue.opacity(0.08)
            
            ForEach(raindrops) { drop in
                RainDropView(drop: drop)
            }
        }
        .onAppear {
            raindrops = (0..<60).map { _ in
                RainDrop(
                    x: CGFloat.random(in: 0...geometry.size.width),
                    startY: CGFloat.random(in: -200...0),
                    speed: CGFloat.random(in: 15...25),
                    length: CGFloat.random(in: 15...30),
                    opacity: Double.random(in: 0.3...0.7)
                )
            }
        }
    }
}

struct RainDrop: Identifiable {
    let id = UUID()
    let x: CGFloat
    let startY: CGFloat
    let speed: CGFloat
    let length: CGFloat
    let opacity: Double
}

struct RainDropView: View {
    let drop: RainDrop
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(drop.opacity), Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2, height: drop.length)
            .position(x: drop.x, y: drop.startY + yOffset)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: Double(drop.speed) / 10)
                        .repeatForever(autoreverses: false)
                ) {
                    yOffset = UIScreen.main.bounds.height + 300
                }
            }
    }
}

struct SnowEffectView: View {
    let geometry: GeometryProxy
    @State private var snowflakes: [Snowflake] = []
    
    var body: some View {
        ZStack {
            Color.white.opacity(0.05)
            
            ForEach(snowflakes) { flake in
                SnowflakeView(flake: flake)
            }
        }
        .onAppear {
            snowflakes = (0..<40).map { _ in
                Snowflake(
                    x: CGFloat.random(in: 0...geometry.size.width),
                    startY: CGFloat.random(in: -100...0),
                    speed: CGFloat.random(in: 20...40),
                    size: CGFloat.random(in: 4...10),
                    opacity: Double.random(in: 0.5...0.9)
                )
            }
        }
    }
}

struct Snowflake: Identifiable {
    let id = UUID()
    let x: CGFloat
    let startY: CGFloat
    let speed: CGFloat
    let size: CGFloat
    let opacity: Double
}

struct SnowflakeView: View {
    let flake: Snowflake
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(flake.opacity))
            .frame(width: flake.size, height: flake.size)
            .position(x: flake.x + xOffset, y: flake.startY + yOffset)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: Double(flake.speed) / 5)
                        .repeatForever(autoreverses: false)
                ) {
                    yOffset = UIScreen.main.bounds.height + 200
                }
                withAnimation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true)
                ) {
                    xOffset = CGFloat.random(in: -30...30)
                }
            }
    }
}

struct SunEffectView: View {
    @State private var rayRotation: Double = 0
    @State private var glowScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Warm overlay
            LinearGradient(
                colors: [Color.orange.opacity(0.08), Color.yellow.opacity(0.05), Color.clear],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            
            // Sun glow in corner
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(glowScale)
                .position(x: UIScreen.main.bounds.width - 30, y: 80)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        glowScale = 1.2
                    }
                }
            
            // Sun rays
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(LinearGradient(colors: [Color.yellow.opacity(0.2), Color.clear], startPoint: .top, endPoint: .bottom))
                    .frame(width: 3, height: 60)
                    .offset(y: -80)
                    .rotationEffect(.degrees(Double(i) * 45 + rayRotation))
                    .position(x: UIScreen.main.bounds.width - 30, y: 80)
            }
            .onAppear {
                withAnimation(Animation.linear(duration: 30).repeatForever(autoreverses: false)) {
                    rayRotation = 360
                }
            }
        }
    }
}

struct CloudOverlayView: View {
    @State private var cloudOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Grey overlay
            Color.gray.opacity(0.08)
            
            // Animated clouds
            HStack(spacing: 100) {
                ForEach(0..<4) { i in
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.4))
                        .offset(y: CGFloat(i % 2 == 0 ? 20 : 60))
                }
            }
            .offset(x: cloudOffset)
            .onAppear {
                withAnimation(Animation.linear(duration: 60).repeatForever(autoreverses: false)) {
                    cloudOffset = -500
                }
            }
        }
    }
}

// MARK: - Countdown Overlay
struct CountdownOverlay: View {
    @Binding var isShowing: Bool
    @Binding var countdownValue: Int
    let onComplete: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(countdownText)
                    .font(.system(size: countdownValue > 0 ? 120 : 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                if countdownValue > 0 {
                    Text("Get Ready!")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .onAppear {
            startCountdown()
        }
    }
    
    private var countdownText: String {
        if countdownValue > 0 {
            return "\(countdownValue)"
        } else {
            return "GO!"
        }
    }
    
    private func startCountdown() {
        // Initial animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Countdown sequence
        func animateNumber(remaining: Int) {
            if remaining > 0 {
                HapticFeedback.medium.trigger()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.2)) {
                        scale = 0.5
                        opacity = 0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        countdownValue = remaining - 1
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            scale = 1.0
                            opacity = 1.0
                        }
                        animateNumber(remaining: remaining - 1)
                    }
                }
            } else {
                // Show "GO!" then dismiss
                HapticFeedback.success.trigger()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                        scale = 1.5
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowing = false
                        onComplete()
                    }
                }
            }
        }
        
        animateNumber(remaining: countdownValue)
    }
}

// MARK: - Walk Record Model (Enhanced)
struct WalkRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let workoutType: String
    let distance: Double
    let duration: TimeInterval
    let routeCoordinates: [CodableCoordinate]
    let calories: Int
    
    // New fields
    var notes: String?
    var mood: ActivityMood?
    var weather: WeatherData?
    var photoIdentifiers: [String]?
    
    var distanceInMiles: Double {
        distance * 0.000621371
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDurationLong: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        }
        return String(format: "%dm %ds", minutes, seconds)
    }
    
    var pace: String {
        guard distanceInMiles > 0.01 else { return "--:--" }
        let paceMinutes = duration / 60 / distanceInMiles
        let mins = Int(paceMinutes)
        let secs = Int((paceMinutes - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
    
    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        return distanceInMiles / (duration / 3600) // mph
    }
    
    init(id: UUID = UUID(), date: Date = Date(), workoutType: String, distance: Double, duration: TimeInterval, routeCoordinates: [CLLocationCoordinate2D], calories: Int, notes: String? = nil, mood: ActivityMood? = nil, weather: WeatherData? = nil, photoIdentifiers: [String]? = nil) {
        self.id = id
        self.date = date
        self.workoutType = workoutType
        self.distance = distance
        self.duration = duration
        self.routeCoordinates = routeCoordinates.map { CodableCoordinate(coordinate: $0) }
        self.calories = calories
        self.notes = notes
        self.mood = mood
        self.weather = weather
        self.photoIdentifiers = photoIdentifiers
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
    
    func updateWalk(_ record: WalkRecord) {
        if let index = walkHistory.firstIndex(where: { $0.id == record.id }) {
            walkHistory[index] = record
            saveHistory()
        }
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
    @Published var locationUpdateCount: Int = 0 // Used for onChange tracking
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
            self.locationUpdateCount += 1 // Increment for onChange tracking
            
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
            return ["Great pace! 🐾", "Your pet loves this!", "Keep moving! 💪", "Fresh air feels good!", "You're doing amazing!"]
        case .run:
            return ["You're on fire! 🔥", "Crush it!", "Feel the speed! 💨", "Amazing energy!", "Keep going strong!"]
        }
    }
}

// MARK: - Main Activity View
struct ActivityView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    
    @StateObject private var locationManager = ActivityLocationManager()
    @StateObject private var walkHistory = WalkHistoryManager()
    @StateObject private var weatherManager = WeatherManager()
    
    @State private var selectedActivity: ActivityType = .walk
    @State private var isWorkoutActive = false
    @State private var showHistory = false
    @State private var showPermissionAlert = false
    @State private var currentEncouragement = ""
    @State private var showWorkoutComplete = false
    @State private var lastCompletedWorkout: WalkRecord?
    @State private var encouragementTimer: Timer?
    @State private var showCountdown = false
    @State private var countdownValue = 3
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            if isWorkoutActive {
                activeWorkoutView
            } else {
                mainActivityView
            }
            
            // Countdown overlay
            if showCountdown {
                CountdownOverlay(
                    isShowing: $showCountdown,
                    countdownValue: $countdownValue,
                    onComplete: {
                        actuallyStartWorkout()
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .onAppear {
            locationManager.requestPermission()
            if let location = locationManager.location {
                weatherManager.fetchWeather(for: location)
            }
        }
        .onChange(of: locationManager.locationUpdateCount) { _, _ in
            if let location = locationManager.location, weatherManager.currentWeather == nil {
                weatherManager.fetchWeather(for: location)
            }
        }
        .sheet(isPresented: $showHistory) {
            ActivityHistoryView(walkHistory: walkHistory)
        }
        .sheet(isPresented: $showWorkoutComplete) {
            if let workout = lastCompletedWorkout {
                EnhancedWorkoutCompleteSheet(
                    workout: workout,
                    walkHistory: walkHistory,
                    onDismiss: { showWorkoutComplete = false }
                )
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
            Text("StepPet needs location access to track your activities.")
        }
    }
    
    // MARK: - Main Activity View
    private var mainActivityView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                headerSection
                weatherAndMusicCard
                weeklyStatsCard
                startActivitySection
                recentActivitiesSection
                Spacer(minLength: 100)
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
            
            Button(action: { 
                HapticFeedback.light.trigger()
                showHistory = true 
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                    
                    if !walkHistory.walkHistory.isEmpty {
                        Text("\(walkHistory.walkHistory.count)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    
                    Text("History")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: themeManager.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.top, 12)
    }
    
    // MARK: - Weather & Music Card
    private var weatherAndMusicCard: some View {
        HStack(spacing: 12) {
            // Weather Card
            HStack(spacing: 10) {
                if let weather = weatherManager.currentWeather {
                    Image(systemName: weather.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weather.temperatureString)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text(weather.condition)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
            )
            
            // Music Quick Access
            HStack(spacing: 8) {
                Button(action: openAppleMusic) {
                    VStack(spacing: 4) {
                        Image(systemName: "music.note")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.pink)
                        Text("Music")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.pink.opacity(0.1)))
                }
                
                Button(action: openSpotify) {
                    VStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.green)
                        Text("Spotify")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.1)))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Weekly Stats Card
    private var weeklyStatsCard: some View {
        HStack(spacing: 10) {
            CompactStatPill(icon: "figure.walk", value: "\(walkHistory.thisWeekWalks.count)", label: "activities", color: .blue)
            CompactStatPill(icon: "map.fill", value: String(format: "%.1f", walkHistory.totalDistanceThisWeek), label: "mi", color: .green)
            CompactStatPill(icon: "clock.fill", value: formatTimeCompact(walkHistory.totalTimeThisWeek), label: "", color: .purple)
            CompactStatPill(icon: "flame.fill", value: "\(walkHistory.thisWeekWalks.reduce(0) { $0 + $1.calories })", label: "cal", color: .orange)
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
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                ForEach(ActivityType.allCases, id: \.self) { activity in
                    CompactActivityButton(activity: activity, isSelected: selectedActivity == activity) {
                        withAnimation(.spring(response: 0.3)) { selectedActivity = activity }
                        HapticFeedback.light.trigger()
                    }
                }
            }
            
            // Map Preview with Animated Pet
            ZStack {
                Map(initialPosition: .region(locationManager.region)) {
                    if let location = locationManager.location {
                        Annotation("", coordinate: location) {
                            AnimatedPetMapMarker(petType: userSettings.pet.type, color: selectedActivity.color, isAnimating: false)
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
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
            
            Button(action: startWorkout) {
                HStack(spacing: 12) {
                    Image(systemName: selectedActivity.icon)
                        .font(.system(size: 22, weight: .bold))
                    Text("Start \(selectedActivity.rawValue)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [selectedActivity.color, selectedActivity.color.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: selectedActivity.color.opacity(0.4), radius: 12, x: 0, y: 6)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 24).fill(selectedActivity.color.opacity(0.06)))
    }
    
    // MARK: - Recent Activities Section
    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                VStack(spacing: 10) {
                    AnimatedPetVideoView(petType: userSettings.pet.type, moodState: .content)
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                    
                    Text("No activities yet")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("Start a walk to track your first activity!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(RoundedRectangle(cornerRadius: 18).fill(themeManager.secondaryTextColor.opacity(0.05)))
            } else {
                VStack(spacing: 10) {
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
            Map(initialPosition: .region(locationManager.region)) {
                if let location = locationManager.location {
                    Annotation("", coordinate: location) {
                        AnimatedPetMapMarker(petType: userSettings.pet.type, color: selectedActivity.color, isAnimating: true)
                    }
                }
                
                if !locationManager.routeCoordinates.isEmpty {
                    MapPolyline(coordinates: locationManager.routeCoordinates)
                        .stroke(selectedActivity.color, lineWidth: 5)
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            // Weather Effects Overlay
            WeatherEffectsOverlay(weather: weatherManager.currentWeather)
                .ignoresSafeArea()
            
            VStack {
                VStack(spacing: 8) {
                    // Weather indicator at top
                    if let weather = weatherManager.currentWeather {
                        HStack(spacing: 6) {
                            Image(systemName: weather.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(weather.temperatureString)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text("•")
                                .font(.system(size: 10))
                            Text(weather.condition)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                        .padding(.bottom, 6)
                    }
                    
                    HStack(spacing: 12) {
                        WorkoutStatPill(title: "Distance", value: String(format: "%.2f mi", locationManager.totalDistance * 0.000621371), color: selectedActivity.color)
                        WorkoutStatPill(title: "Time", value: formatTime(locationManager.elapsedTime), color: .blue)
                        WorkoutStatPill(title: "Pace", value: calculatePace(), color: .purple)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 16)
                
                Spacer()
                
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
                    .background(Capsule().fill(themeManager.cardBackgroundColor).shadow(color: Color.black.opacity(0.1), radius: 10))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
                }
                
                Button { stopWorkout() } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 22, weight: .bold))
                        Text("End \(selectedActivity.rawValue)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [Color.red, Color.red.opacity(0.85)], startPoint: .top, endPoint: .bottom)))
                    .shadow(color: Color.red.opacity(0.5), radius: 20, x: 0, y: 10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 90)
            }
        }
        .onAppear { startEncouragementTimer() }
        .onDisappear {
            encouragementTimer?.invalidate()
            encouragementTimer = nil
        }
    }
    
    // MARK: - Helper Methods
    private func openAppleMusic() {
        if let url = URL(string: "music://") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSpotify() {
        if let url = URL(string: "spotify://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let webUrl = URL(string: "https://open.spotify.com") {
                UIApplication.shared.open(webUrl)
            }
        }
    }
    
    private func startWorkout() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            showPermissionAlert = true
            return
        }
        
        // Start countdown
        countdownValue = 3
        withAnimation(.easeInOut(duration: 0.3)) {
            showCountdown = true
        }
    }
    
    private func actuallyStartWorkout() {
        locationManager.startTracking()
        withAnimation(.spring(response: 0.4)) { isWorkoutActive = true }
        HapticFeedback.success.trigger()
    }
    
    private func stopWorkout() {
        let result = locationManager.stopTracking()
        encouragementTimer?.invalidate()
        encouragementTimer = nil
        
        let calories = Int(result.distance * 0.000621371 * (selectedActivity == .run ? 120 : 80))
        
        let record = WalkRecord(
            workoutType: selectedActivity.rawValue.lowercased(),
            distance: result.distance,
            duration: result.duration,
            routeCoordinates: result.route,
            calories: calories,
            weather: weatherManager.currentWeather
        )
        
        walkHistory.saveWalk(record)
        lastCompletedWorkout = record
        
        withAnimation(.spring(response: 0.4)) {
            isWorkoutActive = false
            currentEncouragement = ""
        }
        HapticFeedback.success.trigger()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showWorkoutComplete = true }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard isWorkoutActive else { return }
            withAnimation(.spring(response: 0.5)) {
                currentEncouragement = selectedActivity.encouragements.randomElement() ?? ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { currentEncouragement = "" }
            }
        }
        
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

// MARK: - Animated Pet Map Marker
struct AnimatedPetMapMarker: View {
    let petType: PetType
    let color: Color
    let isAnimating: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.4
    
    var body: some View {
        ZStack {
            // Pulse rings when tracking
            if isAnimating {
                Circle()
                    .fill(color.opacity(pulseOpacity))
                    .frame(width: 60, height: 60)
                    .scaleEffect(scale)
                
                Circle()
                    .fill(color.opacity(pulseOpacity * 0.5))
                    .frame(width: 80, height: 80)
                    .scaleEffect(scale * 0.8)
            }
            
            // Main marker
            Circle()
                .fill(color)
                .frame(width: 44, height: 44)
                .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 4)
            
            // Pet image
            let imageName = petType.imageName(for: .fullHealth)
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Text(petType.emoji)
                    .font(.system(size: 22))
            }
        }
        .onAppear {
            if isAnimating {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scale = 1.3
                    pulseOpacity = 0.1
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
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.1)))
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
        .background(Capsule().fill(themeManager.cardBackgroundColor).shadow(color: Color.black.opacity(0.1), radius: 8))
    }
}

struct RecentActivityCard: View {
    let walk: WalkRecord
    @EnvironmentObject var themeManager: ThemeManager
    
    private var activityColor: Color { walk.workoutType == "run" ? .orange : .green }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(activityColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                if !walk.coordinates.isEmpty {
                    MiniRoutePreview(coordinates: walk.coordinates, color: activityColor)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: walk.workoutType == "run" ? "figure.run" : "figure.walk")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(activityColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(formatDate(walk.date))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    if let mood = walk.mood {
                        Text(mood.emoji)
                            .font(.system(size: 12))
                    }
                }
                
                HStack(spacing: 10) {
                    Label(String(format: "%.2f mi", walk.distanceInMiles), systemImage: "location.fill")
                    Label(walk.formattedDuration, systemImage: "clock.fill")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            Text(walk.workoutType.capitalized)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(activityColor))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(activityColor.opacity(0.06)))
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

// MARK: - Enhanced Workout Complete Sheet
struct EnhancedWorkoutCompleteSheet: View {
    let workout: WalkRecord
    @ObservedObject var walkHistory: WalkHistoryManager
    let onDismiss: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var selectedMood: ActivityMood?
    @State private var notes: String = ""
    @State private var showPhotosPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var currentStep = 0 // 0 = summary, 1 = mood, 2 = notes/photos
    
    private var activityColor: Color { workout.workoutType == "run" ? .orange : .green }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Steps
                    HStack(spacing: 8) {
                        ForEach(0..<3) { step in
                            Capsule()
                                .fill(step <= currentStep ? activityColor : activityColor.opacity(0.2))
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    if currentStep == 0 {
                        summaryView
                    } else if currentStep == 1 {
                        moodSelectionView
                    } else {
                        notesAndPhotosView
                    }
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle(currentStep == 0 ? "\(workout.workoutType.capitalized) Complete!" : currentStep == 1 ? "How did you feel?" : "Add Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(currentStep == 2 ? "Save" : "Next") {
                        if currentStep == 2 {
                            saveAndDismiss()
                        } else {
                            withAnimation { currentStep += 1 }
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotos, maxSelectionCount: 4, matching: .images)
        .onChange(of: selectedPhotos) { _, items in
            Task {
                photoImages = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        photoImages.append(image)
                    }
                }
            }
        }
    }
    
    // MARK: - Summary View
    private var summaryView: some View {
        VStack(spacing: 24) {
            // Pet Celebration
            VStack(spacing: 12) {
                AnimatedPetVideoView(petType: userSettings.pet.type, moodState: .fullHealth)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                
                Text("Amazing \(workout.workoutType.capitalized)!")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("\(userSettings.pet.name) is so proud of you!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            // Weather Badge
            if let weather = workout.weather {
                HStack(spacing: 8) {
                    Image(systemName: weather.icon)
                        .foregroundColor(.orange)
                    Text("\(weather.temperatureString) • \(weather.condition)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.orange.opacity(0.1)))
            }
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                CompletionStatCard(title: "Distance", value: String(format: "%.2f", workout.distanceInMiles), unit: "miles", icon: "map.fill", color: activityColor)
                CompletionStatCard(title: "Time", value: workout.formattedDurationLong, unit: "", icon: "clock.fill", color: .blue)
                CompletionStatCard(title: "Pace", value: workout.pace, unit: "min/mi", icon: "speedometer", color: .purple)
                CompletionStatCard(title: "Calories", value: "\(workout.calories)", unit: "kcal", icon: "flame.fill", color: .orange)
                CompletionStatCard(title: "Avg Speed", value: String(format: "%.1f", workout.averageSpeed), unit: "mph", icon: "gauge.with.needle", color: .cyan)
                CompletionStatCard(title: "Steps", value: "\(Int(workout.distance / 0.762))", unit: "steps", icon: "figure.walk", color: .green)
            }
            .padding(.horizontal, 20)
            
            // Route Map
            if !workout.coordinates.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Route")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                        .padding(.horizontal, 20)
                    
                    Map {
                        MapPolyline(coordinates: workout.coordinates)
                            .stroke(activityColor, lineWidth: 4)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer(minLength: 30)
        }
        .padding(.top, 10)
    }
    
    // MARK: - Mood Selection View
    private var moodSelectionView: some View {
        VStack(spacing: 30) {
            AnimatedPetVideoView(petType: userSettings.pet.type, moodState: selectedMood == .amazing || selectedMood == .good ? .happy : .content)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            
            Text("How are you feeling?")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            VStack(spacing: 12) {
                ForEach(ActivityMood.allCases, id: \.self) { mood in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedMood = mood }
                        HapticFeedback.light.trigger()
                    } label: {
                        HStack {
                            Text(mood.emoji)
                                .font(.system(size: 28))
                            
                            Text(mood.rawValue)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedMood == mood ? .white : themeManager.primaryTextColor)
                            
                            Spacer()
                            
                            if selectedMood == mood {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedMood == mood ? mood.color : mood.color.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 20)
    }
    
    // MARK: - Notes and Photos View
    private var notesAndPhotosView: some View {
        VStack(spacing: 24) {
            // Notes Section
            VStack(alignment: .leading, spacing: 10) {
                Label("Notes", systemImage: "note.text")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                TextEditor(text: $notes)
                    .frame(height: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.cardBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(themeManager.secondaryTextColor.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if notes.isEmpty {
                                Text("How was your walk? Any highlights?")
                                    .font(.system(size: 15))
                                    .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }
            .padding(.horizontal, 20)
            
            // Photos Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Photos", systemImage: "photo.on.rectangle")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Spacer()
                    
                    Button { showPhotosPicker = true } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                
                if photoImages.isEmpty {
                    Button { showPhotosPicker = true } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            Text("Add photos from your walk")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .foregroundColor(themeManager.secondaryTextColor.opacity(0.3))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(photoImages.indices, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: photoImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    Button {
                                        photoImages.remove(at: index)
                                        selectedPhotos.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .shadow(radius: 2)
                                    }
                                    .offset(x: 6, y: -6)
                                }
                            }
                            
                            if photoImages.count < 4 {
                                Button { showPhotosPicker = true } label: {
                                    VStack {
                                        Image(systemName: "plus")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(themeManager.accentColor)
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                            .foregroundColor(themeManager.accentColor.opacity(0.5))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private func saveAndDismiss() {
        var updatedWorkout = workout
        updatedWorkout.mood = selectedMood
        updatedWorkout.notes = notes.isEmpty ? nil : notes
        
        // Save photos to file system
        if !photoImages.isEmpty {
            var savedPhotoIds: [String] = []
            for image in photoImages {
                if let photoId = PhotoStorageManager.shared.savePhoto(image, for: workout.id) {
                    savedPhotoIds.append(photoId)
                }
            }
            updatedWorkout.photoIdentifiers = savedPhotoIds.isEmpty ? nil : savedPhotoIds
        }
        
        walkHistory.updateWalk(updatedWorkout)
        HapticFeedback.success.trigger()
        onDismiss()
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
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(color.opacity(0.08)))
    }
}

// MARK: - Activity History View
struct ActivityHistoryView: View {
    @ObservedObject var walkHistory: WalkHistoryManager
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedPeriod = 0
    
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
                VStack(spacing: 16) {
                    Picker("Period", selection: $selectedPeriod) {
                        Text("Week").tag(0)
                        Text("Month").tag(1)
                        Text("All").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                    
                    if !filteredWalks.isEmpty {
                        CombinedRoutesMap(walks: filteredWalks)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .padding(.horizontal, 20)
                    }
                    
                    HStack(spacing: 14) {
                        HistoryStatCard(title: "Activities", value: "\(filteredWalks.count)", color: .blue)
                        HistoryStatCard(title: "Distance", value: String(format: "%.1f mi", filteredWalks.reduce(0) { $0 + $1.distanceInMiles }), color: .green)
                        HistoryStatCard(title: "Calories", value: "\(filteredWalks.reduce(0) { $0 + $1.calories })", color: .orange)
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 10) {
                        ForEach(filteredWalks) { walk in
                            HistoryActivityCard(walk: walk)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 30)
                }
                .padding(.top, 12)
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
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.1)))
    }
}

struct HistoryActivityCard: View {
    let walk: WalkRecord
    @EnvironmentObject var themeManager: ThemeManager
    @State private var loadedPhotos: [UIImage] = []
    
    private var activityColor: Color { walk.workoutType == "run" ? .orange : .green }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(formatDate(walk.date))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        if let mood = walk.mood {
                            Text(mood.emoji)
                                .font(.system(size: 14))
                        }
                        
                        // Photo indicator
                        if let photoIds = walk.photoIdentifiers, !photoIds.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 10))
                                Text("\(photoIds.count)")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(themeManager.secondaryTextColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(themeManager.secondaryTextColor.opacity(0.1)))
                        }
                    }
                    
                    Text(walk.workoutType.capitalized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(activityColor)
                }
                
                Spacer()
                
                if let weather = walk.weather {
                    HStack(spacing: 4) {
                        Image(systemName: weather.icon)
                            .font(.system(size: 12))
                        Text(weather.temperatureString)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            HStack(spacing: 16) {
                Label(String(format: "%.2f mi", walk.distanceInMiles), systemImage: "location.fill")
                Label(walk.formattedDuration, systemImage: "clock.fill")
                Label("\(walk.calories) cal", systemImage: "flame.fill")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(themeManager.secondaryTextColor)
            
            if let notes = walk.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(themeManager.secondaryTextColor.opacity(0.05)))
            }
            
            // Photo Gallery
            if !loadedPhotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(loadedPhotos.indices, id: \.self) { index in
                            Image(uiImage: loadedPhotos[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            
            if !walk.coordinates.isEmpty {
                MiniRoutePreview(coordinates: walk.coordinates, color: activityColor)
                    .frame(height: 70)
                    .background(RoundedRectangle(cornerRadius: 10).fill(activityColor.opacity(0.08)))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(activityColor.opacity(0.06)))
        .onAppear {
            loadPhotos()
        }
    }
    
    private func loadPhotos() {
        guard let photoIds = walk.photoIdentifiers else { return }
        loadedPhotos = photoIds.compactMap { PhotoStorageManager.shared.loadPhoto(identifier: $0) }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    ActivityView()
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
