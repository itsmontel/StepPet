//
//  VideoPlayerView.swift
//  StepPet
//

import SwiftUI
import AVKit
import AVFoundation

// MARK: - Looping Video Player
struct LoopingVideoPlayer: UIViewRepresentable {
    let videoName: String
    
    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView(videoName: videoName)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerView = uiView as? PlayerUIView {
            playerView.updateVideo(videoName: videoName)
        }
    }
}

class PlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    private var currentVideoName: String = ""
    
    init(videoName: String) {
        super.init(frame: .zero)
        currentVideoName = videoName
        setupPlayer(videoName: videoName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer(videoName: String) {
        // Try multiple folder locations
        let folders = ["Animation", "AnimationGIF", nil]
        var videoURL: URL?
        
        for folder in folders {
            if let folder = folder {
                if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4", subdirectory: folder) {
                    videoURL = url
                    break
                }
            } else {
                if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
                    videoURL = url
                    break
                }
            }
        }
        
        guard let url = videoURL else {
            print("Video not found: \(videoName)")
            return
        }
        
        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        
        queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer?.isMuted = true
        
        playerLooper = AVPlayerLooper(player: queuePlayer!, templateItem: item)
        
        playerLayer.player = queuePlayer
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = UIColor.clear.cgColor
        
        layer.addSublayer(playerLayer)
        
        queuePlayer?.play()
    }
    
    func updateVideo(videoName: String) {
        guard videoName != currentVideoName else { return }
        currentVideoName = videoName
        
        // Stop current player
        queuePlayer?.pause()
        playerLooper = nil
        queuePlayer = nil
        
        // Setup new player
        setupPlayer(videoName: videoName)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    deinit {
        queuePlayer?.pause()
        playerLooper = nil
        queuePlayer = nil
    }
}

// MARK: - Animated Pet View (MP4 version)
struct AnimatedPetVideoView: View {
    let petType: PetType
    let moodState: PetMoodState
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let videoName = petType.videoName(for: moodState, isDarkMode: themeManager.isDarkMode)
        
        LoopingVideoPlayer(videoName: videoName)
            .id("\(petType.rawValue)-\(moodState.rawValue)-\(themeManager.isDarkMode)")
    }
}

// MARK: - Preview
#Preview {
    VStack {
        AnimatedPetVideoView(petType: .dog, moodState: .happy)
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    .environmentObject(ThemeManager())
}

