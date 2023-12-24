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
// - Some validation.

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var shouldQuitAfterClosingWindow: Bool = true
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return shouldQuitAfterClosingWindow
    }
}

@main
struct RiparazioniApp: App {
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private let dataManager: DataManager
    
    init() {
        // Initialize Firebase.
        FirebaseApp.configure()
        dataManager = DataManager()
    }
    
    var body: some Scene {
        Window("Riparazioni", id:"main_window") {
            MainWindowView().environmentObject(dataManager)
        }.commands{
            CommandGroup(replacing: .importExport) {
                Button("Import", action:{
                    // Disable quitting when closing the main window
                    appDelegate.shouldQuitAfterClosingWindow = false
                    NSApplication.shared.keyWindow?.close()
                    openWindow(id: "import_window") 
                })
            }
        }
        Window("Import", id:"import_window") {
            ImportSceneView().environmentObject(dataManager)
            
        }.commandsRemoved()
        
    }
}
