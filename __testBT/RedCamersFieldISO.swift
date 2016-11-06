import Foundation
import UIKit
import SnapKit

class RedCameraFieldISO: RedCameraField {

	private let isoLabel = UILabel()

	var iso: Int = 0 {
		didSet {
			isoLabel.text = "ISO" + "\(self.iso)"
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		isoLabel.textColor = UIColor.white
		isoLabel.font = UIFont.systemFont(ofSize: 16.0)
		isoLabel.textAlignment = .center
		addSubview(isoLabel)

		// Layout

		isoLabel.snp.makeConstraints { (make) in
			make.edges.equalTo(self)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

