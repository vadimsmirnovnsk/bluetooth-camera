import Foundation
import UIKit
import SnapKit

class RedCameraFieldAperture: RedCameraField {

	private let apertureLabel = UILabel()

	var aperture: Double = 0.0 {
		didSet {
			let apertureString = String(format: "%.1f", self.aperture)
			apertureLabel.text = "f/" + apertureString
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		apertureLabel.textColor = UIColor.white
		apertureLabel.font = UIFont.systemFont(ofSize: 16.0)
		apertureLabel.textAlignment = .center
		addSubview(apertureLabel)

		// Layout

		apertureLabel.snp.makeConstraints { (make) in
			make.edges.equalTo(self)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}


