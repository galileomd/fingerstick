//
//  ResponseHandler.swift
//  NightScout
//
//  Created by Sam Wang on 11/8/14.
//  Copyright (c) 2014 GalileoMD. All rights reserved.
//

import Foundation

protocol ResponseHandler
{
	func onSuccess(response:NSMutableArray)
	func onFailure()
}