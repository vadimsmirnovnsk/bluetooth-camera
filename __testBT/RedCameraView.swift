import Foundation
import UIKit
import SnapKit

@objc class RedCameraView: UIView {

	private let panelTop = RedCameraPanelTopView(frame: CGRect.zero)
	private let panelBottom = RedCameraPanelBottomView(frame: CGRect.zero)

	override init(frame: CGRect) {
		super.init(frame: frame)

		addSubview(panelTop)
		addSubview(panelBottom)

		// Layout

		panelTop.snp.makeConstraints { (make) in
			make.leading.top.trailing.equalTo(self)
		}

		panelBottom.snp.makeConstraints { (make) in
			make.leading.bottom.trailing.equalTo(self)
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
