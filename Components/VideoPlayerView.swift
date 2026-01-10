//
//  VideoPlayerView.swift
//  VirtuPet
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
            // Ensure playback is active when view updates
            playerView.ensurePlayback()
        }
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        if let playerView = uiView as? PlayerUIView {
            playerView.cleanup()
        }
    }
}

class PlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    private var currentVideoName: String = ""
    private var appLifecycleObservers: [NSObjectProtocol] = []
    private var playerObserver: NSKeyValueObservation?
    
    init(videoName: String) {
        super.init(frame: .zero)
        currentVideoName = videoName
        setupPlayer(videoName: videoName)
        setupAppLifecycleObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAppLifecycleObservers() {
        // Resume when app becomes active
        let foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumePlayback()
        }
        
        let activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumePlayback()
        }
        
        // Pause when app goes to background
        let backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.queuePlayer?.pause()
        }
        
        appLifecycleObservers = [foregroundObserver, activeObserver, backgroundObserver]
    }
    
    private func setupPlayer(videoName: String) {
        // Configure audio session to not interrupt other audio (Spotify, Apple Music, etc.)
        // Since our videos are muted, we use ambient category which mixes with other audio
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
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
        
        // Observe player status to handle stalls
        playerObserver = queuePlayer?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            if player.timeControlStatus == .paused && UIApplication.shared.applicationState == .active {
                // Player stalled while app is active, try to resume
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.resumePlayback()
                }
            }
        }
        
        queuePlayer?.play()
    }
    
    func updateVideo(videoName: String) {
        guard videoName != currentVideoName else { return }
        currentVideoName = videoName
        
        // Stop current player
        playerObserver?.invalidate()
        playerObserver = nil
        queuePlayer?.pause()
        playerLooper = nil
        queuePlayer = nil
        
        // Setup new player
        setupPlayer(videoName: videoName)
    }
    
    func ensurePlayback() {
        // If player exists but isn't playing, restart it
        if let player = queuePlayer, player.timeControlStatus != .playing {
            player.play()
        }
    }
    
    func resumePlayback() {
        guard window != nil else { return } // Only resume if view is in window
        queuePlayer?.play()
    }
    
    func cleanup() {
        playerObserver?.invalidate()
        playerObserver = nil
        queuePlayer?.pause()
        playerLooper = nil
        queuePlayer = nil
        
        for observer in appLifecycleObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        appLifecycleObservers.removeAll()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            // View became visible, resume playback
            resumePlayback()
        }
    }
    
    deinit {
        cleanup()
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



