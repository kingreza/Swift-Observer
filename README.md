<h1>Design Patterns in Swift: Observer</h1>
This repository is part of a series. For the full list check out <a href="https://shirazian.wordpress.com/2016/04/11/design-patterns-in-swift/">Design Patterns in Swift</a>

<h3>The problem:</h3>
We have a set of mobile mechanics who are assigned specific zip codes. Each zip code has its own hourly rate. We want to increase and decrease these rates when the number of idle mechanics within a zip code falls or goes above specific thresholds. This way we can proactively set the going rate for each mechanic when demand is high and bring it down when demand is low within a specific zip code.
<h3>The solution:</h3>
We will set up an observer that will monitor the status of each mechanic. This observer will send out notifications to its subscribers when there is a change. Then we will set up a price manager object that will subscribe to our observer and consume its status change notifications. The price manager subscriber  will keep tally of our mechanic supply and when their status is changed it will re-calculate and assign new rates for zip codes if their idle supply falls or goes above specific thresholds.

<!--more-->

Link to the repo for the completed project: <a href="https://github.com/kingreza/Swift-Observer">Swift - Observer</a>

Although there are quite a few examples of the Observer design pattern in iOS (NSNotificationCenter comes to mind) we will be building our own solution from ground up. So this will be a console project (OSX Command line tool). If interested in an <a href="https://www.raywenderlich.com/90773/introducing-ios-design-patterns-in-swift-part-2">iOS focused example click here </a>Also it's worth noting that in the classic definition of the Observer design pattern, the observer itself consumes the event from the subject, for this example we will be delegating that task to another object that we call the 'subscriber'. This is done better encapsulation and separation of responsibility for this specific problem.  

Let's begin:

First off lets define our Zipcode object

````swift
import Foundation

class Zipcode{
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
}
````

We define a Zipcode to have a value which stands for the general zip code value (94043, 90210 etc). We define a baseRate and adjustment property of types double and define a rate property which is computed from baseRate and adjustments.

Next we will define our mechanic's status as an enumerable

````swift
import Foundation
enum Status: Int{
  case Idle = 1, OnTheWay, Busy
}
````

We will define three different statuses. Idle, OnTheWay and Busy. Idle is considered available supply whereas OnTheWay and Busy are not.

Now lets define our Mechanic object

````swift
class Mechanic{

  let name: String
  var zipcode: Zipcode

  var status: Status = .Idle

  init(name: String, location: Zipcode){
    self.name = name
    self.zipcode = location
  }
}
````

A mechanic for our case has a name and a zip code which is his/her area of operation. A mechanic also has a status property of type Status which is initialized to Idle

Next we will define a protocol which our observer will implement.

````swift
import Foundation

protocol Observer: class{
  var subscribers: [Subscriber] {get set}

  func propertyChanged(propertyName: String, oldValue: Int, newValue: Int, options: [String:String]?)

  func subscribe(subscriber: Subscriber)

  func unsubscribe(subscriber: Subscriber)
}
````

Our observer needs to have a propertyChanged method which is called when an observing property is changed. This method will have the name of the property changed, its old and new values along with any other optional values we want to pass in a key-value dictionary.

Now lets define a protocol for our subscribers. This protocol sets all the requirements needed for classes which will subscribe and consume notifications from our observer

````swift
import Foundation

protocol Subscriber: class{
  var properties : [String] {get set}
  func notify(oldValue: Int, newValue: Int, options: [String:String]?)
}
````

First we define a collection of properties which our subscriber is interested in. Our observer will send its notification to this subscriber when any of the changing properties matches one listed in this collection. For the sake brevity this collection is of type String where the values are simple names of properties. Within more complex systems this collection can be of a well defined property type.

We also define a notify function which will be called by our observer along with all relevant values needed to consume its data.

Next we will define a MechanicObserver which will implement our Observer protocol.

````swift
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
````

The MechanicObserver will have a collection of subscribers with simple methods for adding and removing them from the collection through subscribe and unsubscribe functions.

The most interesting part of our code perhaps starts in the propertyChanged function. Let's go over it line by line

````swift
print("Change in property detected, notifying subscribers")
````

