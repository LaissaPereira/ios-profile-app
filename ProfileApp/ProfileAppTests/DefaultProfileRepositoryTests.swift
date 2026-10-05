//
//  DefaultProfileRepositoryTests.swift
//  ProfileAppTests
//
//  Created by Laissa on 28.09.26.
//

import Testing
import Foundation
@testable import ProfileApp

actor SpyProfileCache: ProfileCache {

    private var cachedProfile: CachedProfile?

    private(set) var saveCallCount = 0

    func load() -> CachedProfile? {
        cachedProfile
    }

    func save(
        _ profile: Profile,
        saveAt: Date
    ) {
        saveCallCount += 1

        cachedProfile = CachedProfile(
            profile: profile,
            savedAt: saveAt
        )
    }
}

//spy service
final class SpyProfileService: ProfileService {
    private(set) var fetchCallCount = 0
    
    let result: Result<Profile, Error>
    init(result: Result<Profile, Error>){
        self.result = result
    }
    
    func fetchProfile() async throws -> Profile {
        fetchCallCount += 1
        
        return try result.get()
    }
}
@MainActor
struct DefaultProfileRepositoryTests {

    @Test("Cache hit skips remote service")
    func cacheHitSkipsRemoteService() async throws {
        
        let now = Date(timeIntervalSince1970: 1_000)
        let cachedProfile = Profile(
            name: "Cached User",
            city: "Berlin",
            skills: ["Swift"],
            followers: 100
        )
        
        let remoteProfile = Profile(
            name: "Remote User",
            city: "Hamburg",
            skills: ["SwiftUI"],
            followers: 999
        )
        
        let service = SpyProfileService(result: .success(remoteProfile))
        
        let cache = SpyProfileCache()
        
        await cache.save(cachedProfile, saveAt: now)
        
        let repository = DefaultProfileRepository(
            remoteService: service,
            cache: cache,
            dateProvider: FixedDateProvider(date: now),
            cacheLifetime: 300,
            requestCoordinator: ProfileRequestCoordinator()
        )
        
        let result = try await repository.fetchProfile()
        
        #expect(result.name == "Cached User")
        #expect(service.fetchCallCount == 0)
    }
    
    @Test("Caches miss fetches remote and stores profile")
    func cacheMissFetchesRemoteAndStoresProfile() async throws {
        
        let now = Date(timeIntervalSince1970: 1_000)
        let remoteProfile = Profile(
            name: "Remote User",
            city: "Berlin",
            skills: ["Swift", "SwiftUI"],
            followers: 250

        )
        
        let service = SpyProfileService(
            result: .success(remoteProfile)
        )
        
        let cache = SpyProfileCache()
        
        let repository = DefaultProfileRepository(
            remoteService: service, cache: cache,
            dateProvider: FixedDateProvider(date: now),
            cacheLifetime: 300,
            requestCoordinator: ProfileRequestCoordinator()
  
        )
        
        let result = try await repository.fetchProfile()
        
        #expect(result.name == "Remote User")
        #expect(service.fetchCallCount == 1)
        
        let cached = await cache.load()
        
        #expect(cached?.profile.name == "Remote User")
    }
    
    @Test("Second fetch uses cached profile")
    func secondFetchUsesCache() async throws {
        
        let now = Date(timeIntervalSince1970: 1_000)
        
        let remoteProfile = Profile(
            name: "Remote User",
            city: "Berlin",
            skills: ["Swift"],
            followers: 500
        )

        let service = SpyProfileService(
            result: .success(remoteProfile)
        )

        let cache = SpyProfileCache()

        let repository = DefaultProfileRepository(
            remoteService: service,
            cache: cache,
            dateProvider: FixedDateProvider(date: now),
            cacheLifetime: 300,
            requestCoordinator: ProfileRequestCoordinator()
        )

        let firstResult = try await repository.fetchProfile()
        let secondResult = try await repository.fetchProfile()

        #expect(firstResult.name == "Remote User")
        #expect(secondResult.name == "Remote User")

        #expect(service.fetchCallCount == 1)
        
    }
    
