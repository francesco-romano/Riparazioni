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
// - Undo manager
// - Schermata di loading
// - Manage remotes updates

//class AppDelegate: NSObject, NSApplicationDelegate {
//    func applicationDidFinishLaunching(_ notification: Notification) {
//    }
//}

@main
struct RiparazioniApp: App {
    // Register app delegate for Firebase setup.
//    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
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
