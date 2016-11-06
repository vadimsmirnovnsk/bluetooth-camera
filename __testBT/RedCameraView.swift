import Foundation
import UIKit
import SnapKit

@objc class RedCameraView: UIView {

	let panelTop = RedCameraPanelTopView(frame: CGRect.zero)
	let panelBottom = RedCameraPanelBottomView(frame: CGRect.zero)

	private let focusLabel = UILabel()
	private let filenameLabel = UILabel()
	private let timeLabel = UILabel()

	override init(frame: CGRect) {
		super.init(frame: frame)

		addSubview(panelTop)
		addSubview(panelBottom)

		focusLabel.textColor = UIColor.white
		focusLabel.font = UIFont.systemFont(ofSize: 12.0)
		focusLabel.textAlignment = .center
		focusLabel.text = "AF"
		addSubview(focusLabel)

		filenameLabel.textColor = UIColor.white
		filenameLabel.font = UIFont.systemFont(ofSize: 14.0)
		filenameLabel.textAlignment = .center
		filenameLabel.text = "A01_FILENAME.MOV"
		addSubview(filenameLabel)

		timeLabel.textColor = UIColor.white
		timeLabel.font = UIFont.systemFont(ofSize: 14.0)
		timeLabel.textAlignment = .center
		timeLabel.text = "00:00:10:15"
		addSubview(timeLabel)


		// Layout
		panelTop.snp.makeConstraints { (make) in
			make.leading.top.trailing.equalTo(self)
		}

		focusLabel.snp.makeConstraints { (make) in
			make.top.equalTo(panelTop.snp.bottom).offset(4.0)
			make.centerX.equalTo(self)
		}

		filenameLabel.snp.makeConstraints { (make) in
			make.leading.equalTo(self).offset(8.0)
			make.bottom.equalTo(panelBottom.snp.top).offset(-4.0)
		}

		timeLabel.snp.makeConstraints { (make) in
			make.trailing.equalTo(self).offset(-8.0)
			make.bottom.equalTo(panelBottom.snp.top).offset(-4.0)
		}

		panelBottom.snp.makeConstraints { (make) in
			make.leading.bottom.trailing.equalTo(self)
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
