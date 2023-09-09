//
//  ArchiveService.swift
//  
//
//  Created by Hunter Lee Brown on 4/6/22.
//

import Foundation
import Combine

/// For using mock json or live from URL
/// - .live is default
public enum ArchiveServiceType {
    case mock, live
}


open class ArchiveService {
    
    let serviceType: ArchiveServiceType

    /// Initer
    ///
    /// Params:
    /// - serviceType: ArchiveServiceType
    ///
    public init(_ serviceType: ArchiveServiceType = .live) {
        self.serviceType = serviceType
    }

    /// Base metadata path. Used for individual item requests
    ///
    /// Initial Value:
    /// - https://archive.org/metadata/
    ///
    /// The unique archive identifier is appended to this value
    public var baseMetadataPath = "https://archive.org/metatdata/"

    /// The main archive search endpoint
    ///
    /// Initial Value:
    /// - https://archive.org/advancedsearch.php
    public var searchUrl: URL = URL(string: "https://archive.org/advancedsearch.php")!

    /// Default Collections not to be included in searches
    ///
    /// Default values:
    /// - podcast_mirror
    /// - web
    /// - webwidecrawl
    /// - samples_only
    public var notIncluding: [String] = ["podcasts_mirror", "web", "webwidecrawl", "samples_only"]
    
    internal var cancellables = Set<AnyCancellable>()

}

public enum ArchiveServiceError: Error {
    case badIdentifier
    case unexpectedHttpResponseCode
    case unknown
    case nodata
    case emptyQueryString
    case badParameters
    case decodingError(errorMessage: String)
}

public enum ArchiveTopCollectionType: String {
    case audio
    case movies
    case texts
}

extension ArchiveServiceError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .badIdentifier:
            return "Bad Identifier"
        case .unexpectedHttpResponseCode:
            return "Unexpected https response code"
        case .unknown:
            return "Unknown error"
        case .emptyQueryString:
            return "Query string is empty."
        case .nodata:
            return "No items were found."
        case .badParameters:
            return "The query parameters post body is incorrect."
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}
