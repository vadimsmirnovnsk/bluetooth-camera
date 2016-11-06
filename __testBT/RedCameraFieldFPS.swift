import Foundation
import UIKit
import SnapKit

class RedCameraFieldFPSView: RedCameraField {

	private let fpsLabel = UILabel()

	var fps: Double = 0.0 {
		didSet {
			
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		// Layout
		self.snp.makeConstraints { (make) in
			make.height.equalTo(50.0)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

