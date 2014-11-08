//
//  ViewController.swift
//  NightScout
//
//  Created by Sam Wang on 10/23/14.
//  Copyright (c) 2014 GalileoMD. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, PNChartDelegate {

	var prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
	var sgvArray: [CGFloat] = []
	var xLabelArray: [String] = []
	var xLabelNsdate: [NSDate] = []
	var direction: String = ""
	var timer:NSTimer = NSTimer()
	var audioPlayer = AVAudioPlayer()
	
	let currentTitle = "FingerStick"
	struct Settings {
		var url:String = ""
		var pollingInterval:Int = 0
	}
	
	var globalSettings = Settings()
	
	@IBOutlet weak var currentSgv: UILabel!
	@IBOutlet weak var timeNotification: UILabel!
	
	@IBAction func toggleSideMenu(sender: AnyObject) {
		self.performSegueWithIdentifier("goto_settings", sender: self)
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidLoad()
		
		loadSettings()
		displayChart()
		updateTimeNotification()
		playAlarm()
		
		NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: Selector("updateTimeNotification"), userInfo: nil, repeats: true)
		
		if globalSettings.pollingInterval > 0
		{
			timer.invalidate()		// otherwise the timers accumulate
			timer = NSTimer.scheduledTimerWithTimeInterval(Double(globalSettings.pollingInterval), target: self, selector: Selector("displayChart"), userInfo: nil, repeats: true)
		}
	}
	
	func displayChart()
	{
		json(globalSettings.url)

		if (sgvArray.count != 0)
		{
			var lineChart:PNLineChart = PNLineChart(frame: CGRectMake(0, 170.0, 310, 300.0))
			lineChart.yLabelFormat = "%1.1f"
			lineChart.showLabel = true
			lineChart.backgroundColor = UIColor.clearColor()
			sortXaxis()
			lineChart.xLabels = xLabelArray
			lineChart.showCoordinateAxis = true
			lineChart.delegate = self
			
			// Line Chart Nr.1
			var data01Array: [CGFloat] = sgvArray
			var data01:PNLineChartData = PNLineChartData()
			data01.color = PNGreenColor
			data01.itemCount = data01Array.count
			data01.inflexionPointStyle = PNLineChartData.PNLineChartPointStyle.PNLineChartPointStyleCycle
			data01.getData = ({(index: Int) -> PNLineChartDataItem in
				var yValue:CGFloat = data01Array[index]
				var item = PNLineChartDataItem()
				item.y = yValue
				return item
			})
			
			lineChart.chartData = [data01]
			lineChart.strokeChart()
			lineChart.delegate = self
			
			self.view.addSubview(lineChart)
			self.title = currentTitle
			
			currentSgv.text = "\( Int(sgvArray[sgvArray.count-1]) )"
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
		hourFormatter.dateFormat = "h:mma"
		
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
		println("Settings loaded:")
		println(globalSettings.url)
		println(globalSettings.pollingInterval)
	}
	
	func json(urlLink: String )
	{
		var post = ""
		let json = JsonController()
		let jsonResults = json.postData(urlLink, postString: post)
		
		//reset graph arrays
		sgvArray.removeAll(keepCapacity: true)
		xLabelArray.removeAll(keepCapacity: true)
		xLabelNsdate.removeAll(keepCapacity: true)
		
		println("loading json results: " + String(jsonResults.count) )
		
		for dataDict : AnyObject in jsonResults {
			
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
		
		//println(sgvArray)
		//println(xLabelNsdate)
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
	
}

