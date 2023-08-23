//
//  RegisterVC.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import UIKit
import FirebaseAuth

class RegisterVC: UIViewController {
    let viewModel = RegisterVM()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        scrollView.isScrollEnabled = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private var firsNameTF: UITextField = {
        let tf = UITextField()
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .continue
        tf.layer.cornerRadius = 12
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        tf.placeholder = "First Name..."
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        tf.leftViewMode = .always
        tf.backgroundColor = .white
        return tf
    }()
    
    private var lastNameTF: UITextField = {
        let tf = UITextField()
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .continue
        tf.layer.cornerRadius = 12
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        tf.placeholder = "Last Name..."
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        tf.leftViewMode = .always
        tf.backgroundColor = .white
        return tf
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
        tf.backgroundColor = .white
        return tf
    }()
    
    private var passwordTF: UITextField = {
        let tf = UITextField()
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .continue
        tf.layer.cornerRadius = 12
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        tf.placeholder = "Password..."
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        tf.leftViewMode = .always
        tf.backgroundColor = .white
        tf.isSecureTextEntry = true
        return tf
    }()
    
    
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureLayout()
    }
    
    @objc
    private func registerButtonTapped() {
        firsNameTF.resignFirstResponder()
        lastNameTF.resignFirstResponder()
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()
        
        
        
        guard let firstName = firsNameTF.text, let lastName = lastNameTF.text,
              let email = emailTF.text, let password = passwordTF.text,
              !firstName.isEmpty, !lastName.isEmpty,
              !email.isEmpty, !password.isEmpty,
              password.count >= 6 else {
            alertUserRegisterError(message: "Please enter all information to create a new account.")
            return
        }
        DatabaseManager.shared.userExists(with: email) { [weak self] exists in
            guard let self = self, !exists else {
                self?.alertUserRegisterError(message: "Looks like a user account for that email address already exists.")
                return
            }
            viewModel.createAccount(firstName: firstName, lastName: lastName, email: email, password: password)
        }
    }
    
    @objc
    private func didTapChangeProfilePic() {
        presentPhotoActionSheet()
    }
    
    private func bindViewModel() {
        viewModel.success = { [weak self] user in
            self?.dismiss(animated: true)
        }
        
        viewModel.error = { [weak self] err in
            self?.alertUserRegisterError(message: err)
        }
    }
}

//MARK: FUNCS
extension RegisterVC {
    func alertUserRegisterError(message: String) {
        let alert = UIAlertController(title: "Woops",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        present(alert, animated: true)
    }
    
    private func configure() {
        title = "Register"
        emailTF.delegate = self
        passwordTF.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubViews(imageView,
                               emailTF,
                               passwordTF,
                               registerButton,
                               firsNameTF,
                               lastNameTF)
        
        registerButton.addTarget(self, action: #selector(registerButtonTapped),
                                 for: .touchUpInside)
        
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
    }
    
    private func configureLayout() {
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size)/2,
                                 y: 30,
                                 width: size,
                                 height: size)
        imageView.layer.cornerRadius = imageView.width / 2.0

        firsNameTF.frame = CGRect(x: 30,
                                  y: imageView.bottom + 20,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        lastNameTF.frame = CGRect(x: 30,
                                  y: firsNameTF.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        emailTF.frame = CGRect(x: 30,
                               y: lastNameTF.bottom + 10,
                               width: scrollView.width - 60,
                               height: 52)
        
        passwordTF.frame = CGRect(x: 30,
                                  y: emailTF.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        
        registerButton.frame = CGRect(x: 30,
                                      y: passwordTF.bottom + 20,
                                      width: scrollView.width - 60,
                                      height: 52)
    }
}

//MARK: TEXTFİELD DELEGATE
extension RegisterVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTF || textField == firsNameTF || textField == lastNameTF {
            passwordTF.becomeFirstResponder()
        }else if textField == passwordTF {
            registerButtonTapped()
        }
        return true
    }
    
}

//MARK: Image Picker
extension RegisterVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        let alert = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        alert.addAction(UIAlertAction(title: "Chose Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImage: UIImage

        if let possibleImage = info[.editedImage] as? UIImage {
            selectedImage = possibleImage
        } else if let possibleImage = info[.originalImage] as? UIImage {
            selectedImage = possibleImage
        } else {
            return
        }
        self.imageView.image = selectedImage

        dismiss(animated: true)
        
    }
}
