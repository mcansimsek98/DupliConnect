//
//  LoginVM.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import Foundation
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import Firebase

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
                                                         parameters: ["fields": "email,first_name,last_name,picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completion: { _, result, err in
            guard let result = result as? [String: Any], err == nil else {
                self.error?(err?.localizedDescription ?? "Failed to make facebook graph request")
                return
            }
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else {
                      self.error?("Faield to get email and name from fb result.")
                      return
                  }
            print(result)
            return
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, comletion: { success in
                        if success {
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            URLSession.shared.dataTask(with: url, completionHandler: {data, _, _ in
                                guard let data = data else {
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
                            }).resume()
                        }
                    })
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
    
    func singInWithGoogle(_ vc: UIViewController) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: vc) { result, error in
            guard error == nil else {
                if let err = error {
                    self.error?(err.localizedDescription)
                }
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString,
                  let email = user.profile?.email,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName
            else {
                return
            }
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, comletion: { success in
                        if success {
                            //upload image
                            if let hasImage = user.profile?.hasImage, hasImage {
                                guard let url = user.profile?.imageURL(withDimension: 200) else {
                                    return
                                }
                                URLSession.shared.dataTask(with: url, completionHandler: {data, _, _ in
                                    guard let data = data else {
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
                                }).resume()
                            }
                        }
                    })
                }
            })
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { result, error in
                guard let result = result, error == nil else {
                    if let err = error {
                        self.error?(err.localizedDescription)
                    }
                    return
                }
                let user = result.user
                self.success?(user)
            })
        }
    }
}
