// FocusOverlayView.swift  (add/replace with this version)
import UIKit

final class FocusOverlayView: UIView {
	enum State { case idle, found, invalid }

	// MARK: Appearance

	var idleColor: UIColor = .white
	var foundColor: UIColor = UIColor.Quore.Green.greenBEE19C
	var invalidColor: UIColor = UIColor.Quore.Red.redFF6E76
	var backgroundDimAlpha: CGFloat = 0.7
	var cornerLength: CGFloat = 34
	var cornerWidth: CGFloat = 4
	var cornerRadius: CGFloat = 0

	// MARK: Internals

	private let dimLayer = CAShapeLayer()
	private let corners: [CAShapeLayer] = (0 ..< 4).map { _ in CAShapeLayer() }
	private var currentRect: CGRect? // nil = use default
	private var lastRect: CGRect? // for smoothing

	/// 0…1, how strongly to ease towards the new rect (higher = smoother)
	var smoothing: CGFloat = 0.25

	override init(frame: CGRect) {
		super.init(frame: frame)
		isUserInteractionEnabled = false
		backgroundColor = .clear

		dimLayer.fillRule = .evenOdd
		dimLayer.fillColor = UIColor.black.withAlphaComponent(backgroundDimAlpha).cgColor
		layer.addSublayer(dimLayer)

		for corner in corners {
			corner.fillColor = UIColor.clear.cgColor
			corner.lineWidth = cornerWidth
			corner.lineCap = .round
			corner.strokeColor = idleColor.cgColor
			layer.addSublayer(corner)
		}
	}

	@available(*, unavailable) required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

	/// Default centered rect used when no code is visible
	var defaultRect: CGRect {
		let side = min(308, max(308, min(bounds.width, bounds.height) * 0.7))
		return CGRect(x: (bounds.width - side) / 2, y: (bounds.height - side) / 2, width: side, height: side)
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		drawOverlay(in: currentRect ?? defaultRect)
	}

	// MARK: API

	func setState(_ state: State) {
		let activeColor: UIColor
		switch state {
			case .found: activeColor = foundColor
			case .invalid: activeColor = invalidColor
			default: activeColor = idleColor
		}
		for corner in corners {
			let anim = CABasicAnimation(keyPath: "strokeColor")
			anim.fromValue = corner.strokeColor; anim.toValue = activeColor.cgColor; anim.duration = 0.18
			corner.add(anim, forKey: "color")
			corner.strokeColor = activeColor.cgColor
		}
		if state == .found {
			let pulse = CASpringAnimation(keyPath: "transform.scale")
			pulse.fromValue = 1.0; pulse.toValue = 1.05; pulse.initialVelocity = 0.8; pulse.damping = 6; pulse.duration = 0.35
			layer.add(pulse, forKey: "pulse")
		}
		if state == .invalid {
			let pulse = CASpringAnimation(keyPath: "transform.scale")
			pulse.fromValue = 1.0; pulse.toValue = 1.05; pulse.initialVelocity = 0.8; pulse.damping = 6; pulse.duration = 0.35
			layer.add(pulse, forKey: "pulse")
		}
	}

	/// Animate/resize overlay to a specific rect (pass `nil` to go back to the default)
	func animate(to target: CGRect?, animated: Bool = true) {
		let targetRect = target ?? defaultRect

		// smooth towards target to prevent jitter
		let base = lastRect ?? (currentRect ?? defaultRect)
		let t = smoothing
		let lerped = CGRect(
			x: base.minX + (targetRect.minX - base.minX) * t,
			y: base.minY + (targetRect.minY - base.minY) * t,
			width: base.width + (targetRect.width - base.width) * t,
			height: base.height + (targetRect.height - base.height) * t
		)

		lastRect = lerped
		currentRect = lerped

		if animated {
			CATransaction.begin()
			CATransaction.setAnimationDuration(0.12)
			drawOverlay(in: lerped)
			CATransaction.commit()
		} else {
			drawOverlay(in: lerped)
		}
	}

	// MARK: Drawing

	private func drawOverlay(in r: CGRect) {
		// Dimmed background with cutout
		let p = UIBezierPath(rect: bounds)
		p.append(UIBezierPath(roundedRect: r, cornerRadius: cornerRadius))
		dimLayer.path = p.cgPath
		dimLayer.fillColor = UIColor.black.withAlphaComponent(backgroundDimAlpha).cgColor

		// Corner “L”s
		func cornerPath(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> UIBezierPath {
			let p = UIBezierPath(); p.move(to: a); p.addLine(to: b); p.move(to: a); p.addLine(to: c); return p
		}
		let paths: [UIBezierPath] = [
			cornerPath(
				CGPoint(x: r.minX, y: r.minY),
				CGPoint(x: r.minX + cornerLength, y: r.minY),
				CGPoint(x: r.minX, y: r.minY + cornerLength)
			),
			cornerPath(
				CGPoint(x: r.maxX, y: r.minY),
				CGPoint(x: r.maxX - cornerLength, y: r.minY),
				CGPoint(x: r.maxX, y: r.minY + cornerLength)
			),
			cornerPath(
				CGPoint(x: r.minX, y: r.maxY),
				CGPoint(x: r.minX + cornerLength, y: r.maxY),
				CGPoint(x: r.minX, y: r.maxY - cornerLength)
			),
			cornerPath(
				CGPoint(x: r.maxX, y: r.maxY),
				CGPoint(x: r.maxX - cornerLength, y: r.maxY),
				CGPoint(x: r.maxX, y: r.maxY - cornerLength)
			)
		]
		for (i, p) in paths.enumerated() {
			corners[i].path = p.cgPath
		}
	}
}