    @Test("Force refresh bypasses fresh cache")
    func forceRefreshBypassesFreshCache() async throws {
        let now = Date(
                timeIntervalSince1970: 1_000
            )

            let cachedProfile = Profile(
                name: "Cached User",
                city: "Berlin",
                skills: ["Swift"],
                followers: 100
            )

            let remoteProfile = Profile(
                name: "Fresh Remote User",
                city: "Berlin",
                skills: ["Swift", "SwiftUI"],
                followers: 500
            )

            let service = SpyProfileService(
                result: .success(remoteProfile)
            )

            let cache = SpyProfileCache()

            await cache.save(
                cachedProfile,
                saveAt: now
            )

            let repository = DefaultProfileRepository(
                remoteService: service,
                cache: cache,
                dateProvider: FixedDateProvider(
                    date: now
                ),
                cacheLifetime: 300,
                requestCoordinator: ProfileRequestCoordinator()
            )

            var receivedProfiles: [ProfileUpdate] = []

            for try await update in repository.profileStream(
                forceRefresh: true
            ) {
                receivedProfiles.append(update)
            }

            #expect(service.fetchCallCount == 1)
            #expect(receivedProfiles.count == 1)

            guard case .fresh(let profile) = receivedProfiles[0] else {
                Issue.record(
                    "Expected a fresh profile update"
                )
                return
            }

            #expect(profile.name == "Fresh Remote User")

            let updatedCache = await cache.load()

            #expect(
                updatedCache?.profile.name
                == "Fresh Remote User"
            )
        
        
    }
    @Test("Concurrent forced refreshes share one remote request")
    func concurrentForcedRefreshesShareOneRemoteRequest() async throws {

        let now = Date(
            timeIntervalSince1970: 1_000
        )

        let remoteProfile = Profile(
            name: "Shared Remote",
            city: "Berlin",
            skills: ["Swift", "SwiftUI"],
            followers: 500
        )

        let service = ControlledRemoteService()
        let cache = SpyProfileCache()
        let coordinator = ProfileRequestCoordinator()

        let repository = DefaultProfileRepository(
            remoteService: service,
            cache: cache,
            dateProvider: FixedDateProvider(
                date: now
            ),
            cacheLifetime: 300,
            requestCoordinator: coordinator
        )

        let firstConsumer = Task {
            var updates: [ProfileUpdate] = []

            for try await update in repository.profileStream(
                forceRefresh: true
            ) {
                updates.append(update)
            }

            return updates
        }

        // Guarantee remote request #1 has started.
        await service.waitUntilCallCount(1)

        let secondConsumer = Task {
            var updates: [ProfileUpdate] = []

            for try await update in repository.profileStream(
                forceRefresh: true
            ) {
                updates.append(update)
            }

            return updates
        }

        // Give consumer #2 a chance to join the same in-flight request.
        await Task.yield()

        let callCountBeforeCompletion =
            await service.callCount

        #expect(callCountBeforeCompletion == 1)

        await service.succeed(
            with: remoteProfile
        )

        let firstUpdates =
            try await firstConsumer.value

        let secondUpdates =
            try await secondConsumer.value

        #expect(firstUpdates.count == 1)
        #expect(secondUpdates.count == 1)

        guard case .fresh(let firstProfile) =
            firstUpdates[0]
        else {
            Issue.record(
                "Expected first consumer to receive fresh profile"
            )
            return
        }

        guard case .fresh(let secondProfile) =
            secondUpdates[0]
        else {
            Issue.record(
                "Expected second consumer to receive fresh profile"
            )
            return
        }

        #expect(
            firstProfile.name == "Shared Remote"
        )

        #expect(
            secondProfile.name == "Shared Remote"
        )

        let finalCallCount =
            await service.callCount

        #expect(finalCallCount == 1)
        
        let remoteCallCount =
            await service.callCount

        let cacheSaveCount =
            await cache.saveCallCount

        #expect(remoteCallCount == 1)
        #expect(cacheSaveCount == 1)
    }
    
    @Test("Concurrent forced refreshes share one remote request and one cache write")
    func concurrentForcedRefreshesShareOneRemoteRequestAndOneCacheWrite() async throws {

        let now = Date(
            timeIntervalSince1970: 1_000
        )

        let remoteProfile = Profile(
            name: "Shared Remote",
            city: "Berlin",
            skills: ["Swift", "SwiftUI"],
            followers: 500
        )

        let service = ControlledRemoteService()
        let cache = SpyProfileCache()
        let coordinator = ProfileRequestCoordinator()

        let repository = DefaultProfileRepository(
            remoteService: service,
            cache: cache,
            dateProvider: FixedDateProvider(
                date: now
            ),
            cacheLifetime: 300,
            requestCoordinator: coordinator
        )

        let firstConsumer = Task {
            var updates: [ProfileUpdate] = []

            for try await update in repository.profileStream(
                forceRefresh: true
            ) {
                updates.append(update)
            }

            return updates
        }

        await service.waitUntilCallCount(1)

        let secondConsumer = Task {
            var updates: [ProfileUpdate] = []

            for try await update in repository.profileStream(
                forceRefresh: true
            ) {
                updates.append(update)
            }

            return updates
        }

        await Task.yield()

        #expect(
            await service.callCount == 1
        )

        await service.succeed(
            with: remoteProfile
        )

        let firstUpdates =
            try await firstConsumer.value

        let secondUpdates =
            try await secondConsumer.value

        #expect(firstUpdates.count == 1)
        #expect(secondUpdates.count == 1)

        guard case .fresh(let firstProfile) =
            firstUpdates[0]
        else {
            Issue.record(
                "Expected first consumer to receive fresh profile"
            )
            return
        }

        guard case .fresh(let secondProfile) =
            secondUpdates[0]
        else {
            Issue.record(
                "Expected second consumer to receive fresh profile"
            )
            return
        }

        #expect(
            firstProfile.name == "Shared Remote"
        )

        #expect(
            secondProfile.name == "Shared Remote"
        )

        let remoteCallCount =
            await service.callCount

        let cacheSaveCount =
            await cache.saveCallCount

        #expect(remoteCallCount == 1)
        #expect(cacheSaveCount == 1)
    }

}
