//
//  FileProfileCache.swift
//  ProfileApp
//
//  Created by Laissa on 06.10.26.
//

import Foundation

actor FileProfileCache: ProfileCache {
    
    private let fileURL : URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    func load() async -> CachedProfile? {
        
        do {
            let data = try Data(contentsOf: fileURL)
            let record = try JSONDecoder().decode(CachedProfileRecord.self, from: data)
            
            return await record.toDomain()
        } catch {
            return nil
        }
        
    }
    
    func save(_ profile: Profile, saveAt: Date) async {
        
        let cachedProfile = CachedProfile(profile: profile, savedAt: saveAt)
        
        let record = CachedProfileRecord(
                cachedProfile: cachedProfile
            )
        
        do {
            let data = try JSONEncoder().encode(record)
            try data.write(to: fileURL, options: .atomic)
            
        } catch {
            print("Failed to save profile cache: \(error)")
        }
    }
    
    func remove() async {
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path)
            else {
                return
            }
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Failed to remove profile cache: \(error)")
        }
        
    }
    
}
