//
//  AuthnResponse.swift
//  OktaPKCE
//
//  Created by Pedro Antonio González Laínez on 12/01/2019.
//  Copyright © 2019 Pedro Antonio González Laínez. All rights reserved.
//

import Foundation

struct AuthnResponse: Codable {
    var expiresAt: String
    var status: String
    var sessionToken: String
}
