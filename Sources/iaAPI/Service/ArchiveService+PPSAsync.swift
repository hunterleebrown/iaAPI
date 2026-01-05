//
//  ArchiveService+PPSAsync.swift
//  iaAPI
//
//  Created by Hunter Lee Brown on 12/19/25.
//

import Foundation

// MARK: - PPS Response Structures
private struct PPSResponse: Decodable {
    let response: PPSResponseBody
}

private struct PPSResponseBody: Decodable {
    let body: PPSBody
}

private struct PPSBody: Decodable {
    let hits: PPSHits
    let collection_titles: [String: PPSCollectionTitle]
    
    enum CodingKeys: String, CodingKey {
        case hits
        case collection_titles
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hits = try container.decode(PPSHits.self, forKey: .hits)
        
        // Handle collection_titles polymorphic structure
        var titles: [String: PPSCollectionTitle] = [:]
        
        if let titlesContainer = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .collection_titles) {
            for key in titlesContainer.allKeys {
                // Try to decode as string first (simpler case)
                if let titleString = try? titlesContainer.decode(String.self, forKey: key) {
                    // It's just a string, create a PPSCollectionTitle with the key as identifier
                    titles[key.stringValue] = PPSCollectionTitle(identifier: key.stringValue, title: titleString)
                } 
                // Otherwise try to decode as full object
                else if let fullObject = try? titlesContainer.decode(PPSCollectionTitle.self, forKey: key) {
                    titles[key.stringValue] = fullObject
                }
            }
        }
        
        collection_titles = titles
    }
    
    // Dynamic coding keys to handle arbitrary dictionary keys
    struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        init?(intValue: Int) {
            return nil
        }
    }
}

private struct PPSHits: Decodable {
    let total: Int
    let returned: Int
    let hits: [PPSHit]
}

private struct PPSHit: Decodable {
    let fields: ArchiveMetaData
}

private struct PPSCollectionTitle: Decodable {
    let identifier: String
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case title
    }
    
    // Standard Decodable init for object format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        title = try container.decode(String.self, forKey: .title)
    }
    
    // Custom initializer for programmatic creation (string format case)
    init(identifier: String, title: String) {
        self.identifier = identifier
        self.title = title
    }
}

