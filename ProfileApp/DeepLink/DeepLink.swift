//
//  DeepLink.swift
//  ProfileApp
//
//  Created by Laissa on 26.09.26.
//

import Foundation
// understands external URL
enum DeepLink: Equatable {
    case profile(userID: String)
}

extension DeepLink {
    init?(url : URL){
        guard url.scheme == "profileapp" else {
            return nil
        }
        guard url.host == "profile" else {
            return nil
        }
        guard let userID = url.pathComponents
            .dropFirst()
            .first
        else {
            return nil
        }
        self = .profile(userID: userID)
    }
}
