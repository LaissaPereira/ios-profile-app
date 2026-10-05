//
//  InMemoryProfileCache.swift
//  ProfileApp
//
//  Created by Laissa on 29.09.26.
//

import Foundation
actor InMemoryProfileCache: ProfileCache {
    private var cachedProfile : CachedProfile?
    
    func load() -> CachedProfile? {
        cachedProfile
    }
    func save(_ profile: Profile, saveAt: Date) {
        cachedProfile = CachedProfile(
            profile: profile,
            savedAt: saveAt
        )
    }
}
