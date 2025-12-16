//
//  ArchiveService+MetadataAsync.swift
//  
//
//  Created by Hunter Lee Brown on 4/8/22.
//

import Foundation

extension ArchiveService {

    /// Fetches an Archive with optional collection archives
    ///
    /// - Parameter identifier: The archive identifier
    /// - Parameter includeCollections: Whether to fetch collection archives (default: true)
    /// - Returns: An Archive, optionally with populated collectionArchives
    public func getArchiveAsync(with identifier: String, includeCollections: Bool = true) async throws -> Archive {
        var archive = try await fetchArchive(with: identifier)
        
        guard includeCollections,
              var metadata = archive.metadata,
              !metadata.collection.isEmpty else {
            return archive
        }
        
        // Fetch all collection archives concurrently
        await withTaskGroup(of: (String, Archive?).self) { group in
            for collectionIdentifier in metadata.collection {
                group.addTask {
                    do {
                        let collectionArchive = try await self.fetchArchive(with: collectionIdentifier)
                        return (collectionIdentifier, collectionArchive)
                    } catch {
                        // Silently fail for individual collections that can't be fetched
                        print("Failed to fetch collection '\(collectionIdentifier)': \(error)")
                        return (collectionIdentifier, nil)
                    }
                }
            }
            
            var collectionArchives: [Archive] = []
            for await (_, archiveResult) in group {
                if let fetchedArchive = archiveResult {
                    collectionArchives.append(fetchedArchive)
                }
            }
            
            metadata.collectionArchives = collectionArchives
            archive.metadata = metadata
        }
        
        return archive
    }
    
    /// Internal method that performs the actual archive fetch
    private func fetchArchive(with identifier: String) async throws -> Archive {
        guard !identifier.isEmpty, let url = URL(string: "https://archive.org/metadata/\(identifier)") else {
            throw ArchiveServiceError.badIdentifier
        }

        var archiveData: Data?
        
        switch serviceType {
        case .live:
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode
            else { throw ArchiveServiceError.unexpectedHttpResponseCode }
            archiveData = data
        case .mock:
            archiveData = IAStatic.archiveDoc.data(using: .utf8)!
        }
                
        guard let data = archiveData else { throw ArchiveServiceError.nodata }

        var archive: Archive
        do {
            archive = try JSONDecoder().decode(Archive.self, from: data)
        } catch {
            throw ArchiveServiceError.decodingError(errorMessage: "\(error)")
        }

        return archive
    }
}
