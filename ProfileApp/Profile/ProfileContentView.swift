//
//  ProfileContent.swift
//  ProfileApp
//
//  Created by Laissa on 30.09.26.
//

import SwiftUI

struct ProfileContentView : View {
    
    let profile : Profile
    let isRefreshing : Bool
    let refreshError : String?
    let onRetryRefresh: () -> Void
    
    
    var body : some View {
        VStack(spacing: 16) {
            Text(profile.name)
                .font(.title)
            
            Text(profile.city)
            
            ForEach(profile.skills, id: \.self) {skill in
                Text(skill)
            }
            
            Text("Followers: \(profile.followers)")
            
            if isRefreshing {
                HStack {
                    ProgressView()
                    Text("Refreshing...")
                }
            }
            
            if let refreshError {
                VStack {
                    Text(refreshError)
                    Button("Retry Refresh") {
                        onRetryRefresh()
                    }
                }
            }
        }
    }
}

// ProfileContentView - knows how loaded profile content looks
