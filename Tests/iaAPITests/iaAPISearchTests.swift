import XCTest
import Combine
@testable import iaAPI

final class iaAPISearchTests: XCTestCase {

    var testTimeout: TimeInterval = 100


    func testArchiveSearch() {
        let ex = expectation(description: "Expecting search results")

        let service: ArchiveService = ArchiveService()

        var cancellables = Set<AnyCancellable>()

        service.search(query: "Hunter Lee Brown", format: .mp3)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("ERROR: \(error)")
                    XCTFail()
                case .finished:
                    print("Finished getting archive search")
                }
                ex.fulfill()

            } receiveValue: { (results: ArchiveSearchResults) in
                XCTAssertTrue(results.response.numFound > 0)
                results.response.docs.forEach { meta in
                    if let title = meta.archiveTitle {
                        XCTAssertTrue(!title.isEmpty)
                        XCTAssertTrue(!meta.identifier!.isEmpty)
                        print("\(meta.identifier!): \(title)")
                    }
                }
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
    }

    func testAwaitArchiveSearch() {
        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService()

        Task {
            do {
                let results = try await service.searchAsync(query: "Hunter Lee Brown", rows: 50, page: 3, format: .mp3)
                results.response.docs.forEach { meta in
//                    print("identifier: \(meta.identifier!)")
                    XCTAssertTrue(!meta.identifier!.isEmpty)
                }
                print("Page results----> \(results.response.start)")
                dump(results.response)
                ex.fulfill()
            } catch {
                print(error)
                XCTFail()
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
    }

    func testMockAwaitArchiveSearch() {
        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService(.mock)

        Task {
            do {
                let results = try await service.searchAsync(query: "Hunter Lee Brown", format: .mp3)
                results.response.docs.forEach { meta in
                    print("identifier: \(meta.identifier!)")
                    XCTAssertTrue(!meta.identifier!.isEmpty)
                }
                ex.fulfill()
            } catch {
                print(error)
            }
        }

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
    }


    func testMovieSearch() {
        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService()

        Task {
            do {
                let results = try await service.searchAsync(query: "San Francisco", mediaTypes: [.movies], format: nil, collection: "prelinger")
                results.response.docs.forEach { meta in
                    print("identifier: \(meta.identifier!)")
                    XCTAssertTrue(!meta.identifier!.isEmpty)
                }
                ex.fulfill()
            } catch {
                print(error)
            }
        }

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
    }

    func testLibrivoxCollectionSearch() {
        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService()

        Task {
            do {
                let results = try await service.searchAsync(query: "Charles Dickens", format: .mp3, collection:"librivoxaudio")
                results.response.docs.forEach { meta in
                    dump(meta)
                    XCTAssertTrue(!meta.identifier!.isEmpty)
                }
                ex.fulfill()
            } catch {
                print(error)
            }
        }

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
    }

    func testTopCollections() {

        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService()

        Task {
            do {
                let results = try await service.getCollections(from: .movies)
                results.response.docs.forEach { meta in
                    dump(meta.archiveTitle)
                    XCTAssertTrue(!meta.identifier!.isEmpty)
                }
                ex.fulfill()
            } catch {
                print(error)
            }
        }

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
    }

    func testPPSArchiveSearch() {
        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService()

        Task {
            do {
                let results = try await service.searchPPSAsync(query: "hunterleebrown", rows: 50, page: 1, format: .mp3)
                results.response.docs.forEach { meta in
//                    print("identifier: \(meta.identifier!)")
                    XCTAssertTrue(!meta.identifier!.isEmpty)
                }
                print("Page results----> \(results.response.start)")
                dump(results.response)
                ex.fulfill()
            } catch {
                print(error)
                XCTFail()
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
    }

}
