//
//  CachedProfileRecord.swift
//  ProfileApp
//
//  Created by Laissa on 06.10.26.
//

import Foundation
nonisolated struct CachedProfileRecord : Codable, Sendable {
    let name: String
    let city: String
    let skills: [String]
    let followers: Int
    let savedAt: Date
    
}

//conversion from domain cache model
extension CachedProfileRecord {
    nonisolated init(cachedProfile : CachedProfile){
        self.name = cachedProfile.profile.name
        self.city = cachedProfile.profile.city
        self.skills = cachedProfile.profile.skills
        self.followers = cachedProfile.profile.followers
        self.savedAt = cachedProfile.savedAt
    }
    
    func toDomain() -> CachedProfile {
        CachedProfile(
            profile : Profile(name: name, city: city, skills: skills, followers: followers),
            savedAt: savedAt
        )
    
    }
}
// Disk representation
