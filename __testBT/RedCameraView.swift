import Foundation
import UIKit
import SnapKit

@objc class RedCameraView: UIView {

	let panelTop = RedCameraPanelTopView(frame: CGRect.zero)
	let panelBottom = RedCameraPanelBottomView(frame: CGRect.zero)

	private let focusLabel = UILabel()

	override init(frame: CGRect) {
		super.init(frame: frame)

		addSubview(panelTop)
		addSubview(panelBottom)

		focusLabel.textColor = UIColor.white
		focusLabel.font = UIFont.systemFont(ofSize: 12.0)
		focusLabel.textAlignment = .center
		focusLabel.text = "AF"
		addSubview(focusLabel)

		// Layout
		panelTop.snp.makeConstraints { (make) in
			make.leading.top.trailing.equalTo(self)
		}

		focusLabel.snp.makeConstraints { (make) in
			make.top.equalTo(panelTop.snp.bottom).offset(4.0)
			make.centerX.equalTo(self)
		}

		panelBottom.snp.makeConstraints { (make) in
			make.leading.bottom.trailing.equalTo(self)
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
