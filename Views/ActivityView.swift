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
        isLoading = true
        
        // Use Open-Meteo API (free, no API key required)
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(location.latitude)&longitude=\(location.longitude)&current=temperature_2m,relative_humidity_2m,weather_code&temperature_unit=fahrenheit"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let current = json["current"] as? [String: Any],
                      let temp = current["temperature_2m"] as? Double,
                      let humidity = current["relative_humidity_2m"] as? Int,
                      let weatherCode = current["weather_code"] as? Int else {
                    // Fallback to basic weather if API fails
                    self?.setFallbackWeather()
                    return
                }
                
                let (condition, icon) = self?.weatherCondition(from: weatherCode) ?? ("Unknown", "cloud.fill")
                
                self?.currentWeather = WeatherData(
                    temperature: temp,
                    condition: condition,
                    icon: icon,
                    humidity: humidity
                )
            }
        }.resume()
    }
    
    private func weatherCondition(from code: Int) -> (String, String) {
        // WMO Weather interpretation codes
        switch code {
        case 0: return ("Clear", "sun.max.fill")
        case 1, 2, 3: return ("Partly Cloudy", "cloud.sun.fill")
        case 45, 48: return ("Foggy", "cloud.fog.fill")
        case 51, 53, 55: return ("Drizzle", "cloud.drizzle.fill")
        case 61, 63, 65: return ("Rain", "cloud.rain.fill")
        case 66, 67: return ("Freezing Rain", "cloud.sleet.fill")
        case 71, 73, 75: return ("Snow", "cloud.snow.fill")
        case 77: return ("Snow Grains", "cloud.snow.fill")
        case 80, 81, 82: return ("Rain Showers", "cloud.heavyrain.fill")
        case 85, 86: return ("Snow Showers", "cloud.snow.fill")
        case 95: return ("Thunderstorm", "cloud.bolt.fill")
        case 96, 99: return ("Thunderstorm", "cloud.bolt.rain.fill")
        default: return ("Cloudy", "cloud.fill")
        }
    }
    
    private func setFallbackWeather() {
        // If API fails, don't show weather
        self.currentWeather = nil
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

// MARK: - Premium Weather Effects Overlay
struct WeatherEffectsOverlay: View {
    let weather: WeatherData?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let weather = weather {
                    switch weather.condition.lowercased() {
                    case let condition where condition.contains("rain") || condition.contains("drizzle"):
                        PremiumRainEffect(intensity: condition.contains("light") ? 0.5 : 1.0)
                    case let condition where condition.contains("snow"):
                        PremiumSnowEffect()
                    case let condition where condition.contains("sunny") || condition.contains("clear"):
                        PremiumSunEffect()
                    case let condition where condition.contains("cloudy") || condition.contains("overcast"):
                        PremiumCloudEffect()
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Premium Rain Effect
struct PremiumRainEffect: View {
    let intensity: Double
    @State private var drops: [PremiumRainDrop] = []
    @State private var splashes: [RainSplash] = []
    
    var body: some View {
        ZStack {
            // Atmospheric overlay - darker, moodier
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.25, blue: 0.35).opacity(0.3),
                    Color(red: 0.15, green: 0.2, blue: 0.3).opacity(0.2),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Mist effect at bottom
            LinearGradient(
                colors: [Color.clear, Color.white.opacity(0.08)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Rain drops - multiple layers for depth
            Canvas { context, size in
                for drop in drops {
                    let path = Path { p in
                        p.move(to: CGPoint(x: drop.x, y: drop.y))
                        p.addLine(to: CGPoint(x: drop.x + drop.windOffset, y: drop.y + drop.length))
                    }
                    context.stroke(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color.white.opacity(drop.opacity * 0.8),
                                Color(red: 0.7, green: 0.8, blue: 0.95).opacity(drop.opacity * 0.4)
                            ]),
                            startPoint: CGPoint(x: drop.x, y: drop.y),
                            endPoint: CGPoint(x: drop.x, y: drop.y + drop.length)
                        ),
                        lineWidth: drop.thickness
                    )
                }
            }
            
            // Splash effects at bottom
            ForEach(splashes) { splash in
                RainSplashView(splash: splash)
            }
        }
        .onAppear {
            initializeRain()
            startRainAnimation()
        }
    }
    
    private func initializeRain() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let dropCount = Int(150 * intensity)
        
        drops = (0..<dropCount).map { i in
            PremiumRainDrop(
                x: CGFloat.random(in: CGFloat(-20)...(screenWidth + CGFloat(20))),
                y: CGFloat.random(in: (-screenHeight)...CGFloat(0)),
                length: CGFloat.random(in: CGFloat(20)...CGFloat(45)),
                thickness: CGFloat.random(in: CGFloat(1)...CGFloat(2.5)),
                speed: CGFloat.random(in: CGFloat(18)...CGFloat(28)),
                opacity: Double.random(in: 0.3...0.7),
                windOffset: CGFloat.random(in: CGFloat(2)...CGFloat(8)),
                layer: i % 3
            )
        }
    }
    
    private func startRainAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            let screenHeight = UIScreen.main.bounds.height
            let screenWidth = UIScreen.main.bounds.width
            
            for i in drops.indices {
                drops[i].y += drops[i].speed * (1 + CGFloat(drops[i].layer) * 0.3)
                drops[i].x += drops[i].windOffset * 0.1
                
                if drops[i].y > screenHeight + CGFloat(50) {
                    // Create splash
                    if Bool.random() && splashes.count < 20 {
                        splashes.append(RainSplash(x: drops[i].x, y: screenHeight - CGFloat(50)))
                    }
                    
                    // Reset drop
                    let minY: CGFloat = -100
                    let maxY: CGFloat = -20
                    drops[i].y = CGFloat.random(in: minY...maxY)
                    drops[i].x = CGFloat.random(in: CGFloat(-20)...(screenWidth + CGFloat(20)))
                }
            }
            
            // Remove old splashes
            splashes.removeAll { $0.createdAt.timeIntervalSinceNow < -0.5 }
        }
    }
}

