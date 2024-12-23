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
    
    func getUsers() {
        DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let users):
                strongSelf.hasFetched = true
                
                strongSelf.filterUsers?(users.compactMap({
                    guard let email = $0["email"],
                          let name = $0["name"] else {
                        return nil
                    }
                    return SearchResult(name: name, email: email)
                }).sorted(by: {$0.name < $1.name}))
            case .failure(let err):
                strongSelf.error?(err.localizedDescription)
            }
        })
    }
    
    func searchUsers(query: String) {
        if hasFetched {
            
        }else {
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let users):
                    strongSelf.hasFetched = true
                    strongSelf.users?(users)
                    strongSelf.filetUsers(with: query, users: users)
                case .failure(let err):
                    strongSelf.error?(err.localizedDescription)
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
        filterUsers?(results)
    }
    
}
