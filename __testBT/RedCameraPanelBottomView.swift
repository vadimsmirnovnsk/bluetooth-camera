import Foundation
import UIKit
import SnapKit

class RedCameraPanelBottomView: UIView {

	let recordIndicatorDiameter: CGFloat = 20.0
	let recordIndicator = UIView()
	let powerLabel = UILabel()
	let timeLabel = UILabel()

	override init(frame: CGRect) {
		super.init(frame: frame)

		backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)

		recordIndicator.backgroundColor = UIColor.gray
		recordIndicator.layer.cornerRadius = recordIndicatorDiameter / 2.0
		addSubview(recordIndicator)

		powerLabel.textColor = UIColor.green
		powerLabel.font = UIFont.systemFont(ofSize: 16.0)
		powerLabel.textAlignment = .right
		powerLabel.text = "100.0%"
		addSubview(powerLabel)

		// Layout

		powerLabel.snp.makeConstraints { (make) in
			make.trailing.equalTo(self).offset(-4.0)
			make.centerY.equalTo(self)
		}

		recordIndicator.snp.makeConstraints { (make) in
			make.leading.equalTo(self).offset(8.0)
			make.centerY.equalTo(self)
			make.size.equalTo(CGSize.init(width: recordIndicatorDiameter, height: recordIndicatorDiameter))
		}

		self.snp.makeConstraints { (make) in
			make.height.equalTo(44.0)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public func record(record: Bool) {
		recordIndicator.backgroundColor = record ? UIColor.red : UIColor.gray
	}

}

