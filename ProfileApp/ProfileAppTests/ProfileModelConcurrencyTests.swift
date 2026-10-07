//
//  ProfileModelConcurrencyTests.swift
//  ProfileAppTests
//
//  Created by Laissa on 30.09.26.
//

import Testing
@testable import ProfileApp

final class TwoRequestProfileRepository : ProfileRepository {
    
    private var requestCount = 0
    private var firstContinuation: AsyncThrowingStream<ProfileUpdate, Error>.Continuation?
    private var secondContinuation: AsyncThrowingStream<ProfileUpdate, Error>.Continuation?
    
    func fetchProfile() async throws -> Profile {
        fatalError("Not used in this test")
    }
    func profileStream(forceRefresh: Bool) -> AsyncThrowingStream<ProfileUpdate, Error>{
        requestCount += 1
        let currentRequest = requestCount
        return AsyncThrowingStream { continuation in
            
            if currentRequest == 1 {
                firstContinuation = continuation
            }else {
                secondContinuation = continuation
            }
            
        }
    }
    func clearCache() async {}
    
    func completeFirst(with profile: Profile){
        firstContinuation?.yield(.fresh(profile))
        firstContinuation?.finish()
        firstContinuation = nil
    }
    
    func completeSecond(with profile: Profile) {
        secondContinuation?.yield(.fresh(profile))
        secondContinuation?.finish()
        secondContinuation = nil
    }
    
    
}


@MainActor
struct ProfileModelConcurrencyTests {

    @Test("Latest profile request wins")
    func latestRequestWins() async throws {
        let repository = TwoRequestProfileRepository()
        
        let model = ProfileModel(repository: repository)
       
        //Start request #1
        model.startLoading()
        await Task.yield()
        
        //Beforew #1 finishes, start request #2
        model.startLoading(forceRefresh: true)
        await Task.yield()
        
        let newProfile = Profile(
            name: "NEW",
            city: "Berlin",
            skills: ["Swift"],
            followers: 500
        )
        
        repository.completeSecond(with: newProfile)
        
        await model.waitForCurrentLoad()
        
        switch model.state {
        case .loaded(let profile, isRefreshing: false, refreshError: nil):
            #expect(profile.name == "NEW")
        default:
            Issue.record("Expected newest profile to be loaded")
        }
        
        let oldProfile = Profile(
            name: "OLD",
            city: "Munich",
            skills: ["Old Data"],
            followers: 10
        )

        repository.completeFirst(
            with: oldProfile
        )

        await Task.yield()
    
        switch model.state {

        case .loaded(
            let profile,
            isRefreshing: false,
            refreshError: nil
        ):
            #expect(profile.name == "NEW")

        default:
            Issue.record(
                "Old request should not overwrite newer data"
            )
        }
    }

}
