//
//  ProfileModel.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 10.09.2023.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileModel {
    let ProfileViewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}

