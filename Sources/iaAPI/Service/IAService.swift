//
//  IAService.swift
//  IA-Music
//
//  Created by Hunter Lee Brown on 2/9/17.
//  Copyright © 2017 Hunter Lee Brown. All rights reserved.
//

import Foundation
import UIKit

import Alamofire

public enum IASearchFields : Int {
    case all = 0
    case creator = 1
}


public class IAService {

    public var urlStr : String?
    public var parameters : Dictionary<String, String>!
    public var _queryString : String?
    public var _identifier : String?
    public var _start : Int = 0
    public var searchField : IASearchFields

    public let baseItemUrl = "https://archive.org/metadata/"
    
    public var queryString : String? {
        set {
            self._queryString = newValue!
            self.urlStr = "https://archive.org/advancedsearch.php"
            
            switch self.searchField {
            case .all:
                self._queryString = newValue!
            case .creator:
                self._queryString = "creator:\(newValue!)"
            }

            let nots = ["podcasts_mirror", "web", "webwidecrawl", "samples_only"]
            var queryExclusions = ""
            for not in nots {
                queryExclusions += " AND NOT collection:\(not)"
            }

            self.parameters = [
                "q" : "\(self._queryString!)\(queryExclusions) AND format:\"VBR MP3\" AND (mediatype:audio OR mediatype:etree)",
                "output" : "json",
                "rows" : "50"
            ];
            
        }
        get {
            return self._queryString
        }
        
    }
    
    var request : Request?
    
    
    public typealias SearchResponse = (_ result: [IASearchDocDecodable]?, _ error: Error?) -> Void

    public init() {
        self.searchField = IASearchFields.all
    }
    
    public func searchFetch(_ completion:@escaping SearchResponse) {
        self.request?.cancel()

        guard let qs = self._queryString, qs.count > 0 else {
            completion([IASearchDocDecodable](), nil)
            return
        }

        request = AF.request(urlStr!, method:.post, parameters: parameters)
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

    }
    
    public typealias ArchiveDocResponse = (_ result: IAArchiveDocDecodable?, _ error: Error?) -> Void

    public func archiveDoc(identifier:String, completion:@escaping ArchiveDocResponse) {
        self.request?.cancel()
//        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let baseItemUrl = "https://archive.org/metadata/"
        let urlStr = "\(baseItemUrl)\(identifier)"

        print("url: \(urlStr)")
        
        request = AF.request(urlStr, method:.get, parameters:nil)
            .validate(statusCode: 200..<201)
            .validate(contentType: ["application/json"])
            .responseDecodable(of: IAArchiveDocDecodable.self) { response in
                switch response.result {
                case .success(let doc):

                    print("doc: \(doc)")

                    completion(doc, nil)
                case .failure(let error):

                    print("error: \(error)")

                    completion(nil, error)
                }

            }

        print("request: \(String(describing: request))")
    }
    

}