struct PremiumRainDrop: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let length: CGFloat
    let thickness: CGFloat
    let speed: CGFloat
    let opacity: Double
    let windOffset: CGFloat
    let layer: Int
}

struct RainSplash: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let createdAt = Date()
}

struct RainSplashView: View {
    let splash: RainSplash
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0.6
    
    var body: some View {
        Circle()
            .stroke(Color.white.opacity(opacity), lineWidth: 1)
            .frame(width: 12, height: 12)
            .scaleEffect(scale)
            .position(x: splash.x, y: splash.y)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    scale = 2.0
                    opacity = 0
                }
            }
    }
}

// MARK: - Premium Snow Effect
struct PremiumSnowEffect: View {
    @State private var snowflakes: [PremiumSnowflake] = []
    
    var body: some View {
        ZStack {
            // Cold atmosphere overlay
            LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.9, blue: 0.95).opacity(0.15),
                    Color.white.opacity(0.05),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Fog/mist at bottom
            LinearGradient(
                colors: [Color.clear, Color.white.opacity(0.12)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Snowflakes with Canvas for performance
            Canvas { context, size in
                for flake in snowflakes {
                    let rect = CGRect(
                        x: flake.x - flake.size/2,
                        y: flake.y - flake.size/2,
                        width: flake.size,
                        height: flake.size
                    )
                    
                    // Draw snowflake with glow
                    context.opacity = flake.opacity
                    context.fill(
                        Circle().path(in: rect.insetBy(dx: -2, dy: -2)),
                        with: .color(.white.opacity(0.3))
                    )
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(.white)
                    )
                }
            }
            
            // Large foreground flakes for depth
            ForEach(snowflakes.prefix(15)) { flake in
                if flake.layer == 0 {
                    SnowflakeShape()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: flake.size * 2, height: flake.size * 2)
                        .rotationEffect(.degrees(flake.rotation))
                        .position(x: flake.x, y: flake.y)
                        .blur(radius: 0.5)
                }
            }
        }
        .onAppear {
            initializeSnow()
            startSnowAnimation()
        }
    }
    
    private func initializeSnow() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        snowflakes = (0..<80).map { i in
            PremiumSnowflake(
                x: CGFloat.random(in: CGFloat(0)...screenWidth),
                y: CGFloat.random(in: (-screenHeight)...screenHeight),
                size: CGFloat.random(in: CGFloat(3)...CGFloat(12)),
                speed: CGFloat.random(in: CGFloat(1)...CGFloat(3)),
                opacity: Double.random(in: 0.5...1.0),
                wobbleAmount: CGFloat.random(in: CGFloat(20)...CGFloat(60)),
                wobbleSpeed: Double.random(in: 2...5),
                rotation: Double.random(in: 0...360),
                layer: i < 15 ? 0 : 1
            )
        }
    }
    
    private func startSnowAnimation() {
        var time: Double = 0
        Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { _ in
            time += 0.033
            let screenHeight = UIScreen.main.bounds.height
            let screenWidth = UIScreen.main.bounds.width
            
            for i in snowflakes.indices {
                snowflakes[i].y += snowflakes[i].speed
                snowflakes[i].x += CGFloat(sin(time * snowflakes[i].wobbleSpeed) * 0.5)
                snowflakes[i].rotation += 0.5
                
                if snowflakes[i].y > screenHeight + CGFloat(20) {
                    snowflakes[i].y = CGFloat(-20)
                    snowflakes[i].x = CGFloat.random(in: CGFloat(0)...screenWidth)
                }
            }
        }
    }
}

