//
//  ProfileRepository.swift
//  ProfileApp
//
//  Created by Laissa on 28.09.26.
//

import Foundation

protocol ProfileRepository : Sendable {
    
    func fetchProfile() async throws -> Profile
    
    func profileStream(forceRefresh: Bool) -> AsyncThrowingStream<ProfileUpdate, Error>
    
    func clearCache() async
}



struct MockProfileRepository: ProfileRepository {
    let result: Result<Profile, Error>
    
    func fetchProfile() async throws -> Profile {
        try result.get()
    }
    
    func profileStream(forceRefresh: Bool = false) -> AsyncThrowingStream<ProfileUpdate, Error>{
        AsyncThrowingStream { continuation in
            do {
                let profile = try result.get()
                
                continuation.yield(.fresh(profile))
                continuation.finish()
                
            } catch {
                continuation.finish(throwing: error)
            }
        }
        
    }
    func clearCache() async {}
}
