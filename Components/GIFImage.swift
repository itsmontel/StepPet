//
//  GIFImage.swift
//  VirtuPet
//

import SwiftUI
import UIKit
import ImageIO

// MARK: - GIF Cache Manager
/// Caches loaded GIF frames to prevent repeated loading and UI lag
final class GIFCacheManager {
    static let shared = GIFCacheManager()
    
    private var cache: [String: CachedGIF] = [:]
    private let queue = DispatchQueue(label: "com.virtupet.gifcache", qos: .userInitiated)
    private let lock = NSLock()
    
    struct CachedGIF {
        let images: [UIImage]
        let duration: TimeInterval
    }
    
    private init() {}
    
    /// Check if a GIF is cached
    func isCached(_ gifName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return cache[gifName] != nil
    }
    
    /// Get cached GIF data
    func getCached(_ gifName: String) -> CachedGIF? {
        lock.lock()
        defer { lock.unlock() }
        return cache[gifName]
    }
    
    /// Cache GIF data
    func cache(_ gifName: String, images: [UIImage], duration: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        cache[gifName] = CachedGIF(images: images, duration: duration)
    }
    
    /// Preload a GIF in the background
    func preload(_ gifName: String, completion: (() -> Void)? = nil) {
        // Skip if already cached
        if isCached(gifName) {
            completion?()
            return
        }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Load GIF data
            let folders = ["AnimationGIF", "PlayGIF", nil]
            
            for folder in folders {
                let gifURL: URL?
                if let folder = folder {
                    gifURL = Bundle.main.url(forResource: gifName, withExtension: "gif", subdirectory: folder)
                } else {
                    gifURL = Bundle.main.url(forResource: gifName, withExtension: "gif")
                }
                
                if let url = gifURL,
                   let gifData = try? Data(contentsOf: url),
                   let source = CGImageSourceCreateWithData(gifData as CFData, nil) {
                    
                    let images = self.createImagesFromGIF(source: source)
                    let duration = self.getGIFDuration(source: source)
                    
                    self.cache(gifName, images: images, duration: duration)
                    
                    DispatchQueue.main.async {
                        completion?()
                    }
                    return
                }
            }
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    /// Preload multiple GIFs
    func preloadMultiple(_ gifNames: [String], completion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        
        for name in gifNames {
            group.enter()
            preload(name) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion?()
        }
    }
    
    private func createImagesFromGIF(source: CGImageSource) -> [UIImage] {
        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
            }
        }
        
        return images
    }
    
    private func getGIFDuration(source: CGImageSource) -> TimeInterval {
        let count = CGImageSourceGetCount(source)
        var duration: TimeInterval = 0
        
        for i in 0..<count {
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
               let gifDict = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                
                if let delayTime = gifDict[kCGImagePropertyGIFDelayTime as String] as? Double {
                    duration += delayTime
                } else if let unclampedDelay = gifDict[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                    duration += unclampedDelay
                } else {
                    duration += 0.1
                }
            }
        }
        
        return duration > 0 ? duration : 2.0
    }
}

// MARK: - GIF Image View
struct GIFImage: UIViewRepresentable {
    let gifName: String
    @Binding var isAnimating: Bool
    
