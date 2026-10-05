//
//  DefaultProfileRepository.swift
//  ProfileApp
//
//  Created by Laissa on 28.09.26.
//

import Foundation

struct DefaultProfileRepository: ProfileRepository {

    let remoteService: any ProfileService
    let cache: any ProfileCache
    let dateProvider: any DateProvider
    let cacheLifetime: TimeInterval
    let requestCoordinator: ProfileRequestCoordinator

    func fetchProfile() async throws -> Profile {

        let now = dateProvider.now()

        if let cached = await cache.load() {
            let age = now.timeIntervalSince(cached.savedAt)

            if age < cacheLifetime {
                return cached.profile
            }
        }

        let profile = try await requestCoordinator.fetch {
            try await fetchAndCacheFreshProfile()
        }

        return profile
    }

    func profileStream(
        forceRefresh: Bool
    ) -> AsyncThrowingStream<ProfileUpdate, Error> {

        AsyncThrowingStream { continuation in

            let task = Task {
                do {
                    let now = dateProvider.now()

                    if !forceRefresh,
                       let cached = await cache.load() {

                        let age = now.timeIntervalSince(
                            cached.savedAt
                        )

                        continuation.yield(
                            .cached(cached.profile)
                        )

                        if age < cacheLifetime {
                            continuation.finish()
                            return
                        }
                    }

                    try Task.checkCancellation()

                    let freshProfile =
                        try await requestCoordinator.fetch {
                            try await fetchAndCacheFreshProfile()
                        }

                    try Task.checkCancellation()

                    continuation.yield(
                        .fresh(freshProfile)
                    )

                    continuation.finish()

                } catch is CancellationError {
                    continuation.finish()

                } catch {
                    continuation.finish(
                        throwing: error
                    )
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func fetchAndCacheFreshProfile() async throws -> Profile {

        let profile =
            try await remoteService.fetchProfile()

        await cache.save(
            profile,
            saveAt: dateProvider.now()
        )

        return profile
    }
}

