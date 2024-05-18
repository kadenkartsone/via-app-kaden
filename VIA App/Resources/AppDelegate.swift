//
//  AppDelegate.swift
//  VIA App
//
//  Created by Matheus Oliveira on 2/20/23.
//

import FirebaseCore
import FirebaseMessaging
import UIKit
import CallKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let gcmMessageIDKey = "gcm.Message_ID"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        //Push Notifications for signaling incoming and outgoing calls
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in }
        )

        //Messaging Delegate
        Messaging.messaging().delegate = self
        
        application.registerForRemoteNotifications()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        if let instanceIdToken = InstanceID.instanceID().token() {
//            print("Device token which is good to use with FCM \(instanceIdToken)")
//        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if let aps = userInfo["aps"] as? [String: AnyObject], aps["content-available"] as? Int == 1 {
            
            if let channel = userInfo["channel"] as? String, let callID = userInfo["callID"] as? String, let notificationType = userInfo["notificationType"] as? String, let agoraToken = userInfo["videoCallToken"] as? String {
                
                if callID != "" {
                    guard let callUUID = UUID(uuidString: callID) else {return}
                    if notificationType == "incomingCall" {
                        CallManagerCallKit.sharedInstanceCallManager.reportIncomingCall(id: callUUID, handle: channel)
                        UserDefaults.standard.set(channel, forKey: "incomingCallChannel")
                        UserDefaults.standard.set(callID, forKey: "currentCallID")
                        UserDefaults.standard.set(agoraToken, forKey: "agoraCurrentToken")
                    } else if notificationType == "endingCall" {
                        UserDefaults.standard.set(channel, forKey: "incomingCallChannel")
                        UserDefaults.standard.set(callID, forKey: "currentCallID")
                        CallManagerCallKit.sharedInstanceCallManager.notifyIfCallResponse(callResponse: "endingCall")
                    }
                }
                print("Received silent notification for channel: \(channel)")
            }
        } else {
            // Handle your notification payload
            if let aps = userInfo["aps"] as? [String: AnyObject] {
              let alert = aps["alert"] as? [String: AnyObject]
              let title = alert?["title"] as? String ?? ""
              let message = alert?["body"] as? String ?? ""

              // Create and show your notification
              let notificationContent = UNMutableNotificationContent()
              notificationContent.title = title
              notificationContent.body = message
              notificationContent.sound = UNNotificationSound.default

              let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
              let notificationRequest = UNNotificationRequest(identifier: "normal_notification", content: notificationContent, trigger: notificationTrigger)

              UNUserNotificationCenter.current().add(notificationRequest) { (error) in
                if let error = error {
                  print("Error showing notification: \(error.localizedDescription)")
                } else {
                  print("Notification shown successfully")
                }
              }
            }
            completionHandler(.newData)
        }
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")

        UserDefaults.standard.set(fcmToken, forKey: "deviceFirebaseID")
        
      let dataDict: [String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
      // TODO: If necessary send token to application server.
      // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}
