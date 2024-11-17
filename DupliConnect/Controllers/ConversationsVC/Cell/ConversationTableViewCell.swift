//
//  ConversationTableViewCell.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 1.09.2023.
//

import UIKit

final class ConversationTableViewCell: UITableViewCell {
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLbl: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        label.numberOfLines = 1
        return label
    }()
    
    private let userMessageLbl: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 2
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubViews(userImageView,userNameLbl,userMessageLbl)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let contentWidth = Int.roundToNearestEvenInteger(contentView.width)
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: contentWidth / 6,
                                     height: contentWidth / 6)
        userImageView.layer.cornerRadius = (contentWidth / 6) / 2

        userNameLbl.frame = CGRect(x: userImageView.right + 10,
                                   y: 10,
                                   width:(contentWidth - 20) - userImageView.width,
                                   height: (userImageView.height/2) - 15)
        
        userMessageLbl.frame = CGRect(x: userImageView.right + 10,
                                      y: userNameLbl.bottom + 4,
                                      width: (contentWidth - 30) - userImageView.width,
                                      height: userImageView.height - userNameLbl.height)
    }
    
    public func configure(with model: Conversation) {
        userNameLbl.text = model.name
        userMessageLbl.text = model.latestMessage.text.contains("message_images") ? "📷 Image" : model.latestMessage.text
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadUrl(for: path, complation: { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.downloadImage(url: url)
                }
            case .failure(let err):
                print("faild to get image url: \(err)")
                self?.userImageView.image = nil
            }
        })
        
    }
}
