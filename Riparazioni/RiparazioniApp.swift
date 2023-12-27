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
import FirebaseAuth
import GoogleSignIn


// TODO:
// - Undo manager -- How to fix the Redo, how to handle errors in undo.
// - Schermata di loading
// - Some validation.

//https://developers.google.com/identity/sign-in/ios/sign-in
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var shouldQuitAfterClosingWindow: Bool = true
    var userAuthentication: UserAuthentication?
    
    @Published var authRestorationError: Error? = nil

    func applicationWillFinishLaunching(_ notification: Notification) {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            guard let user = user else {
                self.authRestorationError = error
                print("Firebase error: \(error!.localizedDescription)")
                return
            }
            self.userAuthentication?.authenticateFirebase(user: user, callback: {firebaseAuthError in
                if firebaseAuthError != nil {
                    self.authRestorationError = firebaseAuthError
                    print("Firebase error: \(firebaseAuthError!.localizedDescription)")
                }
            } )
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return shouldQuitAfterClosingWindow
    }
    
//    func application(_ application: NSApplication,open urls: [URL]) {
//        print("URL")
//        for url in urls {GIDSignIn.sharedInstance.handle(url)}
//    }
}

@main
struct RiparazioniApp: App {
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private let dataManager: DataManager
    private let userAuthentication: UserAuthentication
    
    init() {
        // Initialize Firebase.
        FirebaseApp.configure()
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Client ID unavailable.")
            exit(EXIT_FAILURE)
        }
        dataManager = DataManager()
        userAuthentication = UserAuthentication(clientID)
        appDelegate.userAuthentication = userAuthentication
    }
    
    var body: some Scene {
        Window("Riparazioni", id:"main_window") {
                MainWindowView()
                .environmentObject(dataManager)
                .environmentObject(userAuthentication)
        }.commands{
            CommandGroup(replacing: .importExport) {
                Button("Import", action:{
                    // Disable quitting when closing the main window
                    appDelegate.shouldQuitAfterClosingWindow = false
                    NSApplication.shared.keyWindow?.close()
                    openWindow(id: "import_window")
                })}
            CommandGroup(after: .importExport) {
                Button("Logout", action:{
                    userAuthentication.signOut()
                })
            }
        }
        Window("Import", id:"import_window") {
            ImportSceneView().environmentObject(dataManager)
            
        }.commandsRemoved()
        
    }
}
