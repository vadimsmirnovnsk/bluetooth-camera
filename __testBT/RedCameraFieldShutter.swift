import Foundation
import UIKit
import SnapKit

class RedCameraFieldShutter: RedCameraField {

	private let shutterLabel = UILabel()

	var shutterSpeed: Int = 0 {
		didSet {
			shutterLabel.text = "1/" + "\(self.shutterSpeed)"
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		shutterLabel.textColor = UIColor.white
		shutterLabel.font = UIFont.systemFont(ofSize: 16.0)
		shutterLabel.textAlignment = .center
		addSubview(shutterLabel)

		// Layout

		shutterLabel.snp.makeConstraints { (make) in
			make.edges.equalTo(self)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}


