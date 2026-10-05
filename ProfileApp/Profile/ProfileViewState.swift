//
//  ProfileViewState.swift
//  ProfileApp
//
//  Created by Laissa on 21.09.26.
//

import Foundation
//What situation is the screen currently in? Loading/ loaded/ error
enum ProfileViewState {
    // Now the app can only be in one valid state
    case idle
    case loading
    case loaded(
        profile : Profile,
        isRefreshing: Bool,
        refreshError: String?
    )
    case failed(String)
}
