//
//  MainWindowView.swift
//  Riparazioni
//
//  Created by Francesco Romano on 18/12/2023.
//

import SwiftUI

private struct ItemDetailError {
    var alertShown: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
}

struct MainWindowView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.undoManager) var undoManager
    
    // Table and searchable.
    @State private var searchedQuery: String = ""
    @SceneStorage("show_collected") private var showCollected: Bool = false
    @State var selectedItemID: Item.ID?  // TODO: allow multiple selection for e.g. remove items. The detail view can hide details.
    @State private var sortOrder = [KeyPathComparator(\Item.date, order: .reverse)]
    
    // Detail view. They need two different variables because they are independent.
    // Add.
    @State private var showAddItemView: Bool = false
    @State private var detailViewAddItem: Item = Item()
    // Edit.
    @State private var showItemDetailView: Bool = false
    @State private var detailViewItem: Item = Item()
    @State private var itemDetailError: ItemDetailError = ItemDetailError()
    
    var body: some View {
        VStack {
            self.itemsTable
            .searchable(text: $searchedQuery)
            .padding()
            .toolbar {
                self.toolbar
            }
        }.task {
            await dataManager.loadItems()
        }
    }
    
    var itemsTable: some View {
        Table(selection: $selectedItemID, sortOrder: $sortOrder) {
            TableColumn("Customer", value: \.customer.fullName)
            TableColumn("Date", value: \.date) { item in
                Text(item.date.formatted(date: .numeric, time: .omitted))
            }.width(min:80, ideal: 80)
            TableColumn("Description") {
                Text($0.description)
            }
            TableColumn("Price") { item in
                Text(item.price.formatted(
                    .currency(code:"EUR").locale(Locale(identifier: "it-IT"))))
            }.width(min:60, ideal: 60)
            // TODO: order by
            TableColumn("Location") {
                item in Text(itemStateHumanReadable(itemState:item.state))
                
            }
            TableColumn("Contact") {
                Text($0.customer.phone)
            }.width(min:100, ideal: 100)
            TableColumn("Notes") {
                Text($0.notes)
            }
        } rows: {
            ForEach(items) { item in
                TableRow(item)
                    .contextMenu(menuItems: {
                        Button("Hide", action:{})
                        Button("Remove", role:.destructive, action:{})
                        Divider()
                    })
            }
        }
    }
    
    var toolbar: some View {
        Group {
            // TODO: a connection status
            Button(action: {
                showCollected.toggle()
            }) {
                if (showCollected) {
                    Text("Hide collected")
                } else {
                    Text("Show collected")
                }
            }
            Spacer()
            Button(action:{
                // Reset the item to a clean one.
                detailViewAddItem = Item()
                showAddItemView.toggle()
            }) {
                Text("Add")
                Image(systemName: "plus")
            }.sheet(isPresented: $showAddItemView) {
                ItemDetailView(item: $detailViewAddItem, shouldSaveChanges: { item in
                    let result = dataManager.addNewItem(item)
                    guard case let .failure(errorMessage) = result else {
                        undoManager?.registerUndo(withTarget: dataManager, handler: { manager in
                            manager.deleteItem(item)
                        })
                        // Close sheet.
                        showAddItemView = false
                        return
                    }
                    itemDetailError.alertShown = true
                    itemDetailError.alertMessage = errorMessage
                    itemDetailError.alertTitle = "Save failed."
                    // Failed to save.
                    
                })
                .presentationDetents([.medium, .large])
                // Alert modifier must be attached to the sheet otherwise is not shown.
                .alert(itemDetailError.alertTitle,
                       isPresented: $itemDetailError.alertShown,
                       presenting: itemDetailError.alertMessage) {
                    message in
                    Button("Lose changes",  role: .destructive) {
                        showAddItemView = false
                    }
                } message: { message in
                    Text(message)
                }
            }
            // Remove item // Maybe hide?
            Button(action:{
                if self.selectedItem == nil {
                    print("No selection")
                } else {
                    print("Selected \(selectedItemID.debugDescription)")
                }
                
            }) {
                Text("Mark as collected")
                Image(systemName: "minus")
            }.disabled(selectedItemID == nil)
            Spacer()
            Button(action: {
                showItemDetailView = true
                detailViewItem.copyFrom(selectedItem ?? Item())
            }) {
                Text("Details")
                Image(systemName: "info.circle")
            }.disabled(selectedItemID == nil)
            .sheet(isPresented: $showItemDetailView) {
                ItemDetailView(item: $detailViewItem, shouldSaveChanges: { item in
                    let result = dataManager.saveChangesToItem(item, withId: selectedItemID!!)
                    guard case let .failure(errorMessage) = result else {
                        // We need to update the previous item with the new item.
                        let oldItemIndex = dataManager.items.firstIndex(
                            where: {anItem in anItem.id == selectedItemID!})
                        if oldItemIndex == nil {
                            print("Could not find the item. This should not happend")
                            return
                        }
                        let oldItem = dataManager.items[oldItemIndex!]
                        dataManager.items[oldItemIndex!] = item
                        
                        // Register the operation in the UndoManager.
                        undoManager?.registerUndo(withTarget: dataManager, handler: { manager in
                            // Update the list.
                            manager.items[oldItemIndex!] = oldItem
                            let result = dataManager.saveChangesToItem(oldItem, withId: oldItem.id!)
                            // TODO.
                        })
                        
                        // Close sheet.
                        showItemDetailView = false
                        return
                    }
                    itemDetailError.alertShown = true
                    itemDetailError.alertMessage = errorMessage
                    itemDetailError.alertTitle = "Save failed."

                })
                .presentationDetents([.medium, .large])
                // Alert modifier must be attached to the sheet otherwise is not shown.
                .alert(itemDetailError.alertTitle,
                       isPresented: $itemDetailError.alertShown,
                       presenting: itemDetailError.alertMessage) {
                    message in
                    Button("Lose changes",  role: .destructive) {
                        showItemDetailView = false
                    }
                } message: { message in
                    Text(message)
                }
            }

        }
    }
}