extension ArchiveService {
    public func searchPPSAsync(query queryString: String,
                            searchField: ArchiveSearchField = .all,
                            mediaTypes: [ArchiveMediaType] = [.audio, .etree],
                            rows: Int = 50,
                            page: Int = 1,
                            format: ArchiveFileFormat?,
                            collection: String? = nil
    ) async throws -> ArchiveSearchResults {

        guard let queryItems = self.ppsQueryParameters(input: queryString,
                                                        searchField: searchField,
                                                        mediaTypes: mediaTypes,
                                                        rows: rows,
                                                        page: page,
                                                        format: format,
                                                        collection: collection) else {
            throw ArchiveServiceError.badParameters
        }

        var archiveData: Data?

        switch serviceType {
        case .live:
            // Build URL with query parameters for GET request
            guard var urlComponents = URLComponents(url: self.pps, resolvingAgainstBaseURL: true) else {
                throw ArchiveServiceError.badParameters
            }
            
            urlComponents.queryItems = queryItems
            
            guard let requestURL = urlComponents.url else {
                throw ArchiveServiceError.badParameters
            }
            
            print("📡 PPS Request URL: \(requestURL)")
            
            var urlRequest = URLRequest(url: requestURL)
            urlRequest.httpMethod = "GET"

            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode
            else { throw ArchiveServiceError.unexpectedHttpResponseCode }
            archiveData = data
        case .mock:
            archiveData = IAStatic.searchResult.data(using: .utf8)!
        }

        guard let ppsData = archiveData else { throw ArchiveServiceError.nodata }

        // Pretty print JSON for debugging
//        if let jsonObject = try? JSONSerialization.jsonObject(with: ppsData, options: []),
//           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
//           let prettyString = String(data: prettyData, encoding: .utf8) {
//            print("📦 PPS Response JSON:\n\(prettyString)")
//        }

        // Decode PPS response and convert to ArchiveSearchResults
        do {
            let ppsResponse = try JSONDecoder().decode(PPSResponse.self, from: ppsData)
            
            // Get collection titles for building Archive objects (already non-nil, may be empty)
            let collectionTitles = ppsResponse.response.body.collection_titles
            
            // Convert PPS response to standard ArchiveSearchResults format
            // Create JSON that matches ArchiveSearchResults structure
            let adaptedJSON: [String: Any] = [
                "response": [
                    "numFound": ppsResponse.response.body.hits.total,
                    "start": (page - 1) * rows,
                    "docs": ppsResponse.response.body.hits.hits.map { hit -> [String: Any] in
                        // Convert each hit.fields to dictionary format
                        var doc: [String: Any] = [:]
                        
                        if let identifier = hit.fields.identifier {
                            doc["identifier"] = identifier
                        }
                        if let title = hit.fields.archiveTitle {
                            doc["title"] = title
                        }
                        if let description = hit.fields.description.first {
                            doc["description"] = description
                        }
                        if let subject = hit.fields.subject as [String]?, !subject.isEmpty {
                            doc["subject"] = subject
                        }
                        if let creator = hit.fields.creator {
                            doc["creator"] = creator
                        }
                        if let collection = hit.fields.collection as [String]?, !collection.isEmpty {
                            doc["collection"] = collection
                        }
                        if let date = hit.fields.date {
                            doc["date"] = date
                        }
                        doc["mediatype"] = hit.fields.mediatype.rawValue
                        
                        return doc
                    }
                ]
            ]
            
            // Convert back to JSON data and decode as ArchiveSearchResults
            let adaptedData = try JSONSerialization.data(withJSONObject: adaptedJSON)
            let results = try JSONDecoder().decode(ArchiveSearchResults.self, from: adaptedData)
            
            // Build collectionArchives for each doc
            results.response.docs = results.response.docs.map { metadata in
                var mutableMetadata = metadata
                
                // Build Archive objects from collection identifiers
                mutableMetadata.collectionArchives = metadata.collection.compactMap { collectionId in
                    guard let collectionInfo = collectionTitles[collectionId] else {
                        return nil
                    }
                    
                    // Create a basic Archive with metadata
                    return createBasicArchive(
                        identifier: collectionInfo.identifier,
                        title: collectionInfo.title
                    )
                }
                
                return mutableMetadata
            }
            
            return results
        } catch let error as DecodingError {
            print("❌ Decoding error: \(error)")
            throw ArchiveServiceError.decodingError(errorMessage: "\(error)")
        } catch let error as Error {
            print("❌ Error: \(error)")
            throw ArchiveServiceError.decodingError(errorMessage: "\(error)")
        }
    }
    
    // Helper function to create a basic Archive from collection info
    private func createBasicArchive(identifier: String, title: String?) -> Archive {
        // Create JSON for a basic Archive structure
        let archiveJSON: [String: Any] = [
            "metadata": [
                "identifier": identifier,
                "title": title ?? identifier,
                "mediatype": "collection"
            ],
            "files": []
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: archiveJSON)
            let archive = try JSONDecoder().decode(Archive.self, from: data)
            return archive
        } catch {
            // Fallback: return an Archive with minimal metadata
            print("⚠️ Failed to create Archive for \(identifier): \(error)")
            // This will never actually be reached due to the simple JSON structure above
            fatalError("Failed to create basic Archive")
        }
    }

    internal func ppsQueryParameters(input: String,
                                       searchField: ArchiveSearchField,
                                       mediaTypes: [ArchiveMediaType],
                                       rows: Int,
                                       page: Int,
                                       format: ArchiveFileFormat?,
                                       collection: String? = nil) -> [URLQueryItem]? {

        guard input.count > 0 else {
            return nil
        }

        var queryString = ""

        switch searchField {
        case .all:
//            queryString = "( \(buildQueryString(input: input)) )"
            queryString = input
        case .creator:
            queryString = "creator:\(input)"
        }

        let nots = self.notIncluding
        var queryExclusions = ""
        for not in nots {
            queryExclusions += " AND NOT collection:\(not)"
        }

        queryExclusions += "AND NOT access-restricted-item:true"

        var qmediaTypes: [String] = []
        mediaTypes.forEach { (type) in
            qmediaTypes.append("mediaType:\(type.rawValue)")
        }
        let queryMediaTypes = qmediaTypes.joined(separator: " OR ")

        var query: String = "\(queryString)\(queryExclusions) AND (\(queryMediaTypes))"

        if let f = format {
            query.append(" AND format:\"\(f.rawValue)\"")
        }

        if let collection = collection {
            query.append(" AND collection:\(collection)")
        }

        return [
            URLQueryItem(name: "user_query", value: query),
            URLQueryItem(name: "hits_per_page", value: "\(rows)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]
    }

}
