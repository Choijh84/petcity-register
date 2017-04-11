//
//  StoreCategory.swift
//  Pet-Hotels
//
//  Created by Owner on 2016. 12. 25..
//  Copyright © 2016년 TwistWorld. All rights reserved.
//


import Foundation

 /// The category object for the Stores

class StoreCategory: NSObject {

    /// name of the category
    var name: String?
    /// ID of the category
    var objectId: String?
    /// List of store Objects
    var stores =  [Store]()
    
    /**
     Checks if the 2 objects have the same objectId, if so, they are equal

     - parameter object: object to compare self with

     - returns: true if their objectId is equal
     */
    override func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? StoreCategory {
            return objectId == rhs.objectId
        }
        return false
    }

}
