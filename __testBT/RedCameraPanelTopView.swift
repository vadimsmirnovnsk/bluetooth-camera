import Foundation
import UIKit
import SnapKit

class RedCameraPanelTopView: UIView {

	override init(frame: CGRect) {
		super.init(frame: frame)

		backgroundColor = UIColor.darkGray

		// Layout
		self.snp.makeConstraints { (make) in
			make.height.equalTo(50.0)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
