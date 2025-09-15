import UIKit

class FullscreenLoader {
	static let shared = FullscreenLoader()

	private var loaderView: UIView?

	func show(on view: UIView) {
		guard loaderView == nil else { return }

		let overlay = UIView(frame: view.bounds)
		overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)

		let activity = UIActivityIndicatorView(style: .large)
		activity.color = .white
		activity.center = overlay.center
		activity.startAnimating()

		overlay.addSubview(activity)
		view.addSubview(overlay)

		loaderView = overlay
	}

	func hide() {
		loaderView?.removeFromSuperview()
		loaderView = nil
	}
}
