//
//  File.swift
//  
//
//  Created by Hunter Lee Brown on 4/6/22.
//

import Foundation
import Combine

open class ArchiveService {

    private var cancellables = Set<AnyCancellable>()

    func getArchive<T: Decodable>(with identifier: String) -> Future<T, Error> {
        return Future<T, Error> { promise in
            guard !identifier.isEmpty, let url = URL(string: "https://archive.org/metadata/\(identifier)") else {
                return promise(.failure(ArchiveServiceError.badIdentifier))
            }

            URLSession.shared.dataTaskPublisher(for: url)
                .tryMap { (data: Data, response: URLResponse) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else { throw ArchiveServiceError.unexpectedHttpResponseCode}
                    return data
                }
                .decode(type: T.self, decoder: JSONDecoder())
                .receive(on: RunLoop.main)
                .sink { completion in
                    if case let .failure(error) = completion {
                        switch (error) {
                        case let decodingError as DecodingError:
                            promise(.failure(decodingError))
                        case let apiError as ArchiveServiceError:
                            promise(.failure(apiError))
                        default:
                            promise(.failure(ArchiveServiceError.unknown))
                        }
                    }
                } receiveValue: { promise(.success($0)) }
                .store(in: &self.cancellables)
        }
    }
}

public enum ArchiveServiceError: Error {
    case badIdentifier
    case unexpectedHttpResponseCode
    case unknown
}

extension ArchiveServiceError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .badIdentifier:
            return "Bad Identifier"
        case .unexpectedHttpResponseCode:
            return "unexpected https response code"
        case .unknown:
            return "unknown error"
        }
    }
}
