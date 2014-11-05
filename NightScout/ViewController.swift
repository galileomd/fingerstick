//
//  ViewController.swift
//  NightScout
//
//  Created by Sam Wang on 10/23/14.
//  Copyright (c) 2014 GalileoMD. All rights reserved.
//

import UIKit

class ViewController: UIViewController, PNChartDelegate {

	var prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
	var sgvArray: [CGFloat] = []
	var xLabelArray: [String] = []
	var direction: String = ""
	var timer:NSTimer = NSTimer()
	let currentTitle = "Night Scout"
	struct Settings {
		var url:String = ""
		var pollingInterval:Int = 0
	}
	
	var globalSettings = Settings()
	
	@IBOutlet weak var currentSgv: UILabel!
	
	@IBAction func toggleSideMenu(sender: AnyObject) {
		self.performSegueWithIdentifier("goto_settings", sender: self)
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidLoad()
		
		loadSettings()
		displayChart()
		
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
			var lineChart:PNLineChart = PNLineChart(frame: CGRectMake(0, 100.0, 300, 300.0))
			lineChart.yLabelFormat = "%1.1f"
			lineChart.showLabel = true
			lineChart.backgroundColor = UIColor.clearColor()
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
			
			currentSgv.text = "\(sgvArray[sgvArray.count-1])"
		} else
		{
			currentSgv.text = "?"
		}
		
	}
	
	func loadSettings()
	{		
		if let url = prefs.stringForKey("nightScoutURL")
		{
			globalSettings.url = url
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
		sgvArray.removeAll(keepCapacity: true)
		xLabelArray.removeAll(keepCapacity: true)
		println("loading json results: " + String(sgvArray.count) )
		
		for dataDict : AnyObject in jsonResults {
			
			//sgv			
			let sgv = dataDict.objectForKey("sgv") as NSString
			let sgvFLoat = sgv.floatValue
			sgvArray.insert(CGFloat(sgvFLoat),  atIndex: 0)
			
			//date
			let epochDate = dataDict.objectForKey("date") as Int
			let nsDateFromEpoch = NSDate(timeIntervalSince1970: NSTimeInterval(epochDate))
			
			let dateFormatter = NSDateFormatter()
			dateFormatter.dateFormat = "MM/dd"
			let date = dateFormatter.stringFromDate(nsDateFromEpoch)
			
			xLabelArray.insert(date, atIndex:0)
			
			// dir
			direction = dataDict.objectForKey("direction") as NSString
			
			//println("Date \(date) loaded into global var graphItems")
		}
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

