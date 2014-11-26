//
//  ViewController.swift
//  NightScout
//
//  Created by Sam Wang on 10/23/14, co-authored with Sam Burba.  
//  Copyright (c) 2014 GalileoMD. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, LineChartDelegate, ResponseHandler {

	@IBOutlet weak var currentSgvLabel: UILabel!
	@IBOutlet weak var timeNotificationLabel: UILabel!
	@IBOutlet weak var arrowImage: UIImageView!
	
	// chart variables
	let currentTitle = "FingerStick"
	var chartVisible = false
	var chartLabel = UILabel()
	let lineChart = LineChart()
	var latestXLabelDate = NSDate()   // need to make this global so timer can access it
	
	var audioPlayer = AVAudioPlayer()
	var prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()

	// Global config
	struct Settings {
		var url:String = "http://cgmtest.herokuapp.com/api/v1/entries.json"
		var pollingInterval:Int = 10
		var lowAlarm = 90
		var highAlarm = 200
	}
	var globalSettings = Settings()
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidLoad()
		
		loadSettings()
		refreshChartData()
		setupTimers()
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
		}
		
		if let pollingInterval = prefs.integerForKey("pollingInterval") as Int?
		{	globalSettings.pollingInterval = pollingInterval	}
		
		if let lowAlarm = prefs.integerForKey("lowAlarm") as Int?
		{	if lowAlarm != 0 {	globalSettings.lowAlarm = lowAlarm	}
		}
		
		if let highAlarm = prefs.integerForKey("highAlarm") as Int?
		{	if highAlarm != 0 {	globalSettings.highAlarm = highAlarm	}
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

	func displayChart(xLabelNsdate:[NSDate], sgvArray:[CGFloat])
	{
		println("Displaying chart")
 		// Cosmetics
		self.title = currentTitle
		self.navigationController?.navigationBar.barTintColor = UIColorFromHex(0xba5e90)
		self.navigationController?.navigationBar.translucent = true
		self.view.backgroundColor = UIColor.blackColor()
		currentSgvLabel.textColor = UIColor.whiteColor()
		timeNotificationLabel.textColor = UIColor.whiteColor()
		
		if (!sgvArray.isEmpty)
		{
			var views: Dictionary<String, AnyObject> = [:]
			
			var xAxisLabels:[String] = sortXaxis(xLabelNsdate)
			lineChart.clearLines()
			
			lineChart.lowAlarm = globalSettings.lowAlarm
			lineChart.highAlarm = globalSettings.highAlarm
			lineChart.addLine(sgvArray)
			lineChart.addXAxisLabels(xAxisLabels)
			
			if (!chartVisible) {
				chartLabel.text = "..."
				chartLabel.textColor = UIColor.whiteColor()
				chartLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
				chartLabel.textAlignment = NSTextAlignment.Center
				
				self.view.clearsContextBeforeDrawing = true
				self.view.addSubview(chartLabel)
				views["chartLabel"] = chartLabel
				view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[chartLabel]-|", options: nil, metrics: nil, views: views))
				view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-140-[chartLabel]", options: nil, metrics: nil, views: views))
			
				lineChart.areaUnderLinesVisible = false
				lineChart.labelsXVisible = true
				lineChart.labelsYVisible = true
				
				lineChart.setTranslatesAutoresizingMaskIntoConstraints(false)
				lineChart.delegate = self
			
				self.view.addSubview(lineChart)
			
				views["chart"] = lineChart
				view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[chart]-|", options: nil, metrics: nil, views: views))
				view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[chartLabel]-[chart(==250)]", options: nil, metrics: nil, views: views))
				chartVisible = true
			}
			currentSgvLabel.text = "\( Int(sgvArray.last!) )"
		}
		else
		{
			currentSgvLabel.text = "?"
		}
	}
	
	func sortXaxis(xLabelNsdate:[NSDate]) -> [String]
	{
		let xAxisCount = xLabelNsdate.count
		let dateFormatter = NSDateFormatter()
		let hourFormatter = NSDateFormatter()
		var xLabelArray:[String] = []
		
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
				// should drop more labels when quantity increases.  draw every 3rd one for now.
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
		return xLabelArray
	}
	
	func updateTimeNotification()
	{
		println("Time Label updated")
		let timeDifference = latestXLabelDate.timeIntervalSinceNow / 60 * -1
		timeNotificationLabel.text = "\( Int(timeDifference) ) minutes ago"
		
		//The CGM updates at 5 minute intervals - highlight red if we missed one cycle
		if timeDifference > 6
		{
			timeNotificationLabel.backgroundColor = UIColor.redColor()
		}
		else
		{
			timeNotificationLabel.backgroundColor = UIColor.clearColor()
		}
	}
	
	func checkAlarms(latestSgvValue:CGFloat)
	{
		println("Alarm checked")
		if latestSgvValue > CGFloat(globalSettings.highAlarm) || latestSgvValue < CGFloat(globalSettings.lowAlarm)
		{
			println("Alarmed at ", latestSgvValue)
			playAlarm()
		}
	}
	
	func drawArrow(sgvDirectionArrow:String, targetImage: UIImageView)
	{
		println("Arrow Direction: " + sgvDirectionArrow)
		switch sgvDirectionArrow {
		case "Flat":
			self.arrowImage.image = UIImage(named: "arrow")
			self.arrowImage.transform = CGAffineTransformMakeRotation( 0 )
		case "DoubleUp":
			self.arrowImage.image = UIImage(named: "doublearrow")
			self.arrowImage.transform = CGAffineTransformMakeRotation(-90.0 * CGFloat(M_PI) / 180.0 )
		case "SingleUp":
			self.arrowImage.image = UIImage(named: "arrow")
			self.arrowImage.transform = CGAffineTransformMakeRotation(-90.0 * CGFloat(M_PI) / 180.0 )
		case "FortyFiveUp":
			self.arrowImage.image = UIImage(named: "arrow")
			self.arrowImage.transform = CGAffineTransformMakeRotation(-45.0 * CGFloat(M_PI) / 180.0 )
		case "FortyFiveDown":
			self.arrowImage.image = UIImage(named: "arrow")
			self.arrowImage.transform = CGAffineTransformMakeRotation(45.0 * CGFloat(M_PI) / 180.0 )
		case "SingleDown":
			self.arrowImage.image = UIImage(named: "arrow")
			self.arrowImage.transform = CGAffineTransformMakeRotation(90.0 * CGFloat(M_PI) / 180.0 )
		case "DoubleDown":
			self.arrowImage.image = UIImage(named: "doublearrow")
			self.arrowImage.transform = CGAffineTransformMakeRotation(90.0 * CGFloat(M_PI) / 180.0 )
		case "NOT COMPUTABLE":
			self.arrowImage.image = UIImage(named: "notcomputable")
		case "RATE OUT OF RANGE":
			self.arrowImage.image = UIImage(named: "rateoutofrange")
		default:
			self.arrowImage.image = UIImage(named: "arrow")
			self.arrowImage.transform = CGAffineTransformMakeRotation(0)
		}
	}

 
	func setupTimers()
	{
		var timer:NSTimer = NSTimer()
		
		NSTimer.scheduledTimerWithTimeInterval(50, target: self, selector: Selector("updateTimeNotification"), userInfo: nil, repeats: true)
		
		if globalSettings.pollingInterval > 0
		{
			timer.invalidate()		// otherwise the timers accumulate
			timer = NSTimer.scheduledTimerWithTimeInterval(Double(globalSettings.pollingInterval), target: self, selector: Selector("refreshChartData"), userInfo: nil, repeats: true)
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
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func onSuccess(response:NSMutableArray) {
		
		var sgvArray: [CGFloat] = []
		var xLabelNsdate: [NSDate] = []
		var sgvDirectionArrow: String = ""
		var latestEpochDate = NSTimeInterval()
		
		//reset graph arrays
		sgvArray.removeAll(keepCapacity: true)
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
			
			// arrow direction - get latest one
			if latestEpochDate < epochDate
			{
				sgvDirectionArrow = dataDict.objectForKey("direction") as NSString
				latestEpochDate = epochDate
			}
			
			//println("Date \(date) loaded into global var graphItems")
		}
		
		// Do the rendering
		displayChart(xLabelNsdate, sgvArray: sgvArray)
		drawArrow(sgvDirectionArrow, targetImage: arrowImage)
		checkAlarms(sgvArray.last!)
		
		latestXLabelDate = xLabelNsdate.last!		// needed to make this global so the 1minute timer can access
		updateTimeNotification()
	}
	
	func onFailure(error:String) {
		let alertView = UIAlertView()
		alertView.title = "Error!"
		alertView.message = error
		alertView.addButtonWithTitle("OK")
		alertView.show()
	}
	
	
	/**
	* Convert hex color to UIColor
	*/
	func UIColorFromHex(hex: Int) -> UIColor {
		var red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
		var green = CGFloat((hex & 0xFF00) >> 8) / 255.0
		var blue = CGFloat((hex & 0xFF)) / 255.0
		return UIColor(red: red, green: green, blue: blue, alpha: 1)
	}
	
	/**
	* Line chart delegate method.
	*/
	func didSelectDataPoint(x: CGFloat, yValues: Array<CGFloat>) {
		chartLabel.text = "Glucose value: \(yValues)"
	}
	
}

 