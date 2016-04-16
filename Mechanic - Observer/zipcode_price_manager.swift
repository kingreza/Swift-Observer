//
//  zipcode_price_manager.swift
//  Mechanic - Observer
//
//  Created by Reza Shirazian on 2016-04-09.
//  Copyright © 2016 Reza Shirazian. All rights reserved.
//

import Foundation

class ZipcodePriceManager: Subscriber {
  var properties: [String] = ["Status"]
  var zipcodes: Set<Zipcode>
  var supply: [Zipcode: Int] = [:]
  init(zipcodes: Set<Zipcode>, supply: [Zipcode: Int]) {
    self.zipcodes = zipcodes
    self.supply = supply
  }

  func notify(propertyName: String, oldValue: Int, newValue: Int, options: [String:String]?) {
    if properties.contains(propertyName) {
      print("\(propertyName) is changed from \(Status(rawValue: oldValue)!)"
          + " to \(Status(rawValue: newValue)!)")
      if propertyName == "Status"{
        if let options = options {
          let zipcode = zipcodes.filter({$0.value == options["Zipcode"]}).first
          if let zipcode = zipcode {
            if Status(rawValue: newValue) == Status.Idle
                && Status(rawValue: oldValue) != Status.Idle {
              supply[zipcode]! += 1
            } else if Status(rawValue: newValue) != Status.Idle
                && Status(rawValue: oldValue) == Status.Idle {
              supply[zipcode]! -= 1
            }
            updateRates()
            print("**********************")
          }
        }
      }
    }
  }
  func updateRates() {
    supply.forEach({(zipcode: Zipcode, supply: Int) in
      if supply <= 1 {
        zipcode.adjustment = 0.50
        print("Very High Demand! Adjusting price for \(zipcode.value):"
            + " rate is now \(zipcode.rate) because supply is \(supply)")
      } else if supply <= 3 {
        zipcode.adjustment = 0.25
        print("High Demand! Adjusting price for \(zipcode.value): "
            + " rate is now \(zipcode.rate) because supply is \(supply)")
      } else {
        zipcode.adjustment = 0.0
        print("Normal Demand. Adjusting price for \(zipcode.value): "
            + " rate is now \(zipcode.rate) because supply is \(supply)")
      }
    })
  }
}
