# iaAPI

Internet Archive API for Swift
by Hunter Lee Brown
Document Updated November 13, 2020

## Usage
Use as a Swift Package

**import iaAPI**
import iAPI

**initialize**
let service = ArchiveService()

**search**

    service.getArchive(with identifier: String) -> Future<Archive, Error> 
    
    service.search(
        query queryString: String,
        searchField: ArchiveSearchField = .all,
        mediaTypes: [ArchiveMediaType] = [.audio, .etree],
        rows: Int = 50,
        page: Int = 1,
        format: ArchiveFileFormat?
    ) ->Future<ArchiveSearchResults, Error>
    
    service.getArchiveAsync(with identifier: String) async throws -> Archive
    
    service searchAsync(query queryString: String,
        searchField: ArchiveSearchField = .all,
        mediaTypes: [ArchiveMediaType] = [.audio, .etree],
        rows: Int = 50,
        page: Int = 1,
        format: ArchiveFileFormat?
    ) async throws -> ArchiveSearchResults

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
