//
//  VideoCallViewModel.swift
//  VIA App
//
//  Created by Matheus Oliveira on 2/23/23.
//

import Foundation

class VideoCallViewModel {
    
    let appID: String = "50950cb9a44846e6900ca8c9f22a4387"
    var channelName: String?
    var incomingCall: Bool? = false
    var token = UserDefaults.standard.string(forKey: "agoraCurrentToken")
    var callManager = CallManagerCallKit.sharedInstanceCallManager
    let notificationName = NSNotification.Name("endingCall")
    
}//End of class
