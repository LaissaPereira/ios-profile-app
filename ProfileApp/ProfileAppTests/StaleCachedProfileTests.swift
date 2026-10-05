//
//  StaleCachedProfileTests.swift
//  ProfileAppTests
//
//  Created by Laissa on 29.09.26.
//

import Testing
import Foundation
@testable import ProfileApp

@MainActor
struct StaleCachedProfileTests {

    @Test("Expired cache emits stale then fresh profile")
        func expiredCacheEmitsStaleThenFresh() async throws {
                let now = Date(
                    timeIntervalSince1970: 1_000
                )

                let staleProfile = Profile(
                    name: "Stale",
                    city: "Berlin",
                    skills: ["Swift"],
                    followers: 100
                )

                let freshProfile = Profile(
                    name: "Fresh",
                    city: "Berlin",
                    skills: ["Swift", "SwiftUI"],
                    followers: 200
                )

                let service = SpyProfileService(
                    result: .success(freshProfile)
                )

                let cache = InMemoryProfileCache()

                await cache.save(
                    staleProfile,
                    saveAt: now.addingTimeInterval(-600)
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

                var receivedUpdates: [ProfileUpdate] = []

                for try await update in repository.profileStream(
                    forceRefresh: false
                ) {
                    receivedUpdates.append(update)
                }

                #expect(receivedUpdates.count == 2)

                guard case .cached(let firstProfile) = receivedUpdates[0] else {
                    Issue.record("Expected cached profile first")
                    return
                }

                guard case .fresh(let secondProfile) = receivedUpdates[1] else {
                    Issue.record("Expected fresh profile second")
                    return
                }

                #expect(firstProfile.name == "Stale")
                #expect(secondProfile.name == "Fresh")
                #expect(service.fetchCallCount == 1)
            }
}
