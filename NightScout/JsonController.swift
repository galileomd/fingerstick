//
//  JsonController.swift
//  SwiftLoginScreen
//
//  Created by Sam Wang on 8/9/14.
//  Copyright (c) 2014 Dipin Krishna. All rights reserved.
//

import UIKit

class JsonController {
	
	
	
	func postDataNew(urlString:String, postString:NSString, handler:ResponseHandler)
	{
		var session = NSURLSession.sharedSession()
		if let url = NSURL(string: urlString)
		{
			if let task = session.dataTaskWithURL(url, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
				
					var jsonError:NSError?
					if let jsonData = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &jsonError) as NSMutableArray?
					{
						if (jsonError != nil) {
							handler.onFailure("Error parsing json: \(jsonError)")
						}
						else {
							let responseStr = NSString(data: data, encoding:NSUTF8StringEncoding)
							
							NSLog("Response ==> %@", responseStr!);
							handler.onSuccess(jsonData)
						}
					} else {
						handler.onFailure("Connection Failed")
					}

			}) as NSURLSessionDataTask?
			{
				task.resume()
			} else
			{
				
				handler.onFailure("URL Error")
			}
		}
	}
	
	
	
	func postData(urlString:String, postString:NSString, handler:ResponseHandler)
	{
		var postData:NSData = postString.dataUsingEncoding(NSASCIIStringEncoding)!
		var jsonData:NSMutableArray = []
		
		if let url: NSURL = NSURL(string: urlString)
		{
			let request: NSURLRequest = NSURLRequest(URL: url)
			let response: AutoreleasingUnsafeMutablePointer <NSURLResponse?> = nil
			var error: AutoreleasingUnsafeMutablePointer <NSErrorPointer?> = nil
			
			let queue = NSOperationQueue.currentQueue()
			//let queue = NSOperationQueue.mainQueue()
			
			println("Making NSURL connection")
			NSURLConnection.sendAsynchronousRequest(
				request,
				queue: queue,
				completionHandler: {response, data, error in
					if (error == nil)
					{
						println("Processing data")
						self.processData(data, handler: handler)
					} else
					{
						handler.onFailure("\(error.localizedDescription)")
					}
					
				}
			)
		}
		else
		{
			handler.onFailure("URL entered incorrectly")
		}
	}
	
	
	
	func processData(response:NSData, handler:ResponseHandler)
	{
		let responseStr = NSString(data:response, encoding:NSUTF8StringEncoding)
		
		NSLog("Response ==> %@", responseStr!);
		if let jsonData = NSJSONSerialization.JSONObjectWithData(response, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSMutableArray {
			handler.onSuccess(jsonData)
		}
		else
		{
			handler.onFailure("Error")
			// more to do here
		}
	}
}