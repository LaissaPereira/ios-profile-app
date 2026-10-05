//
//  AppDependencies.swift
//  ProfileApp
//
//  Created by Laissa on 28.09.26.
//

import Foundation
//AppDependencies where the real pieces we use when the app runs
struct AppDependencies {
    let profileRepository : any ProfileRepository
       
}

extension AppDependencies {
    static let live : AppDependencies = {
        let client = URLSessionHTTPClient()
        
        let service = RealProfileService(client: client)
        
        let cache = InMemoryProfileCache()
        
        let requestCoordinator = ProfileRequestCoordinator()
        
        let repository = DefaultProfileRepository(
            remoteService: service,
            cache: cache,
            dateProvider: SytemDateProvider(),
            cacheLifetime: 300,
            requestCoordinator: requestCoordinator
        )
        return AppDependencies(profileRepository: repository)
    }()
}



extension AppDependencies {
    static let preview = AppDependencies(
        profileRepository: MockProfileRepository(
            result: .success(Profile(
                name: "Laissa",
                city: "Berlin",
                skills: ["Swift", "SwiftUI"],
                followers: 381
            )
                             
            )
        )
    )
}
