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
    
    @State var email: String = ""
    @State var password: String = ""
    
    var body: some View {
        VStack{
            Text("Login in Riparazioni")
                .fontWeight(.bold)
                .padding(.bottom)
            ZStack {
                VStack {
                    Form{
                        TextField("Email", text: $email)
                            .frame(minWidth: 250)
                        SecureField("Password", text: $password)
                        Button("Login", action:handleEmailPasswordLogin).keyboardShortcut(.defaultAction)
                    }
                    Text("Or login using a provider")
                    GoogleSignInButton(action: handleGoogleSSOButton)
                        .disabled(loginInProgress)
                        .padding(.horizontal)
                }.opacity(loginInProgress ? 0 : 1)
                ProgressView().opacity(loginInProgress ? 1 : 0)
            }
            Spacer()
            HStack {
                Spacer()
                Button("Quit", action: {
                    exit(EXIT_SUCCESS)
                })
            }.padding(.top)
        }.padding()
            .alert("Login Error",
                   isPresented: $showErrorAlert,
                   actions: {}, message: {
                Text(errorMessage)
            })
    }
    
    func handleEmailPasswordLogin() {
        loginInProgress = true
        userAuthenticator.doLogin(email: email, password: password, callback: {error in
            if error == nil {
                dismiss()
            } else {
                errorMessage = error!.localizedDescription
                showErrorAlert.toggle()
            }
            loginInProgress = false
        })
    }
    
    func handleGoogleSSOButton() {
        loginInProgress = true
        
        let window = NSApplication.shared.keyWindow!
        userAuthenticator.doGoogleSSOLogin(withPresentingWindow: window, callback: {error in
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
