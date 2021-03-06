import XCTest
import CSV

final class EncoderTests: XCTestCase {
    func testAsyncEncode() throws {
        var rows: [[UInt8]] = []
        let encoder = CSVEncoder().async { row in rows.append(row) }

        for person in people {
            try encoder.encode(person)
        }

        let string = String(decoding: Array(rows.joined(separator: [10])), as: UTF8.self)
        XCTAssertEqual(string, expected)
    }

    func testMeasureAsyncEncode() {
        
        // 0.543
        measure {
            for _ in 0..<10_000 {
                let encoder = CSVEncoder().async { _ in return }
                do {
                    try people.forEach(encoder.encode)
                } catch let error as EncodingError {
                    XCTFail(error.failureReason ?? "No failure reason")
                    error.errorDescription.map { print($0) }
                    error.recoverySuggestion.map { print($0) }
                } catch let error {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }

    func testSyncEncode() throws {
        let encoder = CSVEncoder().sync
        let encoded = try encoder.encode(people)
        let string = String(decoding: encoded, as: UTF8.self)

        XCTAssertEqual(string, expected)
    }

    func testMeasureSyncEncode() {

        // 0.621
        measure {
            for _ in 0..<10_000 {
                let encoder = CSVEncoder().sync
                do {
                    _ = try encoder.encode(people)
                } catch let error as EncodingError {
                    XCTFail(error.failureReason ?? "No failure reason")
                    error.errorDescription.map { print($0) }
                    error.recoverySuggestion.map { print($0) }
                } catch let error {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }

    func testEscapingDelimiters() throws {
        let quotePerson = Person(firstName: "A", lastName: "J", age: 42, gender: .male, tagLine: #"All "with quotes""#)
        let hashPerson = Person(firstName: "M", lastName: "A", age: 28, gender: .female, tagLine: "#iWin#")

        let quoteResult = """
        "first name","last_name","age","gender","tagLine"
        "A","J","42","M","All ""with quotes""\"
        """
        let hashResult = """
        #first name#,#last_name#,#age#,#gender#,#tagLine#
        #M#,#A#,#28#,#F#,###iWin###
        """

        let quoteEncoder = CSVEncoder().sync
        let hashEncoder = CSVEncoder(encodingOptions: .default, configuration: .init(cellSeparator: 44, cellDelimiter: 35)).sync

        try XCTAssertEqual(quoteEncoder.encode([quotePerson]), Data(quoteResult.utf8))
        try XCTAssertEqual(hashEncoder.encode([hashPerson]), Data(hashResult.utf8))
    }

    func testEncodingColumnValues() throws {
        let data = [
            ["a": "hello", "b": "true", "c": "1"],
            ["a": "world", "b": "false", "c": "2"],
            ["a": "fizz", "b": "false", "c": "3"],
            ["a": "buzz", "b": "true", "c": "5"],
            ["a": "foo", "b": "false", "c": "8"],
            ["a": "bar", "b": "true", "c": "13"],
        ]

        var header = Optional<Array<String>>.none
        var index = 0

        let encoder = CSVEncoder().async { row in
            guard let keys = header else {
                header = String(decoding: row, as: UTF8.self).split(separator: ",").map {
                    String($0).trimmingCharacters(in: .punctuationCharacters)
                }

                return
            }

            let object = data[index]
            let cells = String(decoding: row, as: UTF8.self).split(separator: ",").map {
                String($0).trimmingCharacters(in: .punctuationCharacters)
            }

            keys.enumerated().forEach { offset, name in
                XCTAssertEqual(
                    object[name], cells[offset],
                    "Row \(index), column '\(name)' has value '\(cells[offset])'. Expected '\(object[name] ?? "<null>")'"
                )
            }

            index += 1
        }
        try data.forEach(encoder.encode(_:))
    }
}

fileprivate struct Person: Codable, Equatable {
    let firstName: String
    let lastName: String?
    let age: Int
    let gender: Gender
    let tagLine: String?

    enum Gender: String, Codable {
        case female = "F"
        case male = "M"
    }

    enum CodingKeys: String, CodingKey {
        case firstName = "first name"
        case lastName = "last_name"
        case age
        case gender
        case tagLine
    }
}

fileprivate let people = [
    Person(firstName: "Caleb", lastName: "Kleveter", age: 18, gender: .male, tagLine: "😜"),
    Person(firstName: "Benjamin", lastName: "Franklin", age: 269, gender: .male, tagLine: "A penny saved is a penny earned"),
    Person(firstName: "Doc", lastName: "Holliday", age: 174, gender: .male, tagLine: "Bang"),
    Person(firstName: "Grace", lastName: "Hopper", age: 119, gender: .female, tagLine: nil),
    Person(
        firstName: "Anne", lastName: "Shirley", age: 141, gender: .female,
        tagLine: "God's in His heaven,\nall's right with the world"
    ),
    Person(firstName: "TinTin", lastName: nil, age: 16, gender: .male, tagLine: "Great snakes!")
]
