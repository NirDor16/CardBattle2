import UIKit

class SummaryViewController: UIViewController {

    @IBOutlet weak var winnerLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!

    var winnerName: String = "PC"
    var winnerScore: Int   = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        winnerLabel.text = "Winner: \(winnerName)"
        scoreLabel.text  = "score: \(winnerScore)"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        applyTheme()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyTheme()
        }
    }

    /// Apply dark or light appearance.
    private func applyTheme() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor   = isDark ? .black : .white
        let textColor: UIColor = isDark ? .white : .black
        winnerLabel.textColor  = textColor
        scoreLabel.textColor   = textColor
    }

    @IBAction func backToMenuTapped(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}
