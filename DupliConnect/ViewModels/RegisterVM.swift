//
//  RegisterVM.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import Foundation
import FirebaseAuth

class RegisterVM {
    var success: ((User) -> ())?
    var error: ((String) -> ())?
    
    func createAccount(firstName: String, lastName: String, email: String, password: String) {
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { result, err in
            guard let result = result, err == nil else {
                self.error?(err?.localizedDescription ?? "An unexpected error has occurred. Try again.")
                return
            }
            let user = result.user
            self.success?(user)
            DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName,
                                                                lastName: lastName,
                                                                emailAddress: email))
        })
    }
    
}
