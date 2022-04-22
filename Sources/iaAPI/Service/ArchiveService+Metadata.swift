//
//  ArchiveService+Metadata.swift
//  
//
//  Created by Hunter Lee Brown on 4/8/22.
//

import Foundation
import Combine

extension ArchiveService {
    
    public func getArchive(with identifier: String) -> Future<Archive, Error> {
        
        return Future<Archive, Error> { promise in
            
            guard !identifier.isEmpty, let url = URL(string: "https://archive.org/metadata/\(identifier)") else {
                return promise(.failure(ArchiveServiceError.badIdentifier))
            }
            
            switch self.serviceType {
            case .live:
                self.livePublisher(url: url, promise: promise)
            case .mock:
                self.mockPublisher(promise: promise)
            }
        }
    }
    
    fileprivate func mockPublisher(promise: @escaping Future<Archive, Error>.Promise) {
        let data = IAStatic.archiveDoc.data(using: .utf8)!
        let archive = try! JSONDecoder().decode(Archive.self, from: data)
        promise(.success(archive))
    }
    
    fileprivate func livePublisher(url: URL, promise: @escaping Future<Archive, Error>.Promise) {
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { (data: Data, response: URLResponse) -> Data in
                guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else { throw ArchiveServiceError.unexpectedHttpResponseCode}
                return data
            }
            .decode(type: Archive.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    switch (error) {
                    case let decodingError as DecodingError:
                        promise(.failure(decodingError))
                    case let apiError as ArchiveServiceError:
                        promise(.failure(apiError))
                    default:
                        promise(.failure(ArchiveServiceError.unknown))
                    }
                }
            } receiveValue: { promise(.success($0)) }
            .store(in: &self.cancellables)
    }
}

