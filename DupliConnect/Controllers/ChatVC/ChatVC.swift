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

final class ChatVC: ChatBaseVC {
    private let viewModel = ChatVM()
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
        bindViewModel()
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
        viewModel.getAllMessages(id: id) { [weak self] messages in
            guard let strongSelf = self else { return }
            strongSelf.messages = messages
            DispatchQueue.main.async {
                strongSelf.messagesCollectionView.reloadDataAndKeepOffset()
                if shouldScrollToBottom {
                    strongSelf.messagesCollectionView.scrollToLastItem()
                }
            }
        }
    }
    
    private func bindViewModel() {
        viewModel.error = { [weak self] err in
            guard let strongSelf = self else { return }
            strongSelf.alertErrorWithDismiss(message: err)
        }
        
        viewModel.createdNewConversation = { [weak self] messageId, success in
            guard let strongSelf = self else { return }
            strongSelf.messageInputBar.inputTextView.text = nil
            if success {
                strongSelf.isNewConservation = false
                let newConversationId = "conversation_\(messageId)"
                strongSelf.converstaionsId = newConversationId
                strongSelf.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
            }
        }
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
            guard let strongSelf = self else { return }
            guard let messageId = strongSelf.viewModel.createMessageId(otherUserEmail: strongSelf.otherUserEmail),
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender else {
                return
            }
            
            let longitude: Double  = selectedCoordinates.longitude
            let latitude: Double = selectedCoordinates.latitude
            let clLocation = CLLocation(latitude: latitude, longitude: longitude)
            let location = Location(location: clLocation, size: .zero)
            
            strongSelf.viewModel.sendMessage(to: strongSelf.converstaionsId, otherUserEmail: strongSelf.otherUserEmail, name: name, sender: selfSender, messageId: messageId, url: nil, isVideo: false, isText: false, isNewConservation: strongSelf.isNewConservation, isLocation: true, location: location)
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
        guard let messageId = viewModel.createMessageId(otherUserEmail: otherUserEmail),
              let converstaionsId = converstaionsId,
              let name = title,
              let selfSender = selfSender else {
            return
        }
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
           let imageData = image.pngData() {
            
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            viewModel.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] urlStr in
                guard let strongSelf = self else { return }
                guard let url = URL(string: urlStr) else {
                    return
                }
                strongSelf.viewModel.sendMessage(to: converstaionsId, otherUserEmail: strongSelf.otherUserEmail, name: name, sender: selfSender, messageId: messageId, url: url, isVideo: false, location: Location(location: CLLocation(latitude: 0, longitude: 0), size: .zero))
            }
            
        }else if let videoURL = info[.mediaURL] as? URL {
            
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            viewModel.uploadMessageVideo(with: videoURL, fileName: fileName) { [weak self] urlStr in
                guard let strongSelf = self else { return }
                guard let url = URL(string: urlStr) else {
                    return
                }
                strongSelf.viewModel.sendMessage(to: converstaionsId, otherUserEmail: strongSelf.otherUserEmail, name: name, sender: selfSender, messageId: messageId, url: url, isVideo: true, location: Location(location: CLLocation(latitude: 0, longitude: 0), size: .zero))
            }
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
        case .video(let media):
            imageView.image = media.placeholderImage
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            return .link
        }
        return .lightText
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId {
            if let currentUserImageURL = senderPhotoURL {
                avatarView.downloadImage(url: currentUserImageURL)
            }else {
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                viewModel.getAvatarImage(email: email) { [weak self] url in
                    self?.senderPhotoURL = url
                    DispatchQueue.main.async {
                        avatarView.downloadImage(url: url)
                    }
                }
            }
        }else {
            if let otherUserImageURL = otherUserPhotoURL {
                avatarView.downloadImage(url: otherUserImageURL)
            }else {
                viewModel.getAvatarImage(email: otherUserEmail) { [weak self] url in
                    self?.senderPhotoURL = url
                    DispatchQueue.main.async {
                        avatarView.downloadImage(url: url)
                    }
                }
            }
        }
    }
}

// MARK: InputBarAccessoryViewDelegate
extension ChatVC: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = selfSender,
              let messageId = viewModel.createMessageId(otherUserEmail: otherUserEmail),
              let name = title else {
            return
        }
        
        viewModel.sendMessage(to: converstaionsId, otherUserEmail: otherUserEmail, name: name, sender: selfSender, messageId: messageId, url: nil, isText: true, messageText: text, isNewConservation: isNewConservation, location: Location(location: CLLocation(latitude: 0, longitude: 0), size: .zero))
    }
}

// MARK: MessageCellDelegate - DidSelcet
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
            navigationController?.pushViewController(vc, animated: true)
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
