//
//  ArchiveService+Metadata.swift
//  
//
//  Created by Hunter Lee Brown on 4/8/22.
//

import Foundation
import Combine

extension ArchiveService {
    
    /// Fetches an Archive with optional collection archives using Combine
    ///
    /// - Parameter identifier: The archive identifier
    /// - Parameter includeCollections: Whether to fetch collection archives (default: true)
    /// - Returns: A Future that delivers an Archive, optionally with populated collectionArchives
    public func getArchive(with identifier: String, includeCollections: Bool = true) -> Future<Archive, Error> {
        
        return Future<Archive, Error> { promise in
            
            guard !identifier.isEmpty, let url = URL(string: "https://archive.org/metadata/\(identifier)") else {
                return promise(.failure(ArchiveServiceError.badIdentifier))
            }
            
            // First, fetch the main archive
            let mainArchiveFuture: Future<Archive, Error>
            
            switch self.serviceType {
            case .live:
                mainArchiveFuture = self.liveArchiveFuture(url: url)
            case .mock:
                mainArchiveFuture = self.mockArchiveFuture()
            }
            
            mainArchiveFuture
                .flatMap { archive -> AnyPublisher<Archive, Error> in
                    guard includeCollections,
                          let metadata = archive.metadata,
                          !metadata.collection.isEmpty else {
                        return Just(archive)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                    
                    // Fetch all collection archives
                    let collectionPublishers = metadata.collection.map { collectionIdentifier in
                        self.fetchArchive(with: collectionIdentifier)
                            .map { Optional($0) }
                            .catch { _ in Just(nil) }
                            .eraseToAnyPublisher()
                    }
                    
                    return Publishers.MergeMany(collectionPublishers)
                        .collect()
                        .map { collectionResults -> Archive in
                            var mutableArchive = archive
                            let validCollections = collectionResults.compactMap { $0 }
                            mutableArchive.metadata?.collectionArchives = validCollections
                            return mutableArchive
                        }
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { archive in
                        promise(.success(archive))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /// Internal method that fetches a single archive
    private func fetchArchive(with identifier: String) -> Future<Archive, Error> {
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
    
    private func liveArchiveFuture(url: URL) -> Future<Archive, Error> {
        return Future { promise in
            self.livePublisher(url: url, promise: promise)
        }
    }
    
    private func mockArchiveFuture() -> Future<Archive, Error> {
        return Future { promise in
            self.mockPublisher(promise: promise)
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

