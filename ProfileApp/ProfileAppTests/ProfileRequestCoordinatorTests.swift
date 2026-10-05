//
//  ProfileRequestCoordinatorTests.swift
//  ProfileAppTests
//
//  Created by Laissa on 30.09.26.
//

import Testing
@testable import ProfileApp
actor ControlledRemoteService: ProfileService {

    private struct StartWaiter {
        let expectedCallCount: Int
        let continuation: CheckedContinuation<Void, Never>
    }

    private var continuation:
        CheckedContinuation<Profile, Error>?

    private var startWaiters: [StartWaiter] = []

    private(set) var callCount = 0

    func fetchProfile() async throws -> Profile {
        callCount += 1

        let readyWaiters = startWaiters.filter {
            callCount >= $0.expectedCallCount
        }

        startWaiters.removeAll {
            callCount >= $0.expectedCallCount
        }

        for waiter in readyWaiters {
            waiter.continuation.resume()
        }

        return try await withCheckedThrowingContinuation {
            continuation in

            self.continuation = continuation
        }
    }

    func waitUntilCallCount(
        _ expectedCount: Int
    ) async {

        if callCount >= expectedCount {
            return
        }

        await withCheckedContinuation {
            continuation in

            startWaiters.append(
                StartWaiter(
                    expectedCallCount: expectedCount,
                    continuation: continuation
                )
            )
        }
    }

    func succeed(with profile: Profile) {
        continuation?.resume(
            returning: profile
        )

        continuation = nil
    }

    func fail(with error: Error) {
        continuation?.resume(
            throwing: error
        )

        continuation = nil
    }
}

enum TestErrorControlled: Error {
    case failed
}
@MainActor
struct ProfileRequestCoordinatorTests {

    @Test("Concurrent callers share one in-flight request")
    func concurrentCallersShareOneInFlightRequest() async throws {

        let coordinator = ProfileRequestCoordinator()
        let service = ControlledRemoteService()

        let profile = Profile(
            name: "Laissa",
            city: "Berlin",
            skills: ["Swift", "SwiftUI"],
            followers: 381
        )

        let firstTask = Task {
            try await coordinator.fetch {
                try await service.fetchProfile()
            }
        }

        // Guaranteed: remote request #1 is now running.
        await service.waitUntilCallCount(1)

        let secondTask = Task {
            try await coordinator.fetch {
                try await service.fetchProfile()
            }
        }

        // Give caller #2 a chance to enter the coordinator.
        await Task.yield()

        let callCountBeforeCompletion =
            await service.callCount

        #expect(callCountBeforeCompletion == 1)

        await service.succeed(
            with: profile
        )

        let firstResult =
            try await firstTask.value

        let secondResult =
            try await secondTask.value

        #expect(firstResult.name == "Laissa")
        #expect(secondResult.name == "Laissa")

        let finalCallCount =
            await service.callCount

        #expect(finalCallCount == 1)
    }

    @Test("Cancelling one caller does not cancel shared request")
    func cancellingOneCallerDoesNotCancelSharedRequest() async throws {

        let coordinator = ProfileRequestCoordinator()
        let service = ControlledRemoteService()

        let firstTask = Task {
            try await coordinator.fetch {
                try await service.fetchProfile()
            }
        }

        await service.waitUntilCallCount(1)

        let secondTask = Task {
            try await coordinator.fetch {
                try await service.fetchProfile()
            }
        }

        await Task.yield()

        firstTask.cancel()

        let profile = Profile(
            name: "Laissa",
            city: "Berlin",
            skills: ["Swift", "SwiftUI"],
            followers: 381
        )

        // Shared network work is NOT cancelled.
        await service.succeed(
            with: profile
        )

        do {
            _ = try await firstTask.value

            Issue.record(
                "Expected first caller to be cancelled"
            )

        } catch is CancellationError {
            // Expected ✅

        } catch {
            Issue.record(
                "Expected CancellationError, got \(error)"
            )
        }

        // Other consumer still receives the shared result.
        let secondResult =
            try await secondTask.value

        #expect(
            secondResult.name == "Laissa"
        )

        let finalCallCount =
            await service.callCount

        #expect(finalCallCount == 1)
    }

    @Test("Shared failure clears request and allows retry")
    func sharedFailureClearsRequestAndAllowsRetry() async {

        let coordinator = ProfileRequestCoordinator()
        let service = ControlledRemoteService()

        let firstTask = Task {
            try await coordinator.fetch {
                try await service.fetchProfile()
            }
        }

        await service.waitUntilCallCount(1)

        let secondTask = Task {
            try await coordinator.fetch {
                try await service.fetchProfile()
            }
        }

        await Task.yield()

        #expect(
            await service.callCount == 1
        )

        await service.fail(
            with: TestErrorControlled.failed
        )

        do {
            _ = try await firstTask.value

            Issue.record(
                "Expected first caller to fail"
            )
        } catch {
            // Expected
        }

        do {
            _ = try await secondTask.value

            Issue.record(
                "Expected second caller to fail"
            )
        } catch {
            // Expected
        }

        // Previous failed request should now be cleared.

        let retryProfile = Profile(
            name: "Retry Success",
            city: "Berlin",
            skills: ["Swift"],
            followers: 999
        )

        let thirdTask = Task {
            try await coordinator.fetch {
                try await service.fetchProfile()
            }
        }

        // Deterministically wait for NEW network request.
        await service.waitUntilCallCount(2)

        #expect(
            await service.callCount == 2
        )

        await service.succeed(
            with: retryProfile
        )

        do {
            let result =
                try await thirdTask.value

            #expect(
                result.name == "Retry Success"
            )

        } catch {
            Issue.record(
                "Expected retry request to succeed, got \(error)"
            )
        }
    }
}