struct PremiumSnowflake: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let speed: CGFloat
    let opacity: Double
    let wobbleAmount: CGFloat
    let wobbleSpeed: Double
    var rotation: Double
    let layer: Int
}

struct SnowflakeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3
            let endX = center.x + cos(angle) * radius
            let endY = center.y + sin(angle) * radius
            path.move(to: center)
            path.addLine(to: CGPoint(x: endX, y: endY))
            
            // Add branches
            let branchLength = radius * 0.4
            let branchStart = 0.6
            let midX = center.x + cos(angle) * radius * branchStart
            let midY = center.y + sin(angle) * radius * branchStart
            
            for offset in [-0.4, 0.4] {
                let branchAngle = angle + offset
                path.move(to: CGPoint(x: midX, y: midY))
                path.addLine(to: CGPoint(
                    x: midX + cos(branchAngle) * branchLength,
                    y: midY + sin(branchAngle) * branchLength
                ))
            }
        }
        return path
    }
}

// MARK: - Premium Sun Effect
struct PremiumSunEffect: View {
    @State private var rayRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -200
    @State private var lensFlares: [LensFlare] = []
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        
        ZStack {
            // Warm atmospheric gradient
            RadialGradient(
                colors: [
                    Color(red: 1, green: 0.95, blue: 0.8).opacity(0.25),
                    Color(red: 1, green: 0.9, blue: 0.7).opacity(0.15),
                    Color(red: 1, green: 0.85, blue: 0.6).opacity(0.08),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 500
            )
            
            // Golden hour overlay
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.08),
                    Color.yellow.opacity(0.04),
                    Color.clear
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            
            // Sun core with multiple layers
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(0.4),
                                Color.orange.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(pulseScale)
                
                // Inner bright core
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color.yellow,
                                Color.orange.opacity(0.8)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 70, height: 70)
                    .blur(radius: 2)
                
                // Dynamic rays
                ForEach(0..<12) { i in
                    RayView(index: i, rotation: rayRotation)
                }
            }
            .position(x: screenWidth - 50, y: 100)
            
            // Lens flares
            ForEach(lensFlares) { flare in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [flare.color.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: flare.size
                        )
                    )
                    .frame(width: flare.size * 2, height: flare.size * 2)
                    .position(x: flare.x, y: flare.y)
            }
            
            // Light shimmer across screen
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.1), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 100)
                .offset(x: shimmerOffset)
                .blur(radius: 20)
        }
        .onAppear {
            initializeLensFlares()
            
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                rayRotation = 360
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                shimmerOffset = UIScreen.main.bounds.width + 200
            }
        }
    }
    
    private func initializeLensFlares() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        lensFlares = [
            LensFlare(x: screenWidth * 0.7, y: screenHeight * 0.3, size: 30, color: .orange),
            LensFlare(x: screenWidth * 0.5, y: screenHeight * 0.4, size: 20, color: .yellow),
            LensFlare(x: screenWidth * 0.3, y: screenHeight * 0.5, size: 40, color: .orange.opacity(0.5)),
            LensFlare(x: screenWidth * 0.2, y: screenHeight * 0.6, size: 15, color: .white)
        ]
    }
}

struct RayView: View {
    let index: Int
    let rotation: Double
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.yellow.opacity(0.6),
                        Color.orange.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: index % 2 == 0 ? 4 : 2, height: index % 2 == 0 ? 100 : 70)
            .offset(y: index % 2 == 0 ? -85 : -70)
            .rotationEffect(.degrees(Double(index) * 30 + rotation))
    }
}

struct LensFlare: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
}

// MARK: - Premium Cloud Effect
struct PremiumCloudEffect: View {
    @State private var clouds: [PremiumCloud] = []
    @State private var time: Double = 0
    
    var body: some View {
        ZStack {
            // Overcast sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.6, green: 0.65, blue: 0.7).opacity(0.3),
                    Color(red: 0.7, green: 0.72, blue: 0.75).opacity(0.2),
                    Color(red: 0.75, green: 0.77, blue: 0.8).opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Cloud layers
            ForEach(clouds) { cloud in
                PremiumCloudShape(cloud: cloud)
            }
        }
        .onAppear {
            initializeClouds()
            startAnimation()
        }
    }
    
