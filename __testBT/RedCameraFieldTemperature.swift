import Foundation
import UIKit
import SnapKit

class RedCameraFieldTemperature: RedCameraField {

	private let temperatureLabel = UILabel()

	var temperature: Int = 4000 {
		didSet {
			temperatureLabel.text = "\(self.temperature)" + "K"
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		temperatureLabel.textColor = UIColor.white
		temperatureLabel.font = UIFont.systemFont(ofSize: 16.0)
		temperatureLabel.textAlignment = .center
		addSubview(temperatureLabel)

		// Layout

		temperatureLabel.snp.makeConstraints { (make) in
			make.edges.equalTo(self)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}



