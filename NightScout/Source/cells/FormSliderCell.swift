//
//  FormSliderCell.swift
//  test
//
//  Created by Sam Wang on 11/22/14.
//  Copyright (c) 2014 GalileoMD. All rights reserved.
//

import UIKit

class FormSliderCell: FormBaseCell
{
	/// MARK: Cell views
	
	private let slider = UISlider(frame: CGRect(x: 0, y: 0, width: 150, height: 23))
	private let titleLabel = UILabel()
	private let sliderLabel = UILabel()
	
	
	
	/// MARK: Properties
	
	private var customConstraints: [AnyObject]!
	
	
	
	/// MARK: FormBaseCell
	
	override func configure() {
		super.configure()
		
		slider.center = CGPoint(x: contentView.frame.width * 0.6, y: contentView.frame.height/2)
		
		titleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
		sliderLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
		
		slider.minimumValue = 80
		slider.maximumValue = 150
		
		contentView.addSubview(titleLabel)
		contentView.addSubview(slider)
		contentView.addSubview(sliderLabel)
		
		contentView.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
		contentView.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .Height, relatedBy: .Equal, toItem: contentView, attribute: .Height, multiplier: 1.0, constant: 0.0))
		
		
		contentView.addConstraint(NSLayoutConstraint(item: sliderLabel, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
		contentView.addConstraint(NSLayoutConstraint(item: sliderLabel, attribute: .Height, relatedBy: .Equal, toItem: contentView, attribute: .Height, multiplier: 1.0, constant: 0.0))
		
		contentView.addConstraint(NSLayoutConstraint(item: slider, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
		contentView.addConstraint(NSLayoutConstraint(item: slider, attribute: .Height, relatedBy: .Equal, toItem: contentView, attribute: .Height, multiplier: 1.0, constant: 0.0))
		
		slider.addTarget(self, action: "valueChanged:", forControlEvents: .ValueChanged)
	}
	
	
	override func update() {
		super.update()
		
		titleLabel.text = rowDescriptor.title
		
		slider.minimumValue = rowDescriptor.options[0] as Float
		slider.maximumValue = rowDescriptor.options[1] as Float
		
		if let rowValue = rowDescriptor.value
		{
			slider.value = rowValue as Float
			sliderLabel.text = NSString(format: "%.0f", slider.value)
		}
	}
	
	
	override func defaultVisualConstraints() -> [String] {
		return ["H:|-16-[titleLabel]-16-[sliderLabel]-16-|"]
		
	}
	
	override func constraintsViews() -> [String : UIView] {
		return ["titleLabel" : titleLabel, "slider" : slider, "sliderLabel" : sliderLabel]
	}
	
	/// MARK: Actions
	
	func valueChanged(sender: UISlider) {
		
		sliderLabel.text = NSString(format: "%.0f", sender.value)
		rowDescriptor.value = Int(sender.value)
	}
	
}