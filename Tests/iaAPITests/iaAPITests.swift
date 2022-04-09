import XCTest
import Combine
@testable import iaAPI

final class iaAPITests: XCTestCase {

    var testTimeout: TimeInterval = 100

    func testSearch() {
        let service = IAService(.online)
        let ex = expectation(description: "Expecting search data not nil")
        let searchTitle = "Hunter Lee Brown - Piano Works"
        let req = service.searchMp3(queryString: searchTitle) { (contents, error) in
            if let contentItems = contents {
                var found = false
                contentItems.enumerated().forEach { (index, doc) in
                    if doc.title == searchTitle {
                        found = true
                    }
                }
                XCTAssert(found)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
            print("request: \(String(describing: req))")

        }
    }

    func testDetails() {
        let service = IAService(.online)

        let ex = expectation(description: "Expecting search data not nil")

        let ident = "HunterLeeBrownPianoWorks2010-2011"
        let docTitle = "Hunter Lee Brown - Piano Works"

        service.archiveDoc(identifier: ident, completion: { (inDoc, error) in
            if let doc = inDoc {
                print("the doc: \(doc)")
            }
            if let title = inDoc?.title {
                XCTAssert(title == docTitle)
            }
            ex.fulfill()
        })

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }

    }

    func test78Collection() {

        let service = IAService(.online)

        let ex = expectation(description: "Expecting search data not nil")

        let ident = "78_lets-have-another-cup-o-coffee_glenn-miller-and-his-orchestra-irving-berlin-mario_gbia0015317a"
        let docTitle = "Let's Have Another Cup O' Coffee"

        service.archiveDoc(identifier: ident, completion: { (inDoc, error) in
            if let doc = inDoc {
                print("the doc: \(doc)")
            }
            if let title = inDoc?.title {
                XCTAssert(title == docTitle)
            }

            if let collection = inDoc?.metadata.collection {
                print("collection: \(collection)");
                XCTAssert(collection.contains("78rpm"))
            }

            if let publisher = inDoc?.metadata.publisher {
                print("publisher: \(publisher)")
                XCTAssert(publisher == "Bluebird")
            }

            ex.fulfill()
        })

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
    }

    
    func testMockSearch() {
        
        let service = IAService(.offline)
        
        let ex = expectation(description: "Expecting search data not nil")

        service.searchMp3(queryString: "Nothing") { result, error in
            if let docs = result {
                if docs.count > 0 {
                    docs.forEach { doc in
                        print("\(doc.identifier!) \(doc.title!)")
                    }
                    ex.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
        
    }
    
    func testMockArchiveDoc() {
        
        let service = IAService(.offline)

        let ex = expectation(description: "Expecting search data not nil")

        service.archiveDoc(identifier: "Nothing") { doc, error in
            if let aDoc = doc {
                print("\(aDoc.identifier!) \(aDoc.title!)")
                ex.fulfill()
            }
        }
        
        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
        
    }

    func testGetArchive() {

        let ex = expectation(description: "Expecting archive doc data not nil")
        var cancellables = Set<AnyCancellable>()

        let service = ArchiveService()
//        let identifier = "78_lets-have-another-cup-o-coffee_glenn-miller-and-his-orchestra-irving-berlin-mario_gbia0015317a"
        let identifier = "hunterleebrown-lovesongs"

        service.getArchive(with: identifier)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("ERROR: \(error)")
                    XCTFail()
                case .finished:
                    print("Finished getting archive data")
                }
                ex.fulfill()

            } receiveValue: { (arc: Archive) in
                guard let title = arc.metadata?.title, let mediaType = arc.metadata?.mediatype else {
                    XCTFail()
                    return }
                XCTAssertEqual(title, "Hunter Lee Brown - Love Songs")
                XCTAssertEqual(mediaType, ArchiveMediaType.audio)
                arc.files.forEach { file in
                    XCTAssertNotNil(file.format)
                    print(file.url, file.identifier)
                }
                dump(arc)
                print(arc.metadata?.iconUrl)
                dump(arc.audioFiles, name: "audio")
                dump(arc.non78Audio, name: "non 78: ")
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
    }

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
                    if let title = meta.title, let identifier = meta.identifier {
                        XCTAssertTrue(!title.isEmpty)
                        XCTAssertTrue(!identifier.isEmpty)
                        print("\(identifier): \(title)")
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
                let results = try await service.searchAsync(query: "Hunter Lee Brown", format: .mp3)
                results.response.docs.forEach { meta in
                    if let identifier = meta.identifier {
                        print("identifier: \(identifier)")
                        XCTAssertTrue(!identifier.isEmpty)
                    }
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

    func testArchiveMetadataAsync() {
        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService()

        Task {
            do {
                let archive = try await service.getArchiveAsync(with: "hunterleebrown-lovesongs")
                if let title = archive.metadata?.title {
                    print("archive title: \(title)")
                    XCTAssertEqual(title, "Hunter Lee Brown - Love Songs")
                    ex.fulfill()
                }
            } catch {
                print(error)
                ex.fulfill()
            }
        }

        waitForExpectations(timeout: testTimeout) { (error) in
            if let error = error {
                XCTFail("error: \(error)")
            }
        }
    }

    func testBadArchiveMetadataAsync() {
        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService()

        Task {
            do {
                try await service.getArchiveAsync(with: "hunterledsdsadebrown-lovesongs")
            } catch let error as ArchiveServiceError {
                XCTAssertTrue(error == .nodata)
                XCTAssertEqual(error.description, "there is no data")
                print(error)
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
