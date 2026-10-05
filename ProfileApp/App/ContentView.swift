//
//  ContentView.swift
//  ProfileApp
//
//  Created by Laissa on 18.09.26.
//

import SwiftUI

//ContentView can provide the model/router/etc. to UI
struct ContentView: View {
    
    let dependencies: AppDependencies
    
    @Environment(AppRouter.self)
    private var router
    //It receives it from the application environment


    var body: some View {
        
        @Bindable var router = router
        
        NavigationStack(path: $router.path) {
            List {
                Button("Open Profile") {
                    router.navigate(to: .profile(userID: "user-123"))
                }

                Button("Open Downloads") {
                    router.navigate(to: .downloads)
                }
            }
            .navigationTitle("ProfileApp")
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .profile(let userID):
                    ProfileView(userID: userID, repository: dependencies.profileRepository)

                case .downloads:
                    DownloadView()
                }
            }
        }
        .onOpenURL { url in
            router.handle(url)
        }
    }
}
#Preview {
    ContentView(dependencies: .preview)
    // rendering mock of depencencies for development
        .environment(AppRouter())
}
