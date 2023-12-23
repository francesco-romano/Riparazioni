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
    static private let ItemsCollectionKey: String = "items"
    
    enum Result {
        case success
        case failure(String)
    }
    
    // We initialise the connection by default but we can potentially skip this
    // in the preview code path.
    private var database: Firestore? = nil
    private var listenerRegistration: ListenerRegistration?
    
    @Published var items: [Item] = []
    @Published var errorMessage: String?
    
    init(withoutDBConnection: Bool = false) {
        if !withoutDBConnection {
            self.database = Firestore.firestore()
        }
    }
    
    deinit {
        if listenerRegistration != nil {
            listenerRegistration?.remove()
            listenerRegistration = nil
        }
    }
    
    func addNewItem(_ newItem: Item) -> Result {
        do {
            try database?.collection(Self.ItemsCollectionKey).addDocument(from: newItem)
            // The listener will automatically add it to the collection.
            return .success
        } catch let error {
            return .failure("Error writing item to Firestore: \(error)")
        }
    }
    
    func saveChangesToItem(_ item: Item, withId id: String ) -> Result {
        do {
            try database?.collection(Self.ItemsCollectionKey).document(id).setData(from: item)
            // The listener will automatically update the collection.
            return .success
        } catch let error {
            return .failure("Error writing item to Firestore: \(error)")
        }
    }
    
    func deleteItem(_ item: Item) -> Void {
        database?.collection(Self.ItemsCollectionKey).document(item.id!).delete()
    }
    
    
    func loadItems() {
        // To support preview, network operations are no-op.
        if database == nil {
            print("This should only happen in Preview mode. If this is not the case, it is a logic error!")
            return
        }
        guard listenerRegistration == nil else { return }
        listenerRegistration = database?.collection(Self.ItemsCollectionKey)
            .addSnapshotListener { [weak self]
                (querySnapshot, error) in
                guard let documents: [QueryDocumentSnapshot] = querySnapshot?.documents else {
                    // TODO: check if this is an error
                    print("No documents. CHECK: Is this an error?")
                    return
                }
                self?.items = documents.compactMap{ queryDocumentSnapshot in
                    let result = Swift.Result{ try queryDocumentSnapshot.data(as: Item.self) }
                    switch result {
                    case .success(let item):
                        self?.errorMessage = nil
                        return item
                    case .failure(let error):
                        switch error {
                        case DecodingError.typeMismatch(_, let context):
                            self?.errorMessage = "\(error.localizedDescription): \(context.debugDescription)"
                        case DecodingError.valueNotFound(_, let context):
                            self?.errorMessage = "\(error.localizedDescription): \(context.debugDescription)"
                        case DecodingError.keyNotFound(_, let context):
                            self?.errorMessage = "\(error.localizedDescription): \(context.debugDescription)"
                        case DecodingError.dataCorrupted(let key):
                            self?.errorMessage = "\(error.localizedDescription): \(key)"
                        default:
                            self?.errorMessage = "Error decoding document: \(error.localizedDescription)"
                        }
                        return nil
                    }
                }
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




//        do {
//            let querySnapshot = try await database!.collection(DataManager.ItemsCollectionKey).getDocuments(source: .default)
//
//            var items: [Item] = []
//            for document in querySnapshot.documents {
//                let item = try document.data(as: Item.self)
//                items.append(item)
//            }
//            // We need to explicitly capture `items` as constant to allow it being
//            // used from the main thread.
//            DispatchQueue.main.async { [items] in
//                self.items = items
//            }
//
//        } catch {
//            print("Error getting itmes: \(error)")
//        }
