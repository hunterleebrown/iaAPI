//
//  ArchiveService+SearchAsync.swift
//  
//
//  Created by Hunter Lee Brown on 4/8/22.
//

import Foundation

extension ArchiveService {

    public func searchAsync(query queryString: String,
        searchField: ArchiveSearchField = .all,
        mediaTypes: [ArchiveMediaType] = [.audio, .etree],
        rows: Int = 50,
        page: Int = 1,
        format: ArchiveFileFormat?
    ) async throws -> ArchiveSearchResults {

        guard let parameters = self.buildQueryParameters(input: queryString,
                                                         searchField: searchField,
                                                         mediaTypes: mediaTypes,
                                                         rows: rows,
                                                         page: page,
                                                         format: format) else {
            throw ArchiveServiceError.badParameters
        }

        var archiveData: Data?
        
        switch serviceType {
        case .live:
            var urlRequest = URLRequest(url: self.searchUrl)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = parameters.data(using: String.Encoding.utf8)

            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode
            else { throw ArchiveServiceError.unexpectedHttpResponseCode }
            archiveData = data
        case .mock:
            archiveData = IAStatic.searchResult.data(using: .utf8)!
        }

        guard let data = archiveData, let results = try? JSONDecoder().decode(ArchiveSearchResults.self, from: data)
        else { throw ArchiveServiceError.nodata }

        return results
    }


}

