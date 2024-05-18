//
//  LoginViewController.swift
//  VIA App
//
//  Created by Matheus Oliveira on 2/21/23.
//

import UIKit

class AuthenticationViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var loginSignUpSegementedControl: UISegmentedControl!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var showPasswordButton: UIButton!
    @IBOutlet weak var loginSignUpButton: UIButton!
    @IBOutlet weak var loginSignUpActivityIndicator: UIActivityIndicatorView!
    
    var passwordIsHidden: Bool?
    var viewModel: AuthenticationViewModel = AuthenticationViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    func configureUI() {
        loginSignUpActivityIndicator.isHidden = true
        bindViewModel()
        passwordIsHidden = true
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        nameTextField.isHidden = true
        confirmPasswordTextField.isHidden = true
    }
    
    func configureBasedOnSelectedIndex() {
        if loginSignUpSegementedControl.selectedSegmentIndex == 0 {
            nameTextField.isHidden = true
            confirmPasswordTextField.isHidden = true
            loginSignUpButton.setTitle("Login", for: .normal)
        } else {
            nameTextField.isHidden = false
            confirmPasswordTextField.isHidden = false
            loginSignUpButton.setTitle("Sign Up", for: .normal)
        }
    }
    
    func showPassword() {
        if passwordIsHidden == true {
            passwordIsHidden = false
            showPasswordButton.setImage(UIImage(systemName: "checkmark.square"), for: .normal)
            passwordTextField.isSecureTextEntry = false
            confirmPasswordTextField.isSecureTextEntry = false
        } else {
            passwordIsHidden = true
            showPasswordButton.setImage(UIImage(systemName: "square"), for: .normal)
            passwordTextField.isSecureTextEntry = true
            confirmPasswordTextField.isSecureTextEntry = true
        }
    }
    
    func authButtonWasTapped() {
        loginSignUpActivityIndicator.isHidden = false
        loginSignUpActivityIndicator.startAnimating()
        if loginSignUpSegementedControl.selectedSegmentIndex == 0 {
            viewModel.signInWithEmailPassword(email: emailTextField.text, password: passwordTextField.text)
            loginSignUpActivityIndicator.stopAnimating()
            loginSignUpActivityIndicator.isHidden = true
        } else {
            viewModel.signUpWithEmailPassword(name: nameTextField.text, email: emailTextField.text, password: passwordTextField.text, confirmPassword: confirmPasswordTextField.text)
            loginSignUpActivityIndicator.stopAnimating()
            loginSignUpActivityIndicator.isHidden = true
        }
    }
    
    func goToReceptionistScreen() {
        let storyboard = UIStoryboard(name: "ReceptionistScreen", bundle: nil)
        guard let receptionVC = storyboard.instantiateViewController(withIdentifier: "receptionistNavControl") as? UINavigationController else {return}
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.windows.first?.rootViewController = receptionVC
        windowScene?.windows.first?.makeKeyAndVisible()
    }
    
    func bindViewModel() {
        viewModel.$errorMessage.sink { [weak self] error in
            if let error {
                self?.presentAlertController(title: (self?.viewModel.errorMessageTitle)!, message: error)
            }
        }.store(in: &viewModel.cancellable)
        
        viewModel.$isAuthenticated.sink { [weak self] isAuth in
            if isAuth {
                self?.goToReceptionistScreen()
            }
        }.store(in: &viewModel.cancellable)
    }
    
    func presentAlertController(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        confirmPasswordTextField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func loginSignUpSegmentedControlTapped(_ sender: UISegmentedControl) {
        configureBasedOnSelectedIndex()
    }
    
    @IBAction func forgotPasswordButtonTapped(_ sender: UIButton) {
        viewModel.sendForgotPasswordEmail(to: emailTextField.text)
    }
    
    @IBAction func showPasswordButtonTapped(_ sender: UIButton) {
        showPassword()
    }
    
    @IBAction func loginSignUpButtonTapped(_ sender: UIButton) {
        authButtonWasTapped()
    }
}
