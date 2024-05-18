//
//  FirebaseNotificationManager.swift
//  VIA App
//
//  Created by Matheus Oliveira on 3/6/23.
//

import Foundation
import FirebaseCore
import FirebaseMessaging

class FirebaseNotificationManager {
    
    static var sharedInstanceFirebase = FirebaseNotificationManager()
    
    func sendSilentNotification(callID: String, channel: String, notificationType: String, recipientUUID: String, videoCallToken: String) {
      let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.addValue("key=AAAAHTPUp08:APA91bEmR9Q2HNjSAqEAsR81n_Uko9mUAauPkQ6amVneTPdLZQPg5HCAGtbn_z3bA1UjUXYO30ROb9hXnr4LhnVbdSk1oKjEq_sUF9pc4qveOeVpJMIVEr97GdHmzg7_gvRi8WIBfPxJ", forHTTPHeaderField: "Authorization")

        let notification: [String: Any] = [
          "content_available": true,
            "priority": "high",
            "data": [
                "channel": channel,
                "callID": callID,
                "notificationType": notificationType,
                "videoCallToken": videoCallToken
            ],
                 "to": recipientUUID
        ]

      let jsonData = try! JSONSerialization.data(withJSONObject: notification, options: [])
      request.httpBody = jsonData

      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
          print("Error sending silent notification: \(error.localizedDescription)")
          return
        }
        if let response = response as? HTTPURLResponse,
           response.statusCode != 200 {
          print("Invalid response status code: \(response.statusCode)")
          return
        }
        print("Silent notification sent successfully")
      }
      task.resume()
    }
    
    func sendNormalNotification(title: String, message: String, recipientUUID: String) {
        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("key=AAAAHTPUp08:APA91bEmR9Q2HNjSAqEAsR81n_Uko9mUAauPkQ6amVneTPdLZQPg5HCAGtbn_z3bA1UjUXYO30ROb9hXnr4LhnVbdSk1oKjEq_sUF9pc4qveOeVpJMIVEr97GdHmzg7_gvRi8WIBfPxJ", forHTTPHeaderField: "Authorization")
        
        let notification: [String: Any] = [
            "notification": [
                "title": title,
                "body": message,
                "icon": "app_icon"
            ],
            "to": recipientUUID
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: notification, options: [])
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
                return
            }
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                print("Invalid response status code: \(response.statusCode)")
                return
            }
            print("Notification sent successfully")
        }
        task.resume()
    }
}//End of class
