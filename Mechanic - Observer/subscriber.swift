//
//  subscriber.swift
//  Mechanic - Observer
//
//  Created by Reza Shirazian on 2016-04-09.
//  Copyright © 2016 Reza Shirazian. All rights reserved.
//

import Foundation

protocol Subscriber: class {
  var properties: [String] {get set}
  func notify(propertyName: String, oldValue: Int, newValue: Int, options: [String:String]?)
}
