//
//  ViewController.swift
//  NightScout
//
//  Created by Sam Wang on 10/23/14.
//  Copyright (c) 2014 GalileoMD. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, LineChartDelegate, ResponseHandler {

	@IBOutlet weak var currentSgvLabel: UILabel!
	@IBOutlet weak var timeNotificationLabel: UILabel!
	@IBOutlet weak var arrowImage: UIImageView!
	
	let currentTitle = "FingerStick"

	//
	var sgvArray: [CGFloat] = []
	var xLabelArray: [String] = []
	var xLabelNsdate: [NSDate] = []
	var sgvDirectionArrow: String = ""
	
	// misc variables
	var timer:NSTimer = NSTimer()
	var audioPlayer = AVAudioPlayer()
	
	// chart variables
	var chartLabel = UILabel()
	var lineChart: LineChart?
	
	var prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
	struct Settings {
		var url:String = ""
		var pollingInterval:Int = 0
		var lowAlarm = 90
		var highAlarm = 120
	}
	var globalSettings = Settings()
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidLoad()
		
		loadSettings()
		updateTimeNotification()
		refreshChartData()
		setupTimers()

	}
	
	func drawArrow(arrowDirection:String, targetImage: UIImageView)
	{
		println("Arrow Direction: " + sgvDirectionArrow)
		switch sgvDirectionArrow {
		case "Flat":
			self.arrowImage.transform = CGAffineTransformMakeRotation( 0 )
		case "DoubleUp":
			self.arrowImage.transform = CGAffineTransformMakeRotation(-90.0 * CGFloat(M_PI) / 180.0 )
		case "SingleUp":
			self.arrowImage.transform = CGAffineTransformMakeRotation(-90.0 * CGFloat(M_PI) / 180.0 )
		case "FortyFiveUp":
			self.arrowImage.transform = CGAffineTransformMakeRotation(-45.0 * CGFloat(M_PI) / 180.0 )
		case "FortyFiveDown":
			self.arrowImage.transform = CGAffineTransformMakeRotation(45.0 * CGFloat(M_PI) / 180.0 )
		case "SingleDown":
			self.arrowImage.transform = CGAffineTransformMakeRotation(90.0 * CGFloat(M_PI) / 180.0 )
		case "DoubleDown":
			self.arrowImage.transform = CGAffineTransformMakeRotation(90.0 * CGFloat(M_PI) / 180.0 )
		case "NOT COMPUTABLE":
			println("not computable")
			//self.arrowImage.
		case "RATE OUT OF RANGE":
			println("out of range")
			//self.arrowImage.transform = CGAffineTransformMakeRotation(90.0 * CGFloat(M_PI) / 180.0 )
		default:
			self.arrowImage.transform = CGAffineTransformMakeRotation(0)
			
		}
		
	}
	
	func setupTimers()
	{
		NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: Selector("updateTimeNotification"), userInfo: nil, repeats: true)
		
		if globalSettings.pollingInterval > 0
		{
			timer.invalidate()		// otherwise the timers accumulate
			timer = NSTimer.scheduledTimerWithTimeInterval(Double(globalSettings.pollingInterval), target: self, selector: Selector("refreshChartData"), userInfo: nil, repeats: true)
		}
	}
	
	func displayChart()
	{
		println("Displaying chart")
 		// Cosmetics
		self.title = currentTitle
		self.view.backgroundColor = UIColor.blackColor()
		currentSgvLabel.textColor = UIColor.whiteColor()
		timeNotificationLabel.textColor = UIColor.whiteColor()
		
		if (!sgvArray.isEmpty)
		{
			var views: Dictionary<String, AnyObject> = [:]
			
			chartLabel.text = "..."
			chartLabel.textColor = UIColor.whiteColor()
			chartLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
			chartLabel.textAlignment = NSTextAlignment.Center
			self.view.addSubview(chartLabel)
			views["chartLabel"] = chartLabel
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[chartLabel]-|", options: nil, metrics: nil, views: views))
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-140-[chartLabel]", options: nil, metrics: nil, views: views))
			
			sortXaxis()
			var xAxisLabels:[String] = xLabelArray
			
			let lineChart = LineChart()
			lineChart.areaUnderLinesVisible = false
			lineChart.labelsXVisible = true
			lineChart.labelsYVisible = true
			lineChart.lowAlarm = globalSettings.lowAlarm
			lineChart.highAlarm = globalSettings.highAlarm
			
			lineChart.addLine(sgvArray)
			//lineChart.addLine(data2)
			lineChart.addXAxisLabels(xAxisLabels)
			
			lineChart.setTranslatesAutoresizingMaskIntoConstraints(false)
			lineChart.delegate = self
			self.view.addSubview(lineChart)
			views["chart"] = lineChart
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[chart]-|", options: nil, metrics: nil, views: views))
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[chartLabel]-[chart(==200)]", options: nil, metrics: nil, views: views))

			
			currentSgvLabel.text = "\( Int(sgvArray.last!) )"
			
			checkAlarms()
		} else
		{
			currentSgvLabel.text = "?"
		}
		
	}
	
	func sortXaxis()
	{
		let xAxisCount = xLabelNsdate.count
		let dateFormatter = NSDateFormatter()
		let hourFormatter = NSDateFormatter()
		//var calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
		
		dateFormatter.dateFormat = "MM/dd"
		hourFormatter.dateFormat = "h:mm a"
		
		var initialDay = dateFormatter.stringFromDate(xLabelNsdate[0])
		xLabelArray.insert(initialDay, atIndex:0)
		
		for var index=1; index < xAxisCount; index++		// skip array 0 because that's always labeled
		{
			let currentDate = dateFormatter.stringFromDate(xLabelNsdate[index])
			//println(xLabelNsdate[index])
			if currentDate == initialDay
			{
				if index % 3 == 0
				{
					xLabelArray.append(hourFormatter.stringFromDate(xLabelNsdate[index]))
				} else
				{
					xLabelArray.append("")
				}
			} else
			{
				initialDay = currentDate
				xLabelArray.append(dateFormatter.stringFromDate(xLabelNsdate[index]))
			}
			//let dif = calendar.compareDate(dateItem, toDate: initialDay, toUnitGranularity: NSCalendarUnit.CalendarUnitYear)
			
		}
		//println(xLabelArray)
	}
	
	func updateTimeNotification()
	{
		if xLabelNsdate.count > 0
		{
			let timeDifference = xLabelNsdate.last!.timeIntervalSinceNow / 60 * -1
			timeNotificationLabel.text = "\( Int(timeDifference) ) minutes ago"
			
			if timeDifference > 7
			{
				timeNotificationLabel.backgroundColor = UIColor.redColor()
			}
			else
			{
				timeNotificationLabel.backgroundColor = UIColor.clearColor()
			}
		}
		
	}
	
	func checkAlarms()
	{
		println("Alarm checked")
		if sgvArray.last != nil &&
		   (sgvArray.last > CGFloat(globalSettings.highAlarm) ||
			sgvArray.last < CGFloat(globalSettings.lowAlarm))
		{
			println("Alarmed at ", sgvArray.last)
			playAlarm()
		}
	}
	
	func playAlarm()
	{
		var alertSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("./alarm", ofType: "wav")!)
		
		println(alertSound)
		
		// Removed deprecated use of AVAudioSessionDelegate protocol
		AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)
		AVAudioSession.sharedInstance().setActive(true, error: nil)
		
		var error:NSError?
		audioPlayer = AVAudioPlayer(contentsOfURL: alertSound, error: &error)
		audioPlayer.prepareToPlay()
		audioPlayer.play()
	}

	func loadSettings()
	{
		if let url = prefs.stringForKey("nightScoutURL")
		{
			if url.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != ""
			{
				let newurl = "http://" + url.stringByReplacingOccurrencesOfString("http://", withString: "") + "/api/v1/entries.json"
				globalSettings.url = newurl
			}
			else {
				globalSettings.url = "http://cgmtest.herokuapp.com/api/v1/entries.json"
			}
		}
		else
		{
			globalSettings.url = "http://cgmtest.herokuapp.com/api/v1/entries.json"
		}
		
		if let pollingInterval = prefs.integerForKey("pollingInterval") as Int?
		{
			globalSettings.pollingInterval = pollingInterval

		}
		else {
			globalSettings.pollingInterval = 30
		}
		
		if let lowAlarm = prefs.integerForKey("lowAlarm") as Int?
		{
			globalSettings.lowAlarm = lowAlarm
			
		}
		else {
			globalSettings.pollingInterval = 30
		}
		
		if let highAlarm = prefs.integerForKey("highAlarm") as Int?
		{
			globalSettings.highAlarm = highAlarm
			
		}
		else {
			globalSettings.pollingInterval = 30
		}
		
		println("Settings loaded:")
		println(globalSettings.url)
		println(globalSettings.pollingInterval)
		println(globalSettings.lowAlarm)
		println(globalSettings.highAlarm)
	}
	
	func refreshChartData() {		
		JsonController().postData(globalSettings.url, postString: "", handler: self)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func onSuccess(response:NSMutableArray) {
		//reset graph arrays
		sgvArray.removeAll(keepCapacity: true)
		xLabelArray.removeAll(keepCapacity: true)
		xLabelNsdate.removeAll(keepCapacity: true)
		
		println("loading json results: " + String(response.count) )
		
		for dataDict : AnyObject in response {
			
			//sgv
			let sgv = dataDict.objectForKey("sgv") as NSString
			let sgvFLoat = sgv.floatValue
			sgvArray.insert(CGFloat(sgvFLoat),  atIndex: 0)
			
			//date
			let epochDate:NSTimeInterval = dataDict.objectForKey("date") as Double
			let nsDateFromEpoch = NSDate(timeIntervalSince1970: (epochDate / 1000))
			
			xLabelNsdate.insert(nsDateFromEpoch, atIndex: 0)
			
			let dateFormatter = NSDateFormatter()
			dateFormatter.dateFormat = "MM/dd"
			let date = dateFormatter.stringFromDate(nsDateFromEpoch)
			
			// Populated in sortXAxis() for better look
			// xLabelArray.insert(date, atIndex:0)
			
			// dir
			sgvDirectionArrow = dataDict.objectForKey("direction") as NSString
			
			//println("Date \(date) loaded into global var graphItems")
		}
		
		// Do the rendering
		displayChart()
		drawArrow(sgvDirectionArrow, targetImage: arrowImage)
		
	}
	
	func onFailure() {
		let alertView = UIAlertView()
		alertView.title = "Failed!"
		alertView.message = "Something not good happened"
		alertView.addButtonWithTitle("OK")
		alertView.show()
	}
	
	
	/**
	* Line chart delegate method.
	*/
	func didSelectDataPoint(x: CGFloat, yValues: Array<CGFloat>) {
		chartLabel.text = "Glucose value: \(yValues)"
	}

}

