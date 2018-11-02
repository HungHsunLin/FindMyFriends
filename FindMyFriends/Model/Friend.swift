//
//  Friends.swift
//  FindMyFriend
//
//  Created by HUNG-HSUN LIN on 2018/11/1.
//  Copyright © 2018 Hung Hsun Lin. All rights reserved.
//

import Foundation

struct Friend: Codable {
    var friendName: String
    var id: Int
    var lastUpdateDateTime: Date
    var lat: Float
    var lon: Float
    enum CodingKeys: String, CodingKey {
        case friendName = "friendName"
        case id = "id"
        case lastUpdateDateTime = "lastUpdateDateTime"
        case lat = "lat"
        case lon = "lon"
    }
}
