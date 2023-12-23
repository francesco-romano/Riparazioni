//
//  DataManager.swift
//  Riparazioni
//
//  Created by Francesco Romano on 18/12/2023.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

// Model entry point.
class DataManager: ObservableObject {
    
    enum Result {
        case success
        case failure(String)
    }
    
    private let ItemsCollectionKey: String = "items"
    // We initialise the connection by default but we can potentially skip this
    // in the preview code path.
    private var database: Firestore? = nil
    
    @Published var items: [Item] = []
    
    init(withoutDBConnection: Bool = false) {
        if !withoutDBConnection {
            self.database = Firestore.firestore()
        }
    }
    
    func addNewItem(_ newItem: Item) -> Result {
        do {
            let docRef = try database?.collection(ItemsCollectionKey).addDocument(from: newItem)
            newItem.id = docRef?.documentID
            // Add it to the collection.
            items.append(newItem)
            return .success
        } catch let error {
            return .failure("Error writing city to Firestore: \(error)")
        }
    }
    
    func saveChangesToItem(_ item: Item, withId id: String ) -> Result {
        do {
            try database?.collection(ItemsCollectionKey).document(id).setData(from: item)
            return .success
        } catch let error {
            return .failure("Error writing city to Firestore: \(error)")
        }
    }
    
    func deleteItem(_ item: Item) -> Void {
        let itemIndex = items.firstIndex(where: {$0.id == item.id!})
        if itemIndex == nil {
            print("Could not find item \(item)")
            return
        }
        database?.collection(ItemsCollectionKey).document(item.id!).delete()
        items.remove(at: itemIndex!)
    }
    
    
    func loadItems() async {
        // To support preview, network operations are no-op.
        if database == nil {
            print("This should only happen in Preview mode. If this is not the case, it is a logic error!")
            return
        }
        
        do {
            let querySnapshot = try await database!.collection(ItemsCollectionKey).getDocuments(source: .default)
            
            var items: [Item] = []
            for document in querySnapshot.documents {
                let item = try document.data(as: Item.self)
                items.append(item)
            }
            // We need to explicitly capture `items` as constant to allow it being
            // used from the main thread.
            DispatchQueue.main.async { [items] in
                self.items = items
            }
            
            //            listenerRegistration = db.collection("cities").addSnapshotListener { (querySnapshot, error) in
            //                  guard let documents = querySnapshot?.documents else {
            //                    print("No documents")
            //                    return
            //                  }
            //                  self.cities = documents.compactMap { queryDocumentSnapshot -> City? in
            //                    return try? queryDocumentSnapshot.data(as: City.self)
            //                  }
            //                }
            
        } catch {
            print("Error getting itmes: \(error)")
        }
    }
    
    static func SampleManager() -> DataManager {
        // TODO: this does not really work. When triggering the preview
        // I can't start the main app because of double lock on the DB.
        let manager = DataManager(withoutDBConnection: true)
        manager.items = Item.sampleData
        return manager
    }
}