    private func initializeClouds() {
        let screenWidth = UIScreen.main.bounds.width
        
        clouds = (0..<8).map { i in
            let randomOffset = Int.random(in: -20...20)
            return PremiumCloud(
                x: CGFloat.random(in: CGFloat(-100)...screenWidth),
                y: CGFloat(40 + i * 60 + randomOffset),
                width: CGFloat.random(in: CGFloat(150)...CGFloat(300)),
                height: CGFloat.random(in: CGFloat(60)...CGFloat(120)),
                speed: CGFloat.random(in: CGFloat(0.2)...CGFloat(0.8)),
                opacity: Double.random(in: 0.4...0.8),
                layer: i % 3
            )
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            let screenWidth = UIScreen.main.bounds.width
            
            for i in clouds.indices {
                clouds[i].x += clouds[i].speed
                
                if clouds[i].x > screenWidth + clouds[i].width {
                    clouds[i].x = CGFloat(-1) * clouds[i].width
                }
            }
        }
    }
}

struct PremiumCloud: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let speed: CGFloat
    let opacity: Double
    let layer: Int
}

struct PremiumCloudShape: View {
    let cloud: PremiumCloud
    
    var body: some View {
        ZStack {
            // Cloud shadow
            CloudBlobShape()
                .fill(Color.gray.opacity(cloud.opacity * 0.3))
                .frame(width: cloud.width, height: cloud.height)
                .offset(x: 5, y: 5)
                .blur(radius: 10)
            
            // Main cloud
            CloudBlobShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(cloud.opacity),
                            Color(red: 0.9, green: 0.92, blue: 0.95).opacity(cloud.opacity * 0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: cloud.width, height: cloud.height)
            
            // Highlight
            CloudBlobShape()
                .fill(Color.white.opacity(cloud.opacity * 0.5))
                .frame(width: cloud.width * 0.6, height: cloud.height * 0.4)
                .offset(x: -cloud.width * 0.1, y: -cloud.height * 0.2)
                .blur(radius: 5)
        }
        .position(x: cloud.x, y: cloud.y)
    }
}

struct CloudBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        
        // Create fluffy cloud shape with multiple overlapping circles
        path.addEllipse(in: CGRect(x: w * 0.1, y: h * 0.4, width: w * 0.3, height: h * 0.5))
        path.addEllipse(in: CGRect(x: w * 0.25, y: h * 0.2, width: w * 0.35, height: h * 0.6))
        path.addEllipse(in: CGRect(x: w * 0.5, y: h * 0.3, width: w * 0.3, height: h * 0.5))
        path.addEllipse(in: CGRect(x: w * 0.35, y: h * 0.35, width: w * 0.4, height: h * 0.5))
        path.addEllipse(in: CGRect(x: w * 0.6, y: h * 0.4, width: w * 0.3, height: h * 0.45))
        
        return path
    }
}

// MARK: - Premium Countdown Overlay
struct CountdownOverlay: View {
    @Binding var isShowing: Bool
    @Binding var countdownValue: Int
    let onComplete: () -> Void
    
    @State private var numberScale: CGFloat = 0.3
    @State private var numberOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0
    @State private var particles: [CountdownParticle] = []
    @State private var backgroundBlur: CGFloat = 0
    @State private var pulseRings: [PulseRing] = []
    
    private let accentColor = Color(red: 0.4, green: 0.8, blue: 0.6)
    
