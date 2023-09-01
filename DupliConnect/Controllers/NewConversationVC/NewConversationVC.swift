//
//  NewConversationVC.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import UIKit

class NewConversationVC: BaseVC {
    private let viewModel = NewConversationVM()
    private var users = [[String: String]]()
    private var filterUsers = [[String: String]]()
    private var hasFetched = false
    
    public var completion: (([String:String]) -> (Void))?
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Users..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.isHidden = true
        tv.register(UITableViewCell.self,
                    forCellReuseIdentifier: "cell")
        return tv
    }()
    
    private let noResultLabel: UILabel = {
        let lbl = UILabel()
        lbl.isHidden = true
        lbl.text = "No Results"
        lbl.textAlignment = .center
        lbl.textColor = .green
        lbl.font = .systemFont(ofSize: 21, weight: .medium)
        return lbl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultLabel.frame = CGRect(x: view.width / 4,
                                     y: (view.height - 200) / 2,
                                     width: view.width / 2,
                                     height: 100)
    }
    
    @objc
    private func didTapCancelButton() {
        self.dismiss(animated: true)
    }
    
    
    
    private func bindViewModel() {
        viewModel.users = { [weak self] users in
            guard let self = self else { return }
            self.hideSpinner()
            self.users = users
        }
        
        viewModel.filterUsers = { [weak self] users in
            guard let self = self else { return }
            self.hideSpinner()
            self.filterUsers = users
            self.updateUI()
        }
        
        viewModel.error = { [weak self] err in
            guard let self = self else { return }
            self.hideSpinner()
            self.alertErrorWithDismiss(message: err)
        }
    }
    
    private func updateUI() {
        if filterUsers.isEmpty {
            self.noResultLabel.isHidden = false
            self.tableView.isHidden = true
        }else {
            self.noResultLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
    
}
extension NewConversationVC {
    private func configure() {
        view.addSubViews(noResultLabel,tableView)
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapCancelButton))
        searchBar.becomeFirstResponder()
    }
    
    
}

// MARK: UISearchBarDelegate
extension NewConversationVC: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        self.filterUsers.removeAll()
        self.showSpinner()
        self.viewModel.searchUsers(query: text)
    }
}

// MARK: UITableViewDelegate, UITableViewDataSource
extension NewConversationVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = filterUsers[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let targetUserData = filterUsers[indexPath.row]
        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targetUserData)
        })
    }
}
