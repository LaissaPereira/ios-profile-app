//
//  FIleProfileCacheTests.swift
//  ProfileAppTests
//
//  Created by Laissa on 06.10.26.
//

import Testing
import Foundation
@testable import ProfileApp

struct FIleProfileCacheTests {

    @Test("Saves and loads cached profile from disk")
    func saves() async throws {
        let fileURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        let cache = await FileProfileCache(fileURL: fileURL)
        let profile = Profile(
            name: "Laissa",
            city: "Berlin",
            skills: ["Swift", "SwiftUI"],
            followers: 381
        )
    
       let saveAt = Date(timeIntervalSince1970: 1_000)
        
      await cache.save(profile, saveAt: saveAt)
        
        let loaded = await cache.load()
        
        #expect(loaded != nil)
        await #expect(loaded?.profile.name == "Laissa")
        await #expect(loaded?.profile.city == "Berlin")
        await #expect(loaded?.profile.followers == 381)
        #expect(loaded?.savedAt == saveAt)
        
        try? FileManager.default.removeItem(at: fileURL)
        
    
    }
    
    @Test("Returns nil when cache file does not exist")
    func returnsNilWhenFileDoesNotExist() async {
        
        let fileURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        let cache = await FileProfileCache(fileURL: fileURL)
        
        let loaded = await cache.load()
        
        #expect(loaded == nil)
        
    }
    
    @Test("Cache survives creation of a new cache instance")
    func cachePersistsAcrossInstances() async throws {

        let fileURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString
            )

        let profile = Profile(
            name: "Laissa",
            city: "Berlin",
            skills: ["Swift", "SwiftUI"],
            followers: 381
        )

        let savedAt = Date(
            timeIntervalSince1970: 1_000
        )

        // First cache instance
        let firstCache = await FileProfileCache(
            fileURL: fileURL
        )

        await firstCache.save(
            profile,
            saveAt: savedAt
        )

        // Imagine the app/cache object disappeared.
        // Now create a completely new instance.
        let secondCache = await FileProfileCache(
            fileURL: fileURL
        )

        let loaded =
            await secondCache.load()

        await  #expect(
            loaded?.profile.name == "Laissa"
        )

        await #expect(
            loaded?.profile.skills ==
            ["Swift", "SwiftUI"]
        )

        #expect(
            loaded?.savedAt == savedAt
        )

        try? FileManager.default.removeItem(
            at: fileURL
        )
    }
    
    @Test("Removing cache deletes persisted profile")
    func removingCacheDeletesPersistedProfile() async {

        let fileURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString
            )

        let cache = await FileProfileCache(
            fileURL: fileURL
        )

        let profile = Profile(
            name: "Laissa",
            city: "Berlin",
            skills: ["Swift"],
            followers: 381
        )

        await cache.save(
            profile,
            saveAt: Date(
                timeIntervalSince1970: 1_000
            )
        )

        #expect(await cache.load() != nil)

        await cache.remove()

        #expect(await cache.load() == nil)
    }

    
    
}
