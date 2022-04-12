//
//  Copyright © 2016 Jan Gorman. All rights reserved.
//

import Foundation

public enum QueryError: Error {
  case missingCollection
  case missingFields
  case missingArguments
  case invalidState(String)
}
public protocol Argument {
    var key: String {get }
    var value: Any {get}

    func build() -> String
}
public struct WhereFilterArgument: Argument {
  public let key: String = "where"
  
  public let value: Any
  
  public init(value: ObjectFilterArgument) {
    self.value = value
  }
  
  
  public func build() -> String {
    let realValue = value as! ObjectFilterArgument
    return "\(key): \(realValue.build())" 
  }
}

public struct ObjectFilterArgument  {
   public var key: String
  ///WhereClauseArgument can be the value of another where clause argument
   public var value: Any

    public init(key: String, value: Any) {
        self.key = key
        self.value = value

    }
    public func build() -> String {
        if let value = value as? ObjectFilterArgument, let _ = GraphQLEscapedString(key) {
          //If the key is equal to "where", then this is the first argument so we dont need brackets around it.
            return "{\(key): \(value.build())}"

        }
       else if let value = value as? String, let escaped = GraphQLEscapedString(value) {
        return "{\(key): \(escaped)}"
      } else if let value = value as? [String: Any] {
        return "{\(key): \(GraphQLEscapedDictionary(value))}"
      } else if let value = value as? [Any] {
        return "{\(key): \(GraphQLEscapedArray(value))}"
      }
      return "{\(key): \(value)}"
    }

}
public struct KeyValueArgument: Argument {

public  let key: String
public  let value: Any

  public init(key: String, value: Any) {
    self.key = key
    self.value = value
  }

  public func build() -> String {
    
    
    if let value = value as? String, let escaped = GraphQLEscapedString(value) {
    return "\(key): \(escaped)"
  } else if let value = value as? [String: Any] {
    return "\(key): \(GraphQLEscapedDictionary(value))"
  } else if let value = value as? [Any] {
    return "\(key): \(GraphQLEscapedArray(value))"
  }
  return "\(key): \(value)"
}

}

public final class QueryBuilder {
  
  public enum OperationType: String, Codable {
   case query
    case mutation
  }
  
  let operationType: OperationType
  fileprivate var queries: [Query]
  
  public init(operationType: OperationType = .query) {
    queries = []
    self.operationType = operationType
  }

  /// The collection to query
  ///
  /// - Parameter from: Querying "from"
  /// - Parameter fields: The fields to query in this collection. Use as an alternative to passing in fields separately
  ///                     or when querying multiple top level collections.
  /// - Parameter arguments: The arguments to limit this collection.
  /// - Parameter subQueries: for this collection.
  public func from(_ from: String, fields: [String]? = nil, arguments: [Argument]? = nil,
                   subQueries: [QueryBuilder]? = nil) -> Self {
    var query = Query(from: from)
    if let fields = fields {
      query.with(fields: fields)
    }
    if let arguments = arguments {
      query.with(arguments: arguments)
    }
    if let subQueries = subQueries {
      query.with(subQueries: subQueries.flatMap(\.queries))
    }
    self.queries.append(query)
    return self
  }
  
  /// Query arguments
  ///
  /// - Parameter arguments: The query args struct(s)
  /// - Throws: `MissingCollection` if no collection is defined before passing in arguments
  @discardableResult
  public func with(arguments: Argument...) throws -> Self {
    guard let lastIndex = queries.indices.last else {
      throw QueryError.missingCollection
    }
    queries[lastIndex].with(arguments: arguments)
    return self
  }

  @discardableResult
  func with(rawArguments arguments: [String]) throws -> Self {
    guard let lastIndex = queries.indices.last else {
      throw QueryError.missingCollection
    }
    queries[lastIndex].with(rawArguments: arguments)
    return self
  }
  
  /// The fields to retrieve
  ///
  /// - Parameter fields: The field names
  /// - Throws: `MissingCollection` if no collection is defined before passing in fields
  @discardableResult
  public func with(fields: String...) throws -> Self {
    try with(fields: fields)
    return self
  }

  @discardableResult
  public func with(fields: [String]) throws -> Self {
    guard let lastIndex = queries.indices.last else {
      throw QueryError.missingCollection
    }
    self.queries[lastIndex].with(fields: fields)
    return self
  }
  
  /// Insert a subquery. Add as many top level or nested queries as desired.
  ///
  /// - Parameter query: The subquery
  /// - Throws: `MissingCollection` if no collection is defined before passing in a subquery
  @discardableResult
  public func with(subQuery query: QueryBuilder) throws -> Self {
    guard let lastIndex = queries.indices.last else {
      throw QueryError.missingCollection
    }
    queries[lastIndex].with(subQueries: query.queries)
    return self
  }

  @discardableResult
  func with(literalSubQuery query: String) throws -> Self {
    guard let lastIndex = queries.indices.last else {
      throw QueryError.missingCollection
    }
    queries[lastIndex].with(literalSubQueries: [query])
    return self
  }
  
  /// Query a number of collections for the same field
  ///
  /// - Parameter collections: The collection names
  public func on(collections: String...) -> Self {
    queries[0].with(onCollections: collections)
    return self
  }

  @discardableResult
  func on(collections: [String]) -> Self {
    queries[0].with(onCollections: collections)
    return self
  }
  
  /// Query for the meta field __typename
  public func withTypename() -> Self {
    queries[0].withTypename = true
    return self
  }
  
  /// Build the query.
  ///
  /// - Returns: The constructed query as String
  /// - Throws: Throws `QueryError` if the builder is in an invalid state before calling `build()` 
  public func build() throws -> String {
    try validateQuery()
    return try QueryStringBuilder(self).build()
  }
  ///Set the URLRequest.httpBody to the data this function returns
  public func convertToJsonData() throws -> Data {
    let buildString = try build()
    let jsonDict = [operationType.rawValue: buildString]
    let jsonData = try JSONEncoder().encode(jsonDict)
    return jsonData
  }
  
  private func validateQuery() throws {
    if queries.isEmpty {
      throw QueryError.missingCollection
    }
    try queries.forEach { try $0.validate() }
  }

}

private class QueryStringBuilder {
  
  private let queryBuilder: QueryBuilder
  
  init(_ queryBuilder: QueryBuilder) {
    self.queryBuilder = queryBuilder
  }
  
  func build() throws -> String {
    let count = queryBuilder.queries.count
    let queryString = try queryBuilder.queries.enumerated().reduce(into: "{\n") { (result, arg1) in
      let (i, query) = arg1
      result += try query.build()
      result += joinCollections(current: i, count: count)
    }
    return queryString + "\n}"
  }
  private func joinCollections(current: Int, count: Int) -> String {
    current == count - 1 ? "" : ",\n"
  }

}
