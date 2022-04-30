import XCTest
import Combine
@testable import iaAPI

final class iaAPITests: XCTestCase {

    var testTimeout: TimeInterval = 100

    func testGetArchiveMock() {
        var cancellables = Set<AnyCancellable>()
        let ex = expectation(description: "Expecting archive doc data not nil")
        let identifier = "HunterLeeBrownPianoWorks2010-2011"
        
        let service = ArchiveService(.mock)
        service.getArchive(with: "whatever")
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("Error: \(error)")
                    XCTFail()
                case .finished:
                    print("Finished getting mock Archived")
                }
                ex.fulfill()
            } receiveValue: { arc in
                
                guard let title = arc.metadata?.archiveTitle,
                        let mockIdentitifer = arc.metadata?.identifier else {
                    XCTFail()
                    return }
                
                print(title)
                print(identifier)
                
                XCTAssertEqual(mockIdentitifer, identifier)
                
            }.store(in: &cancellables)

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
                guard let title = arc.metadata?.archiveTitle, let mediaType = arc.metadata?.mediatype else {
                    XCTFail()
                    return }
//                XCTAssertEqual(title, "Let's Have Another Cup O' Coffee")
                XCTAssertEqual(title, "Hunter Lee Brown - Love Songs")
                XCTAssertEqual(mediaType, ArchiveMediaType.audio)
                arc.files.forEach { file in
                    XCTAssertNotNil(file.format)
                    if let url = file.url, let identifier = file.identifier {
                        print(url.description, identifier)
                    }
                }
                dump(arc)
                print(arc.metadata?.iconUrl.description ?? "")
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

    
    
    func testAwaitArchiveMetadata() {
        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService()

        Task {
            do {
                let archive = try await service.getArchiveAsync(with: "hunterleebrown-lovesongs")
                if let title = archive.metadata?.archiveTitle {
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

    func testMockAwaitArchiveMetadata() {
        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService(.mock)

        let mockIdentifier = "HunterLeeBrownPianoWorks2010-2011"
        let mockTitle = "Hunter Lee Brown - Piano Works"
        
        Task {
            do {
                let archive = try await service.getArchiveAsync(with: mockIdentifier)
                if let title = archive.metadata?.archiveTitle {
                    print("archive title: \(title)")
                    XCTAssertEqual(title, mockTitle)
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

    func testHugeAwaitArchiveMetadata() {
        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService()

        Task {
            do {
                let archive = try await service.getArchiveAsync(with: "tntvillage_484164")
                if let title = archive.metadata?.archiveTitle {
                    print("archive title: \(title)")
                    XCTAssertEqual(title, "Glenn Miller - Discografia (1935-2006)")
                    ex.fulfill()
                }
                for(index, file) in archive.non78Audio.enumerated(){
                    print("\(index). \(file.name)")
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

    
    func testAwaitBadArchiveMetadata() {
        let ex = expectation(description: "Expecting search results")
        let service = ArchiveService()

        Task {
            do {
                _ = try await service.getArchiveAsync(with: "hunterledsdsadebrown-lovesongs")
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
