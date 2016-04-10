//
//  mechanic.swift
//  Mechanic - Observer
//
//  Created by Reza Shirazian on 2016-04-08.
//  Copyright © 2016 Reza Shirazian. All rights reserved.
//

import Foundation

class Mechanic{
  
  var observer: Observer?
  
  let name: String
  var zipcode: Zipcode
  
  var status: Status = .Idle{
    didSet{
      observer?.propertyChanged("Status", oldValue: oldValue.rawValue, newValue: status.rawValue, options: ["Zipcode": zipcode.value])
    }
  }
  
  init(name: String, location: Zipcode){
    self.name = name
    self.zipcode = location
  }
}