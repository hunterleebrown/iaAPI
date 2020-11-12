//
//  IAMetaDocMappable.swift
//  IA-Music
//
//  Created by Hunter Lee Brown on 2/11/17.
//  Copyright © 2017 Hunter Lee Brown. All rights reserved.
//

import Foundation


public class IADocMetadata: Decodable {
    public var identifier: String?
    public var description: String?
    public var subject: [String] = [String]()
    public var creator: [String] = [String]()
    public var uploader: String?
    public var title: String?
    public var artist: String?

    enum CodingKeys: String, CodingKey {
        case identifier
        case description
        case subject
        case creator
        case uploader
        case title
        case artist
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try values.decodeIfPresent(String.self, forKey: .identifier)
        self.description = try values.decodeIfPresent(String.self, forKey: .description)

        if let singleSubject = try? values.decodeIfPresent(String.self, forKey: .subject) {
            self.subject.append(singleSubject)
        } else if let multiSubject = try? values.decode([String].self, forKey: .subject) {
            self.subject = multiSubject
         }

        if let singleCreator = try? values.decodeIfPresent(String.self, forKey: .creator) {
            self.creator.append(singleCreator)
        } else if let multiCreator = try? values.decode([String].self, forKey: .creator) {
            self.creator = multiCreator
        }

        self.title = try values.decodeIfPresent(String.self, forKey: .title)
        self.artist = try values.decodeIfPresent(String.self, forKey: .artist)
    }

}

public class IAArchiveDocDecodable: Decodable {

    public var metadata: IADocMetadata
//    var reviews: [[String:String]]
    public var files: [IAFileMappable]?

    enum CodingKeys: String, CodingKey {
        case metadata
        case reviews
        case files
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = try values.decode(IADocMetadata.self, forKey: .metadata)
        self.files = try values.decodeIfPresent([IAFileMappable].self, forKey: .files)
    }


    public var identifier: String? {
        get {
            return metadata.identifier
        }
    }

    public var desc: String? {
        get {
            return metadata.description
        }
    }

    public var subject: String? {
        get {
            return metadata.subject.joined(separator: ", ")
        }
    }
    
    public var creator: String? {
        get {
            return metadata.creator.joined(separator: ", ")
        }
    }
    
    public var uploader: String? {
        get {
            return metadata.uploader
        }
    }

    public var title: String? {
        get {
            return metadata.title
        }
    }
    
    public var artist: String? {
        get {
            return metadata.artist
        }
    }
    
    public var sortedFiles: [IAFileMappable]? {
        guard let audFiles = files else { return nil}
        
        let audioFiles = audFiles.filter({ (f) -> Bool in
            f.format == IAFileMappableFormat.mp3
        })
        
        return audioFiles.sorted(by: { (one, two) -> Bool in
            guard one.cleanedTrack != nil, two.cleanedTrack != nil else { return false}
            return one.cleanedTrack! < two.cleanedTrack!
        })    
    }
    
    public func iconUrl()->URL {
        let itemImageUrl = "http://archive.org/services/img/\(identifier!)"
        return URL(string: itemImageUrl)!
    }
    
    public func rawDescription()->String? {
        return metadata.description
    }

    public func noHTMLDescription()->String? {
        guard let des = desc else { return nil }
        return des.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
    public var jpg: URL? {
        
        guard
            let allFiles = files else { return nil }
        
        let jpgs = allFiles.filter({ (file) -> Bool in
            file.format == .jpg
        })
        
        guard
            jpgs.count > 0,
            let firstJpeg = jpgs.first,
            let name = firstJpeg.name
            else { return nil}
        
        return URL(string:"http://archive.org/download/\(identifier!)/\(name)")
    }
    
    public func fileUrl(file:IAFileMappable) ->URL {
        let urlString = "http://archive.org/download/\(identifier!)/\(file.name!)"
        return URL(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)!
    }
    
}

public enum IAFileMappableFormat: String, Decodable {
    case mp3 = "VBR MP3"
    case jpg   = "JPEG"
    case other
}


public class IAFileMappable: Decodable {

    public var name : String?
    public var title : String?
    public var track : String?
    public var size : String?
    public var format: IAFileMappableFormat? {
        get {
            if let raw = self.rawFormat {
                return IAFileMappableFormat(rawValue: raw)
            }

            return nil
        }
    }
    public var rawFormat: String?
    public var length: String?
    

    enum CodingKeys: String, CodingKey {
        case name
        case title
        case track
        case size
        case format
        case length
      }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try values.decodeIfPresent(String.self, forKey: .name)
        self.title = try values.decodeIfPresent(String.self, forKey: .title)
        self.track = try values.decodeIfPresent(String.self, forKey: .track)
        self.size = try values.decodeIfPresent(String.self, forKey: .size)
        self.rawFormat = try values.decodeIfPresent(String.self, forKey: .format)
        self.length = try values.decodeIfPresent(String.self, forKey: .length)

    }

    public var cleanedTrack: Int?{
        
        if let tr = track {
            if let num = Int(tr) {
                return num
            } else {
                let sp = tr.components(separatedBy: "/")
                if let first = sp.first {
                    let trimmed = first.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    return Int(trimmed) ?? nil
                }
            }
        }
        return nil
    }
    
    public var calculatedSize: String? {
    
        if let s = size {
            if let rawSize = Int(s) {
                return StringUtils.sizeString(size: rawSize)
            }
        }
        return nil
    }
    
    
    public var displayLength: String? {
        
        if let l = length {
            return StringUtils.timeFormatter(timeString: l)
        }
        return nil
    }
    
    public var displayName: String {
        return self.title ?? self.name!
    }


    
}
