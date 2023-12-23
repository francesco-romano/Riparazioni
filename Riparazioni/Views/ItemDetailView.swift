//
//  NewItemView.swift
//  Riparazioni
//
//  Created by Francesco Romano on 20/12/2023.
//

import SwiftUI

struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var item: Item
    let shouldSaveChanges: (_ item: Item) -> Void
    
    @State private var selectedState: ItemState = .new
    @State private var stateAdditionalText: String = ""
    @State private var completedHasDate: Bool = false
    @State private var stateAdditionalDate: Date = Date()
    @State private var dummyDate = Date()
    // TODO: add additional info here.
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $item.customer.name)
                TextField("Last name", text: $item.customer.lastName)
                TextField("Email", text: $item.customer.email)
                TextField("Phone", text: $item.customer.phone)
            }
            Section {
                TextField("Description", text: $item.description)
                DatePicker("Date", selection: $item.date, displayedComponents: [.date])
                TextField("Price", value: $item.price, format: .number.precision(.fractionLength(2)))
                
                Picker("State", selection:$selectedState) {
                    Text("New").tag(ItemState.new)
                    Text("Pending").tag(ItemState.pending("", dummyDate))
                    Text("Completed").tag(ItemState.completed("", nil))
                    Text("Collected").tag(ItemState.collected(dummyDate))
                }
                HStack {
                    switch selectedState {
                    case .pending(_, _):
                        TextField("Details:", text: $stateAdditionalText)
                        DatePicker("Pending Date", selection: $stateAdditionalDate, displayedComponents: [.date])
                    case .completed(_,_):
                        TextField("Details:", text: $stateAdditionalText)
                        Toggle(isOn: $completedHasDate){
                            Text("Being notified?")
                        }.toggleStyle(.checkbox)
                        DatePicker("", selection: $stateAdditionalDate, displayedComponents: [.date]).opacity(completedHasDate ? 1 : 0)
                    case .collected(_):
                        DatePicker("Collection Date", selection: $stateAdditionalDate, displayedComponents: [.date])
                    default: EmptyView()
                    }
                }
                TextField("Notes", text: $item.notes)
                
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel, action:{
                    // This will cancel the view.
                    dismiss()
                })
                Button("Save", action:{
                    // Update the state.
                    self.updateItemState()
                    self.shouldSaveChanges(item)
                }).keyboardShortcut(.defaultAction)
            }
        }.formStyle(.grouped)
            .padding()
            .onAppear(perform: {
                // Update the selected state depending on the item.state.
                // We need to remove the associated value.
                switch item.state {
                case .pending(let string, let date):
                    selectedState = .pending("", dummyDate)
                    stateAdditionalText = string
                    stateAdditionalDate = date
                case .completed(let string, let date):
                    selectedState = .completed("", nil)
                    stateAdditionalText = string
                    completedHasDate = date != nil
                    stateAdditionalDate = date ?? Date()
                case .collected(let date):
                    selectedState = .collected(dummyDate)
                    stateAdditionalDate = date
                default:
                    // No associated value. Just assign the state.
                    selectedState = item.state
                }
                
            })
    }
    
    // Updates the item.state enum with the additional information.
    private func updateItemState() -> Void {
        item.state = selectedState
        if case .pending = selectedState {
            item.state = .pending(stateAdditionalText, stateAdditionalDate)
        } else if case .completed = selectedState {
            item.state = .completed(stateAdditionalText, stateAdditionalDate)
        } else if case .collected = selectedState {
            item.state = .collected(stateAdditionalDate)
        }
    }
}

struct NewItemView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailView(item: .constant(Item()),
                       shouldSaveChanges: {item in })
    }
}
