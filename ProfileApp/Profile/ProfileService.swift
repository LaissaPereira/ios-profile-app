//
//  ProfileService.swift
//  ProfileApp
//
//  Created by Laissa on 18.09.26.
//

import Foundation
//Where/how do I get Profile data

protocol ProfileService : Sendable {
    //Contract for getting profile data
    func fetchProfile() async throws -> Profile
    
}


struct MockProfileService: ProfileService {
    //Fake implementation for development/ testing
    func fetchProfile() async throws -> Profile {
        try await Task.sleep(for: .seconds(2))
        
        return Profile(
            name: "Laissa",
            city: "Berlin",
            skills: ["Swift", "SwiftUI", "Next.js"],
            followers: 381
        )
    }
}

enum ProfileServiceError : Error {
    case failed
}

struct FailingProfileService: ProfileService {
    func fetchProfile() async throws -> Profile {
        try await Task.sleep(for: .seconds(2))
        
        throw ProfileServiceError.failed
    }
}


//Here can have the definition of function in MockProfileSefice, RealProfileService, FailingProfileService

