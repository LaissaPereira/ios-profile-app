//
//  DownloadModelTests.swift
//  ProfileAppTests
//
//  Created by Laissa on 24.09.26.
//
import Testing
import Foundation
@testable import ProfileApp




struct ImmediateSleeper : Sleeper {
    func sleep() async throws {
        
    }
}

struct SuspendingSleeper : Sleeper {
    func sleep() async throws {
        try await Task.sleep(for: .seconds(60))
    }
}


@MainActor
struct DownloadModelTests {

    @Test("Download completes successfully")
    func downloadCompletes() async throws {
        // Arrange
        let model = DownloadModel(sleeper: ImmediateSleeper())
        
        //Act
        model.startDownload()
        
        await Task.yield()
        
        //Assert
        #expect(model.status == .completed )
        #expect(model.completedDownloads == 1)
        
    }
    
    @Test("Cancelling download updates status to cancelled")
    func cancellationChangesState() async throws {
        //Arrange
        let model = DownloadModel(sleeper: SuspendingSleeper())
        
        //Act
        model.startDownload()
        await Task.yield()
        
        //Assert intermediate state
        #expect(model.status == .downloading)
        
        //Act
        await model.cancelDownload()
    
        //Assert final state
        #expect(model.status == .cancelled)
        #expect(model.completedDownloads == 0)
        
        
        
    }

}
