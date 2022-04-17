//
//  Archive.swift
//  
//
//  Created by Hunter Lee Brown on 4/6/22.
//

import Foundation


public struct Archive: Identifiable, Codable {
    public var id: String = UUID().uuidString
    public var metadata: ArchiveMetaData?
    public var files: [ArchiveFile] = []

    enum CodingKeys: String, CodingKey {
        case metadata
        case files
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = try values.decode(ArchiveMetaData.self, forKey: .metadata)
        let getfiles: [ArchiveFile]  = try values.decode([ArchiveFile].self, forKey: .files)
        getfiles.forEach { file in
            let newFile = ArchiveFile(identifier: self.metadata?.identifier,
                                      artist: self.metadata?.artist,
                                      creator: self.metadata?.creator,
                                      archiveTitle: self.metadata?.archiveTitle,
                                      name: file.name,
                                      title: file.title,
                                      track: file.track,
                                      size: file.size,
                                      format: file.format,
                                      length: file.length)
            files.append(newFile)
        }
    }

    public var audioFiles: [ArchiveFile] {
        files.filter { $0.format == .mp3 }
    }

    public var non78Audio: [ArchiveFile] {
        guard let meta = metadata else { return [] }
        var returnedFiles = files.filter{ $0.format == .mp3 }
        if meta.collection.contains("78rpm") {
            returnedFiles = returnedFiles.filter{ !$0.name!.contains("78_")}
        }
        return returnedFiles
    }
}

public enum ArchiveMediaType: String, Codable {
    case audio = "audio"
    case etree = "etree"
    case image = "image"
    case movies = "movies"
    case texts = "texts"
    case other

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = ArchiveMediaType(rawValue: string) ?? .other
    }
}

public protocol ArchiveBaseMetaData: Hashable {
    var identifier: String? {get set}
    var archiveTitle: String? {get set}
    var artist: String? {get set}
    var creator: [String]? {get set}
}

public protocol ArchiveMetaDataProtocol {
    var description: String? {get set}
    var subject: [String] {get set}
    var uploader: String? {get set}
    var collection: [String] {get set}
    var publisher: String? {get set}
    var date: String? {get set}
    var mediatype: ArchiveMediaType {get set}
}


public struct ArchiveMetaData: Codable, ArchiveMetaDataProtocol, ArchiveBaseMetaData {
    public var identifier: String?
    public var description: String?
    public var subject: [String] = []
    public var uploader: String?
    public var creator: [String]? = []
    public var archiveTitle: String?
    public var artist: String?
    public var publisher: String?
    public var date: String?
    public var mediatype: ArchiveMediaType
    public var collection: [String] = []

    enum CodingKeys: String, CodingKey {
        case identifier
        case description
        case subject
        case creator
        case uploader
        case archiveTitle = "title"
        case artist
        case collection
        case publisher
        case date
        case mediatype
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try values.decode(String.self, forKey: .identifier)
        self.description = try values.decodeIfPresent(String.self, forKey: .description)

        if let singleSubject = try? values.decodeIfPresent(String.self, forKey: .subject) {
            self.subject.append(singleSubject)
        } else if let multiSubject = try? values.decode([String].self, forKey: .subject) {
            self.subject = multiSubject
         }

        if let singleCreator = try? values.decodeIfPresent(String.self, forKey: .creator) {
            self.creator = [singleCreator]
        } else if let multiCreator = try? values.decode([String].self, forKey: .creator) {
            self.creator = multiCreator
        }

        self.archiveTitle = try values.decodeIfPresent(String.self, forKey: .archiveTitle)
        self.artist = try values.decodeIfPresent(String.self, forKey: .artist)

        if let singleCollection = try? values.decodeIfPresent(String.self, forKey: .collection) {
            self.collection.append(singleCollection)
        } else if let multipleCollection = try? values.decode([String].self, forKey: .collection) {
            self.collection = multipleCollection
        }

        self.publisher = try values.decodeIfPresent(String.self, forKey: .publisher)
        self.date = try values.decodeIfPresent(String.self, forKey: .date)
        self.mediatype = try values.decode(ArchiveMediaType.self, forKey: .mediatype)
    }

    public var iconUrl: URL {
        let itemImageUrl = "https://archive.org/services/img/\(identifier!)"
        return URL(string: itemImageUrl)!
    }

}
