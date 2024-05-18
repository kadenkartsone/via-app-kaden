//
//  AgoraTokenGenerator.swift
//  VIA App
//
//  Created by Matheus Oliveira on 5/3/23.
//

import Foundation
import Alamofire

struct AgoraTokenGenerator {
    
    static let sharedTokenGenerator = AgoraTokenGenerator()
    
    func getToken(forChannel channel: String,  completion: @escaping (Result<String, Error>) -> Void) {
        let channelName = channel.replacingOccurrences(of: " ", with: "%20")
        let url = "https://agora-token-generator-via.herokuapp.com/access_token?channelName=\(channelName)"
        print(url)
        AF.request(url).responseJSON { response in
            switch response.result {
            case .success(let data):
                if let tokenDict = data as? [String: Any], let token = tokenDict["token"] as? String {
                    if !token.isEmpty {
                        completion(.success(token))
                    } else {
                        completion(.failure(NSError(domain: "AgoraTokenErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Empty token returned"])))
                    }
                } else {
                    completion(.failure(NSError(domain: "AgoraTokenErrorDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid token response format"])))
                }
            case .failure(let error):
                completion(.failure(error))
                print("Error when trying to generate token: \(error)")
            }
        }
    }
}//End of struct