    var body: some View {
        ZStack {
            // Blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Dark overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Particle effects
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .blur(radius: particle.blur)
            }
            
            // Pulse rings
            ForEach(pulseRings) { ring in
                Circle()
                    .stroke(accentColor.opacity(ring.opacity), lineWidth: 3)
                    .frame(width: ring.size, height: ring.size)
            }
            
            // Main countdown content
            VStack(spacing: 30) {
                // Circular progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                    
                    // Glowing orb at progress end
                    Circle()
                        .fill(accentColor)
                        .frame(width: 16, height: 16)
                        .shadow(color: accentColor, radius: 10)
                        .offset(y: -100)
                        .rotationEffect(.degrees(progressValue * CGFloat(360) - CGFloat(90)))
                        .opacity(ringOpacity)
                    
                    // Number display
                    Text(displayText)
                        .font(.system(size: countdownValue > 0 ? 100 : 70, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: accentColor.opacity(0.5), radius: 20)
                        .scaleEffect(numberScale)
                        .opacity(numberOpacity)
                }
                
                // Status text
                Text(statusText)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(4)
                    .textCase(.uppercase)
                    .opacity(numberOpacity)
            }
        }
        .onAppear {
            startPremiumCountdown()
        }
    }
    
    private var progressValue: CGFloat {
        CGFloat(3 - countdownValue) / 3.0
    }
    
    private var displayText: String {
        countdownValue > 0 ? "\(countdownValue)" : "GO!"
    }
    
    private var statusText: String {
        switch countdownValue {
        case 3: return "Get Ready"
        case 2: return "Set"
        case 1: return "Almost There"
        default: return "Let's Go!"
        }
    }
    
    private func startPremiumCountdown() {
        // Initial entrance
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            numberScale = 1.0
            numberOpacity = 1.0
            ringScale = 1.0
            ringOpacity = 1.0
        }
        
        spawnParticles()
        animateSequence(remaining: countdownValue)
    }
    
    private func animateSequence(remaining: Int) {
        if remaining > 0 {
            // Haptic
            HapticFeedback.medium.trigger()
            
            // Add pulse ring
            addPulseRing()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                // Shrink out
                withAnimation(.easeIn(duration: 0.15)) {
                    numberScale = 1.3
                    numberOpacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    countdownValue = remaining - 1
                    numberScale = 0.5
                    
                    // Pop in new number
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        numberScale = 1.0
                        numberOpacity = 1.0
                    }
                    
                    animateSequence(remaining: remaining - 1)
                }
            }
        } else {
            // GO! animation
            HapticFeedback.success.trigger()
            
            // Burst of particles
            for _ in 0..<30 {
                spawnBurstParticle()
            }
            
            // Multiple pulse rings
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    addPulseRing()
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeOut(duration: 0.4)) {
                    numberScale = 2.0
                    numberOpacity = 0
                    ringOpacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isShowing = false
                    onComplete()
                }
            }
        }
    }
    
    private func spawnParticles() {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isShowing {
                timer.invalidate()
                return
            }
            
            let angle = Double.random(in: 0...360) * .pi / 180
            let distance = CGFloat.random(in: 80...150)
            
            let particle = CountdownParticle(
                x: centerX + cos(angle) * distance,
                y: centerY + sin(angle) * distance,
                size: CGFloat.random(in: 4...12),
                color: [accentColor, .white, accentColor.opacity(0.5)].randomElement()!,
                blur: CGFloat.random(in: 0...3)
            )
            
            if particles.count < 40 {
                particles.append(particle)
            }
            
            // Remove old particles
            if particles.count > 30 {
                particles.removeFirst()
            }
        }
    }
    
    private func spawnBurstParticle() {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        let angle = Double.random(in: 0...360) * .pi / 180
        
        let particle = CountdownParticle(
            x: centerX,
            y: centerY,
            size: CGFloat.random(in: 6...16),
            color: [accentColor, .white, .yellow].randomElement()!,
            blur: 0
        )
        
        particles.append(particle)
        
        withAnimation(.easeOut(duration: 0.6)) {
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                particles[index].x = centerX + CGFloat(cos(angle) * 200)
                particles[index].y = centerY + CGFloat(sin(angle) * 200)
            }
        }
    }
    
    private func addPulseRing() {
        let ring = PulseRing(size: 200, opacity: 0.8)
        pulseRings.append(ring)
        
        withAnimation(.easeOut(duration: 0.8)) {
            if let index = pulseRings.firstIndex(where: { $0.id == ring.id }) {
                pulseRings[index].size = 400
                pulseRings[index].opacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            pulseRings.removeAll { $0.id == ring.id }
        }
    }
}

struct CountdownParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    let color: Color
    let blur: CGFloat
}

struct PulseRing: Identifiable {
    let id = UUID()
    var size: CGFloat
    var opacity: Double
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
        let remainder = paceMinutes - Double(mins)
        let secs = Int(remainder * 60)
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

// MARK: - Activity Color (for theming)
struct ActivityStyle {
    static let color: Color = Color(hex: "4CAF50") // Nice green
    static let icon: String = "figure.outdoor.cycle"
    static let encouragements: [String] = [
        "Great pace! 🐾",
        "Your pet loves this!",
        "Keep moving! 💪",
        "Fresh air feels good!",
        "You're doing amazing!",
        "One step at a time! 🚶",
        "Stay strong! 💚",
        "You've got this!"
    ]
}

// MARK: - Main Activity View
struct ActivityView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userSettings: UserSettings
    
