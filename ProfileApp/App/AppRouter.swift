//
//  AppRouter.swift
//  ProfileApp
//
//  Created by Laissa on 26.09.26.
//

import Observation
import SwiftUI
// App-level navigation state and changes navigation state
// A router should manage navigation state, not business logic
//Only navigation


@MainActor
@Observable
final class AppRouter {
    var path = NavigationPath()
    
    func navigate(to route: AppRoute) {
        path.append(route)
    }
    
    func handle(_ deeplink: DeepLink) {
        
        navigate(to: deeplink.route)
    }
    
    func handle(_ url: URL) {
        guard let  deeplink = DeepLink(url: url) else {
            return
        }
        handle(deeplink)
    }
    
    func goBack() {
        guard !path.isEmpty else {
            return
        }
        path.removeLast()
    }
    
    func gotToRoot() {
        path = NavigationPath()
    }
}
