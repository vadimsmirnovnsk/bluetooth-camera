import Foundation
import UIKit
import SnapKit

class RedCameraFieldZoom: RedCameraField {

	private let zoomLabel = UILabel()

	var zoom: Double = 0.0 {
		didSet {
			let zoomString = String(format: "%.1f", self.zoom)
			zoomLabel.text = zoomString + "x"
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		zoomLabel.textColor = UIColor.white
		zoomLabel.font = UIFont.systemFont(ofSize: 16.0)
		zoomLabel.textAlignment = .center
		addSubview(zoomLabel)

		// Layout

		zoomLabel.snp.makeConstraints { (make) in
			make.edges.equalTo(self)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}



