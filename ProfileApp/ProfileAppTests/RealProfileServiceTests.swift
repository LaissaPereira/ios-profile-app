//
//  RealProfileServiceTests.swift
//  ProfileApp
//
//  Created by Laissa on 21.09.26.
//
import Testing
import Foundation
@testable import ProfileApp

enum TestError: Error {
    case networkFailed
}

//Testing URL session - is networking behaivor correct?
@MainActor
struct RealProfileServiceTests {
    
    
    //Test setup
    
    private func makeURL() -> URL {
        URL(string: "https://example.com/profile")!
    }
    
    private func makeResponse(statusCode: Int) -> HTTPURLResponse{
        HTTPURLResponse(
            url: makeURL(),
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
    private func makeService(result: Result<(Data, URLResponse), Error>) -> RealProfileService {
        let client = MockHTTPClient(result: result)
        return RealProfileService(client: client)
    }
    
    private func makeValidProfileData() -> Data {
        let json = """
            {
                "name": "Laissa",
                "city": "Berlin",
                "skills": ["Swift", "SwiftUI"],
                "followers": "381"
            }
            """
        return Data(json.utf8)
    }
    
    private func makeInvalidProfileData() -> Data {
        let json = """
        {
                    
         "name": "Laissa",
         "city": "Berlin",
         "skills": ["Swift", "SwiftUI"],
         "followers": true
        }
        """
        return Data(json.utf8)
    }
    
    
    @Test("Testing the networking method with HTTP 200 status and success result")
    //Positive test when can service.fetchProfile() should be return 200 status code from HTTP and valid JSON
    //It isn't using the internet fake data + fake HTTPURLResponse
    func fetchProfileReturnsDecodedProfile() async throws {
        //Arrange - fake JSON + HTTP 200 + MockHTTPClient
        
        let response = makeResponse(statusCode: 200)
    
        //Create service
        let service = makeService(result: .success((makeValidProfileData(), response)))
        
        
        // Act - call service.fetchProfile()
        let profile = try await service.fetchProfile()
        
        // Asset - profile.name == "Laissa"
        // check decoded Profile
        #expect(profile.name == "Laissa")
        #expect(profile.city == "Berlin")
        #expect(profile.followers == 381)
        #expect(profile.skills == ["Swift", "SwiftUI"])
    }
    
    @Test("Testing the networking method should throw the right error")
    func fetchProfileThrowsInvalidStatusCode() async throws {
        //Arrange
        let data = Data()
        
        let response = makeResponse(statusCode: 500)
        
        let service = makeService(result: .success((data, response)))
        
        //Act + Assert
        await #expect(throws: NetworkError.self){
            try await service.fetchProfile()
        }
        
    }
    @Test("Testing the networking method should throw  HTTP 500 status and throw error")
    //Negative test when can service.fetchProfile() should be return 500 status code from HTTP and swift emitt the error message
    func fetchProfileThrows500StatusCode() async throws {
        //Arrange
        let data = Data()
        
        
        let response = makeResponse(statusCode: 500)
       
        let service = makeService(result: .success((data, response)))
        
        //Act + Assert
        do {
            _ = try await service.fetchProfile()
            Issue.record("Expected invalidStatusCode(500) to be throw")
        }catch let error as NetworkError {
            #expect(error == .invalidStatusCode(500))
        }catch {
            Issue.record("Unexpected error: \(error)")
        }

    }
    
    
    @Test("Testing networking and should fail per invalid Json and decoding failed in Profile DTO")
    //Negative test when can service.fetchProfile() should be return 200 status code from HTTP but swift emitt the error message when decoding the JSON per invalid JSON
    func fecthProfileThrowsDecodingFaliedForInvalidJSON() async throws {
        //Arrange
        
        
        let response = makeResponse(statusCode: 200)
        
        
        let service = makeService(result: .success((makeInvalidProfileData(), response)))
        
        //Act + Assert
        do {
            _ = try await service.fetchProfile()
            Issue.record("Expected decodingFailed to be throw")
        }catch let error as NetworkError  {
            #expect(error  == .decodingFailed)
        }catch {
            Issue.record("Unexpected error: \(error)")
        }
        
    }
    @Test("Maps transport failures to NetworkError.transport")
    func fetchProfileMapsTransportError() async throws {
        // Arrange
    
        let service = makeService(result: .failure(TestError.networkFailed))
        
        //Act & Assert
        
        do {
            _ = try await service.fetchProfile()
            Issue.record("Expect NetworkError.transport")
        } catch let error as NetworkError {
            #expect(error == .transport)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
