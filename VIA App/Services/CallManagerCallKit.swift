//
//  InOutCallProgress.swift
//  VIA App
//
//  Created by Matheus Oliveira on 3/6/23.
//

import CallKit
import Foundation

class CallManagerCallKit: NSObject {
    
    var notificationService = FirebaseNotificationManager.sharedInstanceFirebase
    static var sharedInstanceCallManager = CallManagerCallKit()
    let currentAgoraToken = UserDefaults.standard.string(forKey: "agoraCurrentToken")
    
    static let providerConfiguration: CXProviderConfiguration = {
        let providerConfiguration = CXProviderConfiguration()
        // Prevents multiple calls from being grouped.
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportsVideo = true
        providerConfiguration.supportedHandleTypes = [.generic]
        providerConfiguration.ringtoneSound = "Ringtone.aif"
        return providerConfiguration
    }()
    
    var provider: CXProvider
    var callController: CXCallController = CXCallController()
    
    override init() {
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    func reportIncomingCall(id: UUID, handle: String) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        provider.reportNewIncomingCall(with: id, update: update) { error in
            if let error {
                print(String(describing: error))
            } else {
                print("Call reported")
            }
        }
    }
    
    func startCall(id: UUID, handle: String, completion: @escaping (Bool) -> Void) {
        let outgoinCallIDString = id.uuidString
        UserDefaults.standard.set(outgoinCallIDString, forKey: "currentCallID")
        let handleCX = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: id, handle: handleCX)
        startCallAction.isVideo = true
        let transaction = CXTransaction(action: startCallAction)
        callController.request(transaction) { error in
            if let error = error {
                print(String(describing: error))
                completion(false)
            } else {
                if let receptionistDeviceUUID = UserDefaults.standard.string(forKey: "receptionistDeviceUUID"), !receptionistDeviceUUID.isEmpty {
                    AgoraTokenGenerator.sharedTokenGenerator.getToken(forChannel: "\(handle)") { result in
                        switch result {
                        case .success(let token):
                            UserDefaults.standard.set(token, forKey: "agoraCurrentToken")
                            self.notificationService.sendSilentNotification(callID: id.uuidString, channel: "\(handle)", notificationType: "incomingCall", recipientUUID: receptionistDeviceUUID, videoCallToken: token)
                            print("Agora token: \(token)")
                            completion(true)
                        case .failure(let error):
                            print("Error no token was generated for this call: \(error.localizedDescription)")
                            completion(false)
                        }
                    }
                } else {
                    print("Receptionist UUID not found, please try again")
                    completion(false)
                }
            }
        }
    }

    
    func endCallWithUUIDRemoteAndLocal(uuid: String) {
        guard let callUUID = UUID(uuidString: uuid), let channel = UserDefaults.standard.string(forKey: "incomingCallChannel") else {return}
        let endCallAction = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: endCallAction)
        callController.request(transaction) { [weak self] error in
            if let error {
                print("Error ending call: \(error.localizedDescription)")
            } else {
                if let recipientUUID = UserDefaults.standard.string(forKey: "receptionistDeviceUUID"), let agoraToken = self?.currentAgoraToken {
                    self?.notificationService.sendSilentNotification(callID: uuid, channel: channel, notificationType: "endingCall", recipientUUID: recipientUUID, videoCallToken: agoraToken)
                }
                print("Call ended with UUID: \(uuid)")
            }
        }
    }
    
    func endLocalCallWithUUID(uuid: String) {
        guard let callUUID = UUID(uuidString: uuid) else {return}
        let endCallAction = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: endCallAction)
        callController.request(transaction) { error in
            if let error {
                print("Error ending call: \(error.localizedDescription)")
            } else {
                print("Call ended with UUID: \(uuid)")
            }
        }
    }
    
    func notifyIfCallResponse(callResponse: String) {
        let notificationName = NSNotification.Name(callResponse)
        let notification = Notification(name: notificationName)
        NotificationCenter.default.post(notification)
    }
}//End of class

extension CallManagerCallKit: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // This method gets called if the user answers the call
        // You can perform any necessary actions here, such as connecting the call
        
        notifyIfCallResponse(callResponse: "AcceptedCall")
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        // This method gets called if the user ends the call
        // You can perform any necessary actions here, such as disconnecting the call
        guard let callID = UserDefaults.standard.string(forKey: "currentCallID"), let channel = UserDefaults.standard.string(forKey: "incomingCallChannel") else {return}
        if let recipientUUID = UserDefaults.standard.string(forKey: "receptionistDeviceUUID"), let agoraToken = self.currentAgoraToken {
            self.notificationService.sendSilentNotification(callID: callID, channel: channel, notificationType: "endingCall", recipientUUID: recipientUUID, videoCallToken: agoraToken)
        }
        action.fulfill()
    }
}//End of extension
