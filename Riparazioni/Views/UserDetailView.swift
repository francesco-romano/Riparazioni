//
//  UserDetailView.swift
//  Riparazioni
//
//  Created by Francesco Romano on 27/12/2023.
//

import SwiftUI
import FirebaseAuth

struct UserDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var showSignoutConfirmation: Bool = false

    let user: FirebaseAuth.User
    let doLogout: (() -> Void)
    
    var body: some View {
        VStack {
            AsyncImage(url: user.photoURL)
                .padding()
            Text(user.displayName ?? "")
            Text(user.email ?? "")
            Spacer()
            Button("Logout", action: {showSignoutConfirmation.toggle()})
        }.padding()
            .confirmationDialog("Do you want to logout?", isPresented: $showSignoutConfirmation, actions: {
                Button("Logout", role: .destructive) {
                    doLogout()
                }
//                dismiss()
            })
    }
}
