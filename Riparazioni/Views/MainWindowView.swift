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
    // Delete confirmation.
    @State private var showShouldDeleteItemAlert: Bool = false
    @State private var shouldDeleteItemAlertTitle: String = ""
    
    var body: some View {
        VStack {
            self.itemsTable
                .onDeleteCommand(perform: selectedItem == nil ? nil : {
                    guard selectedItemID != nil else { return }
                    showShouldDeleteItemAlert = true
                    shouldDeleteItemAlertTitle = "Delete \(selectedItem?.customer.fullName ?? "")"
                })
                .searchable(text: $searchedQuery)
                .padding()
                .toolbar {
                    self.toolbar
                }
                .confirmationDialog(
                    shouldDeleteItemAlertTitle,
                    isPresented: $showShouldDeleteItemAlert
                ) {
                    Button("Delete", role: .destructive) {
                        dataManager.deleteItem(selectedItem!)
                    }
                    Button("Cancel", role: .cancel) {
                        showShouldDeleteItemAlert = false
                    }
                }
        }.onAppear {
            dataManager.loadItems()
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
            // TODO: a connection statuscheckmark.seal.fill
            Button(action: {
                showCollected.toggle()
            }) {
                if (showCollected) {
                    Text("Hide collected")
                    Image(systemName: "eye.slash")
                } else {
                    Text("Show collected")
                    Image(systemName: "eye")
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
            // Mark item as collected
            Button(action:{
                guard let selectedItem = selectedItem else { return }
                if selectedItem.state == .collected {
                    return
                }
                selectedItem.state = .collected
                dataManager.saveChangesToItem(selectedItem, withId: selectedItem.id!)
            }) {
                Text("Mark as collected")
                Image(systemName: "checkmark.seal")
            }.disabled(selectedItem == nil)
            Spacer()
            Button(action: {
                showItemDetailView = true
                detailViewItem.copyFrom(selectedItem ?? Item())
            }) {
                Text("Details")
                Image(systemName: "info.circle")
            }.disabled(selectedItem == nil)
                .sheet(isPresented: $showItemDetailView) {
                    ItemDetailView(item: $detailViewItem, shouldSaveChanges: { item in
                        // Save the old item in case we need to undo the operation.
                        let oldItem: Item = selectedItem!
                        let result = dataManager.saveChangesToItem(item, withId: selectedItemID!!)
                        guard case let .failure(errorMessage) = result else {
                            // Register the operation in the UndoManager.
                            undoManager?.registerUndo(withTarget: dataManager, handler: { manager in
                                dataManager.saveChangesToItem(oldItem, withId: oldItem.id!)
                                // TODO: What in case of error?
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
