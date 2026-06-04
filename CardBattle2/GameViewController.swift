import UIKit

/// Landscape-only game screen. Handles card reveal cycle, scoring, sounds, and lifecycle.
class GameViewController: UIViewController {

    @IBOutlet weak var playerNameLabel: UILabel!
    @IBOutlet weak var playerScoreLabel: UILabel!
    @IBOutlet weak var pcNameLabel: UILabel!
    @IBOutlet weak var pcScoreLabel: UILabel!
    @IBOutlet weak var playerCardImageView: UIImageView!
    @IBOutlet weak var timerIconImageView: UIImageView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var pcCardImageView: UIImageView!

    var playerName: String = "Player"
    var playerSide: String = "East Side"

    private let engine = GameEngine()

    // Physical-side references set in assignSides()
    private var myNameLabel: UILabel!
    private var myScoreLabel: UILabel!
    private var myCardView: UIImageView!
    private var opponentScoreLabel: UILabel!
    private var opponentCardView: UIImageView!

    // Card back image shown between reveals
    private let cardBackImage = UIImage(named: "card_back")

    // Dynamic card position/size constraints (portrait ↔ landscape)
    private var leftCX: NSLayoutConstraint!
    private var leftCY: NSLayoutConstraint!
    private var leftW:  NSLayoutConstraint!
    private var leftH:  NSLayoutConstraint!
    private var rightCX: NSLayoutConstraint!
    private var rightCY: NSLayoutConstraint!
    private var rightW:  NSLayoutConstraint!
    private var rightH:  NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        assignSides()
        setupUI()
        setupCardConstraints()
        setupEngine()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start or resume music and timer when screen becomes visible
        if engine.round == 0 {
            SoundManager.shared.startBackgroundMusic()
            engine.start()
        } else {
            SoundManager.shared.resumeBackgroundMusic()
            engine.resume()
        }
    }

    /// Pause timer and music when leaving the screen.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        engine.stop()
        SoundManager.shared.pauseBackgroundMusic()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyTheme()
        }
    }

    // MARK: - Theme

    /// Apply dark or light colors to score labels and background.
    private func applyTheme() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDark ? .black : .white
        let textColor: UIColor = isDark ? .white : .black
        playerNameLabel.textColor  = textColor
        playerScoreLabel.textColor = textColor
        pcNameLabel.textColor      = textColor
        pcScoreLabel.textColor     = textColor
        timerLabel.textColor       = textColor
        timerIconImageView.tintColor = textColor
    }

    // MARK: - Setup

    /// Wire physical left/right outlets to logical player/opponent roles based on side.
    private func assignSides() {
        if playerSide == "East Side" {
            myNameLabel        = pcNameLabel
            myScoreLabel       = pcScoreLabel
            myCardView         = pcCardImageView
            opponentScoreLabel = playerScoreLabel
            opponentCardView   = playerCardImageView
            playerNameLabel.text = "PC"
        } else {
            myNameLabel        = playerNameLabel
            myScoreLabel       = playerScoreLabel
            myCardView         = playerCardImageView
            opponentScoreLabel = pcScoreLabel
            opponentCardView   = pcCardImageView
            pcNameLabel.text   = "PC"
        }
    }

    private func setupUI() {
        myNameLabel.text        = playerName
        myScoreLabel.text       = "0"
        opponentScoreLabel.text = "0"
        timerLabel.text         = "5"
        timerIconImageView.image     = UIImage(systemName: "stopwatch")
        timerIconImageView.tintColor = .label

        for iv in [myCardView, opponentCardView] {
            iv?.layer.cornerRadius = 12
            iv?.clipsToBounds      = true
            iv?.contentMode        = .scaleAspectFit
            iv?.backgroundColor    = .white
            iv?.image = cardBackImage
        }
    }

    // MARK: - Card layout (portrait / landscape)

    private func setupCardConstraints() {
        for iv in [playerCardImageView!, pcCardImageView!] {
            view.constraints
                .filter { ($0.firstItem as? UIView) === iv || ($0.secondItem as? UIView) === iv }
                .forEach { $0.isActive = false }
            iv.constraints.forEach { $0.isActive = false }
            iv.translatesAutoresizingMaskIntoConstraints = false
        }

        leftCX = playerCardImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -180)
        leftCY = playerCardImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        leftW  = playerCardImageView.widthAnchor.constraint(equalToConstant: 170)
        leftH  = playerCardImageView.heightAnchor.constraint(equalToConstant: 240)

        rightCX = pcCardImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 180)
        rightCY = pcCardImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        rightW  = pcCardImageView.widthAnchor.constraint(equalToConstant: 170)
        rightH  = pcCardImageView.heightAnchor.constraint(equalToConstant: 240)

        NSLayoutConstraint.activate([leftCX, leftCY, leftW, leftH, rightCX, rightCY, rightW, rightH])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let landscape = view.bounds.width > view.bounds.height
        if landscape {
            leftCX.constant = -180;  rightCX.constant = 180
            leftW.constant  = 170;   leftH.constant   = 240
            rightW.constant = 170;   rightH.constant  = 240
        } else {
            leftCX.constant = -90;   rightCX.constant = 90
            leftW.constant  = 130;   leftH.constant   = 183
            rightW.constant = 130;   rightH.constant  = 183
        }
    }

    // MARK: - Engine callbacks

    /// Wire the GameEngine callbacks to UI updates and sounds.
    private func setupEngine() {

        // Update countdown label each second
        engine.onCountdownTick = { [weak self] seconds in
            DispatchQueue.main.async { self?.timerLabel.text = "\(seconds)" }
        }

        // Flip cards face-up with animation and sound
        engine.onRevealCards = { [weak self] playerCard, pcCard in
            guard let self else { return }
            DispatchQueue.main.async {
                SoundManager.shared.playFlip()
                self.timerLabel.text = ""
                UIView.transition(with: self.myCardView,
                                  duration: 0.4, options: .transitionFlipFromLeft) {
                    self.myCardView.image     = UIImage(named: playerCard.imageName)
                    self.myCardView.tintColor = nil
                }
                UIView.transition(with: self.opponentCardView,
                                  duration: 0.4, options: .transitionFlipFromRight) {
                    self.opponentCardView.image     = UIImage(named: pcCard.imageName)
                    self.opponentCardView.tintColor = nil
                }
            }
        }

        // Flip cards face-down after reveal phase
        engine.onHideCards = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                SoundManager.shared.playFlip()
                UIView.transition(with: self.myCardView,
                                  duration: 0.4, options: .transitionFlipFromRight) {
                    self.myCardView.image = self.cardBackImage
                }
                UIView.transition(with: self.opponentCardView,
                                  duration: 0.4, options: .transitionFlipFromLeft) {
                    self.opponentCardView.image = self.cardBackImage
                }
            }
        }

        // Update score labels after each round
        engine.onRoundResult = { [weak self] playerScore, pcScore in
            guard let self else { return }
            DispatchQueue.main.async {
                self.myScoreLabel.text       = "\(self.engine.playerScore)"
                self.opponentScoreLabel.text = "\(self.engine.pcScore)"
                self.timerLabel.text         = "5"
            }
        }

        // Game over — play victory sound and navigate to summary
        engine.onGameOver = { [weak self] _, _ in
            DispatchQueue.main.async {
                SoundManager.shared.playVictory()
                self?.performSegue(withIdentifier: "showSummary", sender: nil)
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSummary",
           let summaryVC = segue.destination as? SummaryViewController {
            let ps = engine.playerScore
            let cs = engine.pcScore
            summaryVC.winnerName  = ps > cs ? playerName : "PC"
            summaryVC.winnerScore = max(ps, cs)
        }
    }
}
