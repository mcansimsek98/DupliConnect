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
        self.textLabel?.text = model.title
        switch model.ProfileViewModelType {
        case .info:
            self.textLabel?.textColor = .label
            self.textLabel?.textAlignment = .left
            self.selectionStyle = .none
            break
        case .logout:
            self.textLabel?.textColor = .red
            self.textLabel?.textAlignment = .center
            break
        }
    }
}
