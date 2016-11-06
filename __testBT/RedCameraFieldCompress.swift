import Foundation
import UIKit
import SnapKit

class RedCameraFieldCompress: RedCameraField {

	private let aspectLabel = UILabel()

	//	var temperature: Int = 4000 {
	//		didSet {
	//			aspectLabel.text = "\(self.temperature)" + "K"
	//		}
	//	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		aspectLabel.textColor = UIColor.white
		aspectLabel.font = UIFont.systemFont(ofSize: 16.0)
		aspectLabel.textAlignment = .center
		addSubview(aspectLabel)

		aspectLabel.text = "H.264"

		// Layout

		aspectLabel.snp.makeConstraints { (make) in
			make.edges.equalTo(self)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}




