import Foundation

final class _CSVKeyedDecoder<K>: KeyedDecodingContainerProtocol where K: CodingKey {
    let codingPath: [CodingKey]
    let allKeys: [K]
    let row: [String: String?]
    
    init(path: CodingPath, row: [String: String?]) {
        self.codingPath = path
        self.allKeys = Array(row.keys).compactMap(K.init)
        self.row = row
    }
    
    func contains(_ key: K) -> Bool {
        return row[key.stringValue] != nil
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        return row[key.stringValue] == nil
    }
    
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        guard let value = row[key.stringValue] else { throw DecodingError.badKey(key, at: self.codingPath + [key]) }
        switch value?.lowercased() {
        case "true", "yes", "t", "y", "1": return true
        case "false", "no", "f", "n", "0": return false
        default: throw DecodingError.unableToExtract(type: type, at: self.codingPath + [key])
        }
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        guard let cell = row[key.stringValue] else { throw DecodingError.badKey(key, at: self.codingPath + [key]) }
        guard let value = cell else { throw DecodingError.nilKey(key, type: type, at: self.codingPath + [key]) }
        return value
    }
    
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        guard let cell = row[key.stringValue] else { throw DecodingError.badKey(key, at: self.codingPath + [key]) }
        guard let value = cell else { throw DecodingError.nilKey(key, type: type, at: self.codingPath + [key]) }
        guard let double = Double(value) else { throw DecodingError.unableToExtract(type: type, at: self.codingPath + [key]) }
        return double
    }
    
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        guard let cell = row[key.stringValue] else { throw DecodingError.badKey(key, at: self.codingPath + [key]) }
        guard let value = cell else { throw DecodingError.nilKey(key, type: type, at: self.codingPath + [key]) }
        guard let float = Float(value) else { throw DecodingError.unableToExtract(type: type, at: self.codingPath + [key]) }
        return float
    }
    
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        guard let cell = row[key.stringValue] else { throw DecodingError.badKey(key, at: self.codingPath + [key]) }
        guard let value = cell else { throw DecodingError.nilKey(key, type: type, at: self.codingPath + [key]) }
        guard let int = Int(value) else { throw DecodingError.unableToExtract(type: type, at: self.codingPath + [key]) }
        return int
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        guard let cell = row[key.stringValue] else { throw DecodingError.badKey(key, at: self.codingPath + [key]) }
        let decoder = _CSVDecoder(cell: cell, path: self.codingPath)
        return try T(from: decoder)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        fatalError()
    }
    
    func superDecoder() throws -> Decoder {
        fatalError()
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        fatalError()
    }
}

extension Dictionary where Key == String, Value == Array<String?> {
    public func makeRows() -> () -> [String: String?]? {
        var rowIndex = 1
        
        func next() -> [String: String?]? {
            defer { rowIndex += 1 }
            guard let first = self.first else { return nil }
            guard rowIndex < first.value.count else { return nil }
            return self.mapValues { $0[rowIndex] }
        }
        
        return next
    }
}
