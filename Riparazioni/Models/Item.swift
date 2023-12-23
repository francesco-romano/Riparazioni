//
//  Item.swift
//  Riparazioni
//
//  Created by Francesco Romano on 10/12/2023.
//

import Foundation
import FirebaseFirestoreSwift

class Item: Codable, Identifiable, NSCopying {
    // ID is left empty as it is filled by Firebase when storing the object.
    @DocumentID var id: String?
    var description: String
    var date: Date
    var price: Decimal
    var notes: String
    var customer: Customer
    var state: ItemState = ItemState.new
    
    init(id: String? = nil, description: String = "", date: Date = Date(),
         price: Decimal = 0, notes: String = "",
         customer: Customer = Customer(), state: ItemState = ItemState.new) {
        if (id != nil) {
            self.id = id
        }
        self.description = description
        self.date = date
        self.price = price
        self.notes = notes
        self.customer = customer
        self.state = state
    }
    
    func copyFrom(_ item: Item) -> Void {
        self.description = item.description
        self.date = item.date
        self.price = item.price
        self.notes = item.notes
        self.state = item.state
        self.customer = item.customer.copy() as! Customer
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        Item(id: nil,  // Do not copy over the ID.
             description: description,
             date: date,
             price: price,
             notes: notes,
             customer: customer,
             state: state)
    }
}



extension Item {
    static let sampleData: [Item] =
    [
        // IDs are set manually here.
        Item(id: "item_1",
             description: "Ring to resize",
             date: Date.now,
             customer: Customer(name:"Gianna", lastName:"Parodi")),
        Item(id: "item_2",
             description: "Watch battery",
             date: Date(),
             price: 10,
             notes: "To clean",
             customer: Customer(name:"Andrea", lastName:"Dicarlo"),
             state: ItemState.completed("Cassa A")),
        Item(id: "item_3",
             description: "Ring to clean",
             date: Date(timeIntervalSinceReferenceDate: 31536000),
             price: 0,
             customer: Customer(name:"Valerio", lastName:"Modugno"),
             state: ItemState.pending("Orafo1"))
    ]
}
