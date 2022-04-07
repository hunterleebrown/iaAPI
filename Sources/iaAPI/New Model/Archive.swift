//
//  Archive.swift
//  
//
//  Created by Hunter Lee Brown on 4/6/22.
//

import Foundation


open class ArchiveMetaData: Codable {
    public var metadata: Archive?
    public var files: [ArchiveFile] = []

    enum CodingKeys: String, CodingKey {
        case metadata
        case files
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = try values.decode(Archive.self, forKey: .metadata)
        self.files = try values.decode([ArchiveFile].self, forKey: .files)
        self.files.forEach { file in
            if let identifier = self.metadata?.identifier {
                file.identifier = identifier
            }
        }
    }

    public func fileUrl(file:ArchiveFile) -> URL? {
        guard let identifier = metadata?.identifier, let fileName = file.name else { return nil }
        let urlString = "https://archive.org/download/\(identifier)/\(fileName)"

        return URL(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
    }

    public lazy var audioFiles: [ArchiveFile] = {
        files.filter { $0.format == .mp3 }
    }()

    public lazy var non78Audio: [ArchiveFile] = {
        guard let metadata = metadata, metadata.collection.contains("78rpm") else { return [] }
        return files.filter { $0.format == .mp3  && !($0.name?.contains("78_"))! }
    }()

}

public enum ArchiveMediaType: String, Codable {
    case audio = "audio"
    case etree = "etree"
    case image = "image"
    case movies = "movies"
    case texts = "texts"
}

open class Archive: Codable {
    
    public var identifier: String?
    public var description: String?
    public var subject: [String] = []
    public var creator: [String] = []
    public var uploader: String?
    public var title: String?
    public var artist: String?
    public var collection: [String] = []
    public var publisher: String?
    public var date: String?
    public var mediatype: ArchiveMediaType?

    enum CodingKeys: CodingKey {
        case identifier
        case description
        case subject
        case creator
        case uploader
        case title
        case artist
        case collection
        case publisher
        case date
        case mediatype
    }

    public var iconUrl: URL {
        let itemImageUrl = "https://archive.org/services/img/\(identifier!)"
        return URL(string: itemImageUrl)!
    }

}
