//
//  ImporterIntroView.swift
//  Riparazioni
//
//  Created by Francesco Romano on 24/12/2023.
//

import SwiftUI

// Support optional bindings.
func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

struct ImporterIntroView: View {
    @State private var filePathLabelString: String?
    @State private var chosenFile: URL?
    @State private var shouldErase: Bool = false
    @State private var showFilePicker: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Import items from backup")
            Spacer()
            Text("Select file and options").fontWeight(.bold)
            Form {
                HStack{
                    TextField("", text: $filePathLabelString ?? "No file selected").disabled(true).frame(maxWidth: 150)
                    Button("Choose file", action:{
                        showFilePicker.toggle()
                    })
                }
                .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.json] ) { result in
                    guard case let .success(file) = result else { return }
                    chosenFile = file
                    filePathLabelString = chosenFile?.lastPathComponent
                }
                Toggle("Erase current DB", isOn: $shouldErase)
            }
            Spacer()
            HStack {
                Spacer()
                Button("Cancel", role: .cancel, action:{
                    dismiss()
                })
                NavigationLink("Next", destination: {
                    ImporterProgressView(file: chosenFile ?? URL(string: "file:///dummy.json")!, shouldErase: shouldErase)
                }).disabled(chosenFile == nil)
            }.frame(alignment: .bottomTrailing)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

struct ImporterIntroView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack{
            ImporterIntroView()
        }
    }
}
