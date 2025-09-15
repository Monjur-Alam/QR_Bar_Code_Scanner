// Views/ScannerView.swift
import AVFoundation
import UIKit

/// Mirrors your storyboard layout using Auto Layout (no nibs).
final class ScannerView: UIView {
	enum State { case idle, manual, found, result, invalid }
	// Camera preview layer
	let previewLayer = AVCaptureVideoPreviewLayer()
	var currentState: State = .idle
	private var blurEffectView: UIVisualEffectView?
	private let inset: CGFloat = 24
	private var y_subtitleLabel: CGFloat = 0
	var didCloseButtonTap: (() -> Void)?
	var didTorchButtonTap: (() -> Void)?

	lazy var scanRect: CGRect = {
		let s = min(bounds.width, bounds.height) - (inset * 2)
		let side = min(308, max(308, s * 0.7)) // responsive range
		return CGRect(
			x: (bounds.width - side) / 2,
			y: (bounds.height - side) / 2,
			width: side,
			height: side
		)
	}()

	// UI from the storyboard design
	lazy var closeButton: QuoreIcon = {
		let b = QuoreIcon(image: UIImage.Quore.icon_close_circle_fill, width: 32, height: 32)
		b.onTap = { [weak self] in
			self?.didCloseButtonTap?()
		}
		return b
	}()

	lazy var torchButton: QuoreIcon = {
		let b = QuoreIcon(image: UIImage.Quore.icon_flash_off, width: 32, height: 32)
		b.onTap = { [weak self] in
			self?.didTorchButtonTap?()
		}
		return b
	}()

	let titleLabel: UILabel = {
		let l = UILabel()
		l.text = "Scan QR code"
		l.textColor = .white
		l.font = UIFont.Quore.Lato.Bold.Sixteen
		l.textAlignment = .center
		return l
	}()

	let subtitleLabel: UILabel = {
		let l = UILabel()
		l.text = "Place the QR code in the frame to scan"
		l.textColor = .white
		l.font = UIFont.Quore.Lato.Bold.Fourteen
		l.textAlignment = .center
		l.numberOfLines = 2
		return l
	}()

	lazy var generatedQRImageView: UIImageView = {
		let iv = UIImageView()
		iv.contentMode = .scaleAspectFill
		iv.isHidden = true
		return iv
	}()

	let overlay = FocusOverlayView()

	let manualButton: UIButton = {
		let b = UIButton(type: .system)
		b.setTitle("Type QR code", for: .normal)
		b.setTitleColor(.white, for: .normal)
		b.backgroundColor = UIColor.Quore.Gray.gray6A6B6B
		b.titleLabel?.font = UIFont.Quore.Lato.Bold.Fourteen
		b.layer.cornerRadius = 20
		b.contentEdgeInsets = .init(top: 10, left: 16, bottom: 10, right: 16)
		return b
	}()

	let manualTitleLabel: UILabel = {
		let l = UILabel()
		l.text = "Type the QR code below"
		l.textColor = .white
		l.font = UIFont.Quore.Lato.Semibold.Fourteen
		l.textAlignment = .center
		l.isHidden = true
		return l
	}()

