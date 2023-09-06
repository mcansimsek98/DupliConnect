//
//  NewConversationVM.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 30.08.2023.
//

import Foundation


class NewConversationVM {
    var users: (([[String: String]]) -> ())?
    var filterUsers: (([SearchResult]) -> ())?
    var error: ((String) -> ())?
    
    private var hasFetched = false
    
    func searchUsers(query: String) {
        if hasFetched {
            
        }else {
            DatabaseManager.shared.getAllUsers(completion: { result in
                switch result {
                case .success(let users):
                    self.hasFetched = true
                    self.users?(users)
                    self.filetUsers(with: query, users: users)
                case .failure(let err):
                    self.error?(err.localizedDescription)
                }
            })
        }
    }
    
    func filetUsers(with term: String, users: [[String: String]]) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let results: [SearchResult] = users.filter({
            guard let email = $0["email"],
                  let name = $0["name"]?.lowercased(),
                  email != safeEmail else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"],
                  let name = $0["name"] else {
                return nil
            }
            return SearchResult(name: name, email: email)
        })
        self.filterUsers?(results)
    }
    
}
