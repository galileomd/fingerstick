//
//  AppDelegate.swift
//  NightScout
//
//  Created by Sam Wang on 10/23/14.
//  Copyright (c) 2014 GalileoMD. All rights reserved.
//

import UIKit
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ResponseHandler {

	var window: UIWindow?
	let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()

	
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		
		Crashlytics.startWithAPIKey("983356c44b1dc5cb4a330aa1c09f5e23d79f51b3")
		
		//registering for sending user various kinds of notifications - iOS 8 only
		//application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Sound | UIUserNotificationType.Alert | UIUserNotificationType.Badge, categories: nil))
		
		//application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
		application.setMinimumBackgroundFetchInterval(NSTimeInterval(3600))
		
		return true
	}

	
	func application(application: UIApplication,	performFetchWithCompletionHandler completionHandler: ((UIBackgroundFetchResult) -> Void)!)
	{
		let url = "http://" + prefs.stringForKey("nightScoutURL")!  + "/api/v1/entries.json"
		
		println("Background Refreshing")
		alertUser("Bkg refresh: " + prefs.stringForKey("nightScoutURL")!)
		JsonController().postData(url, postString: "", handler: self)
		
		/////////////////// HOW DO YOU USE THIS //////////
		completionHandler(.NewData)
	}
	
	
	
	func onSuccess(response:NSMutableArray)
	{
		println("Background JSON returned success")
		var latestSgv = NSString()
		var latestEpochDate = NSTimeInterval()
		let lowAlarm = Float(prefs.integerForKey("lowAlarm"))
		let highAlarm =  Float(prefs.integerForKey("highAlarm"))

		for dataDict : AnyObject in response
		{
			let epochDate:NSTimeInterval = dataDict.objectForKey("date") as Double
			
			if latestEpochDate < epochDate
			{
				latestSgv = dataDict.objectForKey("sgv") as NSString
				latestEpochDate = epochDate
			}
		}
		
		let latestSgvFLoat = latestSgv.floatValue

		// add check to make sure data is less than 10 mins old
		if (latestSgvFLoat >= highAlarm) || (latestSgvFLoat <= lowAlarm)
		{
			alertUser("Alarm threshold: \(latestSgv) at \(latestEpochDate)")
		} else
		{
			alertUser("Within parameters at \(latestSgv) at \(latestEpochDate)")
		}

	}
	
	func onFailure(error: String) {
		
		println("Controller returned failure: " + error)
	}
	
	func alertUser(alert:String)
	{
		var localNotification:UILocalNotification = UILocalNotification()
		localNotification.alertAction = "Fingerstick Notification"
		localNotification.alertBody = alert
		localNotification.fireDate = NSDate()
		UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
		
	}
	
	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

    