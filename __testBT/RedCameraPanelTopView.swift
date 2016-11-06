import Foundation
import UIKit
import SnapKit

class RedCameraPanelTopView: UIView {

	var temperature: Int = 5400 {
		didSet {
			self.temperatureField.temperature = self.temperature
		}
	}

	var zoom: Double = 1.0 {
		didSet {
			self.zoomField.zoom = self.zoom
		}
	}

	let fpsField = RedCameraFieldFPS(frame: CGRect.zero)
	let isoField = RedCameraFieldISO(frame: CGRect.zero)
	let shutterField = RedCameraFieldShutter(frame: CGRect.zero)
	let apertureField = RedCameraFieldAperture(frame: CGRect.zero)
	let temperatureField = RedCameraFieldTemperature(frame: CGRect.zero)
	let aspectField = RedCameraFieldAspect(frame: CGRect.zero)
	let compressField = RedCameraFieldCompress(frame: CGRect.zero)
	let zoomField = RedCameraFieldZoom(frame: CGRect.zero)

	private var allFields: [RedCameraField]!

	override init(frame: CGRect) {
		super.init(frame: frame)

		backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)

		allFields = [
			fpsField,
			isoField,
			apertureField,
			shutterField,
			temperatureField,
			aspectField,
			compressField,
			zoomField
		]

		fpsField.fps = 30.0
		isoField.iso = 800
		apertureField.aperture = 2.4
		shutterField.shutterSpeed = 30
		temperatureField.temperature = 5400
		zoomField.zoom = 1.0

		// Layout
		for (index, field) in allFields.enumerated() {
			addSubview(field)

			if index == 0 {
				field.snp.makeConstraints({ (make) in
					make.leading.equalTo(self)
				})
			}
			else {
				field.snp.makeConstraints({ (make) in
					make.leading.equalTo(allFields[index-1].snp.trailing)
					make.width.equalTo(allFields[index-1])
				})
			}

			field.snp.makeConstraints({ (make) in
				make.top.greaterThanOrEqualTo(self)
				make.bottom.lessThanOrEqualTo(self)
				make.centerY.equalTo(self)
			})

			if index == allFields.count - 1 {
				field.snp.makeConstraints({ (make) in
					make.trailing.equalTo(self)
				})
			}
		}

		// Layout
		self.snp.makeConstraints { (make) in
			make.height.equalTo(44.0)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
