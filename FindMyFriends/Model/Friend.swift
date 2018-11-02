//
//  Friends.swift
//  FindMyFriend
//
//  Created by HUNG-HSUN LIN on 2018/11/1.
//  Copyright © 2018 Hung Hsun Lin. All rights reserved.
//

import Foundation
import MapKit

struct Friend: Codable {
    var friendName: String
    var id: String
    var lastUpdateDateTime: String
    var lat: String
    var lon: String
    enum CodingKeys: String, CodingKey {
        case friendName = "friendName"
        case id = "id"
        case lastUpdateDateTime = "lastUpdateDateTime"
        case lat = "lat"
        case lon = "lon"
    }
}
