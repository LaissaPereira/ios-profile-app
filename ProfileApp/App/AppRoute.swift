//
//  AppRoute.swift
//  ProfileApp
//
//  Created by Laissa on 24.09.26.
//

import Foundation
// App-level navigation type and describe destination
enum AppRoute: Hashable {
    case profile(userID: String)
    case downloads
}

extension DeepLink {
    var route: AppRoute {
        switch self {
        case .profile(let userID):
            return .profile(userID: userID)
        }
    }
}
