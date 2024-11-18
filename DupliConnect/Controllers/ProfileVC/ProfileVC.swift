//
//  ProfileVC.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

final class ProfileVC: BaseVC {
    lazy var userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = (view.width / 4) / 2
        return imageView
    }()
    
    lazy var nameLbl: UILabel = {
        let nameLbl = UILabel()
        nameLbl.font = .boldSystemFont(ofSize: 20)
        nameLbl.textColor = .label
        return nameLbl
    }()
    
    lazy var logoutBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Logout", for: .normal)
        btn.setTitleColor(.red, for: .normal)
        btn.addAction(logoutBtnAction, for: .touchUpInside)
        return btn
    }()
    
    lazy var logoutBtnAction: UIAction = {
       return UIAction(handler: { [weak self] _ in
           self?.viewModel.signOut?(true)
        })
    }()
    
    private var data = [ProfileModel]()
    private let viewModel = ProfileVM()

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bindeViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureLayout()
    }
    
    private func configure() {
        title = "Profile"
        view.addSubViews(userImageView, nameLbl, logoutBtn)
    }
    

    private func bindeViewModel() {
        nameLbl.text = UserDefaults.standard.value(forKey: "name") as? String ?? "No Name"

        viewModel.fetchUserPhoto { [weak self] url in
            guard let self, let url else {
                self?.userImageView.image = nil
                return
            }
            DispatchQueue.main.async {
                self.userImageView.downloadImage(url: url)
            }
        }
        
        viewModel.signOut = { [weak self] _ in
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
                self?.viewModel.singOutUser(completion: { isSingOut in
                    if isSingOut {
                        let vc = LoginVC()
                        let nav = UINavigationController(rootViewController: vc)
                        nav.modalPresentationStyle = .fullScreen
                        self?.present(nav, animated: true)
                        self?.tabBarController?.selectedIndex = 0
                    }else {
                       //show alert
                    }
                })
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self?.present(alert, animated: true)
        }
    }
    
    func configureLayout() {
        userImageView.frame = CGRect(x: 30,
                                     y: view.safeAreaInsets.top + 30,
                                     width: view.width / 4,
                                     height: view.width / 4)
        
        nameLbl.frame = CGRect(x: userImageView.width + 50,
                               y: view.safeAreaInsets.top + 40,
                               width: (view.width - (userImageView.width + 20)),
                               height: userImageView.width / 2)
        
        logoutBtn.frame = CGRect(x: (view.width / 2) - ((view.width / 6) / 2),
                                 y: view.height - 130,
                                 width: view.width / 6,
                                 height: 30)
    }
}
