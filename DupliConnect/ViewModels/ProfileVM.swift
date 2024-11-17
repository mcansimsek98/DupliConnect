//
//  ProfileVM.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 10.09.2023.
//

import Foundation
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class ProfileVM {
    var signOut: ((Bool) -> ())?

    
    func singOutUser(completion: @escaping (Bool) -> Void) {
        UserDefaults.standard.setValue(nil, forKey: "email")
        UserDefaults.standard.setValue(nil, forKey: "name")
        
        do {
            //Log Out Facebook
            FBSDKLoginKit.LoginManager().logOut()
            
            //Log Out Google
            GIDSignIn.sharedInstance.signOut()
            
            //Log Out Firebase
            try FirebaseAuth.Auth.auth().signOut()
            completion(true)
        }catch {
            completion(false)
        }
    }
    
    func fetchUserPhoto(completion: @escaping (URL?) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        StorageManager.shared.downloadUrl(for: path) { result in
            switch result {
            case .failure(let error):
                print(error)
                completion(nil)
            case .success(let url):
                completion(url)
            }
        }
    }
}