    @StateObject private var locationManager = ActivityLocationManager()
    @StateObject private var walkHistory = WalkHistoryManager()
    @StateObject private var weatherManager = WeatherManager()
    
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
        VStack(spacing: 16) {
            // Large Map Preview with Animated Pet
            ZStack {
                Map(initialPosition: .region(locationManager.region)) {
                    if let location = locationManager.location {
                        Annotation("", coordinate: location) {
                            AnimatedPetMapMarker(petType: userSettings.pet.type, color: ActivityStyle.color, isAnimating: false)
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(height: 340)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                
                if locationManager.location == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "location.slash.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                        Text("Enable location to see your position")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.5))
                    )
                }
            }
            
            // Start Button
            Button(action: startWorkout) {
                HStack(spacing: 14) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 24, weight: .bold))
                    Text("Start Activity")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [ActivityStyle.color, ActivityStyle.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: ActivityStyle.color.opacity(0.4), radius: 15, x: 0, y: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0 : 0.06), radius: 12, y: 6)
        )
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
                        AnimatedPetMapMarker(petType: userSettings.pet.type, color: ActivityStyle.color, isAnimating: true)
                    }
                }
                
                if !locationManager.routeCoordinates.isEmpty {
                    MapPolyline(coordinates: locationManager.routeCoordinates)
                        .stroke(ActivityStyle.color, lineWidth: 5)
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
                        WorkoutStatPill(title: "Distance", value: String(format: "%.2f mi", locationManager.totalDistance * 0.000621371), color: ActivityStyle.color)
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
                        Text("End Activity")
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
        
        let calories = Int(result.distance * 0.000621371 * 80)
        
        let record = WalkRecord(
            workoutType: "activity",
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
        let remainder = paceMinutes - Double(mins)
        let secs = Int(remainder * 60)
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func startEncouragementTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard isWorkoutActive else { return }
            withAnimation(.spring(response: 0.5)) {
                currentEncouragement = ActivityStyle.encouragements.randomElement() ?? ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { currentEncouragement = "" }
            }
        }
        
        encouragementTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [self] _ in
            guard isWorkoutActive else { return }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.5)) {
                    currentEncouragement = ActivityStyle.encouragements.randomElement() ?? ""
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

// CompactActivityButton removed - now using single Start Activity button

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
// MARK: - Premium Activity History View
struct ActivityHistoryView: View {
    @ObservedObject var walkHistory: WalkHistoryManager
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedPeriod = 0
    @State private var selectedWalk: WalkRecord?
    @State private var showDetailView = false
    
    private var filteredWalks: [WalkRecord] {
        switch selectedPeriod {
        case 0: return walkHistory.thisWeekWalks
        case 1: return walkHistory.thisMonthWalks
        default: return walkHistory.walkHistory
        }
    }
    
    private var totalDistance: Double {
        filteredWalks.reduce(0) { $0 + $1.distanceInMiles }
    }
    
    private var totalCalories: Int {
        filteredWalks.reduce(0) { $0 + $1.calories }
    }
    
    private var totalTime: TimeInterval {
        filteredWalks.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Period Selector with modern design
                    HStack(spacing: 0) {
                        ForEach(["Week", "Month", "All Time"], id: \.self) { period in
                            let index = ["Week", "Month", "All Time"].firstIndex(of: period) ?? 0
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedPeriod = index
                                }
                            } label: {
                                Text(period)
                                    .font(.system(size: 14, weight: selectedPeriod == index ? .bold : .medium, design: .rounded))
                                    .foregroundColor(selectedPeriod == index ? .white : themeManager.secondaryTextColor)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    .background(
                                        Group {
                                            if selectedPeriod == index {
                                                Capsule()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [Color(red: 0.4, green: 0.8, blue: 0.6), Color(red: 0.3, green: 0.7, blue: 0.5)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                            }
                                        }
                                    )
                            }
                        }
                    }
                    .padding(4)
                    .background(Capsule().fill(themeManager.cardBackgroundColor))
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
                    .padding(.horizontal, 20)
                    
                    // Stats Overview with beautiful cards
                    if !filteredWalks.isEmpty {
                        VStack(spacing: 12) {
                            // Main stat - Distance with large display
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Distance")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(themeManager.secondaryTextColor)
                                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                                        Text(String(format: "%.1f", totalDistance))
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundColor(.green)
                                        Text("mi")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(themeManager.secondaryTextColor)
                                    }
                                }
                                
                                Spacer()
                                
                                // Mini combined routes preview
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.1))
                                        .frame(width: 70, height: 70)
                                    
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(themeManager.cardBackgroundColor)
                                    .shadow(color: Color.black.opacity(0.05), radius: 15)
                            )
                            
                            // Secondary stats row
                            HStack(spacing: 12) {
                                PremiumStatCard(
                                    icon: "figure.walk",
                                    title: "Activities",
                                    value: "\(filteredWalks.count)",
                                    color: .blue
                                )
                                PremiumStatCard(
                                    icon: "flame.fill",
                                    title: "Calories",
                                    value: "\(totalCalories)",
                                    color: .orange
                                )
                                PremiumStatCard(
                                    icon: "clock.fill",
                                    title: "Time",
                                    value: formatTotalTime(totalTime),
                                    color: .purple
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Combined Routes Map
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Your Routes")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                Spacer()
                                
                                Text("\(filteredWalks.filter { !$0.coordinates.isEmpty }.count) tracked")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            
                            CombinedRoutesMap(walks: filteredWalks)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 15)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Activity List Header
                    HStack {
                        Text("Recent Activities")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Spacer()
                        
                        if !filteredWalks.isEmpty {
                            Text("Tap to view details")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Activity Cards
                    if filteredWalks.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "figure.walk.circle")
                                .font(.system(size: 60))
                                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                            
                            Text("No activities yet")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            Text("Start a walk or run to see your history here")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.secondaryTextColor.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredWalks) { walk in
                                PremiumActivityCard(walk: walk)
                                    .onTapGesture {
                                        selectedWalk = walk
                                        showDetailView = true
                                        HapticFeedback.light.trigger()
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
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
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
            }
        }
        .sheet(isPresented: $showDetailView) {
            if let walk = selectedWalk {
                ActivityDetailView(walk: walk, walkHistory: walkHistory)
            }
        }
    }
    
    private func formatTotalTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Premium Stat Card