extension MainWindowView {
    var items: [Item] {
        dataManager.items.filter({item in
            var isCollected = false
            if case .collected = item.state {
                isCollected = true
            }
            
            // Modifier to the search. If it is collected we will filter depending
            // on the user property value.
            let showCollected = !isCollected || showCollected

            if searchedQuery.isEmpty {
                return showCollected
            }
            return showCollected && (item.customer.fullName.localizedCaseInsensitiveContains(searchedQuery) ||
            item.description.localizedCaseInsensitiveContains(searchedQuery))
        }).sorted(using: sortOrder)
    }
    
    var selectedItem: Item? {
        guard let selectedItemID = selectedItemID  else { return nil}
        return items.first(where: { item in
            item.id == selectedItemID
        })
    }
//    
//    func saveChangesToItem(_ item: Item, id: Item.ID) -> Void {
//        let result = dataManager.saveChangesToItem(item: item, withId: id!)
//        guard case let .failure(errorMessage) = result else {
//            // We need to update the previous item with the new item.
//            let oldItemIndex = dataManager.items.firstIndex(
//                where: {anItem in anItem.id == selectedItemID!})
//            if oldItemIndex == nil {
//                print("Could not find the item. This should not happend")
//                return
//            }
//            let oldItem = dataManager.items[oldItemIndex!]
//            dataManager.items[oldItemIndex!] = item
//            
//            // Register the operation in the UndoManager.
//            undoManager?.registerUndo(withTarget: self, handler: { weakSelf in
//                weakSelf.saveChangesToItem(oldItem, id: oldItem.id!)
//            })
//            
//            // Close sheet.
//            showItemDetailView = false
//            return
//        }
//        itemDetailError.alertShown = true
//        itemDetailError.alertMessage = errorMessage
//        itemDetailError.alertTitle = "Save failed."
//    }
}


func itemStateHumanReadable(itemState: ItemState) -> String {
    switch itemState {
    case .new:
        return ""
    case .pending(let pendingLocation):
        return "<Lavorazione>" + pendingLocation
    case .completed(let completedLocation):
        return "<Pronto>" + completedLocation
    case .collected:
        return "<Ritirato>"
    }
}

struct MainWindowView_Previews: PreviewProvider {
    static var previews: some View {
        MainWindowView().environmentObject(DataManager.SampleManager())
    }
}
