# Chester

![CI](https://github.com/JanGorman/Chester/workflows/CI/badge.svg)
[![codecov.io](https://codecov.io/github/JanGorman/Chester/coverage.svg?branch=master)](https://codecov.io/github/JanGorman/Chester?branch=master)
[![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen)](https://swift.org/package-manager/)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/Chester.svg?style=flat)](http://cocoapods.org/pods/Chester)
[![License](https://img.shields.io/cocoapods/l/Chester.svg?style=flat)](http://cocoapods.org/pods/Chester)
[![Platform](https://img.shields.io/cocoapods/p/Chester.svg?style=flat)](http://cocoapods.org/pods/Chester)

## Sort of Experimental: @resultBuilder Support

`@resultBuilder` seems like a natural match for this kind of task. There's a separate `GraphQLBuilderTests` test suite that shows the supported cases. In its basic form you can construct a query like this:

```swift
import Chester

let query = GraphQLQuery {
  From("posts")
  Fields("id", "title")
}
```

Nested queries can be defined in their logical order now:

```swift
let query = GraphQLQuery {
  From("posts")
  Fields("id", "title")
  SubQuery {
    From("comments")
    Fields("body")
    SubQuery {
      From("author")
      Fields("firstname")
    }
  }
}
```

### Known Issues

- Queries with multiple root fields and arguments produce a compiler error (e.g. `'Int' is not convertible to 'Any'`)

## Usage

Chester uses the builder pattern to construct GraphQL queries. In its basic form use it like this:

```swift
import Chester

let query = QueryBuilder()
  .from("posts")
  .with(arguments: Argument(key: "id", value: "20"), Argument(key: "author", value: "Chester"))
  .with(fields: "id", "title", "content")

// For cases with dynamic input, probably best to use a do-catch:

do {
  let queryString = try query.build
} catch {
  // Can specify which errors to catch
}

// Or if you're sure of your query

guard let queryString = try? query.build else { return }
```

You can add subqueries. Add as many as needed. You can nest them as well.

```swift
let commentsQuery = QueryBuilder()
  .from("comments")
  .with(fields: "id", content)
let postsQuery = QueryBuilder()
  .from("posts")
  .with(fields: "id", "title")
  .with(subQuery: commentsQuery)
```

You can search on multiple collections at once

```swift
let search = QueryBuilder()
  .from("search")
  .with(arguments: Argument(key: "text", value: "an"))
  .on("Human", "Droid")
  .with(fields: "name")
  .build()
```
Make a Where Clause query like this
```
      let query2 = try QueryBuilder()
      .from("equipments")
      .with(fields: "name")
      .with(arguments:
              WhereClauseArgument(key: "where", value:
                                    WhereClauseArgument(key: "name", value:
                                                          WhereClauseArgument(key: "isEqualTo", value: "SwarmNano (1)"))))

      let q2String = try query2.build()
      
  // prints  q2String = "{\n  equipments(where: {name: {isEqualTo: \"SwarmNano (1)\"}}) {\n    name\n  }\n}"
  
    let jsonDict: [String: Any] = ["query": q2String]
    
//prints jsonDict =  1 element
//    ▿ 0 : 2 elements
//      - key : "query"
//     - value : "{\n  equipments(where: {name: {isEqualTo: \"SwarmNano (1)\"}}) {\n    name\n  }\n}"
    
    let body = try! JSONSerialization.data(withJSONObject: jsonDict, options: [.fragmentsAllowed])
    
//   String(data: body, encoding: .utf8) 
//   = Optional<String>
//   - some : "{\"query\":\"{\\n  equipments(where: {name: {isEqualTo: \\\"SwarmNano (1)\\\"}}) {\\n    name\\n  }\\n}\"}"
    
    var request = URLRequest(url: URL(string: "http://localhost:8088/private/graphql")!)
    request.httpBody = body
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
```


Check the included unit tests for further examples.


## Requirements

- Swift 5
- Xcode 12.5+
- iOS 8

## Installation

Chester is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Chester"
```

Or [Carthage](https://github.com/Carthage/Carthage). Add Chester to your Cartfile:

```ogdl
github "JanGorman/Chester"
```

Or [Swift Package Manager](https://swift.org/package-manager/). To install it, 
simply go to File > Swift Package > Add Swift Package Dependency and add "https://github.com/JanGorman/Chester.git" as Swift Package URL.
Or add the following line to Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/JanGorman/Chester.git", from: "0.14.0")
]
```



## Author

[Jan Gorman](https://twitter.com/JanGorman)

## License

Chester is available under the MIT license. See the LICENSE file for more info.
