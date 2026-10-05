//
//  ProfileCache.swift
//  ProfileApp
//
//  Created by Laissa on 28.09.26.
//

import Foundation

protocol ProfileCache : Sendable {
    func load() async -> CachedProfile?
    func save(_ profile: Profile, saveAt: Date) async
}

