//
//  DownloadView.swift
//  ProfileApp
//
//  Created by Laissa on 23.09.26.
//

import SwiftUI

struct DownloadView: View {
    
    @State private var model = DownloadModel()
    
    
    var body: some View {
        
        VStack(spacing: 16){
            Text(model.status.title)
                .font(.title2)
            
            Text("Completed downloads: \(model.completedDownloads)")
            
            if model.status.isInProgress {
                ProgressView()
                
                Button("Cancel")  {
                    Task {
                        await model.cancelDownload()
                    }
                }
                
            } else {
                
                Button("Start Download") {
                    
                   model.startDownload()
                    
                }
                
                
            }
            
        }
        .padding()
    }
}

#Preview {
    DownloadView()
}
