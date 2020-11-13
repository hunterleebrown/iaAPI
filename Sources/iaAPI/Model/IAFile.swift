//
//  File.swift
//  
//
//  Created by Hunter Lee Brown on 11/13/20.
//

import Foundation

public enum IAFileFormat: String, Decodable {
    case mp3 = "VBR MP3"
    case jpg = "JPEG"
    case oggVideo = "Ogg Video"
    case h264 = "h.264"
    case h254HD = "h.264 HD"
    case mpeg2 = "MPEG2"
    case png = "PNG"
    case mp4HiRes = "HiRes MPEG4"
    case other
}

public enum IAMediaType: String {
    case audio = "audio"
    case etree = "etree"
    case image = "image"
    case movies = "movies"
    case texts = "texts"
}


public class IAFile: Decodable {

    public var name : String?
    public var title : String?
    public var track : String?
    public var size : String?
    public var format: IAFileFormat? {
        get {
            if let raw = self.rawFormat {
                return IAFileFormat(rawValue: raw)
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
                return IAStringUtils.sizeString(size: rawSize)
            }
        }
        return nil
    }


    public var displayLength: String? {

        if let l = length {
            return IAStringUtils.timeFormatter(timeString: l)
        }
        return nil
    }

    public var displayName: String {
        return self.title ?? self.name!
    }

}
