//
//  Header.swift
//  BetaBump
//
//  Created by Timmy Van Cauwenberge on 2/15/21.
//

import Foundation

enum Header {
    case GETHeader(accessToken: String)
    case POSTHeader

    func buildHeader() -> [String:String] {
        switch self {
        case .GETHeader (let accessToken):
            return ["Accept": "application/json",
                    "Content-Type": "application/json",
                    "Authorization": "Bearer \(accessToken)"
            ]
        case .POSTHeader:
            // Spotify's required format for authorization
            let SPOTIFY_API_AUTH_KEY = "Basic \((K.SPOTIFY_API_CLIENT_ID + ":" + K.SPOTIFY_API_SCRET_KEY).data(using: .utf8)!.base64EncodedString())"
            return ["Authorization": SPOTIFY_API_AUTH_KEY,
                    "Content-Type": "application/x-www-form-urlencoded"]
        }
    }
}
