//
//  File.swift
//  
//
//  Created by Hunter Lee Brown on 4/6/22.
//

import Foundation

public enum ArchiveFileFormat: String, Codable, CaseIterable {
    case mp3 = "VBR MP3"
    case jpg = "JPEG"
    case oggVideo = "Ogg Video"
    case h264 = "h.264"
    case h264IA = "h.264 IA"
    case h264HD = "h.264 HD"
    case mpeg2 = "MPEG2"
    case mpg512kb = "512Kb MPEG4"
    case png = "PNG"
    case mp4HiRes = "HiRes MPEG4"
    case tiff = "TIFF"
    case mpeg4 = "MPEG4"
    case singlePageProcessedJP2Zip = "Single Page Processed JP2 ZIP"
    case other

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = ArchiveFileFormat(rawValue: string) ?? .other
    }
}

public protocol ArchiveFileProtocol: ArchiveBaseMetaData {
    var identifier: String? {get set}
    var artist: String? {get set}
    var creator: [String]? {get set}
    var archiveTitle: String? {get set}

    var name: String? {get set}
    var title: String? {get set}
    var track: String? {get set}
    var size: String? {get set}
    var format: ArchiveFileFormat? {get set}
    var length: String? {get set}
    var source: String {get set}

    var url: URL? { get }
    var displayLength: String? { get }
    var calculatedSize: String? { get }
    var iconUrl: URL { get }
    var displayTitle: String { get }
}

public struct ArchiveFile: Codable, Identifiable, ArchiveFileProtocol, Hashable {

    public var id = UUID()

    public var identifier: String?
    public var artist: String?
    public var creator: [String]?
    public var archiveTitle: String?

    public var name: String?
    public var title: String?
    public var track: String?
    public var size: String?
    public var format: ArchiveFileFormat?
    public var length: String?
    public var source: String

    enum CodingKeys: String, CodingKey {
        case name
        case title
        case track
        case size
        case format
        case length
        case source
    }

    public init(
        identifier: String? = nil,
        artist: String? = nil,
        creator: [String]? = nil,
        archiveTitle: String? = nil,
        name: String? = nil,
        title: String? = nil,
        track: String? = nil,
        size: String? = nil,
        format: ArchiveFileFormat? = nil,
        length: String? = nil,
        source: String
    ) {
        self.identifier = identifier
        self.artist = artist
        self.creator = creator
        self.archiveTitle = archiveTitle
        self.name = name
        self.title = title
        self.track = track
        self.size = size
        self.format = format
        self.length = length
        self.source = source
    }

    public var url: URL?  {
        guard let identifier = identifier, let fileName = name else { return nil }
        let urlString = "https://archive.org/download/\(identifier)/\(fileName)"

        if let encodedUrlString =  urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            return URL(string: encodedUrlString)
        }

        return nil
    }

    public var displayLength: String? {

        if let l = length {
            return IAStringUtils.timeFormatter(timeString: l)
        }
        return nil
    }

    public var calculatedSize: String? {

        if let s = size {
            if let rawSize = Int(s) {
                return IAStringUtils.sizeString(size: rawSize)
            }
        }
        return nil
    }

    public var iconUrl: URL {
        let itemImageUrl = "https://archive.org/services/img/\(identifier!)"
        return URL(string: itemImageUrl)!
    }

    public var displayTitle: String {
        return title ?? name ?? ""
    }

    public var isImage: Bool {
        switch format {
        case .jpg, .png, .tiff:
            return true
        default:
            return false
        }
    }

}
