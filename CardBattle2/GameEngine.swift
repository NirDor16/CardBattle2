import Foundation

/// Manages game state, rounds, and the two-phase timer (5s countdown → 3s reveal).
class GameEngine {
    let totalRounds = 10
    private let countdownDuration = 5
    private let revealDuration    = 3

    private(set) var round       = 0
    private(set) var playerScore = 0
    private(set) var pcScore     = 0

    private var timer: Timer?
    private var tick  = 0
    private var phase: Phase = .countdown

    private enum Phase { case countdown, reveal }

    // MARK: - Callbacks

    /// Called every second during countdown with remaining seconds (5→1).
    var onCountdownTick: ((Int) -> Void)?

    /// Called when cards should flip and be revealed; provides the two new cards.
    var onRevealCards: ((Card, Card) -> Void)?

    /// Called after the reveal phase; cards should flip back face-down.
    var onHideCards: (() -> Void)?

    /// Called with updated (playerScore, pcScore) after each round is evaluated.
    var onRoundResult: ((Int, Int) -> Void)?

    /// Called when all 10 rounds are complete with final (playerScore, pcScore).
    var onGameOver: ((Int, Int) -> Void)?

    // MARK: - Control

    /// Start the engine from the beginning.
    func start() {
        round = 0; playerScore = 0; pcScore = 0
        beginCountdown()
    }

    /// Stop all timers — call on viewWillDisappear or app background.
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Resume after a pause — call on viewDidAppear or app foreground.
    func resume() {
        guard timer == nil else { return }
        scheduleTimer()
    }

    // MARK: - Private

    private func beginCountdown() {
        phase = .countdown
        tick  = countdownDuration
        onCountdownTick?(tick)
        scheduleTimer()
    }

    private func beginReveal() {
        phase = .reveal
        tick  = revealDuration
        scheduleTimer()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.handleTick()
        }
    }

    /// Central tick — drives both countdown and reveal phases.
    private func handleTick() {
        tick -= 1
        switch phase {
        case .countdown:
            if tick > 0 {
                onCountdownTick?(tick)
            } else {
                stop()
                let playerCard = Card.deck.randomElement()!
                let pcCard     = Card.deck.randomElement()!
                evaluateRound(playerCard: playerCard, pcCard: pcCard)
                onRevealCards?(playerCard, pcCard)
                round += 1
                beginReveal()
            }
        case .reveal:
            if tick <= 0 {
                stop()
                onHideCards?()
                if round >= totalRounds {
                    onGameOver?(playerScore, pcScore)
                } else {
                    beginCountdown()
                }
            }
        }
    }

    /// Evaluate the round result and update scores.
    private func evaluateRound(playerCard: Card, pcCard: Card) {
        if playerCard.strength > pcCard.strength {
            playerScore += 1
        } else if pcCard.strength > playerCard.strength {
            pcScore += 1
        }
        onRoundResult?(playerScore, pcScore)
    }
}
