//
//  ProfileModel.swift
//  ProfileApp
//
//  Created by Laissa on 18.09.26.
//

import Observation



private func message(for error: NetworkError) -> String {
    switch error {
    case .invalidURL:
        return "The request could not be created."
    case .invalidResponse:
        return "The server returned an invalid response."
    case .invalidStatusCode(let code):
        return "The server returned an error. Code: \(code)"
    case .decodingFailed:
        return "The profile data could not be read."
    case .transport:
        return "Please check your internet connection and try again."
    }
}


//What states does the screen need?
@MainActor
@Observable
final class ProfileModel {
//final class other classes cannot inherit from this one
    var state: ProfileViewState = .idle
    private let repository : any ProfileRepository
    private var loadTask: Task<Void, Never>?
    
    
    init(repository: any ProfileRepository){
        self.repository = repository
    }
    
    
    private func handle(_ error: NetworkError) {
        let message = message(for: error)
        
        switch state{
        case .loaded(let profile, _, _):
            state = .loaded(profile: profile, isRefreshing: false, refreshError: message)
        default:
            state = .failed(message)
        }

    }
    
    
    private func handleUnexpectedError() {
        let message = "Something unexpected happened."

        switch state {
        case .loaded(let profile, _, _):
            state = .loaded(
                profile: profile,
                isRefreshing: false,
                refreshError: message
            )

        default:
            state = .failed(message)
        }
    }
    
    func startLoading(forceRefresh: Bool = false) {
        //ProfileModel own the current loading task avoid duplicate refreshes
        loadTask?.cancel()
        
        loadTask = Task {
            await loadProfile(forceRefresh: forceRefresh)
        }
    }
    
    func waitForCurrentLoad() async {
        await loadTask?.value
    }
    
    func loadProfile(forceRefresh: Bool = false) async {
        state = .loading
        
        do {
            try Task.checkCancellation()
            
            for try await update in repository.profileStream(forceRefresh: forceRefresh) {
                try Task.checkCancellation()
                
                switch update {
            
                case .cached(let profile):
                        state = .loaded(
                            profile: profile,
                            isRefreshing: true,
                            refreshError: nil
                        )
                    
                    case .fresh(let profile):
                        state = .loaded(
                            profile: profile,
                            isRefreshing: false,
                            refreshError: nil
                        )
                
                }
            }
        } catch is CancellationError {
            //cancelled task
            return
            
        } catch  let error as NetworkError {
            //network failure
            handle(error)
        }catch {
            //unexpected error
            handleUnexpectedError()
        }
      
    }
    
    
}
