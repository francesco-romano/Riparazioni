//
//  UserAuthentication.swift
//  Riparazioni
//
//  Created by Francesco Romano on 27/12/2023.
//

import Foundation
import GoogleSignIn
import FirebaseAuth

struct LoginError: Error {
}


class UserAuthentication: ObservableObject {
    private let clientID: String
    
    @Published var user: FirebaseAuth.User?
    // Expose some properties as User is not an observable object.
    @Published var userDisplayName: String?
    
    init(_ clientID: String) {
        self.clientID = clientID
        
        let config = GIDConfiguration(clientID: self.clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    // TODO: How to select the browser where to launch the auth?
    func doLogin(withPresentingWindow window: NSWindow, callback: @escaping ((Error?) -> Void)) {
        GIDSignIn.sharedInstance.signIn(
            withPresenting: window) { signInResult, error in
                guard let result = signInResult else {
                    callback(error)
                    return
                }
                
                self.authenticateFirebase(user: result.user, callback: callback)
            }
    }
    
    func authenticateFirebase(user: GIDGoogleUser, callback: @escaping ((Error?) -> Void)) {
        guard let idToken = user.idToken?.tokenString
        else {
            callback(LoginError())
            return
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString)
        
        Auth.auth().signIn(with: credential) { result, error in
            self.user = result?.user
            // Update also the properties.
            self.userDisplayName = self.user?.displayName
            // If there is no error, this will be nil, which is ok.
            callback(error)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}
