//
//  ImporterProgressView.swift
//  Riparazioni
//
//  Created by Francesco Romano on 24/12/2023.
//

import SwiftUI


struct ImporterProgressView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject private var appDelegate: AppDelegate
    @Environment(\.openWindow) private var openWindow
    
    let file: URL
    let shouldErase: Bool
    
    @State var isDone: Bool = false
    @State var progressDescription: String = ""
    @State var showErrorAlert: Bool = false
    @State var errorAlertMesage: String = ""
    
    init(file: URL, shouldErase: Bool) {
        self.file = file
        self.shouldErase = shouldErase
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text(progressDescription)
            ProgressView().opacity(isDone ? 0 : 1)
            Button("Done", action: {
                closeWindow()
            }).disabled(!isDone).keyboardShortcut(.defaultAction)
                .opacity(isDone ? 1 : 0)
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .task {
            // Open the file.
            do {
                let items = try self.getItemsFromFile(file)
                if items.isEmpty {
                    return
                }
                let numOfItems = items.count
                DispatchQueue.main.async {
                    progressDescription = "Loaded \(numOfItems) items."
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                let newItems: [Item] = items.map({ item in
                    let description = item["description"] as? String
                    let date = dateFormatter.date(from: item["date"] as? String ?? "")
                    
                    let price = item["price"] as? Decimal
                    let notes = item["notes"] as? String
                    let name = item["customer"] as? String
                    let phone = item["contact"] as? String
                    
                    
                    return Item(
                        description: description ?? "",
                        date: date ?? Date(),
                        price: price ?? 0,
                        notes: notes ?? "",
                        customer: Customer(
                            name: name ?? "",
                            lastName: "",
                            phone: phone ?? "",
                            email: ""
                        ),
                        state: getItemStateFromOldPosition(item["position"] as? String)
                        
                    )
                })
                DispatchQueue.main.async {
                    var text = shouldErase ? "Removing all data.\n" : ""
                    text.append("Uploading \(numOfItems) items.")
                    progressDescription = text
                }
                let result = await dataManager.batchUpload(newItems, cleanFirst: shouldErase)
                DispatchQueue.main.async {
                    switch (result) {
                    case .success:
                        progressDescription = "Done. Imported \(numOfItems)."
                    case .failure(let error):
                        showErrorAlert.toggle()
                        errorAlertMesage = error
                    }
                    isDone = true
                }
            }
            catch let error{
                print("Error while importing \(error)")
            }
        }.alert("Failed to import items", isPresented: $showErrorAlert, actions: {
            Button("OK") {
                closeWindow()
            }
        })
    }
    
    func closeWindow() -> Void {
        NSApplication.shared.keyWindow?.close()
        // Open the main window, and re-enable the quitting app.
        openWindow(id:"main_window")
        appDelegate.shouldQuitAfterClosingWindow = true
    }
}


enum ImporterError: Error {
    case decodingError(String)
}

extension ImporterProgressView {
    
    func getItemsFromFile(_ file: URL) throws -> [Dictionary<String, AnyObject>]  {
        let data = try Data(contentsOf: file)
        // We do not have structure so simply read the file.
        guard let items = try JSONSerialization.jsonObject(with: data) as? [Dictionary<String, AnyObject>] else {
            throw ImporterError.decodingError("Invalid format")
        }
        
        return items
    }
    
    func getItemStateFromOldPosition(_ position: String?) -> ItemState {
        if position == nil || position!.isEmpty {
            return .new
        }
        
        if ["CONSEGNATO", "ANNULLATO"].contains(position!)  {
            return .collected(Date(timeIntervalSinceReferenceDate: 0))
        }
        
        if ["Cassa Duto", "CB", "Cassa Small"].contains(position!) {
            return .completed(position!, nil)
        }
        
        if ["Esterno", "Salvucci", "Idea", "DA ORDINARE"].contains(position!) {
            return .pending(position!, Date(timeIntervalSinceReferenceDate: 0))
        }
        return .new
        
    }
}

struct ImporterProgressView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ImporterProgressView(file: URL(string: "file:///dummy.json")!, shouldErase: true)
        }
    }
}


// TODO: make this dynamic by letting the user choose the fields to match.
//
//
//struct ItemKey: Identifiable, Hashable {
//    var key: String
//
//    var id: String {
//        key
//    }
//
//    init(_ key: String) {
//        self.key = key
//    }
//}
//
//struct ItemMatcher: Identifiable, Hashable {
//    var key: String
//    var importerKey: String?
//
//    var id: String {
//        key
//    }
//}
//
//struct ImporterProgressView: View {
//    static private let itemFields: [ItemKey] = [
//        ItemKey("customer.name"),
//        ItemKey("customer.lastName"),
//        ItemKey("customer.phone"),
//        ItemKey("customer.email"),
//        ItemKey("description"),
//        ItemKey("date"),
//        ItemKey("price"),
//        ItemKey("notes"),
//        ItemKey("state")
//    ]
//    let file: URL
//    let shouldErase: Bool
//
//    @State var matchers: [ItemMatcher] = []
//    @State var backupObjectKeys: [ItemKey] = []
//
//    init(file: URL, shouldErase: Bool) {
//        self.file = file
//        self.shouldErase = shouldErase
//    }
//
//    var body: some View {
//        VStack {
//            List {
//                HStack{
//                    ForEach($matchers) { matcher in
//                        VStack {
//                            //                            Text(matcher.key)
//                            Picker("", selection: matcher.importerKey) {
//                                Text("").tag(nil as String?)
//                                ForEach(backupObjectKeys) { item in
//                                    Text(item.key).tag(item)
//                                }
//                            }
//                        }
//                    }
//                    //                    ForEach(0..<9) { index in
//                    //                        VStack{
//                    //                            Text(ImporterProgressView.itemFields[index].key)
//                    //                            Picker("", selection: $pickerSelections[index]) {
//                    //                                Text("").tag(nil as String?)
//                    //                                ForEach(backupObjectKeys) { item in
//                    //                                    Text(item.key).tag(item)
//                    //                                }
//                    //                            }
//                    //                        }
//                    //                    }
//                }
//            }
//
//            Spacer()
//            HStack {
//                Spacer()
//                Button("Cancel", role: .cancel, action:{})
//                NavigationLink("Next") {
//                    ConclusionView()
//                }
//            }.frame(alignment: .bottomTrailing)
//        }
//        .padding()
//        .navigationBarBackButtonHidden(true)
//        .onAppear(perform: {
//            // Open the file.
//            do {
//                let items = try self.getItemsFromFile(file)
//                if items.isEmpty {
//                    return
//                }
//
//                matchers = items.first!.keys.map({ item in
//                    ItemMatcher(key: item)
//                })
//
//                backupObjectKeys = items.first!.keys.map({ item in
//                    ItemKey(item)
//                })
//            }
//            catch let error{
//                print("Error while importing \(error)")
//            }
//        })
//    }
//}
