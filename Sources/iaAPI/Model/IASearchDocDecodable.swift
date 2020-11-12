//
//  IAMapperDoc.swift
//  IA-Music
//
//  Created by Hunter Lee Brown on 2/10/17.
//  Copyright © 2017 Hunter Lee Brown. All rights reserved.
//

import Foundation

public class IAResponse: Decodable {
    public var docs: [IASearchDocDecodable] = [IASearchDocDecodable]()

    enum CodingKeys: String, CodingKey {
        case docs
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.docs = try values.decodeIfPresent([IASearchDocDecodable].self, forKey: .docs)!
    }
}


public class IASearchResults: Decodable {
    var response: IAResponse?

    enum CodingKeys: String, CodingKey {
        case response
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let resp = try values.decodeIfPresent(IAResponse.self, forKey: .response) {
            self.response = resp
        } 
    }
}


class IASearchDocDecodable: Decodable {
    
    public var identifier: String?
    public var title: String?
    public var desc: String?
    public var collection: [String]?
    public var subject: [String] = [String]()
    public var creator: [String] = [String]()
    public var contentDate: String?
    public var archiveDate: String?


    enum CodingKeys: String, CodingKey {
        case identifier
        case title
        case desc
        case collection
        case subject
        case creator
        case contentDate
        case archiveDate
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try values.decodeIfPresent(String.self, forKey: .identifier)
        self.title = try values.decodeIfPresent(String.self, forKey: .title)
        self.desc = try values.decodeIfPresent(String.self, forKey: .desc)
        self.collection = try values.decodeIfPresent([String].self, forKey: .collection)

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

        self.contentDate = try values.decodeIfPresent(String.self, forKey: .contentDate)
        self.archiveDate = try values.decodeIfPresent(String.self, forKey: .archiveDate)
    }

    
    public var displaySubject: String? {

        if self.subject.count > 0 {
            return self.subject.joined(separator: ", ")
        }

        return nil
    }
    
    public var displayCreator: String? {
        if self.creator.count > 0 {
            return self.creator.joined(separator: ", ")
        }

        return nil
    }
    
    public var displayArchiveDate: String? {
        if let date = archiveDate {
            return StringUtils.shortDateFromDateString(date)
        }
        return nil
    }
    
    public var displayContentDate: String? {
        if let date = contentDate {
            return StringUtils.shortDateFromDateString(date)
        }
        return nil
    }
    
    public var iconUrl: URL {
        let itemImageUrl = "http://archive.org/services/img/\(identifier!)"
        return URL(string: itemImageUrl)!
    }
    
}



