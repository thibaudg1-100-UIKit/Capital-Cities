//
//  Capital.swift
//  Project16
//
//  Created by RqwerKnot on 29/10/2022.
//

import UIKit
import MapKit

class Capital: NSObject, MKAnnotation { // With map annotations, you can't use structs, and you must inherit from NSObject because it needs to be interactive with Apple's Objective-C code.
    init(title: String, coordinate: CLLocationCoordinate2D, info: String) {
        self.title = title
        self.coordinate = coordinate
        self.info = info
    }
    
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var info: String
}
