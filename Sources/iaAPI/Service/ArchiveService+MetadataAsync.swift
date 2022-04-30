//
//  ArchiveService+MetadataAsync.swift
//  
//
//  Created by Hunter Lee Brown on 4/8/22.
//

import Foundation

extension ArchiveService {

    public func getArchiveAsync(with identifier: String) async throws -> Archive {

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
        } catch let error as Error {
            throw ArchiveServiceError.decodingError(errorMessage: "\(error)")
        }

        return archive
    }
}