We output a simple message to the console informing the user that a change in property has been detected by the observer.

````swift
let matchingSubscribers = subscribers.filter({$0.properties.contains(propertyName)})
````

Next we will filter out subscribers that are interested on the property that has been modified. As we showed earlier in our subscriber protocol every subscriber has a collection of property names it wishes to be notified about. We find subscribers that match up with the propertyName that has been modified.

````swift
matchingSubscribers.forEach({$0.notify(propertyName, oldValue: oldValue, newValue: newValue, options: options)})
````

Next for every subscriber that matched with that property name, we call its notify method with all the data that was passed to the observer.

This is pretty much it.

Now that our observer is set up lets change our mechanic model so its status property is observed by our observer.

````swift
import Foundation

class Mechanic{

  weak var observer: Observer?

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
````

We add an observer property to our mechanic. Next we changed the definition of our status property to executes our observer's propertyChange method when its value is set.

in Swift willSet and didSet are used to execute specific code before and after a property is changed. <a href="https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Properties.html">For more info click here</a>.

We will also include the mechanic's Zipcode in our options collection which will come in handy later.

For the last piece of the puzzle we need to implement our subscriber. Since this will get a little more complicated lets appraoch it step by step.

First let's define a ZipcodePriceManager class that will implement our Subscriber protocol.

````swift
import Foundation

class ZipcodePriceManager: Subscriber{
  var properties : [String] = ["Status"]
  var zipcodes: Set<Zipcode>
  var supply: [Zipcode: Int] = [:]

