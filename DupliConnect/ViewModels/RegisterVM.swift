//
//  RegisterVM.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import Foundation
import UIKit
import FirebaseAuth

class RegisterVM {
    var success: ((User) -> ())?
    var error: ((String) -> ())?
    
    func createAccount(firstName: String, lastName: String, email: String, profilePhoto: UIImage?, password: String) {
        DatabaseManager.shared.userExists(with: email) { [weak self] exists in
            guard let self = self, !exists else {
                self?.error?("Looks like a user account for that email address already exists.")
                return
            }
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { result, err in
                guard let result = result, err == nil else {
                    self.error?(err?.localizedDescription ?? "An unexpected error has occurred. Try again.")
                    return
                }
                let chatUser = ChatAppUser(firstName: firstName,
                                           lastName: lastName,
                                           emailAddress: email)
                
                DatabaseManager.shared.insertUser(with: chatUser, comletion: { success in
                    if success {
                        //upload image
                        guard let image = profilePhoto, let data = image.pngData() else {
                            return
                        }
                        let fileName = chatUser.profilePictureFileName
                        
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, complation: { result in
                            switch result {
                            case .success(let downLoadUrl):
                                UserDefaults.standard.set(downLoadUrl, forKey: "profile_picture_url")
                                print(downLoadUrl)
                            case .failure(let err):
                                self.error?("Storege Manager error: \(err)")
                            }
                        })
                    }
                })
                let user = result.user
                self.success?(user)
            })
        }
    }
    
}
