//
//  ProfileRequestCoordinator.swift
//  ProfileApp
//
//  Created by Laissa on 30.09.26.
//

import Foundation

private nonisolated func waitForSharedTask(_ sharedTask: Task<Profile, Error>) async throws -> Profile {
    let stream = AsyncThrowingStream<Profile, Error>{
        continuation in
        let waiterTask = Task {
            do {
                let profile = try await sharedTask.value
                continuation.yield(profile)
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in
            waiterTask.cancel()
        }
    }
    for try await profile in stream {
        try Task.checkCancellation()
        return profile
    }
    throw CancellationError()
}


actor ProfileRequestCoordinator {

    private struct InFlightRequest {
        let id: UUID
        let task: Task<Profile, Error>
    }

    private var inFlightRequest: InFlightRequest?

    func fetch(
        using operation: @escaping @Sendable () async throws -> Profile
    ) async throws -> Profile {

        let request: InFlightRequest

        if let existingRequest = inFlightRequest {

            // A shared request already exists.
            // Join the existing work.
            request = existingRequest

        } else {

            // No request exists yet.
            // Create the shared work.
            let id = UUID()

            let task = Task<Profile, Error> {
                try await operation()
            }

            request = InFlightRequest(
                id: id,
                task: task
            )

            inFlightRequest = request
        }

        do {
            let profile = try await request.task.value

            // Only this exact request may clear itself.
            clearRequest(id: request.id)

            // The shared operation may have succeeded,
            // but this particular caller may have cancelled.
            try Task.checkCancellation()

            return profile

        } catch {
            clearRequest(id: request.id)
            throw error
        }
    }

    private func clearRequest(id: UUID) {
        guard inFlightRequest?.id == id else {
            return
        }

        inFlightRequest = nil
    }
}
// In flight request deduplication
// Two concurrent callers -> share one in-fligth task, -> remote operation executes once, -> both callers receive the same result


