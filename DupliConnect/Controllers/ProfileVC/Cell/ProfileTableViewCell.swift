//
//  ProfileTableViewCell.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 10.09.2023.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with model: ProfileModel) {
        textLabel?.text = model.title
        switch model.ProfileViewModelType {
        case .info:
            textLabel?.textColor = .label
            textLabel?.textAlignment = .left
            selectionStyle = .none
            break
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
            break
        }
    }
}
