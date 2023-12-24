//
//  ImportScene.swift
//  Riparazioni
//
//  Created by Francesco Romano on 24/12/2023.
//

import Swift
import SwiftUI

struct ImportSceneView: View {
    @Environment(\.controlActiveState) private var controlActiveState
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var appDelegate: AppDelegate
    @State private var hasTheViewBecameKey: Bool = false
    
    var body: some View {
        NavigationStack {
            ImporterIntroView()
        }
        .onChange(of: controlActiveState) { newValue in
            // macOS 14+ has a dismissWindowAction that can remove this logic.
            switch newValue {
            case .key, .active:
                hasTheViewBecameKey = true
                break
            case .inactive: ()
                // Act only if the view was key.
                if !hasTheViewBecameKey {
                    return
                }
                // Open the main window, and re-enable the quitting app.
                openWindow(id:"main_window")
                appDelegate.shouldQuitAfterClosingWindow = true
            @unknown default:
                break
            }
        }
    }
}

struct ImportSceneView_Previews: PreviewProvider {
    static var previews: some View {
        ImportSceneView()
    }
}