    init(_ gifName: String, isAnimating: Binding<Bool> = .constant(true)) {
        self.gifName = gifName
        self._isAnimating = isAnimating
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.tag = 100 // Tag to find it later
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(imageView)
        
        // Pin imageView to all edges of container
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        loadGIF(into: imageView)
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let imageView = uiView.viewWithTag(100) as? UIImageView else { return }
        
        if isAnimating {
            if !imageView.isAnimating {
                imageView.startAnimating()
            }
        } else {
            imageView.stopAnimating()
        }
        
        // Check if GIF name changed
        if context.coordinator.currentGIFName != gifName {
            loadGIF(into: imageView)
            context.coordinator.currentGIFName = gifName
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(gifName: gifName)
    }
    
    private func loadGIF(into imageView: UIImageView) {
        // Check cache first for instant loading
        if let cached = GIFCacheManager.shared.getCached(gifName) {
            applyGIF(cached.images, duration: cached.duration, to: imageView)
            return
        }
        
        // Load from disk (will be cached for next time)
        loadGIFFromDisk(into: imageView)
    }
    
    private func loadGIFFromDisk(into imageView: UIImageView) {
        // Folders to check for GIF files
        let folders = ["AnimationGIF", "PlayGIF", nil] // nil = root bundle
        
        var gifLoaded = false
        
        for folder in folders {
            let gifURL: URL?
            if let folder = folder {
                gifURL = Bundle.main.url(forResource: gifName, withExtension: "gif", subdirectory: folder)
            } else {
                gifURL = Bundle.main.url(forResource: gifName, withExtension: "gif")
            }
            
            if let url = gifURL,
               let gifData = try? Data(contentsOf: url),
               let source = CGImageSourceCreateWithData(gifData as CFData, nil) {
                
                let images = createImagesFromGIF(source: source)
                let duration = getGIFDuration(source: source)
                
                // Cache for future use
                GIFCacheManager.shared.cache(gifName, images: images, duration: duration)
                
                applyGIF(images, duration: duration, to: imageView)
                
                gifLoaded = true
                break
            }
        }
        
        if !gifLoaded {
            // Fallback to static image from Assets
            let staticImageName = gifName.replacingOccurrences(of: "Animation", with: "").lowercased()
            if let staticImage = UIImage(named: staticImageName) {
                imageView.image = staticImage
            } else {
                // Try loading the gif name directly as a static image
                imageView.image = UIImage(named: gifName)
            }
        }
    }
    
    private func applyGIF(_ images: [UIImage], duration: TimeInterval, to imageView: UIImageView) {
        // Important: Set image first so contentMode works
        if let firstImage = images.first {
            imageView.image = firstImage
        }
        
        imageView.animationImages = images
        imageView.animationDuration = duration
        imageView.animationRepeatCount = 0 // Infinite loop
        
        if isAnimating {
            imageView.startAnimating()
        }
    }
    
    private func createImagesFromGIF(source: CGImageSource) -> [UIImage] {
        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
            }
        }
        
        return images
    }
    
    private func getGIFDuration(source: CGImageSource) -> TimeInterval {
        let count = CGImageSourceGetCount(source)
        var duration: TimeInterval = 0
        
        for i in 0..<count {
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
               let gifDict = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                
                if let delayTime = gifDict[kCGImagePropertyGIFDelayTime as String] as? Double {
                    duration += delayTime
                } else if let unclampedDelay = gifDict[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                    duration += unclampedDelay
                } else {
                    duration += 0.1 // Default frame delay
                }
            }
        }
        
        return duration > 0 ? duration : 2.0 // Default 2 second animation
    }
    
    class Coordinator {
        var currentGIFName: String
        
        init(gifName: String) {
            self.currentGIFName = gifName
        }
    }
}

// MARK: - Static Pet Image View (Fallback)
struct PetImageView: View {
    let petType: PetType
    let moodState: PetMoodState
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let imageName = petType.imageName(for: moodState)
        
        if let _ = UIImage(named: imageName) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // Placeholder
            Image(systemName: "pawprint.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
}

// MARK: - Animated Pet View (Combines GIF + Fallback)
struct AnimatedPetView: View {
    let petType: PetType
    let moodState: PetMoodState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isAnimating = true
    
    var body: some View {
        let gifName = petType.gifName(for: moodState, isDarkMode: themeManager.isDarkMode)
        
        GIFImage(gifName, isAnimating: $isAnimating)
            .onAppear {
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        AnimatedPetView(petType: .bunny, moodState: .fullHealth)
            .frame(width: 200, height: 200)
        
        AnimatedPetView(petType: .dog, moodState: .happy)
            .frame(width: 200, height: 200)
    }
    .environmentObject(ThemeManager())
}

