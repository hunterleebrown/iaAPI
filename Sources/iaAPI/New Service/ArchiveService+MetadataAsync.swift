//
//  File.swift
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

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode
        else { throw ArchiveServiceError.unexpectedHttpResponseCode }

        guard let archive = try? JSONDecoder().decode(Archive.self, from: data)
        else { throw ArchiveServiceError.nodata }

        return archive
    }
}
