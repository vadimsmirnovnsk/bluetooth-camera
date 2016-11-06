import Foundation
import UIKit
import SnapKit

class RedCameraFieldFPS: RedCameraField {

	private let fpsLabel = UILabel()

	var fps: Double = 0.0 {
		didSet {
			let fpsString = String(format: "%.2f", self.fps)
			fpsLabel.text = fpsString + "FPS"
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		fpsLabel.textColor = UIColor.white
		fpsLabel.font = UIFont.systemFont(ofSize: 16.0)
		fpsLabel.textAlignment = .center
		addSubview(fpsLabel)

		// Layout

		fpsLabel.snp.makeConstraints { (make) in
			make.edges.equalTo(self)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

