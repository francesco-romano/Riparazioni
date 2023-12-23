//
//  RiparazioniApp.swift
//  Riparazioni
//
//  Created by Francesco Romano on 10/12/2023.
//

import SwiftUI
import Swift
import FirebaseCore
import FirebaseFirestore


// TODO:
// - Undo manager -- How to fix the Redo, how to handle errors in undo.
// - Schermata di loading

@main
struct RiparazioniApp: App {    
    init() {
        // Initialize Firebase.
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        Window("Riparazioni", id:"main_window") {
            MainWindowView().environmentObject(DataManager())
        }
    }
}
