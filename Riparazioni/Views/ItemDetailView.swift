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
                    Text("Pending").tag(ItemState.pending(""))
                    Text("Completed").tag(ItemState.completed(""))
                    Text("Collected").tag(ItemState.collected)
                }
                // Show the text field only if the state is Pending or Completed.
                TextField("Details:", text: $stateAdditionalText).opacity((
                    selectedState == .pending("") || selectedState == .completed("")
                ) ? 1 : 0)
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
                case .pending(let string):
                    selectedState = .pending("")
                    stateAdditionalText = string
                case .completed(let string):
                    selectedState = .completed("")
                    stateAdditionalText = string
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
            item.state = .pending(stateAdditionalText)
        } else if case .completed = selectedState {
            item.state = .completed(stateAdditionalText)
        }
    }
}

struct NewItemView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailView(item: .constant(Item()),
                       shouldSaveChanges: {item in })
    }
}
