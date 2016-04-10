//
//  zipcode.swift
//  Mechanic - Observer
//
//  Created by Reza Shirazian on 2016-04-09.
//  Copyright © 2016 Reza Shirazian. All rights reserved.
//

import Foundation

class Zipcode: Hashable, Equatable{
  let value: String
  var baseRate: Double
  var adjustment: Double
  var rate: Double{
    return baseRate + (baseRate * adjustment)
  }
  
  init (value: String, baseRate: Double){
    self.value = value
    self.baseRate = baseRate
    self.adjustment = 0.0
  }
  
  var hashValue: Int{
    return value.hashValue
  }
  
}

func == (lhs: Zipcode, rhs: Zipcode) -> Bool {
  return lhs.value == rhs.value
}