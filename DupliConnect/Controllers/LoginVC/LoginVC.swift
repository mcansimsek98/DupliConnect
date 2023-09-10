//
//  LoginVC.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

final class LoginVC: BaseVC {
    let viewModel = LoginVM()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var emailTF: UITextField = {
        let tf = UITextField()
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .continue
        tf.layer.cornerRadius = 12
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        tf.placeholder = "Email Address..."
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        tf.leftViewMode = .always
        tf.backgroundColor = .secondarySystemBackground
        return tf
    }()
    
    private var passwordTF: UITextField = {
        let tf = UITextField()
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .done
        tf.layer.cornerRadius = 12
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        tf.placeholder = "Password..."
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        tf.leftViewMode = .always
        tf.backgroundColor = .secondarySystemBackground
        tf.isSecureTextEntry = true
        return tf
    }()
    
    private let logginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let faceBookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        button.tintColor = .link
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        return button
    }()
    
    private var orLabel: UILabel = {
        let label = UILabel()
        label.text = "or"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureLayout()
        bindViewModel()
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @objc
    private func loginButtonTapped() {
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()
        
        guard let email = emailTF.text, let password = passwordTF.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertErrorWithDismiss(message: "Please enter all information to log in.")
            return
        }
        showSpinner()
        viewModel.signIn(email: email, password: password)
    }
    
    @objc
    private func googleLoginButtonTapped() {
        viewModel.singInWithGoogle(self)
    }
    
    @objc
    private func didTapRegister() {
        let vc = RegisterVC()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func bindViewModel() {
        viewModel.user = { [weak self] user in
            guard let strongSelf = self else { return }
            strongSelf.hideSpinner()
            strongSelf.dismiss(animated: true)
        }
        
        viewModel.error = { [weak self] err in
            guard let strongSelf = self else { return }
            strongSelf.hideSpinner()
            strongSelf.alertErrorWithDismiss(message: err)
        }
    }
}

extension LoginVC {
    private func configure() {
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let self = self else { return }
            navigationController?.dismiss(animated: true)
        })
        
        title = "Log In"
        view.backgroundColor = .systemBackground
        emailTF.delegate = self
        passwordTF.delegate = self
        faceBookLoginButton.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        view.addSubview(scrollView)
        scrollView.addSubViews(imageView,emailTF,passwordTF,logginButton,orLabel,faceBookLoginButton,googleLoginButton)
        logginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        googleLoginButton.addTarget(self, action: #selector(googleLoginButtonTapped), for: .touchUpInside)
    }
    
    private func configureLayout() {
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size)/2,
                                 y: 30,
                                 width: size,
                                 height: size)
        
        emailTF.frame = CGRect(x: 30,
                               y: imageView.bottom + 60,
                               width: scrollView.width - 60,
                               height: 52)
        
        passwordTF.frame = CGRect(x: 30,
                                  y: emailTF.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        logginButton.frame = CGRect(x: 30,
                                    y: passwordTF.bottom + 20,
                                    width: scrollView.width - 60,
                                    height: 52)
        
        orLabel.frame = CGRect(x: 30,
                               y: logginButton.bottom + 40,
                               width: scrollView.width - 60,
                               height: 52)
        
        faceBookLoginButton.center = scrollView.center
        faceBookLoginButton.frame = CGRect(x: 25,
                                           y: orLabel.bottom + 10,
                                           width: scrollView.width - 60,
                                           height: 52)
        
        googleLoginButton.frame = CGRect(x: 30,
                                         y: faceBookLoginButton.bottom + 20,
                                         width: scrollView.width - 60,
                                         height: 52)
    }
}

//MARK: TEXTFİELD DELEGATE
extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTF {
            passwordTF.becomeFirstResponder()
        }else if textField == passwordTF {
            loginButtonTapped()
        }
        return true
    }
    
}

//MARK: Facebook LoginButtonDelegate
extension LoginVC: LoginButtonDelegate {
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        viewModel.singInWithFacebook(token: token)
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        //no operation
        
    }
    
    
}
