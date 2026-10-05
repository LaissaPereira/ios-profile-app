//
//  DownloadModel.swift
//  ProfileApp
//
//  Created by Laissa on 23.09.26.
//

import Observation


@MainActor
@Observable
final class DownloadModel {
    
    var status : DownloadStatus = .ready
    var completedDownloads = 0
    
    private var downloadTask: Task<Void, Never>?
    private let sleeper : any Sleeper
    
    init(sleeper: any Sleeper = TaskSleeper()) {
         self.sleeper = sleeper
     }
   
    func startDownload() {
        
        guard downloadTask == nil else { return }
        
        downloadTask = Task {
            
            status = .downloading
        
        
        do {
            try await sleeper.sleep()
            
            try Task.checkCancellation()
            
            completedDownloads += 1
            status = .completed
            
        } catch is CancellationError {
            status = .cancelled
            
        } catch {
            status = .failed
        }
    
        }
    }
    func cancelDownload() async {
        guard let task = downloadTask else {
            return
        }
        task.cancel()
        await task.value
        downloadTask = nil
    }

}

