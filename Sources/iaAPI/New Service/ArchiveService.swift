//
//  File.swift
//  
//
//  Created by Hunter Lee Brown on 4/6/22.
//

import Foundation
import Combine

open class ArchiveService {

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
            return "query string is empty"
        case .nodata:
            return "there is no data"
        case .badParameters:
            return "the query parameters post body was bad"
        }
    }
}
