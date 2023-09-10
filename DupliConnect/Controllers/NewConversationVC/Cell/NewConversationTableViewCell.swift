//
//  NewConversationTableViewCell.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 6.09.2023.
//

import UIKit

final class NewConversationTableViewCell: UITableViewCell {
    static let identifier = "NewConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLbl: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubViews(userImageView,userNameLbl)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let contentWidth = Int.roundToNearestEvenInteger(contentView.width)
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: contentWidth / 8,
                                     height: contentWidth / 8)
        userImageView.layer.cornerRadius = (contentWidth / 8) / 2
        userNameLbl.frame = CGRect(x: userImageView.right + 10,
                                   y: 10,
                                   width:(contentWidth - 20) - userImageView.width,
                                   height: contentWidth / 8)
    }
    
    public func configure(with model: SearchResult) {
        userNameLbl.text = model.name
        let path = "images/\(model.email)_profile_picture.png"
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
