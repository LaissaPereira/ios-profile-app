//
//  ProfileView.swift
//  ProfileApp
//
//  Created by Laissa on 18.09.26.
//

import SwiftUI
//What should the user see?

struct ProfileView: View {
    
    let userID: String
    @State private var model : ProfileModel
    
    init(
        userID: String,
        repository: any ProfileRepository
    ){
        self.userID = userID
        _model = State(
            initialValue: ProfileModel(repository: repository)
        )
    }
    
    
    var body: some View {
        ScrollView{
            VStack {
                switch model.state {
                case .idle:
                    EmptyView()
                    
                case .loading:
                    ProgressView("Loading profile...")
                case .loaded(let profile, let isRefreshing, let refreshError):
                    
                    Text("User ID: \(userID)")
                    
                    ProfileContentView(profile: profile, isRefreshing: isRefreshing, refreshError: refreshError, onRetryRefresh: {
                        Task {
                            await model.loadProfile(forceRefresh: true)
                        }
                    })
                    
                    
                case .failed(let message):
                    Text(message)
                    Button("Retry") {
                        Task {
                            await model.loadProfile(forceRefresh: true)
                        }
                    }
                }
            }
            .padding()
            .task {
                
                model.startLoading()
                await model.waitForCurrentLoad()
            }
            .refreshable {
                
                model.startLoading(forceRefresh: true)
                await model.waitForCurrentLoad()
            }
        }
    }
}

//Profile View decides which state to render
