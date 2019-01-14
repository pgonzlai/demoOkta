//
//  TokenResponse.swift
//  OktaPKCE
//
//  Created by Pedro Antonio González Laínez on 14/01/2019.
//  Copyright © 2019 Pedro Antonio González Laínez. All rights reserved.
//

import Foundation

struct TokenResponse: Codable {
    var access_token: String
    var expires_in: Double
    var id_token: String
    var scope: String
    var token_type: String
}