struct PremiumStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.03), radius: 8)
        )
    }
}

// MARK: - Premium Activity Card
struct PremiumActivityCard: View {
    let walk: WalkRecord
    @EnvironmentObject var themeManager: ThemeManager
    @State private var loadedPhotos: [UIImage] = []
    
    private var activityColor: Color { walk.workoutType == "run" ? .orange : .green }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            HStack {
                // Activity type icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [activityColor, activityColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: walk.workoutType == "run" ? "figure.run" : "figure.walk")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(formatDate(walk.date))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        if let mood = walk.mood {
                            Text(mood.emoji)
                                .font(.system(size: 16))
                        }
                    }
                    
                    Text(formatTime(walk.date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Weather & Photos indicator
                VStack(alignment: .trailing, spacing: 4) {
                    if let weather = walk.weather {
                        HStack(spacing: 4) {
                            Image(systemName: weather.icon)
                                .font(.system(size: 12))
                            Text(weather.temperatureString)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    if let photoIds = walk.photoIdentifiers, !photoIds.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 10))
                            Text("\(photoIds.count)")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(activityColor))
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                    .padding(.leading, 8)
            }
            .padding(14)
            
            Divider()
                .background(themeManager.secondaryTextColor.opacity(0.1))
            
            // Stats row
            HStack(spacing: 0) {
                StatItem(icon: "location.fill", value: String(format: "%.2f mi", walk.distanceInMiles), color: activityColor)
                
                Divider()
                    .frame(height: 30)
                    .background(themeManager.secondaryTextColor.opacity(0.1))
                
                StatItem(icon: "clock.fill", value: walk.formattedDuration, color: .blue)
                
                Divider()
                    .frame(height: 30)
                    .background(themeManager.secondaryTextColor.opacity(0.1))
                
                StatItem(icon: "flame.fill", value: "\(walk.calories) cal", color: .orange)
            }
            .padding(.vertical, 10)
            
            // Mini route preview
            if !walk.coordinates.isEmpty {
                MiniRoutePreview(coordinates: walk.coordinates, color: activityColor)
                    .frame(height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
            }
            
            // Notes preview if exists
            if let notes = walk.notes, !notes.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text(notes)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(themeManager.secondaryTextColor.opacity(0.03))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(activityColor.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.primaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Activity Detail View (Full Journal)
struct ActivityDetailView: View {
    let walk: WalkRecord
    @ObservedObject var walkHistory: WalkHistoryManager
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var loadedPhotos: [UIImage] = []
    @State private var selectedPhotoIndex: Int?
    @State private var showFullScreenPhoto = false
    
    private var activityColor: Color { walk.workoutType == "run" ? .orange : .green }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Map
                    ZStack(alignment: .bottom) {
                        if !walk.coordinates.isEmpty {
                            Map {
                                MapPolyline(coordinates: walk.coordinates)
                                    .stroke(
                                        LinearGradient(
                                            colors: [activityColor, activityColor.opacity(0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 5
                                    )
                                
                                if let first = walk.coordinates.first {
                                    Annotation("Start", coordinate: first) {
                                        ZStack {
                                            Circle().fill(.white).frame(width: 24, height: 24)
                                            Circle().fill(.green).frame(width: 16, height: 16)
                                        }
                                    }
                                }
                                
                                if let last = walk.coordinates.last {
                                    Annotation("End", coordinate: last) {
                                        ZStack {
                                            Circle().fill(.white).frame(width: 24, height: 24)
                                            Circle().fill(.red).frame(width: 16, height: 16)
                                        }
                                    }
                                }
                            }
                            .mapStyle(.standard(elevation: .realistic))
                            .frame(height: 280)
                        } else {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [activityColor.opacity(0.3), activityColor.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 280)
                                .overlay(
                                    VStack {
                                        Image(systemName: "map")
                                            .font(.system(size: 50))
                                            .foregroundColor(activityColor.opacity(0.5))
                                        Text("No route recorded")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(themeManager.secondaryTextColor)
                                    }
                                )
                        }
                        
                        // Gradient overlay at bottom
                        LinearGradient(
                            colors: [Color.clear, themeManager.backgroundColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 60)
                    }
                    
                    // Main Content
                    VStack(spacing: 24) {
                        // Activity Header
                        VStack(spacing: 8) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(activityColor)
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: walk.workoutType == "run" ? "figure.run" : "figure.walk")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(walk.workoutType.capitalized)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.primaryTextColor)
                                    
                                    Text(formatFullDate(walk.date))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                if let mood = walk.mood {
                                    VStack(spacing: 2) {
                                        Text(mood.emoji)
                                            .font(.system(size: 32))
                                        Text(mood.rawValue)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(mood.color)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Stats Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            DetailStatCard(title: "Distance", value: String(format: "%.2f", walk.distanceInMiles), unit: "mi", icon: "location.fill", color: .green)
                            DetailStatCard(title: "Duration", value: walk.formattedDurationLong, unit: "", icon: "clock.fill", color: .blue)
                            DetailStatCard(title: "Pace", value: walk.pace, unit: "/mi", icon: "speedometer", color: .purple)
                            DetailStatCard(title: "Calories", value: "\(walk.calories)", unit: "cal", icon: "flame.fill", color: .orange)
                            DetailStatCard(title: "Avg Speed", value: String(format: "%.1f", walk.averageSpeed), unit: "mph", icon: "gauge.with.dots.needle.bottom.50percent", color: .cyan)
                            DetailStatCard(title: "Steps", value: "\(Int(walk.distance / 0.762))", unit: "est", icon: "figure.walk", color: .pink)
                        }
                        .padding(.horizontal, 20)
                        
                        // Weather Card
                        if let weather = walk.weather {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Weather Conditions")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: weather.icon)
                                            .font(.system(size: 28))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(weather.condition)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(themeManager.primaryTextColor)
                                        
                                        HStack(spacing: 16) {
                                            Label(weather.temperatureString, systemImage: "thermometer")
                                            Label("\(weather.humidity)%", systemImage: "humidity.fill")
                                        }
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(themeManager.secondaryTextColor)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(themeManager.cardBackgroundColor)
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Photos Section
                        if !loadedPhotos.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Photos")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.primaryTextColor)
                                    
                                    Spacer()
                                    
                                    Text("\(loadedPhotos.count) photos")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                
                                // Photo Grid
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8)
                                ], spacing: 8) {
                                    ForEach(loadedPhotos.indices, id: \.self) { index in
                                        Image(uiImage: loadedPhotos[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .onTapGesture {
                                                selectedPhotoIndex = index
                                                showFullScreenPhoto = true
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Notes/Journal Section
                        if let notes = walk.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(activityColor)
                                    
                                    Text("Journal Entry")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.primaryTextColor)
                                }
                                
                                Text(notes)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(themeManager.primaryTextColor)
                                    .lineSpacing(6)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(activityColor.opacity(0.08))
                                    )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, -20)
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Share functionality
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(activityColor)
                    }
                }
            }
        }
        .onAppear {
            loadPhotos()
        }
        .fullScreenCover(isPresented: $showFullScreenPhoto) {
            if let index = selectedPhotoIndex {
                FullScreenPhotoView(photos: loadedPhotos, selectedIndex: index)
            }
        }
    }
    
    private func loadPhotos() {
        guard let photoIds = walk.photoIdentifiers else { return }
        loadedPhotos = photoIds.compactMap { PhotoStorageManager.shared.loadPhoto(identifier: $0) }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Detail Stat Card
struct DetailStatCard: View {
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
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryTextColor)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.03), radius: 6)
        )
    }
}

// MARK: - Full Screen Photo View
struct FullScreenPhotoView: View {
    let photos: [UIImage]
    let selectedIndex: Int
    @Environment(\.dismiss) var dismiss
    @State private var currentIndex: Int
    
    init(photos: [UIImage], selectedIndex: Int) {
        self.photos = photos
        self.selectedIndex = selectedIndex
        self._currentIndex = State(initialValue: selectedIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    Image(uiImage: photos[index])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                
                Spacer()
                
                Text("\(currentIndex + 1) of \(photos.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Combined Routes Map
struct CombinedRoutesMap: View {
    let walks: [WalkRecord]
    
    var body: some View {
        Map {
            ForEach(walks) { walk in
                if !walk.coordinates.isEmpty {
                    MapPolyline(coordinates: walk.coordinates)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    walk.workoutType == "run" ? Color.orange : Color.green,
                                    (walk.workoutType == "run" ? Color.orange : Color.green).opacity(0.5)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}

// MARK: - History Stat Card (Legacy - kept for compatibility)
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

#Preview {
    ActivityView()
        .environmentObject(ThemeManager())
        .environmentObject(UserSettings())
}
