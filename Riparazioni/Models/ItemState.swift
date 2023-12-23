//
//  ItemState.swift
//  Riparazioni
//
//  Created by Francesco Romano on 10/12/2023.
//

import Foundation

enum ItemState: Codable, Hashable, Identifiable {
    case new
    case pending(String, Date)  // Where is the item, date of swithing to pending.
    case completed(String, Date?) // Where is the item, date of notification.
    case collected(Date)  // Collection date.
    
    //Conform to Identifiable using the rawValue.
    var id: Self { self }
}


extension ItemState {
    var description: String {
        switch self {
        case .new:
            return ""
        case .pending(let pendingLocation, let pendingDate):
            return "<Pending>" + pendingLocation + " " + pendingDate.formatted(
                date: .numeric, time: .omitted)            
        case .completed(let completedLocation, let notificationDate):
            let text = "<Ready>" + completedLocation
            if notificationDate != nil {
                return text + " " + notificationDate!.formatted(date: .numeric, time: .omitted)
            }
            return text
        case .collected(let date):
            return "<Collected>" + date.formatted(date: .numeric, time: .omitted)
        }
    }
}
