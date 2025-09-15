import UIKit

extension UIColor {

	enum Quore {

		enum Green {
			static let greenBEE19C = hexUI(hex: "BEE19C")
		}

		enum Red {
			static let redFF6E76 = hexUI(hex: "FF6E76")
		}

		enum Gray { 
			static let gray6A6B6B = hexUI(hex: "6A6B6B")//
			static let gray949595 = hexUI(hex: "949595")//
		}
	}
}

private func hexUI(hex: String) -> UIColor {
	var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
	if cString.hasPrefix("#") {
		cString.remove(at: cString.startIndex)
	}
	if cString.count != 6 {
		return .gray
	}
	var rgbValue: UInt64 = 0
	Scanner(string: cString).scanHexInt64(&rgbValue)
	return UIColor(
		red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255,
		green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255,
		blue: CGFloat(rgbValue & 0x0000FF) / 255,
		alpha: CGFloat(1)
	)
}
