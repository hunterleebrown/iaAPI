//
//  IAService.swift
//  iaAPI
//
//  Created by Hunter Lee Brown Lee Brown
//  


import Foundation
import UIKit

import Alamofire

public enum IASearchField : Int {
    case all = 0
    case creator = 1
}

public class IAService {

    public var notIncluding: [String] = ["podcasts_mirror", "web", "webwidecrawl", "samples_only"]

    let urlStr: String = "https://archive.org/advancedsearch.php"
    let baseItemUrl = "https://archive.org/metadata/"

    var _queryString: String?
    var _identifier: String?
    var _start: Int = 0

    
    private func buildQueryParameters(input: String,
                                      searchField: IASearchField,
                                      mediaTypes:[IAMediaType],
                                      format:IAFileFormat,
                                      rows:Int)-> Dictionary<String, String>? {

        guard input.count > 0 else {
            return nil
        }

        var queryString = ""

        var parameters: Dictionary<String, String>

        switch searchField {
        case .all:
            queryString = input
        case .creator:
            queryString = "creator:\(input)"
        }

        let nots = self.notIncluding
        var queryExclusions = ""
        for not in nots {
            queryExclusions += " AND NOT collection:\(not)"
        }

        var qmediaTypes: [String] = []
        mediaTypes.forEach { (type) in
            qmediaTypes.append("mediaType:\(type.rawValue)")
        }
        let queryMediaTypes = qmediaTypes.joined(separator: " OR ")

        parameters = [
            "q" : "\(queryString)\(queryExclusions) AND format:\"\(format.rawValue)\" AND (\(queryMediaTypes))",
            "output" : "json",
            "rows" : "\(rows)"
        ];


        return parameters
    }
    
    var request : Request?



    public typealias SearchResponse = (_ result: [IASearchDoc]?, _ error: Error?) -> Void

    @discardableResult public func searchFetch(queryString: String,
                                               searchField: IASearchField = .all,
                                               mediaTypes:[IAMediaType] = [.audio, .etree],
                                               format:IAFileFormat = .mp3,
                                               rows: Int = 50,
                                               completion:@escaping SearchResponse) -> Request? {
        self.request?.cancel()

        guard let parameters = buildQueryParameters(input: queryString,
                                                    searchField: searchField,
                                                    mediaTypes: mediaTypes,
                                                    format: format,
                                                    rows: rows) else {
            completion([IASearchDoc](), nil)
            return nil
        }

        request = AF.request(self.urlStr, method:.post, parameters: parameters)
            .validate(statusCode: 200..<201)
            .validate(contentType: ["application/json"])
            .responseDecodable(of: IASearchResults.self) { response in
                switch response.result {
                case .success(let results):
                    completion(results.response?.docs, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }

        return request ?? nil
    }

    public typealias ArchiveDocResponse = (_ result: IAArchiveDoc?, _ error: Error?) -> Void

    public func archiveDoc(identifier:String, completion:@escaping ArchiveDocResponse) {
        self.request?.cancel()

        let baseItemUrl = "https://archive.org/metadata/"
        let urlStr = "\(baseItemUrl)\(identifier)"

        request = AF.request(urlStr, method:.get, parameters:nil)
            .validate(statusCode: 200..<201)
            .validate(contentType: ["application/json"])
            .responseDecodable(of: IAArchiveDoc.self) { response in
                switch response.result {
                case .success(let doc):
                    print("doc: \(doc)")
                    completion(doc, nil)
                case .failure(let error):
                    print("error: \(error)")
                    completion(nil, error)
                }
            }
    }
    

}
