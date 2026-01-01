//
//  GIFImage.swift
//  VirtuPet
//

import SwiftUI
import UIKit
import ImageIO

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

