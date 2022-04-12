//
//  Copyright © 2016 Jan Gorman. All rights reserved.
//

import XCTest
import Chester

class QueryBuilderTests: XCTestCase {

  func testQueryWithFields() throws {
    let query = try QueryBuilder()
      .from("posts")
      .with(fields: "id", "title")
      .build()
    
    let expectation = try TestHelper().loadExpectationForTest(#function)
    
    XCTAssertEqual(expectation, query)
  }

  func testQueryWithSubQuery() throws {
//    let expectation = self.expectation(description: "Thing")
//    let query2 = try QueryBuilder(operationType: .query)
//      .from("equipments")
//      .with(fields: "name")
//
//      .with(arguments:
//              WhereFilterArgument(value:
//                                    ObjectFilterArgument(key: "name", value:
//                                                          ObjectFilterArgument(key: "isEqualTo", value: "SwarmNano (1)"))))
//
//    let convertBody = try query2.convertToJsonData()
//
//
//    var request = URLRequest(url: URL(string: "http://localhost:8088/private/graphql")!)
//    request.httpBody = convertBody
//    request.httpMethod = "POST"
//    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//    request.setValue(
//        "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjY0MDkyMjExMjAwLCJJRCI6IjMxRjRGM0VFLThGOEYtNDZFMi1CQzZELUE5REFFOENDOTA3RSIsImlzcyI6IlBhc3NpdmVMb2dpYyIsIm5hbWUiOiJhZG1pbiIsInN1YiI6IkFQSSJ9.IDU0cZ8DDFH6Lly1wKfv-sePLXa3nvlS0WhDnCVhfg4",
//        forHTTPHeaderField: "Authorization"
//    )
//
//
//
//    URLSession.shared.dataTask(with: request) { data, response, error in
//      do {
//             let returni = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments])
//        print("returni \(returni)")
//        expectation.fulfill()
//      } catch {
//print("error \(error)")
//
//      }
//
//
//    }.resume()
//
//    wait(for: [expectation], timeout: 10)
//
//      let commentsQuery = try! QueryBuilder()
//        .from("comments")
//        .with(fields: "body")
//      let postsQuery = try! QueryBuilder()
//        .from("posts")
//        .with(fields: "id", "title")
//        .with(subQuery: commentsQuery)
//        .build()
//    let expectationi = try TestHelper().loadExpectationForTest(#function)
//    XCTAssertEqual(expectationi, postsQuery)
//
//  }
//
//  func testQueryWithNestedSubQueries() throws {
//    let authorQuery = try QueryBuilder()
//      .from("author")
//      .with(fields: "firstname")
//    let commentsQuery = try QueryBuilder()
//      .from("comments")
//      .with(fields: "body")
//      .with(subQuery: authorQuery)
//    let postsQuery = try QueryBuilder()
//      .from("posts")
//      .with(fields: "id", "title")
//      .with(subQuery: commentsQuery)
//      .build()
//
//    let expectation = try TestHelper().loadExpectationForTest(#function)
//
//    XCTAssertEqual(expectation, postsQuery)
  }
  
  func testInvalidQueryThrows() throws {
    XCTAssertThrowsError(try QueryBuilder().build())
    XCTAssertThrowsError(try QueryBuilder().with(fields: "id").build())
    XCTAssertThrowsError(try QueryBuilder().from("foo").build())
    XCTAssertThrowsError(try QueryBuilder().with(arguments: KeyValueArgument(key: "key", value: "value")).build())
    
    let subQuery = try QueryBuilder().from("foo").with(fields: "foo")
    
    XCTAssertThrowsError(try QueryBuilder().with(subQuery: subQuery))
  }
  
  func testQueryArgs() throws {
    let query = try QueryBuilder()
      .from("posts")
      .with(arguments: KeyValueArgument(key: "id", value: 4), KeyValueArgument(key: "author", value: "Chester"))
      .with(fields: "id", "title")
      .build()
    
    let expectation = try TestHelper().loadExpectationForTest(#function)
    
    XCTAssertEqual(expectation, query)
  }
  
  func testQueryArgsWithSpecialCharacters() throws {
    let query = try QueryBuilder()
      .from("posts")
      .with(arguments: KeyValueArgument(key: "id", value: 4),
            KeyValueArgument(key: "author", value: "\tIs this an \"emoji\"? 👻 \r\n(y\\n)Special\u{8}\u{c}\u{4}\u{1b}"))
      .with(fields: "id", "title")
      .build()
    
    let expectation = try TestHelper().loadExpectationForTest(#function)
    
    XCTAssertEqual(expectation, query)
  }
  
  func testQueryArgsWithDictionary() throws {
    let query = try QueryBuilder()
      .from("posts")
      .with(arguments: KeyValueArgument(key: "id", value: 4),
            KeyValueArgument(key: "filter", value: [["author": ["Chester"]], ["author": "Iskander"], ["books": 1]]))
      .with(fields: "id", "title")
      .build()
    
    let expectation = try TestHelper().loadExpectationForTest(#function)
    
    XCTAssertEqual(expectation, query)
  }
  
  func testQueryWithMultipleRootFields() throws {
    let query = try QueryBuilder()
      .from("posts", fields: ["id", "title"])
      .from("comments", fields: ["body"])
      .build()
    
    let expectation = try TestHelper().loadExpectationForTest(#function)
    
    XCTAssertEqual(expectation, query)
  }
  
  func testQueryWithMultipleRootFieldsAndArgs() throws {
    let query = try QueryBuilder()
      .from("posts", fields: ["id", "title"], arguments: [KeyValueArgument(key: "id", value: 5)])
      .from("comments", fields: ["body"], arguments: [KeyValueArgument(key: "author", value: "Chester"),
                                                      KeyValueArgument(key: "limit", value: 10)])
      .build()
    
    let expectation = try TestHelper().loadExpectationForTest(#function)
    
    XCTAssertEqual(expectation, query)
  }
  
  func testQueryWithMultipleRootAndSubQueries() throws {
    let avatarQuery = try QueryBuilder()
      .from("avatars")
      .with(arguments: KeyValueArgument(key: "width", value: 100))
      .with(fields: "url")
    let query = try QueryBuilder()
      .from("posts", fields: ["id"], subQueries: [avatarQuery])
      .from("comments", fields: ["body"])
      .build()

    let expectation = try TestHelper().loadExpectationForTest(#function)

    XCTAssertEqual(expectation, query)
  }
  
  func testQueryOn() throws {
    let query = try QueryBuilder()
      .from("search")
      .with(arguments: KeyValueArgument(key: "text", value: "an"))
      .on(collections: "Human", "Droid")
      .with(fields: "name")
      .build()
    
    let expectation = try TestHelper().loadExpectationForTest(#function)
    
    XCTAssertEqual(expectation, query)
  }
  
  func testQueryOnWithTypename() throws {
    let query = try QueryBuilder()
      .from("search")
      .with(arguments: KeyValueArgument(key: "text", value: "an"))
      .on(collections: "Human", "Droid")
      .withTypename()
      .with(fields: "name")
      .build()
    
    let expectation = try TestHelper().loadExpectationForTest(#function)
    
    XCTAssertEqual(expectation, query)
  }
  
}
