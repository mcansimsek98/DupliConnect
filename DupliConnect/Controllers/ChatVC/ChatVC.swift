//
//  ChatVC.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 29.08.2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import AVFoundation
import AVKit
import CoreLocation

class ChatVC: ChatBaseVC {
    public let otherUserEmail: String
    public var isNewConservation = false
    private var converstaionsId: String?
    private var messages = [Message]()
    private let picker = UIImagePickerController()
    
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String,
              let name = UserDefaults.standard.value(forKey: "name") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let userProfilePhotoUrlStr = ""
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
        if let conversationId = converstaionsId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    private func configure() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        picker.delegate = self
        picker.allowsEditing = true
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
        let alertTitle = ["Photo","Video","Location"]
        alertSheetWithTitlesAndActions(title: "Attach Media", message: "What would you like to attach?", titles: alertTitle, actions: [{ [weak self] action in
            let alertTitle = ["Camera","Photo Library"]
            self?.presentPhotoAndVideoActionSheet(title: "Attach Photo", message: "Where would you like to attach a photo from?", alertTitle: alertTitle)
        }, { [weak self] action in
            let alertTitle = ["Camera","Library"]
            self?.presentPhotoAndVideoActionSheet(title: "Attach Video", message: "Where would you like to attach a video from?", alertTitle: alertTitle, isVideo: true)
        }, { [weak self] action in
            self?.presentLocationActionSheet()
        }])
    }
    
    private func presentPhotoAndVideoActionSheet(title: String, message: String, alertTitle: [String], isVideo: Bool = false) {
        if isVideo {
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
        }
        alertSheetWithTitlesAndActions(title: title, message: message, titles: alertTitle, actions: [{ [weak self] action in
            self?.presentPicker(with: .camera)
        }, { [weak self] action in
            self?.presentPicker(with: .photoLibrary)
        }])
    }
    
    private func presentPicker(with sourceType: UIImagePickerController.SourceType) {
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    private func presentLocationActionSheet() {
        let vc = LocationPickerVC(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion  = { [weak self] selectedCoordinates in
            guard let self = self else { return }
            guard let messageId = createMessageId(),
                  let converstaionsId = converstaionsId,
                  let name = title,
                  let selfSender = selfSender else {
                return
            }
            
            let longitude: Double  = selectedCoordinates.longitude
            let latitude: Double = selectedCoordinates.latitude
            let clLocation = CLLocation(latitude: latitude, longitude: longitude)
            let location = Location(location: clLocation, size: .zero)
            
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: converstaionsId, otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: { success in
                if success {
                    
                }else {
                    
                }
            })
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: UIImagePickerControllerDelegate
extension ChatVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let messageId = createMessageId(),
              let converstaionsId = converstaionsId,
              let name = self.title,
              let selfSender = self.selfSender else {
            return
        }
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
           let imageData = image.pngData() {
            // Upload image
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
        }else if let videoURL = info[.mediaURL] as? URL {
            // Upload video
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            StorageManager.shared.uploadMessageVideo(with: videoURL, fileName: fileName, complation: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let urlString):
                    // ready to send message
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
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: converstaionsId, otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: { success in
                        if success {
                            
                        }else {
                            
                        }
                    })
                case .failure(let err):
                    print("message video upload error: \(err)")
                }
            })
        }
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
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == self.selfSender?.senderId {
            return .link
        }
        return .lightText
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        
        if sender.senderId == self.selfSender?.senderId {
            if let currentUserImageURL = self.senderPhotoURL {
                avatarView.downloadImage(url: currentUserImageURL)
            }else {
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                StorageManager.shared.downloadUrl(for: path, complation: { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.senderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.downloadImage(url: url)
                        }
                    case .failure(let err):
                        print(err)
                    }
                })
            }
        }else {
            if let otherUserImageURL = self.otherUserPhotoURL {
                avatarView.downloadImage(url: otherUserImageURL)
            }else {
                let email = self.otherUserEmail
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                StorageManager.shared.downloadUrl(for: path, complation: { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.downloadImage(url: url)
                        }
                    case .failure(let err):
                        print(err)
                    }
                })
            }
        }
    }
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
        case .video(let media):
            guard let videoURL = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoURL)
            vc.player?.play()
            present(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let location):
            let coordinate = location.location.coordinate
            let vc = LocationPickerVC(coordinates: coordinate)
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
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
                    let newConversationId = "conversation_\(message.messageId)"
                    self?.converstaionsId = newConversationId
                    self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = nil
                }else {
                    print("faild message send")
                }
            })
        }else {
            guard let converstaionsId = converstaionsId,
                  let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: converstaionsId, otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: { [weak self] success in
                if success {
                    self?.messageInputBar.inputTextView.text = nil
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
