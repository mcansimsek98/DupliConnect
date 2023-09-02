//
//  ChatVC.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 29.08.2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView


struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

class ChatVC: MessagesViewController {
    public let  otherUserEmail: String
    public var isNewConservation = false
    private let  converstaionsId: String?
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String,
              let name = UserDefaults.standard.value(forKey: "name") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        var userProfilePhotoUrlStr = ""
        return Sender(photoUrl: userProfilePhotoUrlStr,
                      senderId: safeEmail,
                      displayName: name)
    }
    
    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.converstaionsId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        setupInputButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        
        if let conversationId = converstaionsId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    private func configure() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let err):
                print("failed to get messages: \(err)")
            }
        })
    }
}

// MARK: INPUTBAR BUTTON
extension ChatVC {
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default,handler: { [weak self] _ in
            picker.sourceType = .camera
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default,handler: { [weak self] _ in
            picker.sourceType = .photoLibrary
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Viedo", style: .default,handler: { [weak self] _ in
            self?.presentVideooActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default,handler: { [weak self] _ in
            self?.presentAudioActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }

    private func presentVideooActionSheet() {
        
    }
    
    private func presentAudioActionSheet() {
        
    }
}

// MARK: UIImagePickerControllerDelegate
extension ChatVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
              let imageData = image.pngData(),
              let messageId = createMessageId(),
              let converstaionsId = converstaionsId,
              let name = self.title,
              let selfSender = self.selfSender else {
            return
        }
        // Upload image
        // send message
        let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
        
        StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, complation: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let urlString):
                // ready to send message
                print("uploaded message photo: \(urlString)" )
                
                guard let url = URL(string: urlString),
                      let placholder = UIImage(systemName: "plus") else {
                    return
                }
                
                let media = Media(url: url,
                                  image: nil,
                                  placeholderImage: placholder,
                                  size: .zero)
                
                let message = Message(sender: selfSender,
                                      messageId: messageId,
                                      sentDate: Date(),
                                      kind: .photo(media))
                
                DatabaseManager.shared.sendMessage(to: converstaionsId, otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: { success in
                    if success {
                        
                    }else {
                        
                    }
                })
            case .failure(let err):
                print("message photo upload error: \(err)")
            }
        })
        
    }
}

// MARK: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate
extension ChatVC: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    var currentSender: MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            imageView.downloadImage(url: imageURL)
        default:
            break
        }
    }
    
    
    
//    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let message = messages[indexPath.section]
//
//        switch message.kind {
//        case .photo(let media):
//            guard let imageURL = media.url else {
//                return
//            }
//            let vc = PhotoViewerVC(with: imageURL)
//            self.navigationController?.pushViewController(vc, animated: true)
//        default:
//            break
//        }
//    }
}

// MARK: MessageCellDelegate
extension ChatVC: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            let vc = PhotoViewerVC(with: imageURL)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
    }
}


// MARK: InputBarAccessoryViewDelegate
extension ChatVC: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        //Send message
        if isNewConservation {
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completaion: { [weak self] success in
                if success {
                    self?.isNewConservation = false
                }else {
                    print("faild message send")
                }
            })
        }else {
            guard let converstaionsId = converstaionsId,
                  let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: converstaionsId, otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: { success in
                if success {
                    print("message sent")
                }else {
                    print("faild message send")
                }
            })
        }
    }
    
    private func createMessageId() -> String? {
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
