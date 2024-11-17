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
import AuthenticationServices

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
        tf.keyboardType = .emailAddress
        tf.returnKeyType = .continue
        tf.layer.cornerRadius = 12
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        tf.placeholder = " E-mail"
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
        tf.placeholder = " Password"
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        tf.leftViewMode = .always
        tf.backgroundColor = .secondarySystemBackground
        tf.isSecureTextEntry = true
        return tf
    }()
    
    private var orLabel: UILabel = {
        let label = UILabel()
        label.text = "or"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    lazy var logginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .magenta
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.addAction(loginButtonAction, for: .touchUpInside)
        return button
    }()
    
    lazy var appleLoginButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Apple"), for: .normal)
        button.setTitle("  Log In With Apple", for: .normal)
        button.backgroundColor = .lightGray
        button.setTitleColor(.systemGray6, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.addAction(appleLoginButtonAction, for: .touchUpInside)
        return button
    }()
    
    lazy var faceBookLoginButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Facebook"), for: .normal)
        button.setTitle("  Log In With Facebook", for: .normal)
        button.backgroundColor = .lightGray
        button.setTitleColor(.systemGray6, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.addAction(facebookLoginButtonAction, for: .touchUpInside)
        return button
    }()
    
    lazy var googleLoginButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Google"), for: .normal)
        button.setTitle("  Log In With Google", for: .normal)
        button.backgroundColor = .lightGray
        button.setTitleColor(.systemGray6, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.addAction(googleLoginButtonAction, for: .touchUpInside)
        return button
    }()
    
    lazy var registerButton: UIButton = {
        let button = UIButton()
        let title = NSAttributedString(string: "Create an account", attributes: [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 12),
        ])

        button.setAttributedTitle(title, for: .normal)
        button.addAction(registerButtonAction, for: .touchUpInside)
        return button
    }()
    
    lazy var loginButtonAction: UIAction = UIAction { [weak self] _ in
        self?.loginAction()
    }
    
    lazy var appleLoginButtonAction: UIAction = UIAction { _ in
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    lazy var facebookLoginButtonAction: UIAction = UIAction { _ in
        let loginManager = FBSDKLoginKit.LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: self) { [weak self] result, error in
            guard let self else { return }
            
            if let error = error {
                viewModel.error?(error.localizedDescription)
                return
            }
            
            guard let token = result?.token?.tokenString else {
                viewModel.error?("User failed to log in with Facebook.")
                return
            }
            
            viewModel.singInWithFacebook(token: token)
        }
    }
    
    lazy var googleLoginButtonAction: UIAction = UIAction { [weak self] _ in
        guard let self else { return }
        viewModel.singInWithGoogle(self)
    }
    
    lazy var registerButtonAction: UIAction = UIAction { [weak self] _ in
        guard let self else { return }
        let vc = RegisterVC()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
    
    private func loginAction() {
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
}

extension LoginVC {
    private func configure() {
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let self = self else { return }
            navigationController?.dismiss(animated: true)
        })
        
        view.backgroundColor = .systemBackground
        emailTF.delegate = self
        passwordTF.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubViews(imageView,emailTF,passwordTF,logginButton,orLabel,appleLoginButton,faceBookLoginButton,googleLoginButton,registerButton)
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
        
        appleLoginButton.center = scrollView.center
        appleLoginButton.frame = CGRect(x: 25,
                                        y: orLabel.bottom + 10,
                                        width: scrollView.width - 60,
                                        height: 52)
        
        faceBookLoginButton.center = scrollView.center
        faceBookLoginButton.frame = CGRect(x: 25,
                                           y: appleLoginButton.bottom + 10,
                                           width: scrollView.width - 60,
                                           height: 52)
        
        googleLoginButton.center = scrollView.center
        googleLoginButton.frame = CGRect(x: 25,
                                         y: faceBookLoginButton.bottom + 10,
                                         width: scrollView.width - 60,
                                         height: 52)
        
        registerButton.center = scrollView.center
        registerButton.frame = CGRect(x: 25,
                                      y: googleLoginButton.bottom + 50,
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
            loginAction()
        }
        return true
    }
}

extension LoginVC: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            viewModel.singInWithApple(appleIDCredential: appleIDCredential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        viewModel.error?("Apple Sign-In failed: \(error.localizedDescription)")
    }
}

extension LoginVC: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