  init(zipcodes: Set<Zipcode>, supply: [Zipcode: Int]){
    self.zipcodes = zipcodes
    self.supply = supply
  }
 func notify(propertyName: String, oldValue: Int, newValue: Int, options: [String:String]?){}
````

In our definition we can see that ZipcodePriceManager implements subscriber, it defines a properties collection that is initialized to an array which holds one value "Status". Since this class only needs the mechanic's Status to determine zip code's rates we will only monitor that property. (It is also the case we are not observing any other property in our Mechanic's class, however extending the observer to monitor more properties and our subscribers to consume a more diverse set of properties is a trivial process.)

Our ZipcodePriceManager also has two properties that are not part of the subscriber protocol: zipcodes and supply. Since our zipcodes will be all unique values and since we don't care about their order, we will define it as a Set type.

We will also define our supply as a dictionary of key Zipcodes and value Ints. Our unique Zipcodes behaves as a key and the Int value will be the available idle mechanics for that Zipcode. The initial values for these properties will be set by its initializer.

When we define our supply this way, Swift will complain about our Zipcode object. The problem is that our Zipcode object does not implement Hashable and Equatable. Since we are using a Zipcode instance as a key within a dictionary, Swift needs a way to derive a unique value from it. This is something we need to provide Swift. This can be achieved by implementing the Hashable protocol which will require us to add a hashValue property which must return a unique integer. We also need to implement the Equatable protocol which Hashable inherits from. Equatable tells Swift how two Zipcode are equal. This is a requirement for any object that implements the Hashable protocol.

So we change our Zipcode class to be:

````swift

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
````

We added a hashValue function that returns an Int. Since our Zipcode value will be unique for each Zipcode and since String already implements Hashable we can return our Zipcode's value.hashValue.

we also define == operator for Zipcode to compare Zipcode's value for equality. This will make our Zipcode class conform to the Equatable protocol. Note that this is done outside out of Zipcode's class definition. More info on <a href="https://developer.apple.com/library/watchos/documentation/Swift/Reference/Swift_Hashable_Protocol/index.html">Hashable</a> and <a href="https://developer.apple.com/library/watchos/documentation/Swift/Reference/Swift_Equatable_Protocol/index.html">Equatable</a>

Alright let's get back to our ZipcodePriceManager. Next we will implement our notify function. We want our ZipcodePriceManager subscriber to consumer its notifications so that every change to a mechanic's status will increase and decrease the zipcode number of supply.

````swift
  func notify(propertyName: String, oldValue: Int, newValue: Int, options: [String:String]?){
    if properties.contains(propertyName){
       print("\(propertyName) is changed from \(Status(rawValue: oldValue)!) to \(Status(rawValue: newValue)!)")
      if propertyName == "Status"{
        if let options = options{
          let zipcode = zipcodes.filter({$0.value == options["Zipcode"]}).first
          if let zipcode = zipcode{
            if (Status(rawValue: newValue) == Status.Idle && Status(rawValue: oldValue) != Status.Idle){
              supply[zipcode]! += 1
            }else if (Status(rawValue: newValue) != Status.Idle && Status(rawValue: oldValue) == Status.Idle){
              supply[zipcode]! -= 1
            }
            updateRates()
            print("**********************")
          }
        }
      }
    }
  }
````

So let's break this down

First we check to make sure the property being changed is included in the list of properties our subscriber is interested in:

````swift
if properties.contains(propertyName){
````

Next we prompt the user that our subscriber has been notified that a property it is interested in has changed:

````swift
  print("\(propertyName) is changed from \(Status(rawValue: oldValue)!) to \(Status(rawValue: newValue)!)")
````

Next we check to see if the property changed is "Status". If so unwrap its options and find the Zipcode that was passed from the Mechanic.

````swift
  if propertyName == "Status"{
        if let options = options{
          let zipcode = zipcodes.filter({$0.value == options["Zipcode"]}).first
````

if the Zipcode was found, change its supply. If the status is from idle to anything this means an idle mechanic has become busy, then we decrease its value in the supply dictionary. Conversely if the change is from anything else to idle, it means a busy mechanic has become idle so we increase our supply:

````swift
 if let zipcode = zipcode{
   if (Status(rawValue: newValue) == Status.Idle && Status(rawValue: oldValue) != Status.Idle){
     supply[zipcode]! += 1
   }else if (Status(rawValue: newValue) != Status.Idle && Status(rawValue: oldValue) == Status.Idle){
     supply[zipcode]! -= 1
}
````

Finally we call an updateRate function which will update our Zipcode rates according to the new supplies:

````swift
updateRates()
print("**********************")
````

Here is the definition for updateRates() which recalculates and reassigns adjustment ratios to our Zipcodes:

````swift
  func updateRates(){
    supply.forEach({(zipcode: Zipcode, supply: Int) in
      if (supply <= 1){
        zipcode.adjustment = 0.50
        print("Very High Demand! Adjusting price for \(zipcode.value): rate is now \(zipcode.rate) because supply is \(supply)")
      }else if (supply <= 3){
        zipcode.adjustment = 0.25
        print("High Demand! Adjusting price for \(zipcode.value): rate is now \(zipcode.rate) because supply is \(supply)")
      }else{
        zipcode.adjustment = 0.0
        print("Normal Demand. Adjusting price for \(zipcode.value): rate is now \(zipcode.rate) because supply is \(supply)")
      }
    })
  }
````

There isn't much here that's related to our Observer design pattern so I'll let you go over it and figure it out.

So when we put it all together, our ZipcodePriceManager ends up looking like this:

````swift
import Foundation

class ZipcodePriceManager: Subscriber{
  var properties : [String] = ["Status"]
  var zipcodes: Set<Zipcode>
  var supply: [Zipcode: Int] = [:]

  init(zipcodes: Set<Zipcode>, supply: [Zipcode: Int]){
    self.zipcodes = zipcodes
    self.supply = supply
  }

  func notify(propertyName: String, oldValue: Int, newValue: Int, options: [String:String]?){
    if properties.contains(propertyName){
       print("\(propertyName) is changed from \(Status(rawValue: oldValue)!) to \(Status(rawValue: newValue)!)")
      if propertyName == "Status"{
        if let options = options{
          let zipcode = zipcodes.filter({$0.value == options["Zipcode"]}).first
          if let zipcode = zipcode{
            if (Status(rawValue: newValue) == Status.Idle && Status(rawValue: oldValue) != Status.Idle){
              supply[zipcode]! += 1
            }else if (Status(rawValue: newValue) != Status.Idle && Status(rawValue: oldValue) == Status.Idle){
              supply[zipcode]! -= 1
            }
            updateRates()
            print("**********************")
          }
        }
      }
    }
  }

  func updateRates(){
    supply.forEach({(zipcode: Zipcode, supply: Int) in
      if (supply <= 1){
        zipcode.adjustment = 0.50
        print("Very High Demand! Adjusting price for \(zipcode.value): rate is now \(zipcode.rate) because supply is \(supply)")
      }else if (supply <= 3){
        zipcode.adjustment = 0.25
        print("High Demand! Adjusting price for \(zipcode.value): rate is now \(zipcode.rate) because supply is \(supply)")
      }else{
        zipcode.adjustment = 0.0
        print("Normal Demand. Adjusting price for \(zipcode.value): rate is now \(zipcode.rate) because supply is \(supply)")
      }
    })
  }
}
````

It's important to note that our ZipcodePriceManager knows nothing about our Mechanics, and our Mechanics know nothing about ZipcodePriceManager, Supplies or the collection of our serving zip codes. Also our MechanicObserver, although named MechanicObserver has no reference to a Mechanic.

Lets define our Main function and test it out

````swift

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
````

Alright that was a lot, so lets break it down and go step by step. First off we set our Zipcodes:

````swift
var mountainView = Zipcode(value: "94043", baseRate: 40.00)
var redwoodCity = Zipcode(value: "94063", baseRate: 30.00)
var paloAlto = Zipcode(value: "94301", baseRate: 50.00)
var sunnyvale = Zipcode(value: "94086", baseRate: 35.00)

var zipcodes : Set<Zipcode> = [mountainView, redwoodCity, paloAlto, sunnyvale]
````

Next we set our Mechanics:

````swift
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
````

Next we calculate our supply dictionary and setting up our ZipcodePriceManager subscriber. The code for the initial supply calculation might seem a bit complicated but it's just the count of all mechanics that have their status set to idle for each zipcode. Play around with it a bit if you're new to closures.

````swift
var supply: [Zipcode: Int] = [:]

zipcodes.forEach({(zipcode: Zipcode) in supply[zipcode] = mechanics.filter({(mechanic:Mechanic) in mechanic.status == Status.Idle && mechanic.zipcode === zipcode}).count})

var priceManager = ZipcodePriceManager(zipcodes: zipcodes, supply: supply)
````

Next we set up our observer, have our ZipcodePriceManager subscribe to it and have our observer observe all our mechanics:

````swift
let observer = MechanicObserver()

observer.subscribe(priceManager)

mechanics.forEach({$0.observer = observer})
````

Now everything is setup. Let's get our mechanics to work and see how our zipcode rates change as supplies go up and down

````swift
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
````

Note that all we are doing is changing our mechanic's status. We don't call anything else. All of our changes to supply and rates for our zipcodes are taken care of by our observer and subscriber.

As for one last test we unsubscribe our ZipcodePriceManager from the observer and see what happens when we change a mechanic's status:

````swift
observer.unsubscribe(priceManager)
print("unsubscribed")

raj.status = .Idle
````

The output we get to the console when we run all of this is:

````swift
Change in property detected, notifying subscribers
Status is changed from Idle to OnTheWay
Normal Demand. Adjusting price for 94043: rate is now 40.0 because supply is 6
High Demand! Adjusting price for 94063: rate is now 37.5 because supply is 2
Normal Demand. Adjusting price for 94086: rate is now 35.0 because supply is 5
Very High Demand! Adjusting price for 94301: rate is now 75.0 because supply is 1
**********************
Change in property detected, notifying subscribers
Status is changed from Idle to OnTheWay
Normal Demand. Adjusting price for 94043: rate is now 40.0 because supply is 5
High Demand! Adjusting price for 94063: rate is now 37.5 because supply is 2
Normal Demand. Adjusting price for 94086: rate is now 35.0 because supply is 5
Very High Demand! Adjusting price for 94301: rate is now 75.0 because supply is 1
**********************
Change in property detected, notifying subscribers
Status is changed from OnTheWay to Busy
Normal Demand. Adjusting price for 94043: rate is now 40.0 because supply is 5
High Demand! Adjusting price for 94063: rate is now 37.5 because supply is 2
Normal Demand. Adjusting price for 94086: rate is now 35.0 because supply is 5
Very High Demand! Adjusting price for 94301: rate is now 75.0 because supply is 1
**********************
Change in property detected, notifying subscribers
Status is changed from Busy to Idle
Normal Demand. Adjusting price for 94043: rate is now 40.0 because supply is 6
High Demand! Adjusting price for 94063: rate is now 37.5 because supply is 2
Normal Demand. Adjusting price for 94086: rate is now 35.0 because supply is 5
Very High Demand! Adjusting price for 94301: rate is now 75.0 because supply is 1
**********************
Change in property detected, notifying subscribers
Status is changed from Idle to OnTheWay
Normal Demand. Adjusting price for 94043: rate is now 40.0 because supply is 6
High Demand! Adjusting price for 94063: rate is now 37.5 because supply is 2
Normal Demand. Adjusting price for 94086: rate is now 35.0 because supply is 4
Very High Demand! Adjusting price for 94301: rate is now 75.0 because supply is 1
**********************
Change in property detected, notifying subscribers
Status is changed from Idle to OnTheWay
Normal Demand. Adjusting price for 94043: rate is now 40.0 because supply is 6
High Demand! Adjusting price for 94063: rate is now 37.5 because supply is 2
High Demand! Adjusting price for 94086: rate is now 43.75 because supply is 3
Very High Demand! Adjusting price for 94301: rate is now 75.0 because supply is 1
**********************
Change in property detected, notifying subscribers
Status is changed from Idle to OnTheWay
Normal Demand. Adjusting price for 94043: rate is now 40.0 because supply is 6
High Demand! Adjusting price for 94063: rate is now 37.5 because supply is 2
High Demand! Adjusting price for 94086: rate is now 43.75 because supply is 2
Very High Demand! Adjusting price for 94301: rate is now 75.0 because supply is 1
**********************
Change in property detected, notifying subscribers
Status is changed from Idle to OnTheWay
Normal Demand. Adjusting price for 94043: rate is now 40.0 because supply is 5
High Demand! Adjusting price for 94063: rate is now 37.5 because supply is 2
High Demand! Adjusting price for 94086: rate is now 43.75 because supply is 2
Very High Demand! Adjusting price for 94301: rate is now 75.0 because supply is 1
**********************
Change in property detected, notifying subscribers
Status is changed from OnTheWay to Busy
Normal Demand. Adjusting price for 94043: rate is now 40.0 because supply is 5
High Demand! Adjusting price for 94063: rate is now 37.5 because supply is 2
High Demand! Adjusting price for 94086: rate is now 43.75 because supply is 2
Very High Demand! Adjusting price for 94301: rate is now 75.0 because supply is 1
**********************
Change in property detected, notifying subscribers
Status is changed from Idle to OnTheWay
Normal Demand. Adjusting price for 94043: rate is now 40.0 because supply is 5
High Demand! Adjusting price for 94063: rate is now 37.5 because supply is 2
Very High Demand! Adjusting price for 94086: rate is now 52.5 because supply is 1
Very High Demand! Adjusting price for 94301: rate is now 75.0 because supply is 1
**********************
unsubscribed
Change in property detected, notifying subscribers
Program ended with exit code: 0
````

As you can see our observer correctly detects changes to mechanic's status, it correctly sends its notifications to its subscribers. Our ZipcodePriceManager subscriber correctly consumes the notifications and sets the prices for each zip code accordingly.

Congratulations you have just implemented the Observer Design Pattern to solve a nontrivial problem. 

The repo for the complete project can be found here: <a href="https://github.com/kingreza/Swift-Observer">Swift - Observer.</a> 

Download a copy of it and play around with it. See if you can find ways to improve its performance, observer more properties and expand on it anyway you like. Here are some suggestions on how to expand or improve on the project:

<ul>
  <li>What if a mechanic can server multiple zipcodes</li>
  <li>How can we improve the updateRates() function</li>
  <li>How can we add and observe other properties like hoursWorked for overtime calculation, location for when a mechanic is close to a job's location and so on...</li>
</ul>
