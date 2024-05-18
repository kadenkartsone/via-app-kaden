//
//  ReceptionistViewController.swift
//  VIA App
//
//  Created by Matheus Oliveira on 2/21/23.
//

import UIKit

class ReceptionistViewController: UIViewController {
    
    @IBOutlet weak var callReceptionistView: UIView!
    @IBOutlet weak var callReceptionistButton: UIButton!
    @IBOutlet weak var calendarView: UIView!
    @IBOutlet weak var serviceBellView: UIView!
    @IBOutlet weak var viewWidthConstraint: NSLayoutConstraint!
    
    let viewModel = ReceptionistViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: viewModel.notificationName, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func signOutButtonTapped(_ sender: UIBarButtonItem) {
        presentYesNoAlertController(title: "Sign Out", message: "Are you sure that you want to sign out?")
    }
    
    @IBAction func notifyProviderButtonTapped(_ sender: UIButton) {
//        if let receptionistDeviceID = UserDefaults.standard.string(forKey: "receptionistDeviceUUID") {
//            FirebaseNotificationManager.sharedInstanceFirebase.sendNormalNotification(title: "Your Next Patient Is Here", message: "Please let them know that you are aware", recipientUUID: receptionistDeviceID)
//        }
//        presentOkAlertController(title: "Your Provider Was Notified Successfully!", message: "Someone will be with you shortly")
        presentOkAlertController(title: "Feature Coming Soon", message: "As we continue to improve our services we are happy to announce that soon you will be able to notify provider of your arrival on the VIA App!")
    }
    
    @IBAction func scheduleNextAppointmentButtonTapped(_ sender: UIButton) {
        presentOkAlertController(title: "Feature Coming Soon", message: "As we continue to improve our services we are happy to announce that soon you will be able to schedule your next appointments on the VIA App!")
    }
    
    
    @IBAction func callReceptionistButtonTapped(_ sender: UIButton) {
        if let channelName = UserDefaults.standard.string(forKey: "clientChannel") {
            if channelName != "" {
                let uid = UUID()
                CallManagerCallKit.sharedInstanceCallManager.startCall(id: uid, handle: channelName) { [weak self] success in
                    if success {
                        self?.goToVideoCallScreen(isIncomingCall: false)
                        print("Call started successfully")
                    } else {
                        CallManagerCallKit.sharedInstanceCallManager.endLocalCallWithUUID(uuid: uid.uuidString)
                        self?.presentSingleActionAlertController(title: "Call Failed", message: "Please try again")
                        print("Failed to start call")
                    }
                }
            }
        }
    }
    
    @objc func handleNotification(_ notification: Notification) {
        acceptIncomingCall()
        print("Received notification: \(notification)")
    }
    
    func configureUI() {
        navigationItem.hidesBackButton = true
        adaptReceptionistButtonWidth()
        callReceptionistButton.layer.cornerRadius = 0.5 * viewWidthConstraint.constant
        callReceptionistView.layer.cornerRadius = 0.5 * viewWidthConstraint.constant
        calendarView.layer.cornerRadius = calendarView.frame.width/2
        serviceBellView.layer.cornerRadius = serviceBellView.frame.width/2
        calendarView.clipsToBounds = true
        serviceBellView.clipsToBounds = true
        callReceptionistButton.clipsToBounds = true
        callReceptionistView.clipsToBounds = true
        callReceptionistView.layer.masksToBounds = false
        calendarView.layer.masksToBounds = false
        serviceBellView.layer.masksToBounds = false
        callReceptionistButton.layer.borderWidth = 2
        calendarView.layer.borderWidth = 2
        serviceBellView.layer.borderWidth = 2
        callReceptionistView.layer.shadowColor = UIColor.black.cgColor
        calendarView.layer.shadowColor = UIColor.black.cgColor
        serviceBellView.layer.shadowColor = UIColor.black.cgColor
        callReceptionistView.layer.shadowOffset = CGSize(width: 3.0, height: 5.0)
        calendarView.layer.shadowOffset = CGSize(width: 3.0, height: 5.0)
        serviceBellView.layer.shadowOffset = CGSize(width: 3.0, height: 5.0)
        callReceptionistView.layer.shadowRadius = 10.0
        calendarView.layer.shadowRadius = 10.0
        serviceBellView.layer.shadowRadius = 10.0
        callReceptionistView.layer.shadowOpacity = 0.4
        calendarView.layer.shadowOpacity = 0.4
        serviceBellView.layer.shadowOpacity = 0.4
        callReceptionistView.layer.shadowPath = nil
        calendarView.layer.shadowPath = nil
        serviceBellView.layer.shadowPath = nil
    }
    
    func adaptReceptionistButtonWidth() {
        let screenWidth = UIScreen.main.bounds.size.width
        
        
        if screenWidth <= 932 {
            self.viewWidthConstraint.constant = 200
        } else {
            self.viewWidthConstraint.constant = 280
        }
    }
    
    func acceptIncomingCall() {
        goToVideoCallScreen(isIncomingCall: true)
    }
    
    func presentSingleActionAlertController(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAction)
            self.present(alertController, animated: true)
        }
    }
    
    func presentYesNoAlertController(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
                AuthenticationViewModel().signOut { success in
                    if success {
                        // Sign-out was successful
                        print("User signed out successfully.")
                        self.goToAuthenticationScreen()
                    } else {
                        // Sign-out failed
                        print("Failed to sign out.")
                        self.presentOkAlertController(title: "Error", message: "We encountered an error signing out, please make Network connection is available and try again.")
                    }
                }
            }
            let noAction = UIAlertAction(title: "No", style: .default)
            alertController.addAction(yesAction)
            alertController.addAction(noAction)
            self.present(alertController, animated: true)
        }
    }
    
    func presentOkAlertController(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAction)
            self.present(alertController, animated: true)
        }
    }
    
    func goToVideoCallScreen(isIncomingCall: Bool) {
        let storyboard = UIStoryboard(name: "VideoCallScreen", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "videoCallVC") as! VideoCallViewController
        viewController.viewModel.incomingCall = isIncomingCall
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func goToAuthenticationScreen() {
        let storyboard = UIStoryboard(name: "AuthenticationScreen", bundle: nil)
        guard let authVC = storyboard.instantiateViewController(withIdentifier: "authenticationNavController") as? UINavigationController else {return}
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.windows.first?.rootViewController = authVC
        windowScene?.windows.first?.makeKeyAndVisible()
    }
}
