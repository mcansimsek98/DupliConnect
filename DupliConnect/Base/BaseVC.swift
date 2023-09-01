//
//  BaseVC.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 29.08.2023.
//

import UIKit
import JGProgressHUD

class BaseVC: UIViewController {

    let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func showSpinner() {
        spinner.show(in: view)
    }
    
    func hideSpinner() {
        DispatchQueue.main.async {
            self.spinner.dismiss()
        }
    }

    func alertErrorWithDismiss(message: String) {
        let alert = UIAlertController(title: "Woops",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        present(alert, animated: true)
    }
}
