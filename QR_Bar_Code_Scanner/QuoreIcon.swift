import UIKit

class QuoreIcon: UIImageView {

	// MARK: - Properties

	var onTap: (() -> Void)?

	// MARK: - Initialization

	init(image: UIImage?, width: CGFloat, height: CGFloat) {
		super.init(frame: .zero)

		self.image = image

		let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTapClose(_:)))
		addGestureRecognizer(gesture)
		isUserInteractionEnabled = true
		contentMode = .scaleAspectFit
		translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: width),
			heightAnchor.constraint(equalToConstant: height)
		])
	}

	@available(*, unavailable) required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc private func handleTapClose(_ tapGestureRecognizer: UITapGestureRecognizer) {
		onTap?()
	}

	func setImage(image: UIImage) {
		self.image = image
	}
}
