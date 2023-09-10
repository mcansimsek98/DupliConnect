//
//  ChatVM.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 10.09.2023.
//

import Foundation
import UIKit

class ChatVM {
    var error: ((String) -> ())?
    var createdNewConversation: ((String,Bool) ->())?
    
    func getAllMessages(id: String, completion: @escaping ([Message]) -> Void) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                completion(messages)
            case .failure(let err):
                strongSelf.error?(err.localizedDescription)
            }
        })
    }
    
    func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping (String) -> Void) {
        StorageManager.shared.uploadMessagePhoto(with: data, fileName: fileName, complation: { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let urlString):
                completion(urlString)
            case .failure(let err):
                strongSelf.error?(err.localizedDescription)
            }
        })
    }
    
    func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping (String) -> Void) {
        StorageManager.shared.uploadMessageVideo(with: fileUrl, fileName: fileName, complation: { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let urlString):
                completion(urlString)
            case .failure(let err):
                strongSelf.error?(err.localizedDescription)
            }
        })
    }
    
    func sendMessage(to conversationID: String?, otherUserEmail: String, name: String, sender: Sender, messageId: String, url: URL?, isVideo: Bool = false, isText: Bool = false, messageText: String? = nil, isNewConservation: Bool = false, isLocation: Bool = false, location: Location) {
        guard let placholder = UIImage(named: "failedImage") else {
            return
        }
        let media = Media(url: url ?? nil,
                          image: nil,
                          placeholderImage: placholder,
                          size: .zero)
        
        let message = Message(sender: sender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: isText ? .text(messageText ?? "") : isLocation ? .location(location) : isVideo ? .video(media) : .photo(media))
        if isNewConservation {
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: name, firstMessage: message, completaion: { [weak self] success in
                if success {
                    self?.createdNewConversation?(message.messageId,true)
                }else {
                    self?.error?("Failed to send message")
                }
            })
        }else {
            guard let conversationId = conversationID else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: { [weak self] success in
                if !success {
                    self?.error?("Failed to send message")
                }
                self?.createdNewConversation?(message.messageId,false)
            })
        }
    }
    
    
    func getAvatarImage(email: String, completion: @escaping (URL) -> Void) {
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let path = "images/\(safeEmail)_profile_picture.png"
        StorageManager.shared.downloadUrl(for: path, complation: { [weak self] result in
            switch result {
            case .success(let url):
               completion(url)
            case .failure(let err):
                self?.error?(err.localizedDescription)
            }
        })
    }
    
    
    func createMessageId(otherUserEmail: String) -> String? {
        // date, otherUserEmail, senderEmail, ramdomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeUserEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateStr = Date.dateFormaterMessage.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeUserEmail)_\(dateStr)"
        return newIdentifier
    }
}
