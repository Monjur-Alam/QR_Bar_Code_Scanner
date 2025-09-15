import UIKit

final class QRResultPopupViewController: UIViewController {
    private let resultText: String
    var didTapClose: (() -> Void)?

    init(resultText: String) {
        self.resultText = resultText
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 16
        view.addSubview(container)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = resultText
        label.numberOfLines = 0
        label.textAlignment = .center
        container.addSubview(label)

        // --- Buttons: Copy + Close
        let copyBtn = UIButton(type: .system)
        copyBtn.translatesAutoresizingMaskIntoConstraints = false
        copyBtn.setTitle("Copy", for: .normal)
        copyBtn.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)

        let closeBtn = UIButton(type: .system)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [copyBtn, closeBtn])
        buttons.translatesAutoresizingMaskIntoConstraints = false
        buttons.axis = .horizontal
        buttons.alignment = .fill
        buttons.distribution = .fillEqually
        buttons.spacing = 12
        container.addSubview(buttons)

        NSLayoutConstraint.activate([
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            buttons.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            buttons.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            buttons.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            buttons.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            buttons.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func dismissPopup() {
        didTapClose?()
        dismiss(animated: true)
    }

    @objc private func copyTapped() {
        UIPasteboard.general.string = resultText
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast(message: "Copied") { [weak self] in
            self?.didTapClose?()
            self?.dismiss(animated: true)
        }
    }

    private func showToast(message: String, completion: (() -> Void)? = nil) {
        let toast = UILabel()
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.text = message
        toast.textAlignment = .center
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.alpha = 0

        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            toast.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])

        // Simple fade in/out
        UIView.animate(withDuration: 0.2, animations: {
            toast.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0.8, options: [], animations: {
                toast.alpha = 0
            }, completion: { _ in
                toast.removeFromSuperview()
                completion?()
            })
        })
    }
}
