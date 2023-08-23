//
//  LoginVM.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import Foundation
import FirebaseAuth

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
}
