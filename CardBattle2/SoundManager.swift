import AVFoundation

/// Manages all audio: flip sound, victory sound, and background music.
class SoundManager: NSObject {
    static let shared = SoundManager()

    private var backgroundPlayer: AVAudioPlayer?
    private var flipPlayer: AVAudioPlayer?
    private var victoryPlayer: AVAudioPlayer?

    private override init() {
        super.init()
        setupAudioSession()
        preloadSounds()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func preloadSounds() {
        flipPlayer       = makePlayer(filename: "flip",             ext: "mp3")
        victoryPlayer    = makePlayer(filename: "victory",          ext: "mp3")
        backgroundPlayer = makePlayer(filename: "background_music", ext: "mp3")
        backgroundPlayer?.numberOfLoops = -1
        backgroundPlayer?.volume = 0.4
    }

    private func makePlayer(filename: String, ext: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else { return nil }
        return try? AVAudioPlayer(contentsOf: url)
    }

    // MARK: - Playback

    /// Play the card-flip sound effect.
    func playFlip() {
        flipPlayer?.stop()
        flipPlayer?.currentTime = 0
        flipPlayer?.play()
    }

    /// Play the victory / game-over sound.
    func playVictory() {
        stopBackgroundMusic()
        victoryPlayer?.stop()
        victoryPlayer?.currentTime = 0
        victoryPlayer?.play()
    }

    /// Start background music from the beginning.
    func startBackgroundMusic() {
        backgroundPlayer?.currentTime = 0
        backgroundPlayer?.play()
    }

    /// Pause background music (preserves playback position).
    func pauseBackgroundMusic() {
        backgroundPlayer?.pause()
    }

    /// Resume background music from where it was paused.
    func resumeBackgroundMusic() {
        backgroundPlayer?.play()
    }

    /// Stop background music and reset position.
    func stopBackgroundMusic() {
        backgroundPlayer?.stop()
        backgroundPlayer?.currentTime = 0
    }
}
