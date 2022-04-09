# iaAPI

Internet Archive API for Swift
- by Hunter Lee Brown
- Document Updated April 8, 2022

## Usage
Use as a Swift Package

### Import
    import iaAPI

### Initialize
    let service = ArchiveService()

### Search
#### Using Future (Combine)
    service.search(
        query queryString: String,
        searchField: ArchiveSearchField = .all,
        mediaTypes: [ArchiveMediaType] = [.audio, .etree],
        rows: Int = 50,
        page: Int = 1,
        format: ArchiveFileFormat?
    ) ->Future<ArchiveSearchResults, Error>
    
#### Using async await (iOS 15+)
    service searchAsync(query queryString: String,
        searchField: ArchiveSearchField = .all,
        mediaTypes: [ArchiveMediaType] = [.audio, .etree],
        rows: Int = 50,
        page: Int = 1,
        format: ArchiveFileFormat?
    ) async throws -> ArchiveSearchResults

### Single Item
#### Using Future (Combine)
    service.getArchive(with identifier: String) -> Future<Archive, Error> 

#### Using async await (iOS 15 +)
    service.getArchiveAsync(with identifier: String) async throws -> Archive

### Custom Errors
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
