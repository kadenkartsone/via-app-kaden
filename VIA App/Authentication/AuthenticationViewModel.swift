//
//  LoginViewModel.swift
//  VIA App
//
//  Created by Matheus Oliveira on 2/21/23.
//

import Foundation
import FirebaseAuth
import Combine

class AuthenticationViewModel: ObservableObject {
    var auth = Auth.auth()
    
    @Published var isAuthenticated = false
    @Published var errorMessage: String? = nil
    @Published var errorMessageTitle = ""
    @Published var user: User?
    @Published var displayName = ""
    var cancellable: Set<AnyCancellable> = []
    
    deinit {
        cancellable.forEach{$0.cancel()}
    }
    
    func signInWithEmailPassword(email: String?, password: String?) {
        if email != "" && password != "" {
            auth.signIn(withEmail: email!, password: password!) { [weak self] result, error in
                if let error {
                    self?.errorMessageTitle = "Error"
                    self?.errorMessage = error.localizedDescription
                }
                
                if let result {
                    self?.user = result.user
                    self?.isAuthenticated = true
                    UserDefaults.standard.set(email!, forKey: "currentUserEmail")
                    print("User was authenticated")
                    if let deviceID = UserDefaults.standard.string(forKey: "deviceFirebaseID") {
                        FirestoreDatabaseService.sharedDatabase.updateDeviceUUIDOnDatabase(userEmail: email!, deviceID: deviceID) { success in
                            if success {
                                // Database update succeeded
                                print("UUID Updated Successfully")
                            } else {
                                // Database update failed
                                print("UUID Updated Failed")
                            }
                        }
                    }
                        
                        FirestoreDatabaseService.sharedDatabase.fetchUserDataDictionary(userEmail: email!) { result in
                            switch result {
                            case .success(let data):
                                if let nameAndChannel = data["name"] as? String, let receptionistEmail = data["receptionistEmail"] as? String {
                                    UserDefaults.standard.set(nameAndChannel, forKey: "nameAndChannelString")
                                    UserDefaults.standard.set(nameAndChannel, forKey: "clientChannel")
                                    UserDefaults.standard.set(receptionistEmail, forKey: "receptionistEmail")
                                    print("NameAndChannel: \(nameAndChannel) and receptionistEmail: \(receptionistEmail) saved with success.")
                                    
                                    FirestoreDatabaseService.sharedDatabase.listenForDataChanges(userEmail: email!, dataKey: "receptionistEmail", localDataName: "receptionistEmail") { result in
                                        switch result {
                                        case .success(let newReceptionistEmailValue):
                                            print("Recepionist E-mail being listened to with success! \(newReceptionistEmailValue)")
                                        case .failure(let error):
                                            print("Error listening to email changes! \(error.localizedDescription)")
                                        }
                                    }
                                    
                                    FirestoreDatabaseService.sharedDatabase.listenForDataChanges(userEmail: receptionistEmail, dataKey: "deviceInUse", localDataName: "receptionistDeviceUUID") { result in
                                        switch result {
                                        case .success(let newReceptionistDeviceUUIDValue):
                                            print("Recepionist device uuid being listened to with success! \(newReceptionistDeviceUUIDValue)")
                                        case .failure(let error):
                                            print("Error listening to email changes! \(error.localizedDescription)")
                                        }
                                    }
                                }
                            case .failure(let error):
                                print("Error fetching NameAndChannel and receptionist email, please sign out and sign in again \(error.localizedDescription)")
                            }
                        }
                    }
                }
            } else {
                self.errorMessageTitle = "Error"
                self.errorMessage = "All fields are required, please make sure to provide all required information"
            }
        }
        
        func signUpWithEmailPassword(name: String?, email: String?, password: String?, confirmPassword: String?) {
            if name != "" && email != "" && password != "" && confirmPassword != "" {
                if password == confirmPassword {
                    auth.createUser(withEmail: email!, password: password!) { [weak self] result, error in
                        if let error {
                            self?.errorMessageTitle = "Error"
                            self?.errorMessage = error.localizedDescription
                        }
                        
                        if let result {
                            self?.user = result.user
                            self?.isAuthenticated = true
                            UserDefaults.standard.set(name, forKey: "nameAndChannelString")
                            UserDefaults.standard.set(name, forKey: "clientChannel")
                            UserDefaults.standard.set(email!, forKey: "currentUserEmail")
                            print("User was authenticated and created")
                            if let deviceID = UserDefaults.standard.string(forKey: "deviceFirebaseID") {
                                FirestoreDatabaseService.sharedDatabase.saveNewUserToDatabase(name: name!, newUserEmail: email!, userID: result.user.uid, deviceID: deviceID)
                                print("New user saved to Database")
                            }
                        }
                    }
                } else {
                    self.errorMessageTitle = "Passwords don't match"
                    self.errorMessage = "Please make sure passwords match"
                }
            } else {
                self.errorMessageTitle = "Error"
                self.errorMessage = "All fields are required, please make sure to provide all required information"
            }
        }
        
