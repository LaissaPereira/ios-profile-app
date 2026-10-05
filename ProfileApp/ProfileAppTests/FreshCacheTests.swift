//
//  FreshCache.swift
//  ProfileAppTests
//
//  Created by Laissa on 29.09.26.
//

import Foundation
import Testing
@testable import ProfileApp
@MainActor
struct FreshCacheTest {

    @Test("Fresh cache skips remote service")
    func freshCacheSkipsRemoteService() async throws {
        
        let now = Date(timeIntervalSince1970: 1_000)
        
        let cachedProfile = Profile(
            name: "Cached",
            city: "Berlin",
            skills: ["Swift"],
            followers: 100
            
        )
        
        let remoteProfile = Profile(
            name: "Remote",
            city: "Hamburg",
            skills: ["SwiftUI"],
            followers: 999
        )
        
        let service = SpyProfileService(
            result: .success(remoteProfile)
        )
        
        let cache = InMemoryProfileCache()

            await cache.save(
                cachedProfile,
                saveAt: now.addingTimeInterval(-120)
            )

            let repository = DefaultProfileRepository(
                remoteService: service,
                cache: cache,
                dateProvider: FixedDateProvider(date: now),
                cacheLifetime: 300,
                requestCoordinator: ProfileRequestCoordinator()
            )

            let result = try await repository.fetchProfile()

            #expect(result.name == "Cached")
            #expect(service.fetchCallCount == 0)
    }
    
    
    @Test("Expired cache fetches remote profile")
    func expiredCacheFetchesRemoteProfile() async throws {
        let now = Date(timeIntervalSince1970: 1_000)

        let cachedProfile = Profile(
            name: "Old Cached",
            city: "Berlin",
            skills: ["Swift"],
            followers: 100
        )

        let remoteProfile = Profile(
            name: "Fresh Remote",
            city: "Berlin",
            skills: ["Swift", "SwiftUI"],
            followers: 500
        )

        let service = SpyProfileService(
            result: .success(remoteProfile)
        )

        let cache = InMemoryProfileCache()

        await cache.save(
            cachedProfile,
            saveAt: now.addingTimeInterval(-600)
        )

        let repository = DefaultProfileRepository(
            remoteService: service,
            cache: cache,
            dateProvider: FixedDateProvider(date: now),
            cacheLifetime: 300,
            requestCoordinator: ProfileRequestCoordinator()
        )

        let result = try await repository.fetchProfile()

        #expect(result.name == "Fresh Remote")
        #expect(service.fetchCallCount == 1)

        let updatedCache = await cache.load()

        #expect(updatedCache?.profile.name == "Fresh Remote")
        #expect(updatedCache?.savedAt == now)
    }


}
