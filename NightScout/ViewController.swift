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

	var prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
	var sgvArray: [CGFloat] = []
	var xLabelArray: [String] = []
	var xLabelNsdate: [NSDate] = []
	var direction: String = ""
	var timer:NSTimer = NSTimer()
	var audioPlayer = AVAudioPlayer()
	
	var label = UILabel()
	var lineChart: LineChart?
	
	let currentTitle = "FingerStick"
	struct Settings {
		var url:String = ""
		var pollingInterval:Int = 0
		var lowAlarm = 90
		var highAlarm = 120
	}
	
	var globalSettings = Settings()
	
	@IBOutlet weak var currentSgv: UILabel!
	@IBOutlet weak var timeNotification: UILabel!
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidLoad()
		
		loadSettings()
		updateTimeNotification()
		refreshChartData()
		
		
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
		self.view.backgroundColor = UIColor.blackColor()
		currentSgv.textColor = UIColor.whiteColor()
		timeNotification.textColor = UIColor.whiteColor()
		
		if (sgvArray.count > 0)
		{
			//draw arrow
			
			
			//draw chart
			var views: Dictionary<String, AnyObject> = [:]
			
			label.text = "..."
			label.setTranslatesAutoresizingMaskIntoConstraints(false)
			label.textAlignment = NSTextAlignment.Center
			self.view.addSubview(label)
			views["label"] = label
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[label]-|", options: nil, metrics: nil, views: views))
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-180-[label]", options: nil, metrics: nil, views: views))
			
			var data: Array<CGFloat> = sgvArray
			//var data2: Array<CGFloat> = [1, 3, 5, 13, 17, 20,12,21, 42,41]
			
			sortXaxis()
			var xAxisLabels:[String] = xLabelArray
			
			//if let lineChart = LineChart()
			
			let lineChart = LineChart()
			lineChart.areaUnderLinesVisible = false
			lineChart.labelsXVisible = true
			lineChart.labelsYVisible = true
			lineChart.lowAlarm = globalSettings.lowAlarm
			lineChart.highAlarm = globalSettings.highAlarm
			
			lineChart.addLine(data)
			//lineChart.addLine(data2)
			lineChart.addXAxisLabels(xAxisLabels)
			
			lineChart.setTranslatesAutoresizingMaskIntoConstraints(false)
			lineChart.delegate = self
			self.view.addSubview(lineChart)
			views["chart"] = lineChart
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[chart]-|", options: nil, metrics: nil, views: views))
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[label]-[chart(==200)]", options: nil, metrics: nil, views: views))

			self.title = currentTitle
			
			/*
			var lineChart:PNLineChart = PNLineChart(frame: CGRectMake(10, 150.0, 300, 320.0))
			lineChart.yLabelFormat = "%1.0f"
			lineChart.showLabel = true
			sortXaxis()
			lineChart.xLabels = xLabelArray
			lineChart.showCoordinateAxis = true
			lineChart.delegate = self
			
			// Line Chart Nr.1
			var data01Array: [CGFloat] = sgvArray
			var data01:PNLineChartData = PNLineChartData()
			data01.color = PNWhiteColor
			data01.itemCount = data01Array.count
			data01.inflexionPointStyle = PNLineChartData.PNLineChartPointStyle.PNLineChartPointStyleCycle
			data01.getData = ({(index: Int) -> PNLineChartDataItem in
				var yValue:CGFloat = data01Array[index]
				var item = PNLineChartDataItem()
				item.y = yValue
				return item
			})
			
			
			lineChart.lowAlarm = globalSettings.lowAlarm
			lineChart.highAlarm = globalSettings.highAlarm
			lineChart.chartData = [data01]
			lineChart.strokeChart()
			lineChart.delegate = self
			
			self.view.addSubview(lineChart)
			*/
			
			currentSgv.text = "\( Int(sgvArray.last!) )"
			
			checkAlarms()
		} else
		{
			currentSgv.text = "?"
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
			timeNotification.text = "\( Int(timeDifference) ) minutes ago"
			
			if timeDifference > 7
			{
				timeNotification.backgroundColor = UIColor.redColor()
			}
			else
			{
				timeNotification.backgroundColor = UIColor.clearColor()
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
	
	func userClickedOnLineKeyPoint(point: CGPoint, lineIndex: Int, keyPointIndex: Int)
	{
		println("Click Key on line \(point.x), \(point.y) line index is \(lineIndex) and point index is \(keyPointIndex)")
	}
	
	func userClickedOnLinePoint(point: CGPoint, lineIndex: Int)
	{
		println("Click Key on line \(point.x), \(point.y) line index is \(lineIndex)")
	}
	
	func userClickedOnBarCharIndex(barIndex: Int)
	{
		println("Click  on bar \(barIndex)")
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
			direction = dataDict.objectForKey("direction") as NSString
			
			//println("Date \(date) loaded into global var graphItems")
		}
		
		displayChart()
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
		label.text = "x: \(x)     y: \(yValues)"
	}

}

