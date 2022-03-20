import XCTest
@testable import iaAPI

final class iaAPITests: XCTestCase {

    let service = IAService()
    var testTimeout: TimeInterval = 20

    override class func setUp() {
        super.setUp()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(iaAPI().text, "Hello, World!")
    }

    func testSearch() {

        let ex = expectation(description: "Expecting search data not nil")

        let searchTitle = "Hunter Lee Brown - Piano Works"

        let req = service.searchMp3(queryString: "\(searchTitle)") { (contents, error) in
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
        let ex = expectation(description: "Expecting search data not nil")

        service.mockSearch { result, error in
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
        let ex = expectation(description: "Expecting search data not nil")

        service.mockArchiveDoc { doc, error in
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
    
    static var allTests = [
        ("testExample", testExample),
    ]
}
