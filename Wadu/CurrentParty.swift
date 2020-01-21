//
//  CurrentParty.swift
//  Wadu
//
//  Created by Jerry Shi on 2018-07-13.
//  Copyright © 2018 Jerry Shi. All rights reserved.
//

import Foundation

class CurrentParty {
    static let sharedPartyInfo = CurrentParty()
    let globalURL: String? = "http://192.168.2.34:4000"
    var current_party_id: String? = nil
    var current_party_name: String? = nil
    var master: String? = nil
    var memberCount: Int? = 0
}
