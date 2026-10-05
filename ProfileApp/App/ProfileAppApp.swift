//
//  ProfileAppApp.swift
//  ProfileApp
//
//  Created by Laissa on 18.09.26.
//

import SwiftUI
// Start the application it might create/access dependencies and then
//pass them into ContentView can provide the model/router/etc. to UI
@main
struct ProfileAppApp: App {
    
    @State private var router = AppRouter()
    //owns the AppRouter and intialize
    
    private let dependencies = AppDependencies.live
    //create AppDependencies to production
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                dependencies : dependencies
            )
                .environment(router)
            //Injects router into environment
            //Passes dependencies to ContentView 
        }
    }
}

//Other good candites(router, authentication/session, theme, app-wide services)
