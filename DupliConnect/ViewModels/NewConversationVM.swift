//
//  NewConversationVM.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 30.08.2023.
//

import Foundation


class NewConversationVM {
    var users: (([[String: String]]) -> ())?
    var filterUsers: (([[String: String]]) -> ())?
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
        guard hasFetched else {
            return
        }
        
        let results: [[String: String]] = users.filter({
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        })
        self.filterUsers?(results)
    }
    
}