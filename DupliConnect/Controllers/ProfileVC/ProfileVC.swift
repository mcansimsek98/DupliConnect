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
    @IBOutlet weak var tableView: UITableView!
    
    private var data = [ProfileModel]()
    private let viewModel = ProfileVM()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        bindeViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureTableView()
        viewModel.getUserData()
    }
    
    private func configureTableView() {
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    private func bindeViewModel() {
        viewModel.userData = { [weak self] user in
            if !user.isEmpty {
                self?.data = user
                self?.tableView.reloadData()
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
}

//MARK: TableHeaderView
extension ProfileVC {
    func createTableHeader() -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: view.width,
                                              height: 210))
        headerView.backgroundColor = .link
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2,
                                                  y: 30,
                                                  width: 150,
                                                  height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        headerView.addSubview(imageView)
        
        viewModel.fetchUserPhoto { url in
            guard let url = url else {
                imageView.image = nil
                return
            }
            DispatchQueue.main.async {
                imageView.downloadImage(url: url)
            }
        }
        return headerView
    }
}

//MARK: UITableViewDelegate
extension ProfileVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        let model = data[indexPath.row]
        cell.setUp(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}
