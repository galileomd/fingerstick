//
//  JsonController.swift
//  SwiftLoginScreen
//
//  Created by Sam Wang on 8/9/14.
//  Copyright (c) 2014 Dipin Krishna. All rights reserved.
//

import UIKit

class JsonController {
		
	func postData(urlString:NSString, postString:NSString) -> NSMutableArray
	{
		//var url:NSURL = NSURL.URLWithString(urlString)
		//var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
		var postData:NSData = postString.dataUsingEncoding(NSASCIIStringEncoding)!
		var postLength:NSString = String( postData.length )
		var jsonData:NSMutableArray = []
		var urlData:NSData = NSData()
		
		/*
		request.HTTPMethod = "POST"
		request.HTTPBody = postData
		request.setValue(postLength, forHTTPHeaderField: "Content-Length")
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		
		
		var error: NSError?
		var response: NSURLResponse?
		var urlData:NSData = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error:&error)!
		*/
		
		var url: NSURL = NSURL(string: urlString)
		var request1: NSURLRequest = NSURLRequest(URL: url)
		var response: AutoreleasingUnsafeMutablePointer <NSURLResponse?>=nil
		var error: AutoreleasingUnsafeMutablePointer <NSErrorPointer?>=nil
		
		if let localUrlData =  NSURLConnection.sendSynchronousRequest(request1, returningResponse: response, error:nil)
		{
			urlData = localUrlData
		}
		
		var err: NSError
		
		NSLog("Post --> %@", postString)
		NSLog("Response code: %ld", response.debugDescription)
		
		var responseData:NSString  = NSString(data:urlData, encoding:NSUTF8StringEncoding)
		
		NSLog("Response ==> %@", responseData);
		
		if let tmpJsonData = NSJSONSerialization.JSONObjectWithData(urlData, options:NSJSONReadingOptions.MutableContainers , error: nil) as? NSMutableArray
		{
			jsonData = tmpJsonData
		}
		
		return jsonData
		
		
		
		//var error: NSError?
		/*
		if (res.debugDescription == "200" && res.debugDescription == "300")
		{
		
		} else if (res.debugDescription == "404")
		{
			var alertView:UIAlertView = UIAlertView()
			alertView.title = "Submit failed!"
			alertView.message = "No URL \(url) found"
			//alertView.delegate = self
			alertView.addButtonWithTitle("OK")
			alertView.show()
		} else
		{
			var alertView:UIAlertView = UIAlertView()
			alertView.title = "Network Failed!"
			alertView.message = "Connection Failed"
			//alertView.delegate = self
			alertView.addButtonWithTitle("OK")
			alertView.show()
		}
		*/
	}
}