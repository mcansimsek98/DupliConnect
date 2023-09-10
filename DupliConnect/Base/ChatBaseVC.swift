//
//  ChatBaseVC.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 6.09.2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class ChatBaseVC: MessagesViewController {
    func alertSheetWithTitlesAndActions(title: String, message: String, titles: [String], actions: [(UIAlertAction) -> Void]) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for (index, title) in titles.enumerated() {
            let actionHandler: (UIAlertAction) -> Void = { action in
                actions[index](action)
            }
            actionSheet.addAction(UIAlertAction(title: title, style: .default, handler: actionHandler))
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    func alertErrorWithDismiss(message: String) {
        let alert = UIAlertController(title: "Woops",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        present(alert, animated: true)
    }
}
