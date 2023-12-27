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
    @Published var needsLogin: Bool = false  // Triggered in case of login error.

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
    
    func batchUpload(_ items: [Item], cleanFirst: Bool) async -> Result {
        do {
            let collectionRef = database?.collection(DataManager.ItemsCollectionKey)
            
            // Get new write batch
            let batch = database!.batch()
            
            if cleanFirst {
                let allDocs = try await collectionRef?.getDocuments().documents
                // Delete all previous items.
                allDocs!.forEach({ doc in
                    batch.deleteDocument(doc.reference)
                })
            }
            
            // Now insert all new data.
            for item: Item in items {
                let newRef = collectionRef!.document()
                try batch.setData(from: item, forDocument: newRef)
            }
            
            // Commit the batch
            try await batch.commit()
            return .success
        } catch let error {
            return .failure("\(error)")
        }
    }
    
    
    func loadItems() {
        // To support preview, network operations are no-op.
        if database == nil {
            print("This should only happen in Preview mode. If this is not the case, it is a logic error!")
            return
        }
        errorMessage = nil
        guard listenerRegistration == nil else { return }
        listenerRegistration = database?.collection(Self.ItemsCollectionKey)
            .addSnapshotListener { [weak self]
                (querySnapshot, error) in
                guard let documents: [QueryDocumentSnapshot] = querySnapshot?.documents else {
                    // TODO: check if this is an error
                    // 1. This is called when the user is not authenticated.
                    print("No documents. CHECK: Is this an error?")
                    self?.needsLogin = true
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

