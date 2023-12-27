//
//  LoginView.swift
//  Riparazioni
//
//  Created by Francesco Romano on 27/12/2023.
//

import SwiftUI
import GoogleSignInSwift
import GoogleSignIn


struct LoginView: View {
    @EnvironmentObject var userAuthenticator: UserAuthentication
    @Environment(\.dismiss) private var dismiss
    
    @State var loginInProgress: Bool = false
    @State var showErrorAlert: Bool = false
    @State var errorMessage: String = ""
    
    var body: some View {
        VStack{
            Text("Login in Riparazioni")
                .fontWeight(.bold)
                .padding(.bottom)
            ZStack {
                GoogleSignInButton(action: handleSignInButton)
                    .disabled(loginInProgress)
                    .opacity(loginInProgress ? 0 : 1)
                ProgressView().opacity(loginInProgress ? 1 : 0)
            }}.padding()
            .alert("Login Error",
                   isPresented: $showErrorAlert,
                   actions: {}, message: {
                Text(errorMessage)
            })
    }
    
    func handleSignInButton() {
        loginInProgress = true
        
        let window = NSApplication.shared.keyWindow!
        userAuthenticator.doLogin(withPresentingWindow: window, callback: {error in
            if error == nil {
                dismiss()
            } else {
                errorMessage = error!.localizedDescription
                showErrorAlert.toggle()
            }
            loginInProgress = false
        })
    }
}

#Preview {
    LoginView()
}
