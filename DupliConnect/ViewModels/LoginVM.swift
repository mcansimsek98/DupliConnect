//
//  LoginVM.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import Foundation
import FirebaseAuth
import FBSDKLoginKit

class LoginVM {
    var success: ((User) -> ())?
    var error: ((String) -> ())?
    
    func signIn(email: String, password: String) {
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { result, err in
            guard let result = result, err == nil else {
                self.error?(err?.localizedDescription ?? "An unexpected error has occurred. Try again.")
                return
            }
            let user = result.user
            self.success?(user)
        }
    }
    
    func singInWithFacebook(token: String) {
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, name"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completion: { _, result, err in
            guard let result = result as? [String: Any], err == nil else {
                self.error?(err?.localizedDescription ?? "Failed to make facebook graph request")
                return
            }
            guard let userName = result["name"] as? String,
                  let email = result["email"] as? String else {
                self.error?("Faield to get email and name from fb result.")
                return
            }
            let nameComponents = userName.components(separatedBy: " ")
            guard nameComponents.count >= 2 else {
                return
            }
            let firstName = nameComponents.dropLast().joined(separator: " ")
            let lastName = nameComponents.last!
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName,
                                                                        lastName: lastName,
                                                                        emailAddress: email))
                }
            })
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { result, err in
                guard let result = result, err == nil else {
                    if let err = err {
                        self.error?(err.localizedDescription)
                    }
                    return
                }
                let user = result.user
                self.success?(user)
            })
        })
    }
}
