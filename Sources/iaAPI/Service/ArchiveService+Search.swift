//
//  ArchiveService+Search.swift
//  
//
//  Created by Hunter Lee Brown on 4/8/22.
//

import Foundation
import Combine

public enum ArchiveSearchField: Int {
    case all = 0
    case creator = 1
}

public class ArchiveResponse: Decodable {
    public var docs: [ArchiveMetaData] = [ArchiveMetaData]()
    public var numFound: Int = 0

    enum CodingKeys: String, CodingKey {
        case docs
        case numFound
    }
}

public class ArchiveSearchResults: Decodable {
    public var response: ArchiveResponse = ArchiveResponse()

    enum CodingKeys: String, CodingKey {
        case response
    }
}

extension ArchiveService {

    public func search(
        query queryString: String,
        searchField: ArchiveSearchField = .all,
        mediaTypes: [ArchiveMediaType] = [.audio, .etree],
        rows: Int = 50,
        page: Int = 1,
        format: ArchiveFileFormat?
    ) ->Future<ArchiveSearchResults, Error> {

        return Future<ArchiveSearchResults, Error> { promise in
            guard let parameters = self.buildQueryParameters(input: queryString,
                                                             searchField: searchField,
                                                             mediaTypes: mediaTypes,
                                                             rows: rows,
                                                             page: page,
                                                             format: format) else {
                promise(.failure(ArchiveServiceError.emptyQueryString))
                return
            }

            var urlRequest = URLRequest(url: self.searchUrl)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = parameters.data(using: String.Encoding.utf8)

            URLSession.shared.dataTaskPublisher(for: urlRequest)
                .tryMap { (data: Data, response: URLResponse) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else { throw ArchiveServiceError.unexpectedHttpResponseCode}
                    return data
                }
                .decode(type: ArchiveSearchResults.self, decoder: JSONDecoder())
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



    internal func buildQueryParameters(input: String,
                                      searchField: ArchiveSearchField,
                                      mediaTypes:[ArchiveMediaType],
                                      rows:Int,
                                      page: Int,
                                      format:ArchiveFileFormat?
    )-> String? {

        guard input.count > 0 else {
            return nil
        }

        var queryString = ""

        switch searchField {
        case .all:
            queryString = input
        case .creator:
            queryString = "creator:\(input)"
        }

        let nots = self.notIncluding
        var queryExclusions = ""
        for not in nots {
            queryExclusions += " AND NOT collection:\(not)"
        }

        var qmediaTypes: [String] = []
        mediaTypes.forEach { (type) in
            qmediaTypes.append("mediaType:\(type.rawValue)")
        }
        let queryMediaTypes = qmediaTypes.joined(separator: " OR ")

        var query:String = "\(queryString)\(queryExclusions) AND (\(queryMediaTypes))"
        if let f = format {
            query.append(" AND format:\"\(f.rawValue)\" ")
        }

        return "q=\(query)&output=json&rows=\(rows)&page=\(page)"
    }
}