	var textField: UITextField = {
		let tf = UITextField()
		let placeholderText = "Type QR code"
		tf.attributedPlaceholder = NSAttributedString(
			string: placeholderText,
			attributes: [
				.foregroundColor: UIColor.Quore.Gray.gray949595
			]
		)
		tf.textColor = .white
		tf.backgroundColor = UIColor.black.withAlphaComponent(0.5)
		tf.font = UIFont.Quore.Lato.Regular.Fourteen
		tf.layer.cornerRadius = 20
		tf.clipsToBounds = true

		// Left alignment
		tf.textAlignment = .center

		// Add left padding
		let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
		tf.leftView = paddingView
		tf.leftViewMode = .always
		tf.rightView = paddingView
		tf.rightViewMode = .always

		tf.returnKeyType = .go
		tf.isHidden = true
		return tf
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = .black

		previewLayer.videoGravity = .resizeAspectFill
		layer.addSublayer(previewLayer)

		[generatedQRImageView, overlay, titleLabel, subtitleLabel, manualButton, manualTitleLabel, textField, closeButton, torchButton]
			.forEach { addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }

		NSLayoutConstraint.activate([
			closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
			closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

			torchButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
			torchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

			titleLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 66),
			titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
			titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

			subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
			subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
			subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

			manualTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
			manualTitleLabel.bottomAnchor.constraint(equalTo: textField.topAnchor, constant: -24),

			textField.centerXAnchor.constraint(equalTo: centerXAnchor),
			textField.bottomAnchor.constraint(equalTo: centerYAnchor),
			textField.heightAnchor.constraint(equalToConstant: 40),
			textField.widthAnchor.constraint(equalToConstant: 154)
		])
	}

	@available(*, unavailable) required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

	override func layoutSubviews() {
		super.layoutSubviews()
		previewLayer.frame = bounds
		overlay.frame = bounds
		generatedQRImageView.frame = bounds
		let s = min(bounds.width, bounds.height) - (inset * 2)
		let side = min(308, max(308, s * 0.7))
		let y_manualButton = ((bounds.height - side) / 2) + side + 40
		manualButton.frame = CGRect(
			x: (bounds.width - 154) / 2,
			y: y_manualButton,
			width: 154,
			height: 40
		)
	}

	func setState(_ s: State) {
		switch s {
			case .idle:
				titleLabel.isHidden = false
				subtitleLabel.isHidden = false
				torchButton.isHidden = false
				closeButton.setImage(image: UIImage.Quore.icon_close_circle_fill ?? UIImage())
				overlay.isHidden = false
				generatedQRImageView.isHidden = true
				generatedQRImageView.image = nil
				manualButton.isHidden = false
				manualTitleLabel.isHidden = true
				textField.isHidden = true
				textField.text = ""
				textField.resignFirstResponder()
				overlay.setState(.idle)
				currentState = .idle
				overlay.animate(to: nil, animated: true)
			case .manual:
				titleLabel.isHidden = true
				subtitleLabel.isHidden = true
				torchButton.isHidden = true
				closeButton.setImage(image: UIImage.Quore.icon_left_arrow_circle_fill ?? UIImage())
				overlay.isHidden = true
				currentState = .manual
				manualButton.isHidden = true
				manualTitleLabel.isHidden = false
				textField.isHidden = false
				textField.becomeFirstResponder()
				generatedQRImageView.isHidden = false
				applyBlurToQRImageView(true)
				overlay.animate(to: nil, animated: true)
			case .found:
				titleLabel.isHidden = false
				subtitleLabel.isHidden = false
				torchButton.isHidden = false
				closeButton.setImage(image: UIImage.Quore.icon_close_circle_fill ?? UIImage())
				overlay.isHidden = false
				generatedQRImageView.isHidden = false
				applyBlurToQRImageView(true)
				manualButton.isHidden = false
				overlay.setState(.found)
				currentState = .found
			case .result:
				titleLabel.isHidden = true
				subtitleLabel.isHidden = true
				torchButton.isHidden = false
				closeButton.setImage(image: UIImage.Quore.icon_close_circle_fill ?? UIImage())
				overlay.isHidden = true
				generatedQRImageView.isHidden = false
				applyBlurToQRImageView(true)
				manualButton.isHidden = true
				manualTitleLabel.isHidden = true
				textField.isHidden = true
				textField.text = ""
				textField.resignFirstResponder()
				overlay.setState(.found)
				currentState = .result
				overlay.animate(to: nil, animated: true)
			case .invalid:
				overlay.setState(.invalid)
				titleLabel.isHidden = true
				subtitleLabel.isHidden = true
				torchButton.isHidden = false
				closeButton.setImage(image: UIImage.Quore.icon_close_circle_fill ?? UIImage())
				overlay.isHidden = true
				generatedQRImageView.isHidden = false
				applyBlurToQRImageView(true)
				manualButton.isHidden = true
				manualTitleLabel.isHidden = true
				textField.isHidden = true
				textField.text = ""
				textField.resignFirstResponder()
				currentState = .invalid
				overlay.animate(to: nil, animated: true)
		}
	}

	// This will be added inside your setState method or wherever you need the blur effect
	func applyBlurToQRImageView(_ apply: Bool) {
		// If we need to remove the blur
		if !apply {
			blurEffectView?.removeFromSuperview()
			blurEffectView = nil
			return
		}

		// If blur already exists, return
		if blurEffectView != nil { return }

		// Create a blur effect
		let blurEffect = UIBlurEffect(style: .regular) // Choose the blur style you prefer
		let blurView = UIVisualEffectView(effect: blurEffect)

		// Set the frame of the blur view to match the image view's size
		blurView.frame = generatedQRImageView.bounds
		blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

		// Add the blur effect view on top of the QR code image
		generatedQRImageView.addSubview(blurView)

		// Store reference to this blur view for future removal
		blurEffectView = blurView
		blurEffectView?.alpha = 0.6
	}
}
