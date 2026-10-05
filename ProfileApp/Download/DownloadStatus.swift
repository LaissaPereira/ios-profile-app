//
//  DownloadStatus.swift
//  ProfileApp
//
//  Created by Laissa on 23.09.26.
//

import Foundation

enum DownloadStatus : String, Equatable {
    case ready
    case downloading
    case completed
    case cancelled
    case failed 
    
    var title: String {
        switch self {
        case .ready:
            return "Download ready"
        
        case .downloading:
            return "Downloading your file..."
            
        case .completed:
            return "Download completed"
        
        case .cancelled:
            return "Download cancelled"
        
        case .failed:
            return "Download failed. Try again."
        }
    }
    
    var isInProgress: Bool {
        self == .downloading
    }
    
}
