//
//  MainWindowView.swift
//  Riparazioni
//
//  Created by Francesco Romano on 18/12/2023.
//

import SwiftUI
import GoogleSignIn

private struct ItemDetailError {
    var alertShown: Bool = false
    var alertTitle: String = ""
    var alertMessage: String = ""
}

struct ItemStateSorter: SortComparator {
    var order: SortOrder = .forward
    
    func compare(_ lhs: ItemState, _ rhs: ItemState) -> ComparisonResult {
        let tagFromEnum: ((ItemState) -> Int) = { state in
            switch state {
            case .new:
                return 1
            case .pending:
                return 2
            case .completed:
                return 3
            case .collected:
                return 4
            }
        }
        
        let reverseResult: ((ComparisonResult) -> ComparisonResult) = { result in
            switch result {
            case .orderedAscending: return .orderedDescending
            case .orderedSame: return .orderedSame
            case .orderedDescending: return .orderedAscending
            }
        }
        
        let lhsTagValue = tagFromEnum(lhs)
        let rhsTagValue = tagFromEnum(rhs)
        
        // Address the case the enums are different.
        if lhsTagValue < rhsTagValue {
            return order == .forward ? .orderedAscending : .orderedDescending
        }
        if lhsTagValue > rhsTagValue {
            return order == .forward ? .orderedDescending : .orderedAscending
        }
        
        // Enums are the same. Compare the associated value.
        var result: ComparisonResult
        switch (lhs, rhs) {
        case (.new, .new):
            result = .orderedSame
        case (.pending(let lhsLocation, let lhsDate), .pending(let rhsLocation, let rhsDate)):
            result = lhsLocation.localizedCompare(rhsLocation)
            if result == .orderedSame  {
                result = lhsDate.compare(rhsDate)
            }
        case (.completed(let lhsLocation, let lhsDate), .completed(let rhsLocation, let rhsDate)):
            result = lhsLocation.localizedCaseInsensitiveCompare(rhsLocation)
            if result == .orderedSame  {
                if rhsDate == nil && lhsDate != nil {
                    result = .orderedAscending
                } else if rhsDate != nil && lhsDate == nil {
                    result = .orderedDescending
                } else if rhsDate != nil && lhsDate != nil {
                    result = lhsDate!.compare(rhsDate!)
                }
            }
        case (.collected(let lhsDate), .collected(let rhsDate)):
            result = lhsDate.compare(rhsDate)
        default:
            result = .orderedSame
        }
        return order == .forward ? result : reverseResult(result)
    }
    
}

struct MainWindowView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var userAuthentication: UserAuthentication
    @Environment(\.undoManager) var undoManager
    
    // Table and searchable.
    @State private var searchedQuery: String = ""
    @SceneStorage("show_collected") private var showCollected: Bool = false
    @State var selectedItemID: Item.ID?  // TODO: allow multiple selection for e.g. remove items. The detail view can hide details.
    @State private var sortOrder = [KeyPathComparator(\Item.date, order: .reverse)]
    @State private var itemStateSorter = ItemStateSorter()
    
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
    // Signout confirmation
    @State private var showUserDetails: Bool = false
    
    @AppStorage("login_enabled") private var loginEnabled = false
    
    private var shouldShowLoginWindow: Binding<Bool> { Binding( get: {
        loginEnabled && dataManager.errorFetchingData
    }, set: {_ in }
    )
    }
    
    private var shouldShowFetchErrorAlert: Binding<Bool> { Binding( get: {
        !loginEnabled && dataManager.errorFetchingData
    }, set: {_ in }
    )
    }
    
    
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
        }.sheet(isPresented: shouldShowLoginWindow, content: {
            LoginView().environmentObject(userAuthentication)
        }).alert("Failed connecting to the DB", isPresented: shouldShowFetchErrorAlert) {
            Button("OK") {
                NSApplication.shared.terminate(nil)
            }
        } message: {
            Text("Please check your DB permissions and credentials.")
        }
    }
    
    var itemsTable: some View {
        // TODO: macOS 14+ https://developer.apple.com/documentation/SwiftUI/TableColumnCustomization
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
            TableColumn("Location", value: \.state, comparator: itemStateSorter) {
                item in Text(item.state.description)
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
            Button(action: {
                showUserDetails.toggle()
            }) {
                Image(systemName: "person.badge.shield.checkmark")
                Text(userAuthentication.userDisplayName ?? "No user")
            }.popover(isPresented: $showUserDetails, content: {
                UserDetailView(user: userAuthentication.user!, doLogout: {
                    userAuthentication.signOut()
                })
            }).disabled(userAuthentication.user == nil)
            Spacer()
            Text("Items \(items.count) / \(dataManager.items.count)")
            Spacer()
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
            }.keyboardShortcut(KeyboardShortcut("n", modifiers: [.command]))
                .sheet(isPresented: $showAddItemView) {
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
                if case .collected(_) = selectedItem.state {
                    return
                }
                
                selectedItem.state = .collected(Date())
                dataManager.saveChangesToItem(selectedItem, withId: selectedItem.id!)
            }) {
                Text("Mark as collected")
                Image(systemName: "checkmark.seal")
            }.keyboardShortcut(KeyboardShortcut("r", modifiers: [.command]))
                .disabled(selectedItem == nil)
            Spacer()
            Button(action: {
                showItemDetailView = true
                detailViewItem.copyFrom(selectedItem ?? Item())
            }) {
                Text("Details")
                Image(systemName: "info.circle")
            }
            .keyboardShortcut(KeyboardShortcut("i", modifiers: [.command]))
            .disabled(selectedItem == nil)
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
            if case .collected(_) = item.state {
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

struct MainWindowView_Previews: PreviewProvider {
    static var previews: some View {
        MainWindowView().environmentObject(DataManager.SampleManager())
    }
}
