//
//  ConversationsVC.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

final class ConversationsVC: BaseVC {
    private var conversations = [Conversation]()
    private var loginObserver: NSObjectProtocol?
        
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return tv
    }()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chats"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        view.addSubViews(tableView, noConversationsLabel)
        setUpTableView()
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let self = self else { return }
            startListeningForConversations()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningForConversations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureLayout()
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginVC()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        let safeUserEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeUserEmail, completion: { [weak self] result in
            switch result {
            case .success(let newConversations):
                guard !newConversations.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noConversationsLabel.isHidden = false
                    return
                }
                
                self?.tableView.isHidden = false
                self?.noConversationsLabel.isHidden = true

                let oldConversations = self?.conversations ?? []
                self?.conversations = newConversations
                
                let oldIds = Set(oldConversations.map { $0.id })
                let newIds = Set(newConversations.map { $0.id })
                
                let addedIds = newIds.subtracting(oldIds)
                let addedIndexPaths = newConversations.enumerated()
                    .compactMap { index, conversation in
                        addedIds.contains(conversation.id) ? IndexPath(row: index, section: 0) : nil
                    }

                let updatedIndexPaths = newConversations.enumerated()
                    .compactMap { index, conversation in
                        guard let oldIndex = oldConversations.firstIndex(where: { $0.id == conversation.id }),
                              conversation != oldConversations[oldIndex] else {
                            return IndexPath(row: 0, section: 0)
                        }
                        return IndexPath(row: index, section: 0)
                    }

                DispatchQueue.main.async {
                    self?.tableView.insertRows(at: addedIndexPaths, with: .automatic)
                    self?.tableView.reloadRows(at: updatedIndexPaths, with: .automatic)
                }

            case .failure(let err):
                self?.tableView.isHidden = true
                self?.noConversationsLabel.isHidden = false
                print(err)
            }
        })
    }
    
    private func configureLayout() {
        tableView.frame = view.bounds
        noConversationsLabel.frame = CGRect(x: 10,
                                            y: (view.height-100)/2,
                                            width: view.width-20,
                                            height: 100)
    }
    
    @objc
    private func didTapComposeButton() {
        let vc = NewConversationVC()
        vc.completion = { [weak self] result in
            guard let self = self else { return }
            
            let currnetConversations = conversations
            if let targetConversation = currnetConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }) {
                let vc = ChatVC(with: targetConversation.otherUserEmail,id: targetConversation.id)
                vc.title = targetConversation.name
                vc.isNewConservation = false
                vc.navigationItem.largeTitleDisplayMode = .never
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            }else {
                createNewConversation(result: result)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func createNewConversation(result: SearchResult) {
        let safeEmail = DatabaseManager.safeEmail(emailAddress: result.email)
        
        DatabaseManager.shared.conversationExists(with: safeEmail, completion: { [weak self] res in
            guard let self = self else { return }
            
            switch res {
            case .success(let conversationId):
                let vc = ChatVC(with: result.email, id: conversationId)
                vc.title = result.name
                vc.isNewConservation = false
                vc.navigationItem.largeTitleDisplayMode = .never
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatVC(with: result.email,id: nil)
                vc.title = result.name
                vc.isNewConservation = true
                vc.navigationItem.largeTitleDisplayMode = .never
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
}

extension ConversationsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(model)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let conversationId = conversations[indexPath.row].id
        
        if editingStyle == .delete {
            tableView.beginUpdates()
            conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)

            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: { success in
                if !success {
                    print("failed to delete")
                }
            })
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (view.width / 4) - 10
    }
    
    func openConversation(_ model: Conversation) {
        let vc = ChatVC(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
