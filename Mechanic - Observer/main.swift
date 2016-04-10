//
//  main.swift
//  Mechanic - Observer
//
//  Created by Reza Shirazian on 2016-04-08.
//  Copyright © 2016 Reza Shirazian. All rights reserved.
//

import Foundation

var mountainView = Zipcode(value: "94043", baseRate: 40.00)
var redwoodCity = Zipcode(value: "94063", baseRate: 30.00)
var paloAlto = Zipcode(value: "94301", baseRate: 50.00)
var sunnyvale = Zipcode(value: "94086", baseRate: 35.00)

var zipcodes : Set<Zipcode> = [mountainView, redwoodCity, paloAlto, sunnyvale]

var steve = Mechanic(name: "Steve Akio", location: mountainView)
var joe = Mechanic(name: "Joe Jackson", location: redwoodCity)
var jack = Mechanic(name: "Jack Joesph", location: redwoodCity)
var john = Mechanic(name: "John Foo", location: paloAlto)
var trevor = Mechanic(name: "Trevor Simpson", location: sunnyvale)
var brian = Mechanic(name: "Brian Michaels", location: sunnyvale)
var tom = Mechanic(name: "Tom Lee", location: sunnyvale)
var mike = Mechanic(name: "Mike Cambell", location: mountainView)
var jane = Mechanic(name: "Jane Sander", location: mountainView)
var ali = Mechanic(name: "Ali Ham", location: paloAlto)
var sam = Mechanic(name: "Sam Fox", location: mountainView)
var reza = Mechanic(name: "Reza Shirazian", location: mountainView)
var max = Mechanic(name: "Max Watson", location: sunnyvale)
var raj = Mechanic(name: "Raj Sundeep", location: sunnyvale)
var bob = Mechanic(name: "Bob Anderson", location: mountainView)

var mechanics = [steve, joe, jack, john, trevor, brian, tom, mike, jane, ali, sam, reza, max, raj, bob]

var supply: [Zipcode: Int] = [:]

zipcodes.forEach({(zipcode: Zipcode) in supply[zipcode] = mechanics.filter({(mechanic:Mechanic) in mechanic.status == Status.Idle && mechanic.zipcode === zipcode}).count})

var priceManager = ZipcodePriceManager(zipcodes: zipcodes, supply: supply)

let observer = MechanicObserver()

observer.subscribe(priceManager)

mechanics.forEach({$0.observer = observer})

john.status = .OnTheWay
steve.status = .OnTheWay
steve.status = .Busy
steve.status = .Idle
trevor.status = .OnTheWay
brian.status = .OnTheWay
tom.status = .OnTheWay
reza.status = .OnTheWay
tom.status = .Busy
raj.status = .OnTheWay

observer.unsubscribe(priceManager)
print("unsubscribed")

raj.status = .Idle