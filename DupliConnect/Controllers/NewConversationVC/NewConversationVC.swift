//
//  NewConversationVC.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import UIKit

class NewConversationVC: BaseVC {
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
        
    }
    
    @objc
    private func didTapCancelButton() {
        self.dismiss(animated: true)
    }
    
}
extension NewConversationVC {
    private func configure() {
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
        
    }
}
