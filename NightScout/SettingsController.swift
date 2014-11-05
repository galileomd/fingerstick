//
//  SettingsController.swift
//  NightScout
//
//  Created by Sam Wang on 10/26/14.
//  Copyright (c) 2014 GalileoMD. All rights reserved.
//

import UIKit

class SettingsController: FormViewController, FormViewControllerDelegate
{
	var prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
	struct Settings {
		var url:String = ""
		var pollingInterval:Int = 0
		var lowAlarm = 0
		var highAlarm = 0
	}
	
	var globalSettings = Settings()
	
	@IBOutlet var formTable: UITableView!
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		if let localUrl = prefs.stringForKey("nightScoutURL")
		{
			globalSettings.url = localUrl
		}
		
		if let localPolling = prefs.integerForKey("pollingInterval") as Int?
		{
			globalSettings.pollingInterval = localPolling
		}
		
		self.loadForm()

	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.delegate = self
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Bordered, target: self, action: "submit:")
	}

	/// MARK: Actions
	
	func submit(_: UIBarButtonItem!) {
		let nightScoutURL = self.form.formValues()["nightScoutURL"]!
		prefs.setObject(nightScoutURL, forKey: "nightScoutURL")
		
		let pollingInterval = self.form.formValues()["pollingInterval"]!
		prefs.setObject(pollingInterval, forKey: "pollingInterval")
		
		prefs.synchronize()

		//  Debugging
		println("Saving")
		println(nightScoutURL)
		println(pollingInterval)
		
		/*let message = self.form.formValues().description
		let alert: UIAlertView = UIAlertView(title: "Form output", message: message, delegate: nil, cancelButtonTitle: "OK")
		alert.show()
		*/
		
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	func loadForm()
	{
		let form = FormDescriptor()
		
		let section1 = FormSectionDescriptor()
		section1.headerTitle = "NightScout Connection"
		var row = FormRowDescriptor(tag: "nightScoutURL", rowType: .URL, title: "URL http://")
		row.value = globalSettings.url
		section1.addRow(row)
		
		row = FormRowDescriptor(tag: "pollingInterval", rowType: .SegmentedControl, title: "Polling Interval (mins)")
		row.options = [300, 600, 3600]
		row.titleFormatter = { value in
			switch( value ) {
			case 300:
				return "5"
			case 600:
				return "10"
			case 3600:
				return "60"
			default:
				return nil
			}
		}
		//row.cellConfiguration = ["titleLabel.font" : UIFont.boldSystemFontOfSize(16.0)] //, "segmentedControl.tintColor" : UIColor.redColor()]
		row.value = globalSettings.pollingInterval
		section1.addRow(row)
		
		
		let section2 = FormSectionDescriptor()
		section2.headerTitle = "Alarms"
		row = FormRowDescriptor(tag: "lowAlarm", rowType: .Phone, title: "Low range")
		row.value = globalSettings.lowAlarm
		section2.addRow(row)
		
		row = FormRowDescriptor(tag: "highAlarm", rowType: .Phone, title: "High range")
		row.value = globalSettings.highAlarm
		section2.addRow(row)
		
		form.sections = [section1, section2]
		
		self.form = form
		
	}
	
	func formViewController(controller: FormViewController, didSelectRowDescriptor rowDescriptor: FormRowDescriptor) {
		if rowDescriptor.tag == "button" {
			self.view.endEditing(true)
		}
	}
	
	func clear()
	{
		let appDomain = NSBundle.mainBundle().bundleIdentifier
		NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)
	}

}