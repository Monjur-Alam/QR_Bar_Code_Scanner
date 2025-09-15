import Foundation
import UIKit

extension UIImage {
	enum Quore {
		static let icon_close_circle_fill = UIImage(named: "icon_close_circle_fill")
		static let icon_flash_on = UIImage(named: "icon_flash_on")
		static let icon_flash_off = UIImage(named: "icon_flash_off")
		static let icon_qr_code = UIImage(named: "icon_qr_code")
		static let icon_left_arrow_circle_fill = UIImage(named: "icon_left_arrow_circle_fill")
	}

	func normalizedImage() -> UIImage {
		if imageOrientation == .up { return self }
		UIGraphicsBeginImageContextWithOptions(size, false, scale)
		draw(in: CGRect(origin: .zero, size: size))
		let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return normalizedImage ?? self
	}
}
