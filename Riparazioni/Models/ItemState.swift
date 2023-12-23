//
//  ItemState.swift
//  Riparazioni
//
//  Created by Francesco Romano on 10/12/2023.
//

import Foundation

enum ItemState: Codable, Hashable, Identifiable {
    case new
    case pending(String)
    case completed(String) //, Date)
    case collected//(Date)
    
    //Conform to Identifiable using the rawValue
    var id: Self { self }
}
