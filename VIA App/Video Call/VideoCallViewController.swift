//
//  VideoCallViewController.swift
//  VIA App
//
//  Created by Matheus Oliveira on 2/23/23.
//

import UIKit
import AVFoundation
import AgoraRtcKit

class VideoCallViewController: UIViewController {
    
    @IBOutlet weak var hangUpButton: UIButton!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var localView: UIView!
    @IBOutlet weak var remoteView: UIView!
    
    var agoraEngine: AgoraRtcEngineKit!
    var userRole: AgoraClientRole = .broadcaster
    let viewModel = VideoCallViewModel()

    var callerID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isIncomingCallSetChannelName()
        initializeAgoraEngine()
        initViews()
        setupLocalVideo()
        Task {await joinChannel()}
        SoundEffectsManager.sharedSoundEffectsManager.playSoundLoop(sound: "FaceTimeOutgoing", audioType: "mp3", volume: 1.0)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: viewModel.notificationName, object: nil)
    }
    
    @IBAction func hangUpButtonTapped(_ sender: UIButton) {
        if let callID = UserDefaults.standard.string(forKey: "currentCallID") {
            viewModel.callManager.endCallWithUUIDRemoteAndLocal(uuid: callID)
        }
        leaveChannel()
    }
    
   func isIncomingCallSetChannelName() {
    if viewModel.incomingCall == true {
        if let channelString = UserDefaults.standard.string(forKey: "incomingCallChannel") {
            viewModel.channelName = channelString
            if let callerID = UserDefaults.standard.string(forKey: "callerID") {
                callerIDLabel.text = "Incoming call from: \(callerID)"
            }
        }
    } else {
        if let clientChannelString = UserDefaults.standard.string(forKey: "clientChannel") {
            viewModel.channelName = clientChannelString
            // Hide the caller ID label for outgoing calls
            callerIDLabel.isHidden = true
        }
    }
}
    
    func initializeAgoraEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = viewModel.appID
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    }
    
    func initViews() {
        navigationItem.hidesBackButton = true
        self.mainView.addSubview(localView)
        self.mainView.addSubview(remoteView)
        self.mainView.addSubview(hangUpButton)
        self.mainView.bringSubviewToFront(hangUpButton)
        self.mainView.bringSubviewToFront(localView)
        localView.layer.cornerRadius = 12
        localView.clipsToBounds = true
    }
    
    func checkForPermissions() async -> Bool {
        var hasPermissions = await self.avAuthorization(mediaType: .video)
        if !hasPermissions { return false }
        hasPermissions = await self.avAuthorization(mediaType: .audio)
        return hasPermissions
    }
    
    func avAuthorization(mediaType: AVMediaType) async -> Bool {
        let mediaAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch mediaAuthorizationStatus {
        case .denied, .restricted: return false
        case .authorized: return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: mediaType) { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default: return false
        }
    }
    
    func showMessage(title: String, text: String, delay: Int = 2) -> Void {
        let deadlineTime = DispatchTime.now() + .seconds(delay)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            self.present(alert, animated: true)
            alert.dismiss(animated: true, completion: nil)
        })
    }
    
    func setupLocalVideo() {
        agoraEngine.enableVideo()
        agoraEngine.startPreview()
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = localView
        agoraEngine.setupLocalVideo(videoCanvas)
    }

    func joinChannel() async {
        guard let channelName = viewModel.channelName else {return}

        callerID = UUID().uuidString
        
        agoraEngine.enableDualStreamMode(true)
        
        if await !self.checkForPermissions() {
            showMessage(title: "Error", text: "Permissions were not granted")
            return
        }
        
        let option = AgoraRtcChannelMediaOptions()
        
        if self.userRole == .broadcaster {
            option.clientRoleType = .broadcaster
            setupLocalVideo()
        } else {
            option.clientRoleType = .audience
        }
        
        option.channelProfile = .communication
        
        let result = agoraEngine.joinChannel(byToken: viewModel.token, channelId: channelName, uid: 0, mediaOptions: option, joinSuccess: { (channel, uid, elapsed) in })
        
        if result == 0 {
            //            showMessage(title: "Success", text: "Successfully joined the channel as \(self.userRole)")
            print("Successfully Joined Call on Channel: \(channelName)!")
        }
        
        let screenSize = UIScreen.main.bounds.size
        let screenAspectRatio = screenSize.width / screenSize.height

        var videoDimensions: CGSize

        if screenAspectRatio > 1.0 {
            // Landscape orientation
            let width: Int32 = 1920
            let height: Int32 = 1080
            videoDimensions = CGSize(width: Int(width), height: Int(height))
        } else {
            // Portrait orientation
            let height: Int32 = 1920
            let width: Int32 = 1080
            videoDimensions = CGSize(width: Int(width), height: Int(height))
        }

        let videoEncoderConfiguration = AgoraVideoEncoderConfiguration()
        videoEncoderConfiguration.dimensions = videoDimensions
        videoEncoderConfiguration.frameRate = .fps30
        videoEncoderConfiguration.bitrate = AgoraVideoBitrateStandard
        agoraEngine.setVideoEncoderConfiguration(videoEncoderConfiguration)
    }
    
    func leaveChannel() {
        agoraEngine.stopPreview()
        let result = agoraEngine.leaveChannel(nil)
        DispatchQueue.global(qos: .userInitiated).async {AgoraRtcEngineKit.destroy()}
        viewModel.incomingCall = false
        UserDefaults.standard.set("", forKey: "incomingCallChannel")
        UserDefaults.standard.set("", forKey: "currentCallID")
        UserDefaults.standard.set("", forKey: "agoraCurrentToken")
        if result == 0 {print("Call ended Successfully!"); navigationController?.popViewController(animated: true);         SoundEffectsManager.sharedSoundEffectsManager.playSound(sound: "Pop", audioType: "mp3", volume: 0.2)}
    }
    
    func didReceiveEndCallNotification() {
        if let callID = UserDefaults.standard.string(forKey: "currentCallID") {
            viewModel.callManager.endLocalCallWithUUID(uuid: callID)
        }
    }
    
    @objc func handleNotification(_ notification: Notification) {
        didReceiveEndCallNotification()
        leaveChannel()
        print("Received notification: \(notification)")
    }
}//End of class

extension VideoCallViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.renderMode = .hidden
        videoCanvas.view = remoteView
        SoundEffectsManager.sharedSoundEffectsManager.stopSound()
        SoundEffectsManager.sharedSoundEffectsManager.playSound(sound: "beep3", audioType: "mp3", volume: 0.2)
        agoraEngine.setupRemoteVideo(videoCanvas)
    }
}
