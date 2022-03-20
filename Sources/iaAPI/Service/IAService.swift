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
    
    public init() { }
    
    public var notIncluding: [String] = ["podcasts_mirror", "web", "webwidecrawl", "samples_only"]
    
    let urlStr: String = "https://archive.org/advancedsearch.php"
    let baseItemUrl = "https://archive.org/metadata/"
    
    var _queryString: String?
    var _identifier: String?
    var _start: Int = 0
    
    private func buildQueryParameters(input: String,
                                      searchField: IASearchField,
                                      mediaTypes:[IAMediaType],
                                      rows:Int,
                                      format:IAFileFormat?
    )-> Dictionary<String, String>? {
        
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
        
        var query:String = "\(queryString)\(queryExclusions) AND (\(queryMediaTypes))"
        if let f = format {
            query.append(" AND format:\"\(f.rawValue)\" ")
        }
        parameters = [
            "q" : query,
            "output" : "json",
            "rows" : "\(rows)"
        ];
        
        
        return parameters
    }
    
    var request : Request?
    
    public typealias SearchResponse = (_ result: [IASearchDoc]?, _ error: Error?) -> Void
    
    @discardableResult public func searchMp3(queryString: String, completion:@escaping SearchResponse) -> Request? {
        return self.search(queryString: queryString, format: .mp3, completion: completion)
    }
    
    @discardableResult public func search(
        queryString: String,
        searchField: IASearchField = .all,
        mediaTypes:[IAMediaType] = [.audio, .etree],
        rows: Int = 50,
        format: IAFileFormat?,
        completion:@escaping SearchResponse) -> Request? {
            self.request?.cancel()
            
            guard let parameters = buildQueryParameters(input: queryString,
                                                        searchField: searchField,
                                                        mediaTypes: mediaTypes,
                                                        rows: rows,
                                                        format: format) else {
                completion([IASearchDoc](), nil)
                return nil
            }
            
            dump(parameters);
            
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
    
    public func mockSearch(completion:@escaping SearchResponse) {
        if let data = IAStatic.searchResult.data(using: .utf8) {
            let decoder = JSONDecoder()
            let jsonData = try! decoder.decode(IASearchResults.self, from: data)
            print(jsonData)
            completion(jsonData.response?.docs, nil)
        }
    }
    
    public func mockArchiveDoc(completion:@escaping ArchiveDocResponse) {
        if let data = IAStatic.archiveDoc.data(using: .utf8) {
            let decoder = JSONDecoder()
            let jsonData = try! decoder.decode(IAArchiveDoc.self, from: data)
            print(jsonData)
            completion(jsonData, nil)
        }
    }
}
