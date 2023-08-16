@testable import Models
import XCTest

final class HTMLStringTests: XCTestCase {
  func testURLInit() throws {
    XCTAssertNil(URL(string: "go to www.google.com", encodePath: true))
    XCTAssertNil(URL(string: "go to www.google.com", encodePath: false))
    XCTAssertNil(URL(string: "", encodePath: true))
    
    let simpleUrl = URL(string: "https://www.google.com", encodePath: true)
    XCTAssertEqual("https://www.google.com", simpleUrl?.absoluteString)
    
    let urlWithTrailingSlash = URL(string: "https://www.google.com/", encodePath: true)
    XCTAssertEqual("https://www.google.com/", urlWithTrailingSlash?.absoluteString)
    
    let extendedCharPath = URL(string: "https://en.wikipedia.org/wiki/Elbbrücken_station", encodePath: true)
    XCTAssertEqual("https://en.wikipedia.org/wiki/Elbbr%C3%BCcken_station", extendedCharPath?.absoluteString)
    XCTAssertNil(URL(string: "https://en.wikipedia.org/wiki/Elbbrücken_station", encodePath: false))
    
    let extendedCharQuery = URL(string: "http://test.com/blah/city?name=京都市", encodePath: true)
    XCTAssertEqual("http://test.com/blah/city?name=%E4%BA%AC%E9%83%BD%E5%B8%82", extendedCharQuery?.absoluteString)
  }
}
