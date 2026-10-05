//
//  ProfileModelTests.swift
//  ProfileApp
//
//  Created by Laissa on 22.09.26.
//

import Foundation
@testable import ProfileApp
import Testing

struct MockProfileRepository: ProfileRepository {
    let result: Result<Profile, Error>
    func fetchProfile() async throws -> Profile{
        try result.get()
    }
    func profileStream(forceRefresh : Bool) -> AsyncThrowingStream<ProfileUpdate, Error> {
        AsyncThrowingStream { continuation in
            do {
                let profile = try result.get()
                continuation.yield(.cached(profile))
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

final class ControlledProfileRepository: ProfileRepository {
    private var continuation: AsyncThrowingStream<ProfileUpdate, Error> .Continuation?
    
    func fetchProfile() async throws -> Profile {
        fatalError("fetchProfile() is not used in this test")
    }
    
    func profileStream(forceRefresh: Bool) -> AsyncThrowingStream<ProfileUpdate,Error>
    {
        AsyncThrowingStream { continuation in
                    self.continuation = continuation
                }
    }
    func succeed(with profile: Profile) {
        continuation?.yield(.fresh(profile))
        continuation?.finish()
        continuation = nil
    }
    
    func fail(with error: Error) {
        continuation?.finish(throwing: error)
        continuation = nil
        
    }
    
}


struct SlowProfileRepository: ProfileRepository {
    func fetchProfile() async throws -> Profile {
        try await Task.sleep(for: .seconds(10))
        return Profile(
            name: "Laissa",
            city: "Berlin",
            skills: ["Swift"],
            followers: 381
        )
    }
    
    func profileStream(forceRefresh : Bool) -> AsyncThrowingStream<ProfileUpdate, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let profile = try await fetchProfile()
                    continuation.yield(.cached(profile))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// Test verify if ProfileModel is update the state correctly
// Test if is feature behavior correct?
@MainActor
struct ProfileModelTests {
    @Test("Load profile successfully")
        func loadProfileSetsLoadedState() async throws {
            //Arrange
            let profile = Profile(
                name: "Laissa",
                city: "Berlin",
                skills: ["Swift", "SwiftUI"],
                followers: 381
            )
            let repository = MockProfileRepository(result: .success(profile))
            let model = ProfileModel(repository: repository)
            
            //Act
            await model.loadProfile()
            
            //Assert
            switch model.state {
            case .loaded(let loadedProfile, isRefreshing: true, refreshError: nil):
                #expect(loadedProfile.name == "Laissa")
                #expect(loadedProfile.city == "Berlin")
                #expect(loadedProfile.followers == 381)
            default:
                Issue.record("Expected loaded state")
            }
        }
    
    @Test("Shows transport error message")
    func loadProfileSetsFailedStateForTransportError() async throws {
        //Arrange
        let repository = MockProfileRepository(result: .failure(NetworkError.transport))
        let model = ProfileModel(repository: repository)
        
        //Act
        await model.loadProfile()
        
        //Assert
        switch model.state{
        case.failed(let message):
            #expect(
                message == "Please check your internet connection and try again."
            )
        default:
            Issue.record("Expect failed state")
        }
    }
    @Test("Enters loading state while profile request is in progress")
    func loadProfileSetsLoadingStateBeforeFinishing() async throws {
        //Arrange
        let repository = ControlledProfileRepository()
        let model = ProfileModel(repository: repository)
        
        //Act
        let task = Task {
            await model.loadProfile()
        }
        await Task.yield()
        
        //Assert loading state
        switch model.state {
        case .loading:
            break
        default:
            Issue.record("Expected loading state")
        }
        let profile = Profile(
                name: "Laissa",
                city: "Berlin",
                skills: ["Swift", "SwiftUI"],
                followers: 381
            )

    repository.succeed(with: profile)
    await task.value
    
    //Assert
    switch model.state {
    case .loaded(let loadedProfile, isRefreshing: false, refreshError: nil):
        #expect(loadedProfile.name == "Laissa")
    default:
        Issue.record("Expected loaded state")
    }
}
    @Test("Cancelling profile load does not show an error")
    func cancellingLoadDoesNotSetFailedState() async throws {
        
        //Arrange
        let model = ProfileModel(repository: SlowProfileRepository())
        //Act
        let task = Task {
            await model.loadProfile()
        }
        await Task.yield()
        task.cancel()
        await task.value
        //Assert
        switch model.state {
        case .failed:
            Issue.record("Cancellation should not produce a failed state")
        default:
            break
        }
    }
}

