//
//  FirestoreDatabaseService.swift
//  VIA App
//
//  Created by Matheus Oliveira on 4/27/23.
//

import Foundation
import FirebaseFirestore

enum FirebaseError: Error {
    case firebaseError(Error)
    case failedToUnwrapData
    case noDataFound
}

class FirestoreDatabaseService {
    
    static let sharedDatabase = FirestoreDatabaseService()
    let database = Firestore.firestore()
    
    func saveNewUserToDatabase(name: String, newUserEmail: String, userID: String, deviceID: String) {
        let docRef = database.document("users/\(newUserEmail)")
        docRef.setData(["name": name, "userID": userID, "deviceInUse": deviceID, "receptionistEmail": ""])
    }
    
    func updateDeviceUUIDOnDatabase(userEmail: String, deviceID: String, completion: @escaping (Bool) -> Void) {
        let docRef = database.document("users/\(userEmail)")
        docRef.setData(["deviceInUse": deviceID], merge: true)  { error in
            if let error = error {
                print("Error updating document: \(error)")
                completion(false) // Call completion handler with false to indicate failure
            } else {
                print("Document successfully updated!")
                completion(true) // Call completion handler with true to indicate success
            }
        }
    }
    
    func deleteUser(userEmail: String, completion: @escaping (Bool) -> Void) {
        let docRef = database.collection("users").document(userEmail)
        
        docRef.delete { (error) in
            if let error = error {
                print("Error deleting document: \(error)")
                completion(false)
            } else {
                print("Document successfully deleted")
                completion(true)
            }
        }
    }
    
    func fetchUserDataDictionary(userEmail: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let docRef = database.document("users/\(userEmail)")
        
        docRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let data = snapshot?.data() else {
                    completion(.failure(NSError(domain: "Fetch user data", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error Document does not exist or Data could not be retrieved"])))
                    return
                }
                completion(.success(data))
            }
        }
    }
    
    func fetchUserData(userEmail: String, dataKey: String, localDataName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let docRef = database.document("users/\(userEmail)")
        
        docRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let data = snapshot?.data(),
                      let dataValue = data[dataKey] as? String else {
                    completion(.failure(NSError(domain: "Fetch user data", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error Document does not exist or Data could not be retrieved"])))
                    return
                }
                UserDefaults.standard.set(dataValue, forKey: localDataName)
                completion(.success(dataValue))
            }
        }
    }
    
    func listenForDataChanges(userEmail: String, dataKey: String, localDataName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let docRef = database.document("users/\(userEmail)")
        
        docRef.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let data = snapshot?.data(),
                      let dataValue = data[dataKey] as? String else {
                    completion(.failure(NSError(domain: "Liten data changes", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error Document does not exist or Data could not be retrieved"])))
                    return
                }
                UserDefaults.standard.set(dataValue, forKey: localDataName)
                completion(.success(dataValue))
            }
        }
    }
}//End of Class

