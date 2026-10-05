//
//  Sleeper.swift
//  ProfileApp
//
//  Created by Laissa on 24.09.26.
//

import Foundation

protocol Sleeper : Sendable {
    func sleep() async throws
}

struct TaskSleeper : Sleeper {
    func sleep() async throws {
        try await Task.sleep(for: .seconds(5))
    }
}
