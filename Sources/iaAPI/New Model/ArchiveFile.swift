//
//  File.swift
//  
//
//  Created by Hunter Lee Brown on 4/6/22.
//

import Foundation

public enum ArchiveFileFormat: String, Codable {
    case mp3 = "VBR MP3"
    case jpg = "JPEG"
    case oggVideo = "Ogg Video"
    case h264 = "h.264"
    case h264HD = "h.264 HD"
    case mpeg2 = "MPEG2"
    case mpg512kb = "512Kb MPEG4"
    case png = "PNG"
    case mp4HiRes = "HiRes MPEG4"
    case tiff = "TIFF"
    case other

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = ArchiveFileFormat(rawValue: string) ?? .other
    }
}

open class ArchiveFile: Codable, Identifiable {
    public var id: UUID = UUID()
    public var name: String?
    public var title: String?
    public var track: String?
    public var size: String?
    public var format: ArchiveFileFormat?
    public var length: String?

    public internal(set) var identifier: String?

    enum CodingKeys: String, CodingKey {
        case name
        case title
        case track
        case size
        case format
        case length
      }

    public lazy var url:  URL? = {
        guard let identifier = identifier, let fileName = name else { return nil }
        let urlString = "https://archive.org/download/\(identifier)/\(fileName)"

        if let encodedUrlString =  urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            return URL(string: encodedUrlString)
        }

        return nil
    }()

}
