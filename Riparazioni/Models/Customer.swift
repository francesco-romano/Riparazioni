//
//  Customer.swift
//  Riparazioni
//
//  Created by Francesco Romano on 10/12/2023.
//

import Foundation

class Customer: Codable, NSCopying {
    var name: String
    var lastName: String
    var phone: String
    var email: String
    
    init(name: String = "",
         lastName: String = "",
         phone:String = "",
         email: String = "") {
        self.name = name
        self.lastName = lastName
        self.phone = phone
        self.email = email
    }
    
    var fullName: String {
        name + " " + lastName
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        Customer(name: name, lastName: lastName, phone: phone, email: email)
    }
}