    func signOut(completion: @escaping (Bool) -> Void) {
        guard let userEmail = UserDefaults.standard.string(forKey: "currentUserEmail") else {
            // Handle the case where "currentUserEmail" is not found in UserDefaults
            completion(false)
            return
        }
        
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
            FirestoreDatabaseService.sharedDatabase.updateDeviceUUIDOnDatabase(userEmail: userEmail, deviceID: "") { success in
                if success {
                    // Database update succeeded
                    print("UUID updated successfully!")
                    
                    do {
                        try self.auth.signOut()
                        UserDefaults.standard.set("", forKey: "currentUserEmail")
                        UserDefaults.standard.set("", forKey: "receptionistDeviceUUID")
                        UserDefaults.standard.set("", forKey: "receptionistEmail")
                        UserDefaults.standard.set("", forKey: "clientChannel")
                        UserDefaults.standard.set("", forKey: "nameAndChannelString")
                        completion(true) // Sign out successful
                    } catch {
                        print(error)
                        self.errorMessage = error.localizedDescription
                        completion(false) // Sign out failed
                    }
                } else {
                    // Database update failed
                    print("UUID update failed!")
                    completion(false)
                }
            }
        }else{
            print("Internet Connection not Available!")
            completion(false)
        }
    }

//    func signOut(completion: @escaping (Bool) -> Void) {
//        do {
//            try auth.signOut()
//            if let userEmail = UserDefaults.standard.string(forKey: "currentUserEmail") {
//                FirestoreDatabaseService.sharedDatabase.updateDeviceUUIDOnDatabase(userEmail: userEmail, deviceID: "") { success in
//                    if success {
//                        // Database update succeeded
//                        print("UUID updated successfully!")
//                        UserDefaults.standard.set("", forKey: "currentUserEmail")
//                        UserDefaults.standard.set("", forKey: "receptionistDeviceUUID")
//                        UserDefaults.standard.set("", forKey: "receptionistEmail")
//                        UserDefaults.standard.set("", forKey: "clientChannel")
//                        UserDefaults.standard.set("", forKey: "nameAndChannelString")
//                        completion(true)
//                    } else {
//                        // Database update failed
//                        print("UUID update failed!")
//                        completion(false)
//                    }
//                }
//            }
//            completion(true) // Sign out successful
//        } catch {
//            print(error)
//            errorMessage = error.localizedDescription
//            completion(false) // Sign out failed
//        }
//    }
        
        func deleteAccount() async -> Bool {
            do {
                try await user?.delete()
                if let userEmail = UserDefaults.standard.string(forKey: "currentUserEmail") {
                    FirestoreDatabaseService.sharedDatabase.deleteUser(userEmail: userEmail) { (success) in
                        if success {
                            print("User successfully deleted")
                        } else {
                            print("Error deleting user")
                        }
                    }
                }
                return true
            }
            catch {
                errorMessage = error.localizedDescription
                return false
            }
        }
        
        func sendForgotPasswordEmail(to email: String?) {
            if email == "" {
                self.errorMessageTitle = "No Email Entered"
                self.errorMessage = "Please provide the email associated with the account, then tap forgot password."
            } else {
                auth.sendPasswordReset(withEmail: email!) { error in
                    if let error {
                        self.errorMessageTitle = "Error"
                        self.errorMessage = "Something went wrong, please verify the if email entered is correct and try again. \(error.localizedDescription)"
                        print("Error sending email with password reset: \(error.localizedDescription)")
                    } else {
                        self.errorMessageTitle = "Verify Your Inbox"
                        self.errorMessage = "An email from noreply@via-app was sent with a link to reset your password. Please check your spam/junk if you don't receive it."
                        print("Reset Password email sent with success!")
                    }
                }
            }
        }
    }//End of class
