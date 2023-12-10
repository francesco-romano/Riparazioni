//
//  RiparazioniApp.swift
//  Riparazioni
//
//  Created by Francesco Romano on 10/12/2023.
//

import SwiftUI
import Swift
import FirebaseCore

class AppDelegate: NSObject, NSApplicationDelegate {
    private func applicationDidFinishLaunching(_ application: NSApplication) -> Void {
    FirebaseApp.configure()
  }
}

@main
struct RiparazioniApp: App {
    // Register app delegate for Firebase setup.
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
