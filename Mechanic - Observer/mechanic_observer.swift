//
//  mechanic_observer.swift
//  Mechanic - Observer
//
//  Created by Reza Shirazian on 2016-04-08.
//  Copyright © 2016 Reza Shirazian. All rights reserved.
//

import Foundation

class MechanicObserver: Observer{
  
  var subscribers: [Subscriber] = []
  
  func propertyChanged(propertyName: String, oldValue: Int, newValue: Int, options:[String:String]?){
    print("Change in property detected, notifying subscribers")
    let matchingSubscribers = subscribers.filter({$0.properties.contains(propertyName)})
    matchingSubscribers.forEach({$0.notify(propertyName, oldValue: oldValue, newValue: newValue, options: options)})
  }
  
  func subscribe(subscriber: Subscriber){
    subscribers.append(subscriber)
  }
  
  func unsubscribe(subscriber: Subscriber) {
    subscribers = subscribers.filter({$0 !== subscriber})
  }
}
