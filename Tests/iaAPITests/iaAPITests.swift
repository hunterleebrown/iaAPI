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

        let req = service.searchFetch(queryString: "\"\(searchTitle)\"") { (contents, error) in

            if let contentItems = contents {
                print("contentItems: \(contentItems)")
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

    static var allTests = [
        ("testExample", testExample),
    ]
}
