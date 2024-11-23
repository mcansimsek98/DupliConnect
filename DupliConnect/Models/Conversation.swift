//
//  Conversation.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 10.09.2023.
//

import Foundation

struct Conversation: Equatable {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.id == rhs.id
    }
}
