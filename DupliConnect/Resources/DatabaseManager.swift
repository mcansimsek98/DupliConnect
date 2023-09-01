//
//  DatabaseManager.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

// MARK: ACCOUNT MANAGMENT
extension DatabaseManager {
    ///
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { shapshot in
            guard shapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Insert new user to database
    public func insertUser(with user: ChatAppUser, comletion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "firstName": user.firstName,
            "lastName": user.lastName
        ], withCompletionBlock: {error, databaseRef in
            guard error == nil else {
                print("Failed ot write to database")
                comletion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String:String]] {
                    // append to user dictionary
                    let newElement: [[String:String]] = [
                        ["name": user.firstName + " " + user.lastName,
                         "email": user.safeEmail
                        ]
                    ]
                    usersCollection.append(contentsOf: newElement)
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error,_ in
                        guard error == nil else {
                            comletion(false)
                            return
                        }
                        comletion(true)
                    })
                }else {
                    // create that array
                    let newCollection: [[String:String]] = [
                        ["name": user.firstName + " " + user.lastName,
                         "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error,_ in
                        guard error == nil else {
                            comletion(false)
                            return
                        }
                        comletion(true)
                    })
                }
            })
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}

// MARK: SENDING MASSAGES / CONVERSATİONS
extension DatabaseManager {
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completaion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completaion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = Date.dateFormaterMessage.string(from: messageDate)
            let conversationId = "conversation_\(firstMessage.messageId)"
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ] as [String : Any]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user
                // you should append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] err,_ in
                    guard err == nil else {
                        completaion(false)
                        return
                    }
                    completaion(true)
                    self?.finishCreatingConversation(conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     complation: completaion)
                })
            }else {
                // conversation array does not exist
                // create it
                userNode["conversations"] = [newConversationData]
                ref.setValue(userNode, withCompletionBlock: { [weak self] err,_ in
                    guard err == nil else {
                        completaion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     complation: completaion)
                    completaion(true)
                })
            }
        })
    }
    
    private func finishCreatingConversation(conversationID: String, firstMessage: Message, complation: @escaping (Bool) -> Void) {
        let messageDate = firstMessage.sentDate
        let dateString = Date.dateFormaterMessage.string(from: messageDate)
        var content = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            content = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            complation(false)
            return
        }
        let currenUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)

        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": content,
            "date": dateString,
            "sender_email": currenUserEmail,
            "isRead": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("adding conversation: \(conversationID)")
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { err, _ in
            guard err == nil else {
                complation(false)
                return
            }
            complation(true)
        })
    }
    
    /// Fetcehes and returns all conversations for the user with passed email
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
    
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}
