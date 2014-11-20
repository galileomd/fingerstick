//
//  JsonController.swift
//  SwiftLoginScreen
//
//  Created by Sam Wang on 8/9/14.
//  Copyright (c) 2014 Dipin Krishna. All rights reserved.
//

import UIKit

class JsonController {
	
	func postData(urlString:String, postString:NSString, handler:ResponseHandler)
	{
		var postData:NSData = postString.dataUsingEncoding(NSASCIIStringEncoding)!
		var jsonData:NSMutableArray = []
		
		if let url: NSURL = NSURL(string: urlString)
		{
			let request: NSURLRequest = NSURLRequest(URL: url)
			let response: AutoreleasingUnsafeMutablePointer <NSURLResponse?>=nil
			var error: AutoreleasingUnsafeMutablePointer <NSErrorPointer?>=nil
			
			let queue = NSOperationQueue.mainQueue()
			
			NSURLConnection.sendAsynchronousRequest(
				request,
				queue: queue,
				completionHandler: {response, data, error in
					if (error == nil)
					{
						self.processData(data, handler: handler)
					} else
					{
						handler.onFailure("Server connection error")
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