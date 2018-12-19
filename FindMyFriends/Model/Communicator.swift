//
//  Communicator.swift
//  FindMyFriends
//
//  Created by HUNG-HSUN LIN on 2018/11/1.
//  Copyright © 2018 Hung Hsun Lin. All rights reserved.
//

import Foundation
import Alamofire


let GROUPNAME_KEY = "GroupName"
let GROUPNAME = "yourGroup"
let USERNAME_KEY = "UserName"
let LAT_KEY = "Lat"
let LON_KEY = "Lon"
let RESULT_KEY = "result"


typealias DoneHandler = (_ result: [String : Any]?, _ error: Error?) -> Void

class Communicator {
    static var MY_NAME = "Tony"
    
    // Constants
    static let BASEURL = "http://yourServer/"
    let UPDATELOCATION_URL = BASEURL + "updateUserLocation.php?"
    let QUERY_FRIENDS_LOCATIONS_URL = BASEURL + "queryFriendLocations.php?"
    
    static let shared = Communicator()
    private init() {
        
    }
    
    // MARK: - Public methods.
    func updateLocation(lat: Double, lon: Double, completion: @escaping DoneHandler) {
        
        let urlString = "\(UPDATELOCATION_URL)\(GROUPNAME_KEY)=\(GROUPNAME)&\(USERNAME_KEY)=\(Communicator.MY_NAME)&\(LAT_KEY)=\(lat)&\(LON_KEY)=\(lon)"
        
        print(urlString)
        
        doPost(urlString: urlString,
               completion: completion)
    }
    
    func queryFriendLocations(completion: @escaping DoneHandler) {
        
        let urlString = "\(QUERY_FRIENDS_LOCATIONS_URL)\(GROUPNAME_KEY)=\(GROUPNAME)"
        print(urlString)
        
        doPost(urlString: urlString,
               completion: completion)
    }
    
    // MARK: - Post data.
    
    private func doPost(urlString: String,
                        completion: @escaping DoneHandler) {
        Alamofire.request(urlString, method: .post, encoding: URLEncoding.default).responseJSON { (response) in
            self.handleJSON(response: response, completion: completion)
        }
        
    }
    
    private func handleJSON(response: DataResponse<Any>,
                            completion: DoneHandler) {
        // result -> public enum
        switch response.result {
        case .success(let json):
            print("Get success response: \(json)")
            
            guard let finalJson = json as? [String : Any] else {
                let error = NSError(domain: "Invalid JSON object.", code: -1, userInfo: nil)
                completion(nil, error)
                return
            }
            guard let result = finalJson[RESULT_KEY] as? Bool, result == true else {
                let error = NSError(domain: "Server respond false or not result.", code: -1, userInfo: nil)
                completion(nil, error)
                return
            }
            completion(finalJson, nil)
            
        case .failure(let error):
            print("Server respond error: \(error)")
            
            completion(nil, error)
        }
        
    }
}
