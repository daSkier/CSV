internal final class AsyncDecoder: Decoder {
    internal enum Storage {
        case none
        case singleValue([UInt8])
        case keyedValues([String: [UInt8]])
    }

    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey : Any]
    var decoding: Decodable.Type
    var handler: AsyncDecoderHandler
    var decodingOptions: CSVCodingOptions
    var onInstance: (Decodable)throws -> ()
    var data: Storage


    init(
        decoding: Decodable.Type,
        path: [CodingKey],
        info: [CodingUserInfoKey : Any] = [:],
        data: Storage = .none,
        decodingOptions: CSVCodingOptions,
        configuration: Config = Config.default,
        onInstance: @escaping (Decodable)throws -> ()
    ) {
        self.codingPath = path
        self.userInfo = info
        self.decoding = decoding
        self.handler = AsyncDecoderHandler(configuration: configuration){ _ in return }
        self.decodingOptions = decodingOptions
        self.onInstance = onInstance
        self.data = data

        self.handler.onRow = { [unowned self] row in
            self.data = .keyedValues(row)
            let decoded = try self.decoding.init(from: self)
            try self.onInstance(decoded)
            self.data = .none
        }

        if self.userInfo[CodingUserInfoKey(rawValue: "decoder")!] == nil {
            self.userInfo[CodingUserInfoKey(rawValue: "decoder")!] = "CSVDecoder(Async)"
        }
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard case .keyedValues = self.data else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: self.codingPath,
                debugDescription: "Attempted to created keyed container with unkeyed data"
            ))
        }

        let container = try AsyncKeyedDecoder<Key>(path: self.codingPath, decoder: self)
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError()
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        guard case .singleValue = self.data else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: self.codingPath,
                debugDescription: "Attempted to create single value container with keyed data"
            ))
        }

        return try AsyncSingleValueDecoder(path: self.codingPath, decoder: self)
    }

    func decode(_ data: [UInt8], length: Int)throws {
        try self.handler.parse(data, length: length).get()
    }
}

internal final class AsyncDecoderHandler {
    var parser: Parser
    var currentRow: [String: [UInt8]]
    var onRow: ([String: [UInt8]])throws -> ()

    private var columnCount: Int
    private var currentColumn: Int

    init(configuration: Config = Config.default, onRow: @escaping ([String: [UInt8]])throws -> ()) {
        self.parser = Parser(configuration: configuration)
        self.currentRow = [:]
        self.onRow = onRow
        self.columnCount = 0
        self.currentColumn = 0

        self.parser.onHeader = { _ in self.columnCount += 1 }
        self.parser.onCell = { header, cell in
            self.currentRow[String(decoding: header, as: UTF8.self)] = cell
            if self.currentColumn == (self.columnCount - 1) {
                self.currentColumn = 0
                try self.onRow(self.currentRow)
            } else {
                self.currentColumn += 1
            }
        }
    }

    func parse(_ bytes: [UInt8], length: Int) -> Result<Void, ErrorList> {
        return self.parser.parse(bytes, length: length)
    }
}
