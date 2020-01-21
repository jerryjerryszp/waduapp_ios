//
//  User.swift
//  Wadu
//
//  Created by Jerry Shi on 2018-06-05.
//  Copyright © 2018 Jerry Shi. All rights reserved.
//

import Foundation

class User {
    static let sharedUserInfo = User()
    //let globalURL = "http://192.168.2.34:4000"
    let globalURL = "https://83c540ec.ngrok.io"
    var name: String? = nil
    var imageData: NSData? = nil
    var isMaster: Bool? = true
    var masterName: String? = nil
    var party_id: String? = nil
    var party_name: String? = nil
    var user_current_id: String? = nil
    var user_allowed_shutter: Bool? = false
    var user_position: Int? = 0
}
